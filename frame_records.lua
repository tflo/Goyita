-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Copyright (c) 2025-2026 Thomas Floeren

local MYNAME, A = ...
local db = A.db

--[[============================================================================
	Fonts and vars
============================================================================]]--

local bodyfontsize = 14

local headerfont = BMA_Font_Header or CreateFont 'GoyitaHeaderFont'
headerfont:SetFont([[Interface/AddOns/Goyita/media/fonts/FiraMono-Regular.ttf]], bodyfontsize - 2, '')

local bodyfont = BMA_Font_Body or CreateFont 'GoyitaBodyFont'
bodyfont:SetFont([[Interface/AddOns/Goyita/media/fonts/FiraMono-Medium.ttf]], bodyfontsize, '')

-- It's OK that the text updates only after reload.
local headertext do
	local sep = ' – '
	headertext = format(
		'%s%s%s%s%s%s',
		db.cfg.show_bids and 'Bids' .. sep or '',
		db.cfg.show_timetier and 'T/tier' .. sep or '',
		db.cfg.show_timeremaining and 'T/remaining' .. sep or '',
		db.cfg.show_timewindow and 'T/window' .. sep or '',
		db.cfg.show_price and (db.cfg.price_type == 3 and '+' or '') .. 'Price' .. sep or '',
		'Item'
	)
end

--[[============================================================================
	Frame
============================================================================]]--

local frame = CreateFrame('Frame', MYNAME .. '_records_display', UIParent, 'ButtonFrameTemplate')
frame:Hide()
ButtonFrameTemplate_HidePortrait(frame)
ButtonFrameTemplate_HideButtonBar(frame)
frame.Inset:Hide()
-- frame:SetFrameStrata('TOOLTIP')
-- frame:Raise()
frame:RegisterForDrag('LeftButton')
frame.Bg:SetTexture(609607) -- Interface/BlackMarket/BlackMarketBackground-Tile
frame.Bg:SetVertexColor(.5, .5, .5, 1)
-- frame.Bg:Hide()
-- frame.Bg:SetTexture(nil)

-- frame.tex = frame:CreateTexture()
-- frame.tex:SetPoint("CENTER")
-- frame.tex:SetAtlas('housing-wood-frame-basic-background')


frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(false)
-- frame:SetUserPlaced(false)
frame:SetToplevel(true)
tinsert(UISpecialFrames, frame:GetName()) -- ESC closing

frame:SetScript('OnDragStart', function(self)
	self:StartMoving()
	self:SetUserPlaced(false)
end)

frame:SetScript('OnDragStop', function(self)
	self:StopMovingOrSizing()
	self:SetUserPlaced(false)
end)

-- frame:SetSize(550, 500)

--[[----------------------------------------------------------------------------
	Header frame
----------------------------------------------------------------------------]]--

local headerframe = CreateFrame('Frame', nil, frame)
headerframe:SetPoint('TOPLEFT', 10, -30)
headerframe:SetPoint('TOPRIGHT', -10, -30)
headerframe:SetHeight(22)

headerframe.text = headerframe:CreateFontString(nil, nil, 'GoyitaHeaderFont')
headerframe.text:SetPoint('TOPLEFT')
-- headerframe.text:SetHeight(20)
headerframe.text:SetJustifyH('LEFT')
headerframe.text:SetText(headertext)

local divider = headerframe:CreateTexture(nil, 'ARTWORK')
divider:SetTexture('Interface/Common/UI-TooltipDivider-Transparent')
divider:SetPoint('BOTTOMLEFT')
divider:SetPoint('BOTTOMRIGHT')
divider:SetHeight(1)
divider:SetColorTexture(0.93, 0.93, 0.93, 0.45)

--[[----------------------------------------------------------------------------
	Scroll box
----------------------------------------------------------------------------]]--

local scrollBox = CreateFrame('Frame', nil, frame, 'WowScrollBoxList')
local scrollBar = CreateFrame('EventFrame', nil, frame, 'MinimalScrollBar')
local view = CreateScrollBoxListLinearView()
-- view:SetElementExtent(200)
view:SetElementExtentCalculator(function(_, element)
local _, line_count = element:gsub("\n", "\n")
	return line_count * bodyfontsize + bodyfontsize / 2
end)
view:SetElementInitializer('Frame', function(f, data)
	if not f.text then
		f.text = f:CreateFontString(nil, nil, 'GoyitaBodyFont')
-- 		f.text:SetHeight(100)
		f.text:SetPoint('LEFT')
-- 		f.text:SetWidth(450)
		f.text:SetJustifyH('LEFT')
	end
	f.text:SetText(data)
end)

ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

scrollBox:SetPoint('TOPLEFT', 10, -56)
scrollBox:SetPoint('BOTTOMRIGHT', -40, 20)
scrollBar:SetPoint('TOPRIGHT', -10, -56)
scrollBar:SetPoint('BOTTOMRIGHT', -10, 20)

--[[============================================================================
	Caller
============================================================================]]--

-- frame:SetScript('OnShow', function()
-- 	scrollBox:SetDataProvider(CreateDataProvider(A.records))
-- end)

function A.display_open(update)
	if InCombatLockdown() then return end
	frame:SetTitle('BM Records' .. (update and '' or ' [Cache view]') .. ' – Reset at ' .. db.cfg.bm_reset_time)
	if BlackMarketFrame and BlackMarketFrame:IsShown() then
		frame:SetParent(BlackMarketFrame)
		frame:SetSize(db.cfg.frame_width, BlackMarketFrame:GetHeight())
-- 		frame.tex:SetSize(frame:GetSize()) -- for the Atlas experiment
		frame:ClearAllPoints()
		frame:SetPoint('TOPLEFT', BlackMarketFrame, 'TOPRIGHT'--[[ , -120, 0]])
	else
		frame:SetParent(UIParent)
		frame:SetSize(db.cfg.frame_width, db.cfg.frame_height)
-- 		frame.tex:SetSize(frame:GetSize()) -- for the Atlas experiment
		frame:ClearAllPoints()
		frame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 35, -50)
	end
	scrollBox:SetDataProvider(CreateDataProvider(A.messy_main_func(update)))
	frame:Show()
end
function A.display_close() frame:Hide() end
