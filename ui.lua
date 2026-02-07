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

local function last_record_to_chat(update)
	local records = messy_main_func(update)
	if split_lines_for_console then
		local t = strsplittable('\n', records[1])
		arrayprint(t)
	else
		print(records[1])
	end
	print(BLOCKSEP)
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
	A.BLOCKSEP,
	format( -- Header
		'%s%s Help: %s or %s accepts these arguments:',
		CLR.HEAD(),
		CLR.ADDON(MYPRETTYNAME),
		CLR.CMD(CMD1),
		CLR.CMD(CMD2)
	),
	format( -- Show records
		'%s%s (or just %s) : Open records frame (cached view).',
		CLR.TXT(),
		CLR.CMD('r'),
		CLR.CMD('/gy')
	),
	format( -- Show notifications
		'%s%s or %s : Open notifications frame (history of recent notifications).',
		CLR.TXT(),
		CLR.CMD('notif'),
		CLR.CMD('n')
	),
	format( -- Print last
		'%s%s : Print last record to the chat console (cached view).',
		CLR.TXT(),
		CLR.CMD('p')
	),
	format( -- Set BM reset time
		'%s%s : Set local BlackMarket reset time (default: %s).',
		CLR.TXT(),
		CLR.CMD('rtime <HH:MM>'),
		CLR.KEY('23:30')
	),
	format( -- Sounds master toggle
		'%s%s : Toggle notification sounds.',
		CLR.TXT(),
		CLR.CMD('sound')
	),
	format( -- Chat messages master toggle
		'%s%s : Toggle chat notifications.',
		CLR.TXT(),
		CLR.CMD('chat')
	),
	format( -- Notifications frame master toggle
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
		'%s%s %s : Set a key to the specified value.',
		CLR.TXT(),
		CLR.CMD('c'),
		CLR.CMD('<key> <value>')
	),
	format('%s%s : Print addon version.', CLR.TXT(), CLR.CMD('version')),
	format('%s%s or %s : Print this help text.', CLR.TXT(), CLR.CMD('help'), CLR.CMD('h')),
	format('%s%s : Toggle debug mode.', CLR.TXT(), CLR.CMD('dm')),

	format('%sThe following %q commands require an UI Reload!', CLR.ADDON(), CLR.CMD('clear'), CLR.WARN('UI Realod')),
	format( -- Clear records
		'%s%s : Clear auction records (the text in the records frame).',
		CLR.TXT(),
		CLR.CMD('clearrecords')
	),
	format( -- Clear auctions
		'%s%s : Clear auction data (the data used for computing the records).',
		CLR.TXT(),
		CLR.CMD('clearauctions')
	),
	format( -- Clear notifs
		'%s%s : Clear notification history.',
		CLR.TXT(),
		CLR.CMD('clearnotifs')
	),
	format( -- Clear data
		'%s%s : Clear records, auction data, notification history.',
		CLR.TXT(),
		CLR.CMD('cleardata')
	),
	format( -- Clear all data
		'%s%s : Like %q, but all realms.',
		CLR.TXT(),
		CLR.CMD('clearalldata'),
		CLR.CMD('cleardata')
	),
	format( -- Clear settings
		'%s%s : Clear all user settings, back to defaults.',
		CLR.TXT(),
		CLR.CMD('clearsettings')
	),
	A.BLOCKSEP,
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
	elseif args[1] == nil or args[1] == 'r' or args[1] == 'rec' or args[1] == 'records' then
		A.show_records(false)
	elseif args[1] == 'n' or args[1] == 'notif' or args[1] == 'notifs' then
		A.show_notifs(true, false)
	elseif args[1] == 'p' or args[1] == 'print' then
		last_record_to_chat(false)
	elseif args[1] == 'clearrecords' then -- TODO: add confirmations (and check) for all clears
		A.clear_records()
	elseif args[1] == 'clearauctions' then
		A.clear_auctions()
	elseif args[1] == 'clearnotifs' then
		A.clear_notifs()
	elseif args[1] == 'cleardata' then
		A.clear_data()
	elseif args[1] == 'clearalldata' then
		A.clear_alldata()
	elseif args[1] == 'clearsettings' then
		A.clear_settings()
	elseif args[1] == 'sounds' or args[1] == 'sound' then
		db.cfg.notif_sound = not db.cfg.notif_sound
		addonprint(format('Notification sounds are %s now.', db.cfg.notif_sound and CLR.ON('enabled') or CLR.OFF('disabled')))
	elseif args[1] == 'chat' then
		db.cfg.notif_chat = not db.cfg.notif_chat
		addonprint(format('Chat notifications are %s now.', db.cfg.notif_chat and CLR.ON('enabled') or CLR.OFF('disabled')))
	elseif args[1] == 'screen' or args[1] == 'onscreen' then
		db.cfg.notif_frame = not db.cfg.notif_frame
		addonprint(format('On-screen notifications are %s now.', db.cfg.notif_frame and CLR.ON('enabled') or CLR.OFF('disabled')))
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

--[[============================================================================
	For the bindings.xml
============================================================================]]--

-- BINDING_HEADER_GOYITA = "Goyita  "
BINDING_NAME_BFA6 = 'Show Records'
function BFA6() A.show_records() end
BINDING_NAME_C780 = 'Show Notifications'
function C780() A.show_notifs() end
BINDING_NAME_FC97 = 'Refresh BMAH'
function FC97() A.bm_refresh() end

