local tabb = require "engine.table"
local co = {}

---@param realm Realm
function co.run(realm)
	-- First, calculate court needs
	local con = 0
	-- From pops
	for _, province in pairs(realm.provinces) do
		local pop = tabb.size(province.all_pops)
		con = con + 1
	end
	realm.court_wealth_needed = con

	-- Once we know the needed investment, handle investments
	local inv = realm.court_investment
	local spillover = 0
	if inv > con then
		spillover = inv - con
	end
	-- If we're overinvested, remove a fraction above the invested amount
	inv = inv - spillover * 0.85

	-- Lastly, invest a fraction of the investment into actual investment
	local invested = inv * (1 / (12 * 7.5)) -- 7.5 years to invest everything
	realm.court_investment = inv - invested
	realm.court_wealth = realm.court_wealth + invested

	-- At the very end, apply some decay to present investment to prevent runaway growth
	local wealth_decay_rate = 1 - 1 / (12 * 15) -- 15 years to decay everything
	if realm.court_wealth > con then
		wealth_decay_rate = 1 - 1 / (12 * 5) -- 5 years to decay the part above the needed amount
	end
	realm.court_wealth = realm.court_wealth * wealth_decay_rate
end

return co
