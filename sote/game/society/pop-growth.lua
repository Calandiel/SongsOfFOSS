local pg = {}

local POP = require "game.entities.pop".POP
local tabb = require "engine.table"

---Runs natural growth and decay on a single province.
---@param province Province
function pg.growth(province)
	-- First, get the carrying capacity...
	local cc = province.foragers_limit
	local pop = province:population_weight()

	local death_rate = 1 / 12 / 2
	local birth_rate = 1 / 12 / 2

	-- Mark pops for removal...
	---@type POP[]
	local to_remove = {}
	---@type POP[]
	local to_add = {}

	local race_sex = {}

	for _, pp in pairs(province.outlaws) do
		if pp.age > pp.race.max_age then
			to_remove[#to_remove + 1] = pp
		end
	end
	for _, pp in pairs(province.all_pops) do
		if pp.age > pp.race.max_age then
			to_remove[#to_remove + 1] = pp
		elseif pop > cc and (pp.need_satisfaction[NEED.FOOD] or 0.5) < 0.1 then
			-- Deaths due to starvation!
			if love.math.random() < (1 - cc / pop) * death_rate * pp.race.carrying_capacity_weight then
				to_remove[#to_remove + 1] = pp
			end
		else
			local sex_prob = 0.1

			if not race_sex[pp.race] then
				race_sex[pp.race] = {}
				race_sex[pp.race][pp.female] = true
			elseif race_sex[pp.race][not pp.female] == nil then
				if tabb.size(tabb.filter(province.all_pops, function (a)
					return a.race == pp.race and a.female ~= pp.female
				end)) > 0 then
					race_sex[pp.race][not pp.female] = true
				else race_sex[pp.race][not pp.female] = false end
			end
			if race_sex[pp.race][not pp.female] then sex_prob = 0 end

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
				local base = pp.need_satisfaction[NEED.FOOD] or 0

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
			pp.home_province, province
		)
		newborn.parent = pp
		pp.children[newborn] = newborn
	end

	-- province:validate_population()
end

return pg
