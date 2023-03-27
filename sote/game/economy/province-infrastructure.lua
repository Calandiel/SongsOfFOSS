local r = {}

---
---@param province Province
function r.run(province)
	-- First, calculate infrastructure needs
	local inf = 0
	-- From pops
	for _, pop in pairs(province.all_pops) do
		local n = pop.race.male_infrastructure_needs
		if pop.female then
			n = pop.race.female_infrastructure_needs
		end
		inf = inf + n * pop:get_age_multiplier()
	end
	-- From buildings
	for _, building in pairs(province.buildings) do
		inf = inf + building.type.needed_infrastructure
	end
	-- Write the needs
	province.infrastructure_needed = inf

	-- Once we know the needed infrastructure, handle investments
	local inv = province.infrastructure_investment
	local spillover = 0
	if inv > inf then
		spillover = inv - inf
	end
	-- If we're overinvested, remove a fraction above the invested amount
	inv = inv - spillover * 0.9

	-- Lastly, invest a fraction of the investment into actual infrastructure
	local invested = inv * (1 / (12 * 5)) -- 5 years to invest everything
	province.infrastructure_investment = inv - invested
	province.infrastructure = province.infrastructure + invested

	-- At the very end, apply some decay to present infrastructure as to prevent runaway growth
	local infrastructure_decay_rate = 1 - 1 / (12 * 100) -- 100 years to decay everything
	if province.infrastructure > inf then
		infrastructure_decay_rate = 1 - 1 / (12 * 50) -- 50 years to decay the part above the needed amount
	end
	province.infrastructure = province.infrastructure * infrastructure_decay_rate
end

return r
