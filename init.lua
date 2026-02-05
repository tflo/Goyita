-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Copyright (c) 2025-2026 Thomas Floeren

local MYNAME, A = ...
local DB_ID = 'DB_6583B024_97F4_47B0_8F4C_BB1C1B4FE393'

local type = type

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

-- Reverse nil cleanup
local function clean_removed(src, ref)
	for k, v in pairs(src) do
		if ref[k] == nil then
			src[k] = nil
		elseif type(v) == 'table' then
			clean_removed(v, ref[k])
		end
	end
end

-- DB version log here
-- 3 (Feb 4, 2026): default value changed: chat_alerts = true
-- 2 (Feb 3, 2026): endtime color keys changed
local DB_VERSION_CURRENT = 3

local defaults = {
	cfg = {
		-- Main switch for the records display
		display_records = true,
		-- Used as base for plausibility boundaries of the time window
		bm_reset_time = '23:30',
		-- Set a hard earliest possible end time, to not display implausible end times like 14:30
		-- Plausability for late is always enabled
		timewindow_plausibilityfilter_early = false,
		-- Hours to subtract from the new auction reset time (e.g. 23:30), to get plausible time windows.
		-- Earliest I've ever seen was 19:00 or maybe 18:50 (with 23:30 as start time)
		offset_plausible_earlytime = 5,
		-- I think the latest I've seen was around 22:30 (with 23:30 reset time)
		-- But in theory (many late bidders) this can extend up to the reset time (or even more?)
		offset_plausible_latetime = 0,
		-- Hard limit for text cache, = number of displayed records
		num_records_max = 50,
		frame_width = 460,
		-- Height used for standalone window, not when attached to BlackMarketFrame
		frame_height = 400,
		-- Enable columns
		show_timewindow = true,
		show_timeremaining = true,
		show_timetier = true,
		show_bids = true,
		show_price = true,
		-- Timestamp in the record header with seconds
		timestamp_with_seconds = true,
		-- 1: price is current bid, or min bid if there are no bids (like Blizz BMAH frame)
		-- 2: price is min bid (what you'll have to bid), unless completed
		-- 3: price is min increment, unless completed
		-- Completed auction price is always current (=last) bid, or min bid if failed
		price_type = 1, -- 1 | 2 | 3
		-- Also a failed auction's price is current bid (zero), instead of min bid
		true_completed_price = false,
		-- Slightly more efficient space usage, but a bit ugly
		show_price_in_namecolumn = false,
		-- Only for standalone price column
		pricecolumn_leftaligned = false,
		-- 0: uniform color (white currently)
		-- 1: by remaining time to calculated times (eg orange < 30m, red < 0s)
		-- 2: by the color of the time tier that provided decisive information for the last calculation
		endtime_colormode = 2,
		-- Truncation applies to the last column (item name)
		do_truncate = true,
		-- At 460 width, fontsize 14, all columns, price column separate: max 17
		len_truncate = 17,
		-- For truncation, in case we use a font that lacks '…' (\226\128\166)
		ellipsis_replacement = nil,
		-- Delete the previous record if the new one is 100% identical
		deduplicate_records = true,
		-- [seconds] The BLACK_MARKET_ITEM_UPDATE event might fire several times in quick succession, so…
		-- the delay ensures that we capture the last one, without updating unnecessarily after the first one,
		-- it also ensures that the data is really available when we update.
		-- A shorter delay makes the frame pop up faster, but I wouldn't set this lower than 0.3s
		delay_after_bm_itemupdate_event = 0.3,
		-- Event notifications
		notif_sound = true, -- Any sound notification
		notif_sound_outbid = true,
		notif_sound_won = true,
		notif_sound_bid = true,
		notif_chat = true, -- Any chat notification
		notif_chat_outbid = true,
		notif_chat_won = true,
		notif_chat_bid = true,
		notif_frame = true, -- Any notification frame
		notif_frame_outbid = true,
		notif_frame_won = true,
		notif_frame_bid = false,
		debugmode = false,
	},
	global = {
		frames = {
			records = {
				anchor = 'TOPLEFT',
				x = 35,
				y = -50,
			},
			notifs = {
				anchor = 'TOP',
				x = 0,
				y = -150,
			},
		},
		notifs = {},
		num_unread_notifs = 0,
	},
	db_version = DB_VERSION_CURRENT,
}

if type(_G[DB_ID]) ~= 'table' then
	_G[DB_ID] = {}
elseif not _G[DB_ID].db_version or _G[DB_ID].db_version ~= DB_VERSION_CURRENT then
	-- Clean up or transfer old db stuff here
	_G[DB_ID].cfg.chat_alerts = true -- 3
	_G[DB_ID].cfg.timewindow_color_by_rem = nil -- 2
	_G[DB_ID].cfg.timewindow_color_by_src = nil -- 2
	-- Never clean the whole db, the realm key is user-specific, and there may be several of it!
	clean_removed(_G[DB_ID].cfg, defaults.cfg)
	-- Update db_version
	_G[DB_ID].db_version = DB_VERSION_CURRENT
	A.db_updated = true
end

merge_defaults(defaults, _G[DB_ID])

local db = _G[DB_ID]
A.db = db
A.defaults = defaults

