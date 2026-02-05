-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Copyright (c) 2025-2026 Thomas Floeren

local MYNAME, A = ...
local db = A.db
local defaults = A.defaults
local DB_ID = 'DB_6583B024_97F4_47B0_8F4C_BB1C1B4FE393'
local CLR = A.CLR
local addonprint, debugprint = A.addonprint, A.debugprint

local tonumber = tonumber
local type = type
local format = format

-- Misc variables
local FILLCHAR = '-'
local BLOCKSEP = A.BLOCKSEP
local realm
local user_is_author = false

--[[============================================================================
	Main
============================================================================]]--

--[[----------------------------------------------------------------------------
	Helpers
----------------------------------------------------------------------------]]--

local function is_valid_bm_reset_time(timestr)
	local h, m = timestr:match("^(%d%d?):(%d%d)$")
	if h and m then
		h, m = tonumber(h), tonumber(m)
		if h > 23 or m > 59 then return false end
	else
		return false
	end
	return true
end
A.is_valid_bm_reset_time = is_valid_bm_reset_time -- ui

local MSG_INVALID_BM_RESET_TIME = format(
	'%s No valid BMAH reset time found! %sThis may lead to wrong upper end times. Use %s to set a correct local reset time. Valid examples: %s, %s, %s. Not valid: %s.',
	CLR.WARN(),
	CLR.TXT(),
	CLR.CMD('/gy rtime <HH:MM>'),
	CLR.GOOD('23:30'),
	CLR.GOOD('2:30'),
	CLR.GOOD('02:30'),
	CLR.BAD('23:65')
)


