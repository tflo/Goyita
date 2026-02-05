-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Copyright (c) 2025-2026 Thomas Floeren

local MYNAME, A = ...
local db = A.db

--[[============================================================================
	Frame
============================================================================]]--

local alert_text
local frame
local global_position = true

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
	tinsert(UISpecialFrames, frame:GetName())
	-- frame.Inset:Hide()
	-- frame.Inset:SetPoint('TOP', 15, -30)
	local p, _, _, x, _ = frame.Inset:GetPointByName('TOPLEFT')
	frame.Inset:SetPoint(p, x, -40)

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
	if global_position then frame:SetDontSavePosition(true) end
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
		if global_position then
			local point, _, _, x, y = self:GetPoint()
			db.cfg.frames.alerts.anchor = point
			db.cfg.frames.alerts.x = x
			db.cfg.frames.alerts.y = y
		end
	end)

	tinsert(UISpecialFrames, frame:GetName())
	frame:SetScript(
		'OnHyperlinkClick',
		function(self, link, text, button) SetItemRef(link, text, button, self) end
	)
	frame:SetScript('OnHyperlinkEnter', function(self, link) -- self, link, text, button
		-- GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
		GameTooltip:SetOwner(self)
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
	end)

	frame:SetScript('OnHyperlinkLeave', function() GameTooltip:Hide() end)

	frame:SetHyperlinksEnabled(true)

	frame:SetScript('OnHide', function() db[A.realm].num_unread_alerts = 0 end)
end

--[[============================================================================
	Caller
============================================================================]]--

-- layout cache needs the frame created before login
if not global_position then create_alerts_frame() end

function A.show_alert(itemlink, timestamp, lastbid)
	create_alerts_frame()
	local timestr = A.time_format(timestamp, false)
	local goldstr = floor(lastbid / 1e4)

	local text = format('Outbid on %s at %s (last bid: %sg)', itemlink, timestr, goldstr)

	alert_text:SetText(text)
	frame:Show()
end
