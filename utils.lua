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

local function addonprint(msg)
	print(format('%s%s: %s', CLR.ADDON(), MYNAME, CLR.TXT(msg)))
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

A.addonprint = addonprint
A.debugprint = debugprint
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
	db.cfg.price_type = 2
	db.cfg.true_completed_price = true
	db.cfg.timewindow_plausibilityfilter_early = false
	db.cfg.num_records_max = 50
	db.cfg.len_truncate = 17
	db.cfg.frame_width = 460
	db.cfg.frame_height = 400
	db.cfg.show_price_in_namecolumn = false
	db.cfg.delay_after_bm_itemupdate_event = 0.3
end
