-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Copyright (c) 2025-2026 Thomas Floeren

local MYNAME, A = ...
local MYPRETTYNAME = C_AddOns.GetAddOnMetadata(MYNAME, 'Title')
local MYVERSION = C_AddOns.GetAddOnMetadata(MYNAME, 'Version')
local MYSHORTNAME = 'BMX'
local DB_ID = 'DB_6583B024_97F4_47B0_8F4C_BB1C1B4FE393'

local WTC = WrapTextInColorCode
local tonumber = tonumber
local type = type
local format = format

-- Misc variables
local split_records = true
local split_lines = true
if split_lines then split_records = true end
local FILLCHAR = '-'
-- Hours to subtract from the set new auction start time (e.g. 23:30), to get plausible time frames.
local OFFSET_PLAUSIBLE_EARLYTIME = 5
local OFFSET_PLAUSIBLE_LATETIME = 0

--[[============================================================================
	SavedVariables and Defaults
============================================================================]]--

-- Note that we have the `LoadSavedVariablesFirst: 1` directive in the toc,
-- so no need to wait for ADDON_LOADED.

local function merge_defaults(src, dst)
	for k, v in pairs(src) do
		local src_type = type(v)
		if src_type == 'table' then
			if type(dst[k]) ~= 'table' then
				dst[k] = {}
			end
			merge_defaults(v, dst[k])
		elseif type(dst[k]) ~= src_type then
			dst[k] = v
		end
	end
end

-- DB version log here
local DB_VERSION_CURRENT = 1

local defaults = {
	cfg = {
		debugmode = false,
		auction_starttime = '23:30',
		ellipsis_replacement = nil,
		num_records_max = 1,
		num_lines_max = 10,
		do_limit_num_records = true,
		do_limit_num_lines = nil,
		display_list = true,
		show_timeframe = true,
		show_timerem = true,
		show_timetier = true,
		show_bids = true,
		timeframe_plausibilityfilter_early = nil,
		timeframe_color_by_src = true,
		timeframe_color_by_rem = nil,
		last_at_top = nil,
		do_truncate = true,
		len_truncate = 10,
		fixed_name_len = nil,
	},
	auctions = {
	},
	textcache = {
	},
	db_version = DB_VERSION_CURRENT,
}

if type(_G[DB_ID]) ~= 'table' then
	_G[DB_ID] = {}
elseif not _G[DB_ID].db_version or _G[DB_ID].db_version ~= DB_VERSION_CURRENT then
	-- Clean up old db stuff here
	_G[DB_ID].db_version = DB_VERSION_CURRENT
end

merge_defaults(defaults, _G[DB_ID])

local db = _G[DB_ID]
A.db = db
A.defaults = defaults

-- Dev config
db.cfg.do_limit_num_records = true
db.cfg.num_records_max = 3
db.cfg.len_truncate = 30

--[[============================================================================
	Constants and Utils
============================================================================]]--

--[[----------------------------------------------------------------------------
	Color
----------------------------------------------------------------------------]]--

local colors = {
	ADDON = '1E90FF', -- dodgerblue
	TXT = 'FFF8DC', -- cornsilk
	DEBUG = 'FF00FF', -- magenta
	HEAD = 'FFE4B5', -- moccasin
	WARN = 'FF4500', -- orangered
	BAD = 'DC143C', -- crimson
	ON = '32CD32', -- limegreen
	OFF = 'C0C0C0', -- silver
	CMD = 'FFA500', -- orange
	KEY = 'FFD700', -- gold
	XXX = '00FA9A', -- mediumspringgreen
	YYY = '90EE90', -- lightgreen
}

local CLR = setmetatable({}, {
	__index = function(_, k)
		local color = colors[k]
		assert(color, format('Color %q not defined.', k))
		color = 'FF' .. color
		return function(text) return text and WTC(text, color) or '\124c' .. color end
	end,
})

-- Usage: print('text ' .. CLR.WARN('warning') .. ' text' .. CLR.HEAD() .. ' text')

local BLOCKSEP = CLR.ADDON(strrep('+', 42))

local function addonprint(msg)
	print(format('%s%s: %s', CLR.ADDON(), MYPRETTYNAME, CLR.TXT(msg)))
