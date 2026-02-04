-- SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
-- Copyright (c) 2025-2026 Thomas Floeren

local MYNAME, A = ...
local db = A.db

local WTC = WrapTextInColorCode
local tonumber = tonumber
local type = type
local format = format


function A.simulate_event(func, func2)
	local realm = "AzjolNerub-Quel'Thalas"
	local t = {}
	for k, _ in pairs(db[realm].auctions) do
		tinsert(t, k)
	end
	local market_id = t[random(1, #t)]
	local item_id = (db[realm].auctions[market_id].link):match('item:(%d+):')
	local result_code = 0
	local arg2 = item_id
	if func2 then arg2 = result_code end
	func(market_id, arg2)
	if func2 then func2() end
end
