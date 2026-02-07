-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Copyright (c) 2025-2026 Thomas Floeren

local MYNAME, A = ...
local db = A.db

local num_notifs_max = 30

--[[============================================================================
	Frame
============================================================================]]--

local notif_text
local frame
local global_position = true

local function create_notifs_frame()
	if frame then return end
	frame =
		-- CreateFrame('Frame', MYNAME .. 'frame', UIParent, 'BasicFrameTemplateWithInset')
		CreateFrame('Frame', MYNAME .. 'NotificationsFrame', UIParent, 'ButtonFrameTemplate')

	frame:SetPoint(
		db.global.frames.notifs.anchor,
		UIParent,
		db.global.frames.notifs.anchor,
		db.global.frames.notifs.x,
		db.global.frames.notifs.y
	)

-- 	ButtonFrameTemplate_HidePortrait(frame)
-- 	SetPortraitTexture(frame.PortraitContainer.portrait,'player')
	SetPortraitTextureFromCreatureDisplayID(frame.PortraitContainer.portrait, 121434)
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
	frame:SetTitle(MYNAME .. ' Notifications') -- ButtonFrameTemplate

	notif_text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightLarge')
	notif_text:SetPoint('TOPLEFT', 20, -60)
	-- notif_text:SetWidth(0)
	notif_text:SetHeight(1500)
	notif_text:SetJustifyH('LEFT')
	notif_text:SetJustifyV('TOP')
	-- notif_text:SetWordWrap(true)

	frame:SetScript('OnDragStart', function(self) self:StartMoving() end)

	frame:SetScript('OnDragStop', function(self)
		self:StopMovingOrSizing()
		if global_position then
			local point, _, _, x, y = self:GetPoint()
			db.global.frames.notifs.anchor = point
			db.global.frames.notifs.x = x
			db.global.frames.notifs.y = y
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

	frame:SetScript('OnHide', function() db.global.num_unread_notifs = 0 end)
end

--[[============================================================================
	Caller
============================================================================]]--

-- layout cache needs the frame created before login
if not global_position then create_notifs_frame() end

function A.show_notifs(user_opened, login_opened)
	create_notifs_frame()
	local cache, text = db.global.notifs, ''
	if #cache < 1 then
		text = 'Notifications history is empty.'
	else
		if not user_opened and not login_opened then
			db.global.num_unread_notifs = db.global.num_unread_notifs + 1
		end
		local num_alerts = user_opened and num_notifs_max
			or min(db.global.num_unread_notifs, num_notifs_max)
		while #cache > num_notifs_max do
			tremove(cache)
		end
		text = table.concat(cache, '\n', 1, min(#cache, num_alerts))
		-- frame:SetHeight(num_alerts * 40 + 50)
	end
	notif_text:SetText(text)
	local w = notif_text:GetStringWidth() -- GetUnboundedStringWidth
	local h = notif_text:GetStringHeight()
	-- print(w, h)
	h = h + 90 -- Don't know why we have to adjust; linebreaks? TODO: use spacing
	w = w + 40 -- The coin texture is not calculated by the func
	frame:SetSize(w, h)
	frame:Show()
end


--[[
TODO:
We could take measures when the frame is called while the bmah is open, for example
- don't show the frame
- lower the strata to below bmah frame
- dock it
]]





--[[
GameFontHighlightLarge
GameFontGreenLarge
GameFontRedLarge
]]