end

local function debugprint(...)
	if db.cfg.debugmode then
		print(format('%s%s > DEBUG > %s', CLR.DEBUG(), MYSHORTNAME, CLR.TXT()), ...)
	end
end

local function arrayprint(array)
	for _, v in ipairs(array) do
		print(v)
	end
end


--[[============================================================================
	Main
============================================================================]]--

local fixed_name_len = db.cfg.do_truncate and db.cfg.fixed_name_len

--[[----------------------------------------------------------------------------
	Helpers
----------------------------------------------------------------------------]]--

local function is_auctstarttime_valid()
	local v = db.cfg.auction_starttime
	if v:find('%d%d:%d%d') then
		local h, m = tonumber(v:sub(1, 2)), tonumber(v:sub(4))
		if h > 23 or m > 59 then return false end
	else
		return false
	end
	return true
end

local MSG_INVALID_ENDTIME_VALUES =
	'Check your Custom Options!\n\nYou have entered an invalid time string \nfor the auction start time.\nExamples for valid time strings: \n\124cFF00F90023:59, 01:19, 19:01, 00:10\124r. \n(Invalid: \124cFFFF25002359, 23:62, 1:19, 19:1, 24:10\124r.)'

local times_left = {
	[0] = {
		min = 0,
		max = 0,
		name = 'Completed',
		symbol = { 'C', 'W' },
		color = 'FF424242', -- Tungsten
	},
	[1] = {
		min = 0, -- Now
		max = 1800, -- 30m
		name = 'Short',
		symbol = 'S',
		color = 'FFFF2500', -- Maraschino
	},
	[2] = {
		min = 1800, -- 30m
		max = 7200, -- 2h
		name = 'Medium',
		symbol = 'M',
		color = 'FFFF9300', -- Tangerine
	},
	[3] = {
		min = 7200, -- 2h
		max = 43200, -- 12h
		name = 'Long',
		symbol = 'L',
		color = 'FF0096FF', -- Aqua
	},
	[4] = {
		min = 43200, -- 12h
		max = 86400, -- 24h
		name = 'Very Long',
		symbol = 'V',
		color = 'FF00FA92', -- Sea Foam
	},
}

-- Misc colors by columns/elements
local clr = {
	won = 'FF5E5E5E', -- Iron; Replaces the regular time-zero symbol
	diff = 'FFC0C0C0', -- Magnesium; New-bids counter and time-left-changed indicator
	me = 'FF009192', -- Teal; Replaces new-bids counter if it was me
	bids = { -- Lesser than or equal
		{ 0, 'FF008E00' }, -- Clover
		{ 10, 'FF00FA92' }, -- Sea Foam
		{ 20, 'FF0096FF' }, -- Aqua
		{ 30, 'FFFF9300' }, -- Tangerine
		{ 1e9, 'FFFF2500' }, -- Maraschino
	},
	header = {
		last = 'FFFFFFFF', -- White
		old = 'FF797979', -- Steel
	},
	timeframe = {
		default = 'FFFFFFFF', -- White
	},
}

local function clear_list() db.textcache = nil end

local function clear_all()
	wipe(db.textcache)
	wipe(db.auctions)
end

local ellipsis = tostring(db.cfg.ellipsis_replacement) and db.cfg.ellipsis_replacement or '…'
local len_ellipsis = strlenutf8(ellipsis)
local function truncate(str)
	if #str > max(db.cfg.len_truncate, 1) then
		str = strsub(str, 1, db.cfg.len_truncate - len_ellipsis) .. ellipsis
	end
	return str
end

-- 11 places before name start: bbddd|tttd|<name starts here>; 6 places from time to name

local function get_time()
	-- return GetServerTime()
	return time()
end

local function time_format(epoch)
	if type(epoch) == 'number' then return date('%H:%M', epoch) end
	return '??:??'
end

local function sec_format(sec)
	local h = floor(math.fmod(sec, 86400) / 3600)
	local m = floor(math.fmod(sec, 3600) / 60)
	local s = floor(math.fmod(sec, 60))
	return h, m, s
end

