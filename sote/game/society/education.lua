local tabb = require "engine.table"
local ed = {}

---@param realm Realm
function ed.run(realm)
	-- First, calculate endowment needs
	local edu = 0
	-- From pops
	for _, province in pairs(realm.provinces) do
		local pop = tabb.size(province.all_pops)
		for _, tech in pairs(province.technologies_present) do
			---@type number
			edu = edu + tech.research_cost * pop
		end
	end
	realm.budget.education.target = edu

	-- Once we know the needed endowment, handle investments
	local inv = realm.budget.education.to_be_invested
	local spillover = 0
	if inv > edu then
		spillover = inv - edu
	end
	-- If we're overinvested, remove a fraction above the invested amount
	inv = inv - spillover * 0.9

	-- Lastly, invest a fraction of the investment into actual endowment
	local invested = inv * (1 / (12 * 7.5)) -- 7.5 years to invest everything
	realm.budget.education.to_be_invested 		= inv - invested
	realm.budget.education.budget			 	= realm.budget.education.budget + invested

	-- At the very end, apply some decay to present endowment to prevent runaway growth
	local endowment_decay_rate = 1 - 1 / (12 * 50) -- 50 years to decay everything
	if realm.budget.education.budget > edu then
		endowment_decay_rate = 1 - 1 / (12 * 25) -- 25 years to decay the part above the needed amount
	end
	realm.budget.education.budget = realm.budget.education.budget * endowment_decay_rate
end

return ed
