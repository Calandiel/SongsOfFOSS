local pg = {}

local POP = require "game.entities.pop".POP
local tabb = require "engine.table"
local character_ranks = require "game.raws.ranks.character_ranks"
local economical = require "game.raws.values.economical"
local economic_effects = require "game.raws.effects.economic"

---Runs natural growth and decay on a single province.
---@param province Province
function pg.growth(province)
	-- First, get the carrying capacity...
	local cc = province.foragers_limit
	local cc_used = province.foragers
	local starvation_check = 1 / 10

	local death_rate = 1 / 12 / 7
	local birth_rate = 1 / 12 / 4

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

	local eligible = tabb.accumulate(tabb.join(tabb.copy(province.all_pops), province.characters), {}, function (a, _, pp)
		local healthcare_satisfaction_total = tabb.accumulate(pp.need_satisfaction[NEED.HEALTHCARE],{consumed = 0, demanded = 0}, function(b, case, values)
			return {consumed = b.consumed + values.consumed , demanded = b.demanded + values.demanded}
		end)
		local healthcare_satisfaction = healthcare_satisfaction_total.consumed / healthcare_satisfaction_total.demanded
		local min_life_satisfaction = tabb.accumulate(pp.need_satisfaction, 1, function(b, need, cases)
			if NEEDS[need].life_need then
				tabb.accumulate(cases, b, function (c, _, v)
					local ratio = v.consumed / v.demanded
					if ratio < c then
						return ratio
					end
					return b
				end)
			end
			return b
		end)
		-- first remove all pop that reach max age
		if pp.age > pp.race.max_age then
			to_remove[#to_remove + 1] = pp
		-- next check for starvation
		elseif min_life_satisfaction / pp:get_age_multiplier() < starvation_check
			and love.math.random() < death_rate * (starvation_check - min_life_satisfaction) / starvation_check then
			to_remove[#to_remove + 1] = pp
		-- TODO REPLACE WITH ACTUAL DISEASE ROLL
		-- next check for capacity, simulated disease culling on pops
		elseif not pp:is_character() and cc_used > cc and love.math.random() < healthcare_satisfaction / (0.5 + healthcare_satisfaction * 0.5) * death_rate then
			to_remove[#to_remove + 1] = pp
		-- next remove elders for old age check
		elseif pp.age >= pp.race.elder_age then
			if love.math.random() < (pp.race.max_age - pp.age) / (pp.race.max_age - pp.race.elder_age) * death_rate then
				to_remove[#to_remove + 1] = pp
			end
		-- finally, pop is eligable to breed if old enough
		elseif pp.age >= pp.race.teen_age then
			a[pp] = pp
		end
		return a
	end)

	tabb.accumulate(eligible, to_add, function (a, _, pp)
		---@type POP
		pp = pp

		-- This pop growth is caused by overproduction of resources in the realm.
		-- The chance for growth should then depend on the amount of food produced
		-- Make sure that the expected food consumption has been calculated by this point!

		-- teens and older adults have reduced chance to conceive
		local base = 1
		if pp.age < pp.race.adult_age then
			base = base * (pp.age - pp.race.teen_age) / (pp.race.adult_age - pp.race.teen_age)
		elseif pp.age >= pp.race.middle_age then
			base = base * (1 - (pp.age - pp.race.middle_age) / (pp.race.elder_age - pp.race.middle_age))
		end

		-- SINCE CHARACTERS DONT FORGET CHILDREN AT TEEN AGE THIS SERVES AS A HARDCAP FOR NOW
		-- chance of having a new child is dependent on current number of children and excess food and water satsifation (over starving)
		local starvation_check = starvation_check / pp:get_age_multiplier()
		local dependents = tabb.size(pp.children)
		local excess_need_per_child = (1 - starvation_check) / pp.race.fecundity

		-- Calculate the fraction symbolizing the amount of "overproduction" of food
		local food_satisfaction = tabb.accumulate(pp.need_satisfaction[NEED.FOOD], 1, function (b, k, v)
			local n = v.consumed / v.demanded
			if n < b then
				b = n
			end
			return b
		end)
		food_satisfaction = math.max(0, food_satisfaction - (starvation_check + dependents * excess_need_per_child))
		
		base = base * food_satisfaction

		-- Calculate mortaility from lack of healthcare, stand in
		local healthcare_satisfaction_total = tabb.accumulate(pp.need_satisfaction[NEED.HEALTHCARE],{consumed = 0, demanded = 0}, function(b, case, values)
			return {consumed = b.consumed + values.consumed , demanded = b.demanded + values.demanded}
		end)
		local healthcare_satisfaction = healthcare_satisfaction_total.consumed / healthcare_satisfaction_total.demanded -- from 0 to 3
		local healthcare_weight = healthcare_satisfaction / (0.5 + healthcare_satisfaction * 0.5) + 0.5 -- from 0.5 to 2
		base = base * healthcare_weight

		-- chance of having a new child is dependent on current number of children and excess food and water satsifation (over starving)
		local dependents = tabb.size(pp.children)
		local excess_need_per_child = 0.8 / pp.race.fecundity

		if love.math.random() < base * birth_rate * pp.race.fecundity then
			-- yay! spawn a new pop!
			a[#to_add + 1] = pp
		end
		return a
	end)

	-- Kill old pops...
	for _, pp in pairs(to_remove) do
		if pp:is_character() then
			WORLD:emit_immediate_event("death", pp, province)
		else
			province:kill_pop(pp)
		end
	end
	-- Add new pops...
	local food_price = economical.get_local_price_of_use(province,'calories')
	for _, pp in pairs(to_add) do
		local character = pp:is_character()
		local newborn = POP:new(
			pp.race,
			pp.faith,
			pp.culture,
			love.math.random() > pp.race.males_per_hundred_females / (100 + pp.race.males_per_hundred_females),
			0,
			pp.home_province, province,
			character
		)
		newborn.parent = pp
		pp.children[newborn] = newborn
		local needs = newborn.race.male_needs
		if newborn.female then
			needs = newborn.race.female_needs
		end
		local amount = needs[NEED.FOOD]['calories']
		local donation = math.max(math.min(pp.savings / 12, food_price * amount), 0)
		economic_effects.add_pop_savings(pp, -donation, economic_effects.reasons.Donation)
		economic_effects.add_pop_savings(newborn, donation, economic_effects.reasons.Donation)
		if character then
			newborn.rank = character_ranks.NOBLE
			WORLD:emit_immediate_event('character-child-birth-notification', pp, newborn)
		end
	end

	-- province:validate_population()
end

return pg