-- E.g.: auction start is at 23:30 --> plausible earliest end time is 18:30
local auctstart_hour, auctstart_minute =
	tonumber(db.cfg.auction_starttime:sub(1, 2)), tonumber(db.cfg.auction_starttime:sub(4))
local plausible_earlytime =
	format('%s:%s', auctstart_hour - OFFSET_PLAUSIBLE_EARLYTIME, auctstart_minute)
local plausible_latetime =
	format('%s:%s', auctstart_hour - OFFSET_PLAUSIBLE_LATETIME, auctstart_minute)

-- Header anatomy:
-- 5 time + 1 sep + 1 update source + 1 sep + flexible filler + Extra group = ?
-- First char of name is char #12 --> min truncate value of 9 --> rounded to 10
local LEN_HEADERINFO = 7 -- 5 Current time + 1 fillChar + 1 source indicator
local function sep_filler(lenname)
	return strrep(
		FILLCHAR,
		(db.cfg.show_bids and 6 or 0)
			+ (db.cfg.show_timetier and 2 or 0)
			+ (db.cfg.show_timerem and 6 or 0)
			+ (db.cfg.show_timeframe and 12 or 0)
			+ lenname
			- LEN_HEADERINFO
	)
end

-- TODO: implement _G.wa_BMAH_ListUpdatedViaRequestItemsFunc
local function source_of_update() -- To be removed later (?)
	local str = _G.wa_BMAH_ListUpdatedViaRequestItemsFunc and '!' or FILLCHAR
	_G.wa_BMAH_ListUpdatedViaRequestItemsFunc = nil
	return str
end

-- Bid Count
local function column_bids(id, num, tleft, me)
	if not db.cfg.show_bids then return '' end
	local diff = '   '
	if me and tleft > 0 then
		diff = format(' \124c%sMe\124r', clr.me)
	else
		db.auctions[id].num_bids = db.auctions[id].num_bids or 0
		if db.auctions[id].num_bids < num then
			diff = format('\124c%s%3s\124r', clr.diff, '+' .. num - db.auctions[id].num_bids)
		end
	end

	local color
	for _, v in ipairs(clr.bids) do
		if num <= v[1] then
			color = v[2]
			break
		end
	end

	if tleft > 0 then return format('\124c%s%2s\124r%3s ', color, num, diff) end
	return format('%2s%3s ', num, diff)
end

-- Time Left
local function column_timetier(id, tleft, me)
	if not db.cfg.show_timetier then return '' end
	local diff = ' '
	db.auctions[id].time_left = db.auctions[id].time_left or 4
	if tleft < db.auctions[id].time_left then diff = format('\124c%s!\124r', clr.diff) end

	if tleft > 0 then
		return format('\124c%s%s\124r%s', times_left[tleft].color, times_left[tleft].symbol, diff)
	end
	-- Omit color, since we dim the whole line
	return format('%s%s', times_left[0].symbol[me and 2 or 1], diff)
end

