local tabb = require "engine.table"
local co = {}

---@param realm Realm
function co.run(realm)
	-- First, calculate court needs
	local con = 0

	-- From characters
	for _, province in pairs(realm.provinces) do
		local nobles = tabb.size(province.characters)

		---@type number
		con = con + nobles / 5
	end
	realm.budget.court.target = con


	-- Once we know the needed investment, handle investments
	local inv = realm.budget.court.to_be_invested
	local spillover = 0
	if inv > con then
		spillover = inv - con
	end
	-- If we're overinvested, remove a fraction above the invested amount
	inv = inv - spillover * 0.85

	-- Lastly, invest a fraction of the investment into actual investment
	local invested = inv * (1 / (12 * 7.5)) -- 7.5 years to invest everything
	realm.budget.court.to_be_invested 	= inv - invested
	realm.budget.court.budget 			= realm.budget.court.budget + invested

	-- At the very end, apply some decay to present investment to prevent runaway growth
	local wealth_decay_rate = 1 - 1 / (12 * 15) -- 15 years to decay everything
	if realm.budget.court.budget > con then
		wealth_decay_rate = 1 - 1 / (12 * 5) -- 5 years to decay the part above the needed amount
	end
	realm.budget.court.budget = realm.budget.court.budget * wealth_decay_rate
end

return co
