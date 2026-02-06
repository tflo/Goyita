-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Copyright (c) 2025-2026 Thomas Floeren

local MYNAME, A = ...
local db = A.db
local defaults = A.defaults
local MYPRETTYNAME = C_AddOns.GetAddOnMetadata(MYNAME, 'Title')
local MYVERSION = C_AddOns.GetAddOnMetadata(MYNAME, 'Version')
local CLR = A.CLR
local addonprint, arrayprint = A.addonprint, A.arrayprint
local BLOCKSEP = A.BLOCKSEP

local tonumber = tonumber
local type = type
local format = format

--[[============================================================================
	UI
============================================================================]]--

local CMD1, CMD2, CMD3 = '/goyita', '/gy', nil

local function last_record_to_console(update)
	local records = messy_main_func(update)
	if split_lines_for_console then
		local t = strsplittable('\n', records[1])
		arrayprint(t)
	else
		print(records[1])
	end
	print(BLOCKSEP)
end

local function clear_list()
	wipe(db.realms[realm].records)
end

local function clear_all()
	wipe(db.realms[realm].records)
	wipe(db.realms[realm].auctions)
end

local function print_config()
	local array = {}
	for k, v in pairs(db.cfg) do
		local deftext, defvalue = '', defaults.cfg[k]
		if defvalue ~= v then deftext = ' (' .. tostring(defvalue) .. ')' end
		tinsert(array, tostring(k) .. ' = ' .. tostring(v) .. deftext)
	end
	table.sort(array)
	arrayprint(array)
end

local function set_config(key, value)
	if not value then
		addonprint(
			format(
				'%sMissing value! %sSeparate key and value with a %s.',
				CLR.BAD(),
				CLR.TXT(),
				CLR.KEY('Space')
			)
		)
	end
	if value == 'true' then
		value = true
	elseif value == 'false' then
		value = false
	else
		value = tonumber(value) or value
	end
	if type(db.cfg[key]) == type(value) then
		db.cfg[key] = value
		addonprint(format('%s set to %s.', CLR.KEY(key), CLR.KEY(tostring(value))))
	else
		addonprint(
			format(
				"Either the key (%s) doesn't exist or the value (%s) is invalid.",
				CLR.KEY(key),
				CLR.KEY(tostring(value))
			)
		)
	end
end

local help = {
	format( -- Header
		'%s%s Help: %s or %s accepts these arguments:',
		CLR.HEAD(),
		CLR.ADDON(MYPRETTYNAME),
		CLR.CMD(CMD1),
		CLR.CMD(CMD2)
	),
	format( -- Show main
		'%s%s (or just %s) : Open records frame (cached view).',
		CLR.TXT(),
		CLR.CMD('s'),
		CLR.CMD('/gy')
	),
	format( -- Print last
		'%s%s : Print last record to the chat console (cached view).',
		CLR.TXT(),
		CLR.CMD('p')
	),
	format( -- BM reset time
		'%s%s : Set local BlackMarket reset time (default: %s).',
		CLR.TXT(),
		CLR.CMD('rtime <HH:MM>'),
		CLR.KEY('23:30')
	),
	format( -- Sound
		'%s%s : Toggle all sounds.',
		CLR.TXT(),
		CLR.CMD('sound')
	),
	format( -- Chat alerts
		'%s%s : Toggle all chat alerts.',
		CLR.TXT(),
		CLR.CMD('chat')
	),
	format( -- Frame alerts
		'%s%s : Toggle on-screen notification frames.',
		CLR.TXT(),
		CLR.CMD('screen')
	),
	format( -- Cfg print
		'%s%s : Show all setting keys and values.',
		CLR.TXT(),
		CLR.CMD('c')
	),
	format( -- Cfg set
		'%s%s %s : Set a key to the scpeified value..',
		CLR.TXT(),
		CLR.CMD('c'),
		CLR.CMD('<key> <value>')
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
	elseif args[1] == nil or args[1] == 'show' or args[1] == 's' then
		A.display_open(false)
	elseif args[1] == 'print' or args[1] == 'p' then
		last_record_to_console(false)
	elseif args[1] == 'clear' then
		clear_list()
	elseif args[1] == 'clearall' then
		clear_all()
	elseif args[1] == 'sounds' or args[1] == 'sound' then
		db.cfg.notif_sound = not db.cfg.notif_sound
		addonprint(format('Notification sounds are %s now.', db.cfg.notif_sound and CLR.ON('On') or CLR.OFF('Off')))
	elseif args[1] == 'chat' then
		db.cfg.notif_chat = not db.cfg.notif_chat
		addonprint(format('Chat notifications are %s now.', db.cfg.notif_chat and CLR.ON('On') or CLR.OFF('Off')))
	elseif args[1] == 'onscreen' or args[1] == 'screen' then
		db.cfg.notif_frame = not db.cfg.notif_frame
		addonprint(format('On-screen notifications are %s now.', db.cfg.notif_frame and CLR.ON('On') or CLR.OFF('Off')))
	elseif args[1] == 'resettime' or args[1] == 'rtime' then
		local timestr = args[2]
		if A.is_valid_bm_reset_time(timestr) then
			db.cfg.bm_reset_time = timestr
			addonprint(format('Black Market reset time set to %s local time. Will become effective after UI reload.', CLR.KEY(timestr)))
		else
			addonprint(format('%s%s is not a valid time! %sValid examples: %s, %s, %s', CLR.WARN(), CLR.BAD(timestr), CLR.TXT(), CLR.GOOD('23:30'), CLR.GOOD('2:30'), CLR.GOOD('02:30')))
		end
	elseif args[1] == 'c' and args[2] == nil then
		print(BLOCKSEP)
		addonprint('Current config:')
		print_config()
		print(BLOCKSEP)
	elseif args[1] == 'c' and args[2] and args[3] then
		print(BLOCKSEP)
		set_config(args[2], args[3])
		print(BLOCKSEP)
	elseif args[1] == 'help' or args[1] == 'h' then
		arrayprint(help)
	elseif args[1] == 't1' then
		A.simulate_event(A.BLACK_MARKET_BID_RESULT, A.BLACK_MARKET_ITEM_UPDATE)
	elseif args[1] == 't2' then
		A.simulate_event(A.BLACK_MARKET_OUTBID)
	elseif args[1] == 't3' then
		A.simulate_event(A.BLACK_MARKET_WON)
	else
		addonprint(
			format('%s Enter %s for help.', CLR.BAD('Not a valid input.'), CLR.CMD(CMD2 .. ' h'))
		)
	end
end
