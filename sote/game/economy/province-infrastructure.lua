local pop_utils = require "game.entities.pop".POP

local r = {}

---
---@param province province_id
function r.run(province)
	-- First, calculate infrastructure needs
	local inf = 0
	local fat_province = DATA.fatten_province(province)

	-- From pops
	for _, pop_location in pairs(DATA.get_pop_location_from_location(province)) do
		local pop = DATA.pop_location_get_pop(pop_location)

		local race = DATA.fatten_race(DATA.pop_get_race(pop))
		local female = DATA.pop_get_female(pop)

		local n = race.male_infrastructure_needs
		if female then
			n = race.female_infrastructure_needs
		end
		inf = inf + n * pop_utils.get_age_multiplier(pop)
	end

	-- From buildings
	for _, building in pairs(province.buildings) do
		---@type number
		inf = inf + building.type.needed_infrastructure
	end

	-- Write the needs
	fat_province.infrastructure_needed = inf

	-- Once we know the needed infrastructure, handle investments
	local inv = fat_province.infrastructure_investment
	local spillover = 0
	if inv > inf then
		spillover = inv - inf
	end
	-- If we're overinvested, remove a fraction above the invested amount
	inv = inv - spillover * 0.9

	-- Lastly, invest a fraction of the investment into actual infrastructure
	local invested = inv * (1 / (12 * 5)) -- 5 years to invest everything
	fat_province.infrastructure_investment = inv - invested
	fat_province.infrastructure = fat_province.infrastructure + invested

	-- At the very end, apply some decay to present infrastructure as to prevent runaway growth
	local infrastructure_decay_rate = 1 - 1 / (12 * 100) -- 100 years to decay everything
	if fat_province.infrastructure > inf then
		infrastructure_decay_rate = 1 - 1 / (12 * 50) -- 50 years to decay the part above the needed amount
	end
	fat_province.infrastructure = fat_province.infrastructure * infrastructure_decay_rate
end

return r
