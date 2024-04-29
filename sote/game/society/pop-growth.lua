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
	local cc_used = province:population_weight()
	local min_life_need = 0.125
	local death_rate = 0.003333333 -- 4% per year
	local birth_rate = 0.005833333 -- 7% per year

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

	local starvation_check = min_life_need * 2
	local eligible = tabb.accumulate(tabb.join(tabb.copy(province.all_pops), province.characters), {}, function (a, _, pp)
		local min_life_satisfaction = tabb.accumulate(pp.need_satisfaction, 3, function(b, need, cases)
			if NEEDS[need].life_need then
				b = tabb.accumulate(cases, b, function (c, _, v)
					local ratio = v.consumed / v.demanded
					if ratio < c then
						return ratio
					end
					return c
				end)
			end
			return b
		end)
		-- first remove all pop that reach max age
		if pp.age > pp.race.max_age then
			to_remove[#to_remove + 1] = pp
		-- next check for starvation
		elseif min_life_satisfaction < starvation_check then -- prevent births if not at least 25% food and water
			-- children are more likely to die of starvation 
			local age_adjusted_starvation_check = starvation_check / pp:get_age_multiplier()
			if love.math.random() < (age_adjusted_starvation_check - min_life_satisfaction) / age_adjusted_starvation_check  * death_rate then
				to_remove[#to_remove + 1] = pp
			end
		elseif pp.age >= pp.race.elder_age then
			if love.math.random() < (pp.race.max_age - pp.age) / (pp.race.max_age - pp.race.elder_age) * death_rate then
				to_remove[#to_remove + 1] = pp
			end
		-- finally, pop is eligable to breed if old enough
		elseif pp.age >= pp.race.teen_age then
			a[pp] = min_life_satisfaction
		end
		return a
	end)

	tabb.accumulate(eligible, to_add, function (a, pp, min_life_satisfaction)
		---@type POP
		pp = pp

		-- teens and older adults have reduced chance to conceive
		local base = 1
		if pp.age < pp.race.adult_age then
			base = base * (pp.age - pp.race.teen_age) / (pp.race.adult_age - pp.race.teen_age)
		elseif pp.age >= pp.race.middle_age then
			base = base * (1 - (pp.age - pp.race.middle_age) / (pp.race.elder_age - pp.race.middle_age))
		end

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
		-- TODO figure out beter way to keep character count lower
		-- spawn orphan pop instead of character child if too many nobles to home pop
		if character and pp.province:home_characters()/pp.province:home_population() > 0.3 then -- if twice more than ideal noble percentage
			POP:new(
				pp.race,
				pp.faith,
				pp.culture,
				love.math.random() > pp.race.males_per_hundred_females / (100 + pp.race.males_per_hundred_females),
				pp.race.teen_age, -- otherwise fails at foraging and instantly dies without market surplus
				pp.home_province, province,
				false
			)
		else
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
			-- set newborn to parents satisfaction
			newborn.need_satisfaction = tabb.accumulate(pp.need_satisfaction, newborn.need_satisfaction, function (need_satisfaction, need, cases)
				need_satisfaction[need] = tabb.accumulate(cases, need_satisfaction[need], function (case_satisfaction, case, values)
					case_satisfaction[case].consumed = values.consumed / values.demanded * needs[need][case] * newborn:get_age_multiplier()
					return case_satisfaction
				end)
				return need_satisfaction
			end)
			newborn:get_need_satisfaction()
			-- donate a small amount of funs should it suddenly be left without a parent
			local amount = needs[NEED.FOOD]['calories']
			local donation = math.max(math.min(pp.savings / 12, food_price * amount), 0)
			economic_effects.add_pop_savings(pp, -donation, economic_effects.reasons.Donation)
			economic_effects.add_pop_savings(newborn, donation, economic_effects.reasons.Donation)
			if character then
				newborn.rank = character_ranks.NOBLE
				WORLD:emit_immediate_event('character-child-birth-notification', pp, newborn)
			end
		end
	end

	-- province:validate_population()
end

return pg