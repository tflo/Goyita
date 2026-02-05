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
	frame:SetSize(800, 300)
	-- frame:SetWidth(400)
	frame:SetFrameStrata('FULLSCREEN_DIALOG')
	frame:Raise()
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	if global_position then frame:SetDontSavePosition(true) end
	frame:RegisterForDrag('LeftButton')
	-- frame.TitleText:SetText(MYNAME .. 'Alerts') -- BasicFrameTemplateWithInset
	frame:SetTitle(MYNAME .. ' Alerts') -- ButtonFrameTemplate

	alert_text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightLarge')
	alert_text:SetPoint('TOPLEFT', 20, -60)
	-- alert_text:SetWidth(0)
	alert_text:SetHeight(1500)
	alert_text:SetJustifyH('LEFT')
	alert_text:SetJustifyV('TOP')
	-- alert_text:SetWordWrap(true)

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

function A.show_alert(user_opened)
	create_alerts_frame()
	db[A.realm].num_unread_alerts = db[A.realm].num_unread_alerts + 1
	local cache = db[A.realm].alertcache
	local num_alerts = user_opened and db.cfg.num_alerts_max or db[A.realm].num_unread_alerts
	while #cache > db.cfg.num_alerts_max do
		tremove(cache)
	end
	local text = table.concat(cache, '\n\n', 1, min(#cache, num_alerts))
-- 	frame:SetHeight(num_alerts * 40 + 50)
	alert_text:SetText(text)
	local w = alert_text:GetStringWidth() -- GetUnboundedStringWidth
	local h = alert_text:GetStringHeight()
-- 	print(w, h)
	h = h + 90 -- Don't know why we have to adjust; linebreaks? TODO: use spacing
	w = w + 40 -- The coin texture is not calculated by the func
	frame:SetSize(w, h)
	frame:Show()
end

-- A.alerts_frame = frame

--[[
GameFontHighlightLarge
GameFontGreenLarge
GameFontRedLarge
]]
