-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Copyright (c) 2025-2026 Thomas Floeren

local MYNAME, A = ...
local db = A.db
local MYSHORTNAME = 'GY'

local WTC = WrapTextInColorCode
local tonumber = tonumber
local type = type
local format = format

--[[============================================================================
	Basic
============================================================================]]--

-- This color system is addon-generic, not for the records display!
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
	GOOD = '00FA9A', -- mediumspringgreen
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
A.CLR = CLR
-- Usage: print('text ' .. CLR.WARN('warning') .. ' text' .. CLR.HEAD() .. ' text')

local function psec(precise, wrap, num_fractions, num_seconds)
	local raw = precise and GetTimePreciseSec() or GetTime()
	local seconds, fractions = strsplit('.', tostring(raw))
	-- numbers: places before decimal separator; this func will be used for time diffs, so we do need to know the real time since computer boot
	-- fractions: places after decimal separator; max 3 for GetTime, 8 for GetTimePreciseSec
	if type(num_seconds) == 'number' then
		num_seconds = max(floor(num_seconds), 2)
	else
		num_seconds = 3
	end
	if type(num_fractions) == 'number' then
		num_fractions = max(floor(num_fractions), 1)
	else
		num_fractions = 3
	end
	num_fractions = precise and min(num_fractions, 8) or min(num_fractions, 3)

	seconds = seconds:sub(-num_seconds)
	-- Testing bc if it's a full second, there aren't any fractions, so the strsplit gives us nil
	fractions = fractions and fractions:sub(1, num_fractions) or '0'

	while #seconds < num_seconds do
		seconds = '0' .. seconds
	end

	while #fractions < num_fractions do
		fractions = fractions .. '0'
	end

	local str = strjoin('.', seconds, fractions)
	if wrap ~= false then
		return '[' .. str .. ']'
	else
		return str
	end
end

local function addonprint(msg)
	print(format('%s%s: %s', CLR.ADDON(), MYNAME, CLR.TXT(msg)))
end

local function debugprint(...)
	if db.cfg.debugmode then
		print(format('%s%s>DEBUG>%s', CLR.DEBUG(), MYSHORTNAME, CLR.TXT()), ...)
	end
end

local function debugprint_pt(...)
	if db.cfg.debugmode then
		local time = psec(true, true, 3, 2)
		print(format('%s%s>DEBUG%s>%s', CLR.DEBUG(), MYSHORTNAME, time, CLR.TXT()), ...)
	end
end

local function arrayprint(array)
	for _, v in ipairs(array) do
		print(v)
	end
end

A.addonprint = addonprint
A.debugprint = debugprint
A.debugprint_pt = debugprint_pt
A.arrayprint = arrayprint

A.BLOCKSEP = CLR.ADDON(strrep('+', 42))

--[[============================================================================
	Misc
============================================================================]]--

-- Should not be called earlier than at login
function A.get_bm_realm()
	local connected_realms = GetAutoCompleteRealms()
	if not connected_realms or #connected_realms == 0 then return GetNormalizedRealmName() end
	table.sort(connected_realms)
	return table.concat(connected_realms, '-')
end

--[[----------------------------------------------------------------------------
	Clearing
----------------------------------------------------------------------------]]--

function A.clear_records() -- public
	wipe(db.realms[realm].records)
end
function A.clear_auctions() -- public
	wipe(db.realms[realm].auctions)
end
function A.clear_notifs() -- public
	wipe(db.global.notifs)
end
function A.clear_data() -- public
	A.clear_records()
	A.clear_auctions()
	A.clear_notifs()
end

function A.clear_realms()
	wipe(db.realms)
end
function A.clear_alldata() -- public
	A.clear_realms()
	A.clear_notifs()
end

function A.clear_global()
	wipe(db.global)
end
function A.clear_frames()
	wipe(db.global.frames)
end
function A.clear_cfg()
	wipe(db.cfg)
end
function A.clear_settings() -- public
	A.clear_cfg()
	A.clear_frames()
end

--[[----------------------------------------------------------------------------
	Dev tools
----------------------------------------------------------------------------]]--

function A.simulate_event(func, func2)
	local realm = A.get_bm_realm()
	local t = {}
	for k, _ in pairs(db.realms[realm].auctions) do
		tinsert(t, k)
	end
	local market_id = t[random(1, #t)]
	local item_id = (db.realms[realm].auctions[market_id].link):match('item:(%d+):')
	local result_code = 0
	local arg2 = item_id
	if func2 then arg2 = result_code end
	func(market_id, arg2)
	if func2 then func2() end
end

-- Config test
function A.set_test_config() -- @ login
-- 	local realm = A.get_bm_realm()
-- 	db.cfg.font_records = 1
-- 	db.cfg.price_type = 2
	db.cfg.true_completed_price = true
-- 	db.cfg.timewindow_plausibilityfilter_early = false
-- 	db.cfg.num_records_max = 50
-- 	db.cfg.len_truncate = 17
-- 	db.cfg.records_frame_width = 460
-- 	db.cfg.records_frame_height = 400
	db.cfg.show_price_in_namecolumn = false
	db.cfg.delay_after_bm_itemupdate_event = 0.2
end
