-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Copyright (c) 2025-2026 Thomas Floeren

local MYNAME, A = ...
local db = A.db

-- Alert Frame for Outbid/Won Notifications

local alert_text
local frame


--[[============================================================================
	Frame
============================================================================]]--

local function create_alerts_frame()
	if frame then return end
	frame =
		-- CreateFrame('Frame', MYNAME .. 'frame', UIParent, 'BasicFrameTemplateWithInset')
		CreateFrame('Frame', MYNAME .. 'AlertsFrame', UIParent, 'ButtonFrameTemplate')

	frame:SetPoint(
		db.cfg.frames.alerts.anchor,
		UIParent,
		db.cfg.frames.alerts.anchor,
		db.cfg.frames.alerts.x,
		db.cfg.frames.alerts.y
	)

	ButtonFrameTemplate_HidePortrait(frame)
	ButtonFrameTemplate_HideButtonBar(frame)
	frame.Inset:Hide()

	frame:Hide()
	-- frame:SetPoint('TOP')
	-- frame:SetPoint('TOP', UIParent, 'TOP', 0, -150)
	frame:SetSize(400, 200)
	frame:SetFrameStrata('FULLSCREEN_DIALOG')
	frame:Raise()
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	if db.cfg.global_frame_positions then frame:SetDontSavePosition(true) end
	frame:RegisterForDrag('LeftButton')
	-- frame.TitleText:SetText('Goyita Alert') -- BasicFrameTemplateWithInset
	frame:SetTitle('Goyita Alerts') -- ButtonFrameTemplate

	-- GameFontHighlightLarge
	-- GameFontGreenLarge
	-- GameFontRedLarge

	alert_text = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
	alert_text:SetPoint('TOP', 0, -35)
	alert_text:SetWidth(360)
	alert_text:SetJustifyH('CENTER')
	alert_text:SetWordWrap(true)

	frame:SetScript('OnDragStart', function(self) self:StartMoving() end)

	frame:SetScript('OnDragStop', function(self)
		self:StopMovingOrSizing()
		if db.cfg.global_frame_positions then
			local point, _, _, x, y = self:GetPoint()
			db.cfg.frames.alerts.anchor = point
			db.cfg.frames.alerts.x = x
			db.cfg.frames.alerts.y = y
		end
	end)

	tinsert(UISpecialFrames, frame:GetName())
end
-- 	if ALERT_POSITION_MODE == 'global' and db.cfg.alert_position then frame:SetUserPlaced(false) end

--[[============================================================================
	Caller
============================================================================]]--

if not db.cfg.global_frame_positions then
create_alerts_frame()
end

function A.show_alert(itemlink, timestamp, lastbid)
	create_alerts_frame()
	local timestr = A.time_format(timestamp, false)
	local goldstr = floor(lastbid / 1e4)

	local text = format('Outbid on %s at %s (last bid: %sg)', itemlink, timestr, goldstr)

	alert_text:SetText(text)
	frame:Show()
end