local function column_timeleft(market_id, now, tleft)
	if not db.cfg.show_timeframe and not db.cfg.show_timerem then return '' end
	local id = db.auctions[market_id]
	local early_prev, late_prev = id.early or now + 0, id.late or now + 86400 --86400
	-- 'src' refers to the origin of the time prognostics, i.e. the duration tier that provided the
	-- early/late times (4, 3, 2, or 1)
	local early_prev_src, late_prev_src = id.early_src or tleft, id.late_src or tleft
	local early, late, color_early, color_late, rem_early, rem_late
	if tleft > 0 then
		early, late = now + times_left[tleft].min, now + times_left[tleft].max
		early = max(early, early_prev)
		late = min(late, late_prev)
		rem_early, rem_late = early - now, late - now
		id.early, id.late = early, late
		id.early_src = early == early_prev and early_prev_src or tleft
		id.late_src = late == late_prev and late_prev_src or tleft
		if db.cfg.timeframe_color_by_rem then
			for _, v in ipairs(times_left) do
				-- Color semantics: use v.max or v.min here?
				if not color_early and rem_early <= v.min then color_early = v.color end
				if not color_late and rem_late <= v.min then color_late = v.color end
				if color_early and color_late then break end
			end
		elseif db.cfg.timeframe_color_by_src then
			color_early, color_late = times_left[id.early_src].color, times_left[id.late_src].color
		end
		color_early, color_late =
			color_early or clr.timeframe.default, color_late or clr.timeframe.default
	else
		-- We need also values if we first open the BMAH after all auctions have finished
		early, late = early_prev, late_prev
		rem_early = 0
	end
	local early_format, late_format = time_format(early), time_format(late)
	-- Late time plausibility check (always), since 23:30 is a hard limit (new auctions start)
	-- Cheap hack: Once the time has passed the 00:00 mark, we simply check it against the plausible early time
	if late_format > plausible_latetime or late_format < plausible_earlytime then
		late_format = plausible_latetime
	end
	-- Early time plausibility check (option)
	if db.cfg.timeframe_plausibilityfilter_early then
		if early_format < plausible_earlytime then early_format = plausible_earlytime end
	end
	local str_rem, str_frame = '', ''
	if db.cfg.show_timerem then
		local hours, minutes, seconds = sec_format(rem_early)
		str_rem = format(
			'%s%s%s',
			hours > 0 and format('%sh', hours) or '',
			hours < 10 and minutes > 0 and format('%sm', minutes) or '',
			hours < 1 and minutes < 10 and format('%ss', seconds) or ''
		)
		str_rem = format('%s%s ', strrep(' ', 5 - #str_rem), str_rem)
	end
	if tleft > 0 then
		if db.cfg.show_timerem then str_rem = format('\124c%s%s\124r', color_early, str_rem) end
		if db.cfg.show_timeframe then
			str_frame = format(
				'\124c%s%s\124r–\124c%s%s\124r ',
				color_early,
				early_format,
				color_late,
				late_format
			) -- 12 chars
		end
	else -- Omit all color code if auction over, to allow dimming
		if db.cfg.show_timeframe then
			str_frame = format('%s–%s ', early_format, late_format) -- 12 chars
		end
	end
	return format('%s%s', str_rem, str_frame)
end

-- Item name
local len_name = 0
local function column_name(link, tleft)
	-- 11.1.5 changes!
	-- See https://github.com/Auctionator/Auctionator/commit/fbbb0b19267bb0d41de4f64af7a42275b0ce80e0
	local color, str = link:match('|c(nIQ%d+:)|.+%[(.-)%]')
	-- local color, str = link:match('|c(ff%w+).+%[(.-)%]') -- old (before 11.1.5)
	if db.cfg.do_truncate then
		str = format('%s', truncate(str))
		len_name = db.cfg.fixed_name_len and db.cfg.do_truncate and db.cfg.len_truncate
			or max(len_name, min(db.cfg.len_truncate, #str))
	else
		len_name = max(len_name, #str)
	end
	if tleft > 0 then
		return format('\124c%s%s\124r', color, str)
	else
		return str
	end
end

-- Dimm entire line to gray if auction is completed
local function dim(tleft, me)
	if tleft == 0 then
		local color = me and clr.won or times_left[0].color
		return format('\124c%s', color)
	end
	return ''
end


--[[----------------------------------------------------------------------------
	Super-messy Spaghetti Main Func
----------------------------------------------------------------------------]]--

local function messy_main_func(update)
	debugprint('Main func started.')
	-- Itinerate the auctions by index
	local i_last = C_BlackMarket.GetNumItems()
	debugprint('Index of last auction:', i_last)
	-- Check if BMAH has data
	if update and not i_last then return 'No auction indices found!' end
	if db.cfg.show_timeframe and not is_auctstarttime_valid() then
		return MSG_INVALID_ENDTIME_VALUES
	end
	if update and i_last and i_last > 0 then -- Empty BMAH has last index 0; don't do anything then
		local now = get_time()
		local text = ''
		for i = 1, i_last do
			local name, _, _, _, _, _, _, _, _, _, curr_bid, me_high, num_bids, time_left, link, market_id =
				C_BlackMarket.GetItemInfoByIndex(i)
			if not num_bids or not time_left or not link or not market_id then
				return (format('Could not get required data for auction #%s!', i))
			end
			if
				db.auctions[market_id]
				and (
					name ~= db.auctions[market_id].name
					or num_bids < db.auctions[market_id].num_bids
					or time_left > db.auctions[market_id].time_left
				)
			then
				db.auctions[market_id] = nil
				addonprint(
					format(
						'Auction has same ID as one from the previous session! Auction data of %s reset.',
						link
					)
				)
			end
			db.auctions[market_id] = db.auctions[market_id] or {}
			-- Construct new line
			text = format(
				'%s%s%s%s%s%s\124r\n',
				text,
				dim(time_left, me_high),
				column_bids(market_id, num_bids, time_left, me_high),
				column_timetier(market_id, time_left, me_high),
				column_timeleft(market_id, now, time_left),
				column_name(link, time_left)
			)
			-- Update DB for the comparison functions (time frames are updated in the function itself)
			db.auctions[market_id].time = now
			db.auctions[market_id].num_bids = num_bids
			db.auctions[market_id].time_left = time_left
			db.auctions[market_id].link = link
			db.auctions[market_id].name = name
			debugprint(
				'DB: id:',
				market_id,
				'|| time:',
				time_format(db.auctions[market_id].time),
				'|| link:',
				db.auctions[market_id].link,
				'|| name:',
				db.auctions[market_id].name,
				'|| num_bids:',
				db.auctions[market_id].num_bids,
				'|| time_left:',
				db.auctions[market_id].time_left,
				'|| early:',
				time_format(db.auctions[market_id].early),
				'|| late:',
				time_format(db.auctions[market_id].late)
			)
		end
		-- Prepend header
		local header = format(
			'\124c%s%s%s%s%s\124r\n',
			clr.header.last,
			time_format(now),
			FILLCHAR,
			source_of_update(),
			sep_filler(len_name)
		)
		text = header .. text

		if db.cfg.last_at_top then
			tinsert(db.textcache, 1, text)
		else
			tinsert(db.textcache, text)
		end
		-- Change header color to 'old' for the second-to-last record
		if #db.textcache > 1 then
			db.textcache[#db.textcache - 1] = gsub(
				db.textcache[#db.textcache - 1],
				'\124c' .. clr.header.last,
				'\124c' .. clr.header.old,
				1
			)
		end
		-- Delete overflowing text cache
		if db.cfg.do_limit_num_records then
			while #db.textcache > db.cfg.num_records_max do
				if db.cfg.last_at_top then
					tremove(db.textcache)
				else
					tremove(db.textcache, 1)
				end
			end
		end
		if db.cfg.do_limit_num_lines then
			local num_lines
			while not num_lines or num_lines > db.cfg.num_lines_max do
				num_lines = -1 -- The empty line of the last record is not displayed
				for _, record in ipairs(db.textcache) do
					local _, num = record:gsub('\n', '\n')
					num_lines = num_lines + num + 1 -- 1 for the spacer line between the records
				end
				if num_lines > db.cfg.num_lines_max then
					if db.cfg.last_at_top then
						tremove(db.textcache)
					else
						tremove(db.textcache, 1)
					end
				end
			end
		end
		-- Remove old auction data by ID (otherwise the time frames could get messed up in a future auction)
		for id, _ in pairs(db.auctions) do
			if db.auctions[id].time < now - 86400 then db.auctions[id] = nil end
		end
	end

	-- Output is always a string (one textblock); we can split later if needed.
	print(BLOCKSEP)
	if not db.cfg.display_list then return 'BMAH Helper display disabled.' end
	if #db.textcache == 0 then return 'No current or cached output.' end
	if not update then
		addonprint(format('%s', CLR.BAD('Printing CACHED data:')))
	else
		-- addonprint(format('%s', CLR.GOOD('Printing updated data:')))
	end
	return table.concat(db.textcache, '\n')
end

local function records_to_console(update)
	local text = messy_main_func(update)
	if split_lines then
		local t = strsplittable('\n', text)
		arrayprint(t)
	elseif split_records then
		local t = strsplittable('\n\n', text)
		arrayprint(t)
	else
		print(text)
	end
	print(BLOCKSEP)
end


--[[============================================================================
	UI
============================================================================]]--

local CMD1, CMD2, CMD3 = '/bmahhelper', '/bmx', nil

local help = {
	format(
		'%s%s Help: %s or %s accepts these arguments:',
		CLR.HEAD(),
		CLR.ADDON(MYPRETTYNAME),
		CLR.CMD(CMD1),
		CLR.CMD(CMD2)
	),
	format(
		'%s%s or %s : Print record(s) to the chat console.',
		CLR.TXT(),
		CLR.CMD('print'),
		CLR.CMD('p')
	),
	format('%s%s : Print addon version.', CLR.TXT(), CLR.CMD('version')),
	format('%s%s or %s : Print this help text.', CLR.TXT(), CLR.CMD('help'), CLR.CMD('h')),
}

--[[----------------------------------------------------------------------------
	Slash function
----------------------------------------------------------------------------]]--

SLASH_BMAHHELPER1 = CMD1
SLASH_BMAHHELPER2 = CMD2
SlashCmdList.BMAHHELPER = function(msg)
	local args = {}
	for arg in msg:gmatch('[^ ]+') do
		tinsert(args, arg)
	end
	if args[1] == 'version' or args[1] == 'ver' then
		addonprint(format('Version %s', CLR.KEY(MYVERSION)))
	elseif args[1] == 'dm' then
		db.cfg.debugmode = not db.cfg.debugmode
		addonprint(
			format('Debug mode %s.', db.cfg.debugmode and CLR.ON('enabled') or CLR.OFF('disabled'))
		)
	elseif args[1] == 'print' or args[1] == 'p' then
		records_to_console(false)
	elseif args[1] == 'help' or args[1] == 'h' then
		arrayprint(help)
	else
		addonprint(
			format('%s Enter %s for help.', CLR.BAD('Not a valid input.'), CLR.CMD(CMD2 .. ' h'))
		)
	end
end

--[[============================================================================
	Events
============================================================================]]--

-- https://warcraft.wiki.gg/wiki/Category:API_systems/BlackMarketInfo

local bmah_update_wait
local function BLACK_MARKET_ITEM_UPDATE()
	if bmah_update_wait then return end
	bmah_update_wait = true
	C_Timer.After(1, function()
		debugprint('Show/update list bc of event.')
		records_to_console(true)
		bmah_update_wait = nil
	end)
end

local function BLACK_MARKET_OPEN()
	-- do stuff
end

local function BLACK_MARKET_CLOSE()
	-- do stuff
end

-- local function PLAYER_LOGIN()
-- 	-- do stuff
-- end
--
-- local function PLAYER_ENTERING_WORLD(is_login, is_reload)
-- 	if not is_login and not is_reload then return end
-- 	local delay = is_login and 5 or 1
-- 	C_Timer_After(delay, XXX)
-- end
--
-- local function PLAYER_LOGOUT()
-- 	-- do stuff
-- end


--[[----------------------------------------------------------------------------
	Event frame, handlers, and registration
----------------------------------------------------------------------------]]--

local ef = CreateFrame('Frame', MYNAME .. '_eventframe')

local event_handlers = {
	['BLACK_MARKET_ITEM_UPDATE'] = BLACK_MARKET_ITEM_UPDATE,
	['BLACK_MARKET_CLOSE'] = BLACK_MARKET_CLOSE,
	['BLACK_MARKET_OPEN'] = BLACK_MARKET_OPEN,
-- 	['PLAYER_LOGIN'] = PLAYER_LOGIN,
-- 	['PLAYER_ENTERING_WORLD'] = PLAYER_ENTERING_WORLD,
-- 	['PLAYER_LOGOUT'] = PLAYER_LOGOUT,
}

for event in pairs(event_handlers) do
	ef:RegisterEvent(event)
end

ef:SetScript('OnEvent', function(_, event, ...)
	event_handlers[event](...) -- We do not want a nil check here.
end)

-- The nil check would just hide/silence an unnecessary event registration.



--[[============================================================================
	Separator Big
============================================================================]]--
--[[----------------------------------------------------------------------------
	Separator Small
----------------------------------------------------------------------------]]--
--------------------------------------------------------------------------------
-- Separator Small
--------------------------------------------------------------------------------

-- Another Separator Style -----------------------------------------------------

--[[ Another Separator Style ]]-------------------------------------------------


--[[ Notes =====================================================================

	Inspired by:
	XXX

============================================================================]]--
