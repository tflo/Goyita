-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Copyright (c) 2025-2026 Thomas Floeren

local MYNAME, A = ...
local db = A.db
local CLR = A.CLR
local addonprint, debugprint, debugprint_pt = A.addonprint, A.debugprint, A.debugprint_pt

local type = type
local format = format

-- Misc variables
local realm

--[[============================================================================
	Events
============================================================================]]--

-- https://www.townlong-yak.com/framexml/live/Blizzard_BlackMarketUI/Blizzard_BlackMarketUI.lua
-- https://warcraft.wiki.gg/wiki/API_C_BlackMarket.RequestItems
-- This is in the events section bc it triggers BLACK_MARKET_ITEM_UPDATE.
function A.bm_refresh()
	if not A.bm_is_connected then
		addonprint('This requires the BMAH to be opened!')
		return
	end
	C_BlackMarket.RequestItems()
end

--[[
NOTES:
https://warcraft.wiki.gg/wiki/Category:API_systems/BlackMarketInfo
Blizz std messages: 'Bid accepted.', 'You have been outbid on <item name>.',
'You won an auction for <item name>'
]]

local function get_data_for_notif(market_id, item_id)
	local link, curr, min, incr
	if db.realms[realm] and db.realms[realm].auctions and db.realms[realm].auctions[market_id] then
		link = db.realms[realm].auctions[market_id].link
		curr = db.realms[realm].auctions[market_id].curr_bid
		min = db.realms[realm].auctions[market_id].min_bid
		incr = db.realms[realm].auctions[market_id].min_incr
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

local id_for_bid_notif

local bmah_update_wait
local function BLACK_MARKET_ITEM_UPDATE()
	debugprint_pt('BLACK_MARKET_ITEM_UPDATE fired.')
	if bmah_update_wait then return end
	bmah_update_wait = true
	C_Timer.After(db.cfg.delay_after_bm_itemupdate_event, function()
		debugprint_pt('Updating now.')
		A.show_records(true)
		if id_for_bid_notif then
			local link, curr, min, incr = get_data_for_notif(id_for_bid_notif)
			local str = format('%s placed on %s. Next bid: %s (+%s).', curr, link, min, incr)
			if db.cfg.notif_chat and db.cfg.notif_chat_bid then
				addonprint(str)
			end
			if db.cfg.notif_frame and db.cfg.notif_frame_bid then
				tinsert(db.global.notifs, 1, str)
				A.show_notifs()
			end
			id_for_bid_notif = nil
		end
		bmah_update_wait = nil
	end)
end

local function BLACK_MARKET_OPEN()
	A.bm_is_connected = true
	A.time_bm_opened = GetTime()
end

local function BLACK_MARKET_CLOSE()
	A.bm_is_connected = false
	A.hide_records()
end


local function BLACK_MARKET_OUTBID(market_id, item_id)
	if db.cfg.notif_sound and db.cfg.notif_sound_outbid then PlaySoundFile(644193, 'Master') end -- "Aargh"
	local chat = db.cfg.notif_chat and db.cfg.notif_chat_outbid
	local frame = db.cfg.notif_frame and db.cfg.notif_frame_outbid
	if chat or frame then
		local link, _, min = get_data_for_notif(market_id, item_id)
		-- Since we are likely away from the BMAH, we don't have updated data, so read min_bid as curr_bid
		local str = format('%sOutbid on %s at %s\124r', CLR.WARN(), link, CLR.TXT(min))
		if chat then addonprint(str) end
		if frame then
			tinsert(db.global.notifs, 1, str)
			A.show_notifs()
		end
	end
	debugprint('BLACK_MARKET_OUTBID', market_id, item_id)
end

local function BLACK_MARKET_WON(market_id, item_id)
	if db.cfg.notif_sound and db.cfg.notif_sound_won then PlaySoundFile(636419, 'Master') end -- "Nicely Done"
	local chat = db.cfg.notif_chat and db.cfg.notif_chat_won
	local frame = db.cfg.notif_frame and db.cfg.notif_frame_won
	if chat or frame then
		local link, curr = get_data_for_notif(market_id, item_id)
		local str = format('%s%s won for %s\124r', CLR.GOOD(), link, CLR.TXT(curr))
		if chat then addonprint(str) end
		if frame then
			tinsert(db.global.notifs, 1, str)
			A.show_notifs()
		end
	end
	debugprint('BLACK_MARKET_WON', market_id, item_id)
end

local function BLACK_MARKET_BID_RESULT(market_id, result_code)
	if result_code == 0 then
		if db.cfg.notif_sound and db.cfg.notif_sound_bid then PlaySoundFile(636627, 'Master') end -- "Yes"
		-- The bid triggers a BLACK_MARKET_ITEM_UPDATE. So send the msg with that event, for up-to-date data.
		if
			db.cfg.notif_chat and db.cfg.notif_chat_bid
			or db.cfg.notif_frame and db.cfg.notif_frame_bid
		then
			id_for_bid_notif = market_id
		end
	end
	debugprint('BLACK_MARKET_BID_RESULT', market_id, result_code)
end

-- For the simulator
A.BLACK_MARKET_BID_RESULT = BLACK_MARKET_BID_RESULT
A.BLACK_MARKET_WON = BLACK_MARKET_WON
A.BLACK_MARKET_OUTBID = BLACK_MARKET_OUTBID
A.BLACK_MARKET_ITEM_UPDATE = BLACK_MARKET_ITEM_UPDATE



local function PLAYER_LOGIN()
	A.user_is_author = tf6 and tf6.user_is_tflo

	realm = A.get_bm_realm() -- Not available at addon load time
	if type(realm) ~= 'string' then return end
	A.realm = realm

	db.realms[realm] = db.realms[realm] or {}
	db.realms[realm].auctions = db.realms[realm].auctions or {}
	db.realms[realm].records = db.realms[realm].records or {}

	if A.user_is_author then A.set_test_config() end
end

local function FIRST_FRAME_RENDERED()
	-- Interestingly, the OnHide script doesn't run when a frame gets dismissed per logout;
	-- So, this works without any further measures.
	if db.global.num_unread_notifs > 0 then A.show_notifs(false, true) end

	if A.db_updated then
		C_Timer.After(
			10,
			function() addonprint(format('Database updated to v%s.', CLR.KEY(db.db_version))) end
		)
	end
end

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
	['FIRST_FRAME_RENDERED'] = FIRST_FRAME_RENDERED,
}

for event in pairs(event_handlers) do
	ef:RegisterEvent(event)
end

ef:SetScript('OnEvent', function(_, event, ...)
	event_handlers[event](...) -- We do not want a nil check here.
end)

