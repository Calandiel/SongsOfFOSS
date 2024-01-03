local pg = {}

local POP = require "game.entities.pop".POP

---Runs natural growth and decay on a single province.
---@param province Province
function pg.growth(province)
	-- First, get the carrying capacity...
	local cc = province.foragers_limit
	local pop = province:population_weight()

	local death_rate = 1 / 12 / 12
	local birth_rate = 1 / 12 / 12

	-- local food_good = 'food'
	-- local food_income = province.realm.production[food_good] or 0
	-- local food_sold = province.realm.sold[food_good] or 0
	-- local food_bought = province.realm.bought[food_good] or 0

	local provincial_water = (province.local_production[ 'water' ] or 0) -
		(province.local_consumption[ 'water' ] or 0)

	-- Mark pops for removal...
	---@type POP[]
	local to_remove = {}
	---@type POP[]
	local to_add = {}

	for _, pp in pairs(province.outlaws) do
		if pp.age > pp.race.max_age then
			to_remove[#to_remove + 1] = pp
		end
	end
	for _, pp in pairs(province.all_pops) do
		if pp.age > pp.race.max_age then
			to_remove[#to_remove + 1] = pp
		elseif pop > cc and pp.basic_needs_satisfaction < 0.2 then
			-- Deaths due to starvation!
			if love.math.random() < (1 - cc / pop) * death_rate * pp.race.carrying_capacity_weight then
				to_remove[#to_remove + 1] = pp
			end
		else
			local sex_prob = 0.1
			if pp.female then
				sex_prob = 1.0
			end
			if pp.age > pp.race.adult_age then
				-- if it's a female adult ...
				-- commenting out because it leads to instant explosion of population in low population provinces
				-- if pop < cc then
				-- 	if love.math.random() < (1 - pop / cc) * birth_rate * pp.race.fecundity / pp.race.carrying_capacity_weight then
				-- 		-- yay! spawn a new pop!
				-- 		to_add[#to_add + 1] = pp
				-- 	end
				-- end

				-- This pop growth is caused by overproduction of resources in the realm.
				-- The chance for growth should then depend on the amount of food produced
				-- Make sure that the expected food consumption has been calculated by this point!

				-- Calculate the fraction symbolizing the amount of "overproduction" of food
				local base = pp.life_needs_satisfaction
				-- Clamp the growth
				base = math.min(1, base)

				local fem = 100 / (100 + pp.race.males_per_hundred_females)
				local offspring = fem * pp.race.female_needs[NEED.FOOD] + (1 - fem) * pp.race.male_needs[NEED.FOOD]
				local rate = 1 / offspring

				if love.math.random() < sex_prob * birth_rate * base * rate * pp.race.fecundity then
					-- yay! spawn a new pop!
					to_add[#to_add + 1] = pp
				end
			end
		end
	end

	-- Kill old pops...
	for _, pp in pairs(to_remove) do
		province:kill_pop(pp)
	end
	-- Add new pops...
	for _, pp in pairs(to_add) do
		local newborn = POP:new(
			pp.race,
			pp.faith,
			pp.culture,
			love.math.random() > pp.race.males_per_hundred_females / (100 + pp.race.males_per_hundred_females),
			0,
			province, province
		)
		newborn.parent = pp
	end

	-- province:validate_population()
end

return pg
