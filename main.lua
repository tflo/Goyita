-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Copyright (c) 2025-2026 Thomas Floeren

local MYNAME, A = ...
local MYPRETTYNAME = C_AddOns.GetAddOnMetadata(MYNAME, 'Title')
local MYVERSION = C_AddOns.GetAddOnMetadata(MYNAME, 'Version')
local MYSHORTNAME = 'XXX'
local DB_ID = 'DB_6583B024_97F4_47B0_8F4C_BB1C1B4FE393'

local C_Timer_After = C_Timer.After
local WTC = WrapTextInColorCode
local tonumber = tonumber
local type = type
local format = format


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
	config = {
		debugmode = false,
		auction_starttime = '23:30',
		ellipsis = '…',
		num_records_max = 100,
	},
	records = {
	},
	db_version = DB_VERSION_CURRENT,
}

if type(_G[DB_ID]) ~= 'table' then
	_G[DB_ID] = {}
elseif not _G[DB_ID].db_version or _G[DB_ID].db_version ~= DB_VERSION_CURRENT then
	-- Clean up old db stuff
	_G[DB_ID].db_version = DB_VERSION_CURRENT
end

merge_defaults(defaults, _G[DB_ID])

local db = _G[DB_ID]
A.db = db
A.defaults = defaults


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
	print(format('%s%s > DEBUG > %s', CLR.DEBUG(), MYSHORTNAME, CLR.TXT()), ...)
end

--[[============================================================================
	Main
============================================================================]]--

-- Main

--[[============================================================================
	UI
============================================================================]]--

local CMD1, CMD2, CMD3 = '/myXXXfullcommand', '/myXXXshortcmd', nil

local help = {
	format('%s%s Help: %s or %s accepts these arguments:', CLR.HEAD(), CLR.ADDON(MYPRETTYNAME), CLR.CMD(CMD1), CLR.CMD(CMD2)),
	format('%s%s : Print addon version.', CLR.TXT(), CLR.CMD('/version')),
	format('%s%s or %s : Print this help text.', CLR.TXT(), CLR.CMD('/help'), CLR.CMD('/h')),
}

local function multiprint(lines)
	for _, v in ipairs(lines) do
		print(v)
	end
end

--[[----------------------------------------------------------------------------
	Slash function
----------------------------------------------------------------------------]]--

SLASH_XXX1 = '/XXXXXX'
SLASH_XXX2 = '/XXX'
SlashCmdList.XXX = function(msg)
	local args = {}
	for arg in msg:gmatch('[^ ]+') do
		tinsert(args, arg)
	end
	if args[1] == 'version'  or args[1] == 'ver' then
		addonprint(format('Version %s', CLR.KEY(MYVERSION)))
	elseif args[1] == 'dm' then
		db.debugmode = not db.debugmode
		addonprint(format('Debug mode %s.', db.debugmode and CLR.ON('enabled') or CLR.OFF('disabled')))
	elseif X == Y then
	else
	end
end

--[[============================================================================
	Events
============================================================================]]--

local function BLACK_MARKET_ITEM_UPDATE()
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


]]
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