local times_left = {
	[0] = {
		min = 0,
		max = 0,
		name = 'Completed',
		symbol = { 'C', 'W' },
-- 		color = 'FF424242', -- Tungsten
		color = 'FF5E5E5E', -- Iron
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
	endtime = {
		default = 'FFFFFFFF', -- White
	},
	gold = {
		amount = 'FFFFD478', -- Banana FFFFFB78
-- 		delim = 'FFFFD478', -- Cantaloupe
		sym = 'FFFFFFFF', -- White
	},
}

local ellipsis = tostring(db.cfg.ellipsis_replacement) and db.cfg.ellipsis_replacement or '…'
local len_ellipsis = strlenutf8(ellipsis)
local function truncate(str)
	if #str > max(db.cfg.len_truncate, 1) then
		str = strsub(str, 1, db.cfg.len_truncate - len_ellipsis) .. ellipsis
	end
	return str
end

local function get_time()
	-- return GetServerTime()
	return time()
end

local function time_format(epoch, sec)
	if type(epoch) == 'number' then
		return sec and date('%H:%M:%S', epoch) or date('%H:%M', epoch)
	end
	return '??:??'
end
A.time_format = time_format

local function sec_format(sec)
	local h = floor(math.fmod(sec, 86400) / 3600)
	local m = floor(math.fmod(sec, 3600) / 60)
	local s = floor(math.fmod(sec, 60))
	return h, m, s
end

-- E.g.: auction start is at 23:30 --> plausible earliest end time is 18:30
local bm_reset_hour, bm_reset_minute =
	tonumber(db.cfg.bm_reset_time:sub(1, 2)), tonumber(db.cfg.bm_reset_time:sub(4))
local plausible_earlytime =
	format('%s:%s', bm_reset_hour - db.cfg.offset_plausible_earlytime, bm_reset_minute)
local plausible_latetime =
	format('%s:%s', bm_reset_hour - db.cfg.offset_plausible_latetime, bm_reset_minute)

-- Header anatomy:
-- 5 time + 1 sep + 1 update source + 1 sep + flexible filler + Extra group = ?
-- First char of name is char #12 --> min truncate value of 9 --> rounded to 10
local LEN_HEADERINFO = 7 -- 5 Current time + 1 fillChar + 1 source indicator
local function sep_filler(lenname)
	return strrep(
		FILLCHAR,
		(db.cfg.show_bids and 6 or 0)
			+ (db.cfg.show_timetier and 2 or 0)
			+ (db.cfg.show_timeremaining and 6 or 0)
			+ (db.cfg.show_timewindow and 12 or 0)
			+ (db.cfg.show_price and not db.cfg.show_price_in_namecolumn and 5 or 0)
			+ (db.cfg.timestamp_with_seconds and -3 or 0)
			+ lenname
			- LEN_HEADERINFO
	)
end

--[[
NOTES:
API prices are copper, but here they are always Gold-even. So you can losslessly
	convert to Gold with floor(price / 1e4).
The min increment is de facto the diff between current and min bid price. It's not the
	increment to the next min bid.
]]

-- TODO: implement _G.wa_BMAH_ListUpdatedViaRequestItemsFunc
-- https://warcraft.wiki.gg/wiki/API_C_BlackMarket.RequestItems
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
		db[realm].auctions[id].num_bids = db[realm].auctions[id].num_bids or 0
		if db[realm].auctions[id].num_bids < num then
			diff = format('\124c%s%3s\124r', clr.diff, '+' .. num - db[realm].auctions[id].num_bids)
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
	db[realm].auctions[id].time_left = db[realm].auctions[id].time_left or 4
	if tleft < db[realm].auctions[id].time_left then diff = format('\124c%s!\124r', clr.diff) end

	if tleft > 0 then
		return format('\124c%s%s\124r%s', times_left[tleft].color, times_left[tleft].symbol, diff)
	end
	-- Omit color, since we dim the whole line
	return format('%s%s', times_left[0].symbol[me and 2 or 1], diff)
end

local function column_timeleft(market_id, now, tleft)
	if not db.cfg.show_timewindow and not db.cfg.show_timeremaining then return '' end
	local id = db[realm].auctions[market_id]
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
		if db.cfg.endtime_colormode == 1 then -- by rem
			for _, v in ipairs(times_left) do
				-- Color semantics: use v.max or v.min here?
				if not color_early and rem_early <= v.min then color_early = v.color end
				if not color_late and rem_late <= v.min then color_late = v.color end
				if color_early and color_late then break end
			end
		elseif db.cfg.endtime_colormode == 2 then -- by src
			color_early, color_late = times_left[id.early_src].color, times_left[id.late_src].color
		end
		color_early, color_late =
			color_early or clr.endtime.default, color_late or clr.endtime.default
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
	if db.cfg.timewindow_plausibilityfilter_early then
		if early_format < plausible_earlytime then early_format = plausible_earlytime end
	end
	local str_rem, str_window = '', ''
	if db.cfg.show_timeremaining then
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
		if db.cfg.show_timeremaining then str_rem = format('\124c%s%s\124r', color_early, str_rem) end
		if db.cfg.show_timewindow then
			str_window = format(
				'\124c%s%s\124r–\124c%s%s\124r ',
				color_early,
				early_format,
				color_late,
				late_format
			) -- 12 chars
		end
	else -- Omit all color code if auction over, to allow dimming
		if db.cfg.show_timewindow then
			str_window = format('%s–%s ', early_format, late_format) -- 12 chars
		end
	end
	return format('%s%s', str_rem, str_window)
end

-- Price
local function column_price(price, tleft)
	if not db.cfg.show_price or db.cfg.show_price_in_namecolumn then return '' end
	price = floor(price / 1e4 + 0.5)
	local usym
	if price >= 999.5e3 then
		usym = 'm'
		price = floor(price / 1e5 + 0.5) / 10
	else
		usym = 'k'
		if price < 9.5e3 then
			price = floor(price / 1e2 + 0.5) / 10
		else
			price = floor(price / 1e3 + 0.5)
		end
	end
	local padding_l, padding_r = strrep(' ', 4 - #(price .. usym)), ''
	if db.cfg.pricecolumn_leftaligned then
		padding_r = padding_l
		padding_l = ''
	end
	if tleft > 0 then
		return format(
			'%s\124c%s%s\124c%s%s\124r%s ',
			padding_l,
			clr.gold.amount,
			price,
			clr.gold.sym,
			usym,
			padding_r
		)
	end
	return format('%s%s%s%s ', padding_l, price, usym, padding_r)
end

-- Item name
-- Optionally merge the price in here
local len_name = 0
local function column_name(link, price, tleft)
	-- 11.1.5 changes!
	-- See https://github.com/Auctionator/Auctionator/commit/fbbb0b19267bb0d41de4f64af7a42275b0ce80e0
	local clr_name, str = link:match('|c(nIQ%d+:)|.+%[(.-)%]')
	if db.cfg.show_price and db.cfg.show_price_in_namecolumn then
		local gold = floor(price / 1e7 + 0.5)
		str = format('%s==%s', gold, str)
	end
	if db.cfg.do_truncate then
		str = format('%s', truncate(str)) -- XXX ??
		len_name = max(len_name, min(db.cfg.len_truncate, #str))
	else
		len_name = max(len_name, #str)
	end
	if tleft > 0 then
		local gold, _, name = strsplit('=', str)
		if name then
			return format('\124c%s%s\124c%sk\124r \124c%s%s\124r', clr.gold.amount, gold, clr.gold.sym, clr_name, name)
		end
		return format('\124c%s%s\124r', clr_name, str)
	else
		return str:gsub('==', 'k ')
	end
end

local function select_price(curr, min, incr, tleft)
	if tleft > 0 then
		if db.cfg.price_type == 2 then
			return max(curr, min)
		elseif db.cfg.price_type == 3 then
			return incr
		end
	elseif db.cfg.true_completed_price then
		return curr -- Shows zero if completed and not sold
	end
	return curr > 0 and curr or min -- This is what the BMAH frame shows
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
-- 	debugprint('Main func called.')
	if type(db[realm]) ~= 'table' then
		local text = 'Could not get realm name at login! \nPlease try reloading or report this bug.'
		addonprint(CLR.BAD(text))
		return { text .. '\n' }
	end
	-- Itinerate the auctions by index
	local i_last = C_BlackMarket.GetNumItems()
	debugprint('Index of last auction:', i_last)
	-- Check if BMAH has data
	if update and not i_last then return { 'No auction indices found!\n' } end
	if db.cfg.show_timewindow and not is_valid_bm_reset_time(db.cfg.bm_reset_time) then
		addonprint(MSG_INVALID_BM_RESET_TIME)
	end
	if update and i_last and i_last > 0 then -- Empty BMAH has last index 0; don't do anything then
		local now = get_time()
		local text = ''
		for i = 1, i_last do
			-- https://warcraft.wiki.gg/wiki/API_C_BlackMarket.GetItemInfoByID
			local name, _, _, _, _, _, _, _, min_bid, min_incr, curr_bid, me_high, num_bids, time_left, link, market_id =
				C_BlackMarket.GetItemInfoByIndex(i)
			if not num_bids or not time_left or not link or not market_id then
				return { format('Could not fetch data for auction index %s!\n', i) }
			end
			if
				db[realm].auctions[market_id]
				and (
					name ~= db[realm].auctions[market_id].name
					or num_bids < db[realm].auctions[market_id].num_bids
					or time_left > db[realm].auctions[market_id].time_left
				)
			then
				db[realm].auctions[market_id] = nil
				addonprint(
					format(
						'Auction has same ID as one from the previous reset! Auction data of %s reset.',
						link
					)
				)
			end

			db[realm].auctions[market_id] = db[realm].auctions[market_id] or {}

			local price = select_price(curr_bid, min_bid, min_incr, time_left)
			-- Construct new line
			text = format(
				'%s%s%s%s%s%s%s\124r\n',
				text,
				dim(time_left, me_high),
				column_bids(market_id, num_bids, time_left, me_high),
				column_timetier(market_id, time_left, me_high),
				column_timeleft(market_id, now, time_left),
				column_price(price, time_left),
				column_name(link, price, time_left)
			)
			-- Update DB for the comparison functions (time windows are updated in the function itself)
			-- Also used for messages.
			db[realm].auctions[market_id].time = now
			db[realm].auctions[market_id].num_bids = num_bids
			db[realm].auctions[market_id].time_left = time_left
			db[realm].auctions[market_id].link = link
			db[realm].auctions[market_id].name = name
			db[realm].auctions[market_id].curr_bid = curr_bid
			db[realm].auctions[market_id].min_bid = min_bid
			db[realm].auctions[market_id].min_incr = min_incr
--[[
			debugprint(
				'id:',
				market_id,
				'|| time:',
				time_format(now),
				'|| link:',
				link,
				'|| curr_bid:',
				floor(curr_bid / 1e4),
				'|| min_bid:',
				floor(min_bid / 1e4),
				'|| min_incr:',
				floor(min_incr / 1e4),
				'|| num_bids:',
				num_bids,
				'|| time_left:',
				time_left,
				'|| early:',
				time_format(db[realm].auctions[market_id].early),
				'|| late:',
				time_format(db[realm].auctions[market_id].late)
			)
--]]
		end
		-- Prepend header
		local header = format(
			'\124c%s%s%s%s%s\124r\n',
			clr.header.last,
			time_format(now, db.cfg.timestamp_with_seconds),
			FILLCHAR,
			source_of_update(),
			sep_filler(len_name)
		)
		text = header .. text

		tinsert(db[realm].textcache, 1, text)

		if #db[realm].textcache > 1 then
			-- Dedupe second-to-last record if new one is 100% identical (except header)
			if
				db.cfg.deduplicate_records
				and db[realm].textcache[1]:match('\n.*$')
					== db[realm].textcache[2]:match('\n.*$')
			then
				tremove(db[realm].textcache, 2)
				addonprint('Deduplicated last record.')
			else
				-- Change header color to 'old' for the second-to-last record
				db[realm].textcache[2] = gsub(
					db[realm].textcache[2],
					'\124c' .. clr.header.last,
					'\124c' .. clr.header.old,
					1
				)
			end
		end
		-- Delete overflowing text cache
		while #db[realm].textcache > db.cfg.num_records_max do
			tremove(db[realm].textcache)
		end
		-- Remove old auction data by ID (otherwise the time windows could get messed up in a future auction)
		for id, _ in pairs(db[realm].auctions) do
			if db[realm].auctions[id].time < now - 86400 then db[realm].auctions[id] = nil end
		end
	end

	-- print(BLOCKSEP)
	if not db.cfg.display_records then return { 'Records display disabled.\n' } end
	if #db[realm].textcache == 0 then return { 'No current or cached records.\n' } end
	if not update then
		addonprint(format('%s', CLR.BAD('Showing CACHED data.')))
	else
		-- addonprint(format('%s', CLR.GOOD('Printing updated data:')))
	end
	return db[realm].textcache
end

A.messy_main_func = messy_main_func




--[[============================================================================
	Events
============================================================================]]--

--[[
NOTES:
https://warcraft.wiki.gg/wiki/Category:API_systems/BlackMarketInfo
Blizz std messages: 'Bid accepted.', 'You have been outbid on <item name>.',
'You won an auction for <item name>'
]]

local function get_data_for_alert(market_id, item_id)
	local link, curr, min, incr
	if db[realm] and db[realm].auctions and db[realm].auctions[market_id] then
		link = db[realm].auctions[market_id].link
		curr = db[realm].auctions[market_id].curr_bid
		min = db[realm].auctions[market_id].min_bid
		incr = db[realm].auctions[market_id].min_incr
	end
	if type(curr) ~= 'number' or type(min) ~= 'number' or type(incr) ~= 'number' then
		debugprint(format('%sCould not get prices from DB!', CLR.WARN()))
		curr, min, incr = '<Unknown Current Bid>', '<Unknown Min Bid>', '<Unknown Increment>'
	else
		curr, min, incr =
			GetMoneyString(curr, true), GetMoneyString(min, true), GetMoneyString(incr, true)
	end
	if type(link) ~= 'string' then
		debugprint(format('%sCould not get link from DB! Trying GetItemInfo...', CLR.WARN()))
		link = item_id and C_Item.GetItemInfo(item_id) or '<Unknown Item>'
	end
	return link, curr, min, incr
end

local id_for_bid_msg

local bmah_update_wait
local function BLACK_MARKET_ITEM_UPDATE()
	debugprint('BLACK_MARKET_ITEM_UPDATE fired.')
	if bmah_update_wait then return end
	bmah_update_wait = true
	C_Timer.After(db.cfg.delay_after_bm_itemupdate_event, function()
		debugprint('Updating now.')
		A.display_open(true)
		if id_for_bid_msg then
			local link, curr, min, incr = get_data_for_alert(id_for_bid_msg)
			addonprint(format('%s placed on %s. Next bid: %s (+%s).', curr, link, min, incr))
			id_for_bid_msg = nil
		end
		bmah_update_wait = nil
	end)
end

local function BLACK_MARKET_OPEN()
	-- TODO: Start a timer here to check if the next update is a full update
end

local function BLACK_MARKET_CLOSE()
	A.display_close()
end


local function BLACK_MARKET_OUTBID(market_id, item_id)
	if db.cfg.sounds and db.cfg.sound_outbid then PlaySoundFile(644193, 'Master') end -- "Aargh"
	local link, _, min = get_data_for_alert(market_id, item_id)
	if db.cfg.chat_alerts and db.cfg.chat_alert_outbid then
		-- Since we are likely away from the BMAH, we don't have updated data, so read min_bid as curr_bid
		addonprint(format('%sOutbid on %s! %sCurrent bid: %s', CLR.WARN(), link, CLR.TXT(), min))
	end
	debugprint('BLACK_MARKET_OUTBID', market_id, item_id)
end

local function BLACK_MARKET_WON(market_id, item_id)
	if db.cfg.sounds and db.cfg.sound_won then PlaySoundFile(636419, 'Master') end -- "Nicely Done"
	local link, curr = get_data_for_alert(market_id, item_id)
	if db.cfg.chat_alerts and db.cfg.chat_alert_won then
		addonprint(format('%s%s won for %s!', CLR.GOOD(), link, curr))
	end
	debugprint('BLACK_MARKET_WON', market_id, item_id)
end

local function BLACK_MARKET_BID_RESULT(market_id, result_code)
	if result_code == 0 then
		if db.cfg.sounds and db.cfg.sound_bid then PlaySoundFile(636627, 'Master') end -- "Yes"
		-- The bid triggers a BLACK_MARKET_ITEM_UPDATE. So send the msg with that event, for up-to-date data.
		if db.cfg.chat_alerts and db.cfg.chat_alert_bid then id_for_bid_msg = market_id end
	end
	debugprint('BLACK_MARKET_BID_RESULT', market_id, result_code)
end

-- For the simulator
A.BLACK_MARKET_BID_RESULT = BLACK_MARKET_BID_RESULT
A.BLACK_MARKET_WON = BLACK_MARKET_WON
A.BLACK_MARKET_OUTBID = BLACK_MARKET_OUTBID
A.BLACK_MARKET_ITEM_UPDATE = BLACK_MARKET_ITEM_UPDATE



local function PLAYER_LOGIN()
	realm = A.get_bm_realm()
	if type(realm) ~= 'string' then return end
	db[realm] = db[realm] or {}
	db[realm].auctions = db[realm].auctions or {}
	db[realm].textcache = db[realm].textcache or {}
	user_is_author = tf6 and tf6.user_is_tflo
	A.user_is_author = user_is_author
	if user_is_author then
		A.set_test_config()
		A.clean_removed(_G[DB_ID].cfg, defaults.cfg)
	end
end

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
	['BLACK_MARKET_OUTBID'] = BLACK_MARKET_OUTBID, -- marketID, itemID
	['BLACK_MARKET_WON'] = BLACK_MARKET_WON, -- marketID, itemID
	['BLACK_MARKET_BID_RESULT'] = BLACK_MARKET_BID_RESULT, -- marketID, resultCode
	['PLAYER_LOGIN'] = PLAYER_LOGIN,
-- 	['PLAYER_ENTERING_WORLD'] = PLAYER_ENTERING_WORLD,
-- 	['PLAYER_LOGOUT'] = PLAYER_LOGOUT,
}

for event in pairs(event_handlers) do
	ef:RegisterEvent(event)
end

ef:SetScript('OnEvent', function(_, event, ...)
	event_handlers[event](...) -- We do not want a nil check here.
end)

