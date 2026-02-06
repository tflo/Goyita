-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Copyright (c) 2025-2026 Thomas Floeren

local MYNAME, A = ...
local db = A.db

--[[============================================================================
	Fonts and vars
============================================================================]]--

local tight_font
local bf, hf
local fira_reg = [[Interface/AddOns/Goyita/media/fonts/FiraMono-Regular.ttf]]
local fira_med = [[Interface/AddOns/Goyita/media/fonts/FiraMono-Medium.ttf]]
local victor_med = [[Interface/AddOns/Goyita/media/fonts/VictorMono-Medium.ttf]]
local victor_med_it = [[Interface/AddOns/Goyita/media/fonts/VictorMono-MediumItalic.ttf]]

if db.cfg.font_records == 1 then
	bf, hf = fira_med, fira_reg
elseif db.cfg.font_records == 2 then
	bf, hf = victor_med, victor_med
	tight_font = true
elseif db.cfg.font_records == 3 then
	bf, hf = victor_med_it, victor_med_it
	tight_font = true
end


local bodyfontsize = 14

local headerfont = BMA_Font_Header or CreateFont 'GoyitaHeaderFont'
headerfont:SetFont(hf, bodyfontsize - 2, '')

local bodyfont = BMA_Font_Body or CreateFont 'GoyitaBodyFont'
bodyfont:SetFont(bf, bodyfontsize, '')

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
local frame
local scroll_box
local frame_docked

local function create_records_frame()
	if frame then return end
	frame = CreateFrame('Frame', MYNAME .. 'RecordsFrame', UIParent, 'ButtonFrameTemplate')
	frame:Hide()
	ButtonFrameTemplate_HidePortrait(frame)
	ButtonFrameTemplate_HideButtonBar(frame)
	tinsert(UISpecialFrames, frame:GetName()) -- ESC closing
	frame.Inset:Hide()
	frame:SetToplevel(true)
	-- frame:SetFrameStrata('HIGH')
	-- frame:Raise()
	frame.Bg:SetTexture(609607) -- Interface/BlackMarket/BlackMarketBackground-Tile
	frame.Bg:SetVertexColor(0.5, 0.5, 0.5, 1)

	frame:RegisterForDrag('LeftButton')
	frame:EnableMouse(true)
	frame:SetMovable(true)
-- 	if db.cfg.global_frame_positions then frame:SetDontSavePosition(true) end
	frame:SetDontSavePosition(true)

	frame:SetPoint(
		db.global.frames.records.anchor,
		UIParent,
		db.global.frames.records.anchor,
		db.global.frames.records.x,
		db.global.frames.records.y
	)


	frame:SetScript('OnDragStart', function(self)
		self:StartMoving()
	end)

	frame:SetScript('OnDragStop', function(self)
		self:StopMovingOrSizing()
-- 		if db.cfg.global_frame_positions then
		if not frame_docked then
			local point, _, _, x, y = self:GetPoint()
			db.global.frames.records.anchor = point
			db.global.frames.records.x = x
			db.global.frames.records.y = y
		end
	end)

	-- Header frame

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

	-- Scroll box

	scroll_box = CreateFrame('Frame', nil, frame, 'WowScrollBoxList')
	local scroll_bar = CreateFrame('EventFrame', nil, frame, 'MinimalScrollBar')
	local view = CreateScrollBoxListLinearView()
	-- view:SetElementExtent(200)
	view:SetElementExtentCalculator(function(_, element)
		local _, line_count = element:gsub('\n', '\n')
		return line_count * bodyfontsize + bodyfontsize / 2
	end)
	view:SetElementInitializer('Frame', function(f, data)
		if not f.text then
			f.text = f:CreateFontString(nil, nil, 'GoyitaBodyFont')
			-- f.text:SetHeight(100)
			f.text:SetPoint('LEFT')
			-- f.text:SetWidth(450)
			f.text:SetJustifyH('LEFT')
		end
		f.text:SetText(data)
	end)

	ScrollUtil.InitScrollBoxListWithScrollBar(scroll_box, scroll_bar, view)

	scroll_box:SetPoint('TOPLEFT', 10, -56)
	scroll_box:SetPoint('BOTTOMRIGHT', -40, 20)
	scroll_bar:SetPoint('TOPRIGHT', -10, -56)
	scroll_bar:SetPoint('BOTTOMRIGHT', -10, 20)
end

--[[============================================================================
	Caller
============================================================================]]--

-- if not db.cfg.global_frame_positions then create_records_frame() end

function A.show_records(update)
	if InCombatLockdown() then return end
	create_records_frame()
	frame:SetTitle('BM Records' .. (update and '' or ' [Cache view]') .. ' – Reset at ' .. db.cfg.bm_reset_time)

	local width = db.cfg.records_frame_width - (tight_font and 33 or 0)
	if BlackMarketFrame and BlackMarketFrame:IsShown() then
		frame_docked = true
		frame:SetParent(BlackMarketFrame)
		frame:SetSize(width, BlackMarketFrame:GetHeight())
-- 		frame.tex:SetSize(frame:GetSize()) -- for the Atlas experiment
		frame:ClearAllPoints()
		frame:SetPoint('TOPLEFT', BlackMarketFrame, 'TOPRIGHT', -7, 0)
	else
		frame_docked = false
		frame:SetParent(UIParent)
		frame:SetSize(width, db.cfg.records_frame_height)
-- 		frame.tex:SetSize(frame:GetSize()) -- for the Atlas experiment
		frame:ClearAllPoints()
		frame:SetPoint(
			db.global.frames.records.anchor,
			UIParent,
			db.global.frames.records.anchor,
			db.global.frames.records.x,
			db.global.frames.records.y
		)
	end
	scroll_box:SetDataProvider(CreateDataProvider(A.messy_main_func(update)))
	frame:Show()
end
function A.display_close() frame:Hide() end




--[[

frame:SetDontSavePosition(true)
frame:SetUserPlaced(false)

frame.Bg:Hide()
frame.Bg:SetTexture(nil)

frame.tex = frame:CreateTexture()
frame.tex:SetPoint("CENTER")
frame.tex:SetAtlas('housing-wood-frame-basic-background')

frame:SetScript('OnShow', function()
	scroll_box:SetDataProvider(CreateDataProvider(A.messy_main_func(update)))
end)

]]
