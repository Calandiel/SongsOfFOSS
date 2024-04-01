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
	local pop = province:population_weight()
	local starvation_check = 1 / 5

	local death_rate = 1 / 12 / 7
	local birth_rate = 1 / 12 / 4

	-- Mark pops for removal...
	---@type POP[]
	local to_remove = {}
	---@type POP[]
	local to_add = {}

	local eligible = {}
	for _, pp in pairs(province.outlaws) do
		if pp.age > pp.race.max_age then
			to_remove[#to_remove + 1] = pp
		end
	end

	local race_sex = tabb.accumulate(tabb.join(tabb.copy(province.all_pops), province.characters), {}, function (a, _, pp)
		-- update pop life and basic need satisfaction percentages after production-and-consumption tick
		local _, _ = pp:get_need_satisfaction()
		local min_life_satisfaction = tabb.accumulate(pp.need_satisfaction, 1, function(b, need, cases)
			if NEEDS[need].life_need then
				tabb.accumulate(cases, b, function (c, k, v)
					local ratio = v.consumed / v.demanded
					if ratio < c then
						c = ratio
					end
					return c
				end)
			end
			return b
		end)
		if pp.age > pp.race.max_age then
			to_remove[#to_remove + 1] = pp
		elseif min_life_satisfaction < starvation_check or pp.age >= pp.race.elder_age then
			-- Deaths due to starvation or old age!
			-- TODO figure out how player deals with starvation while on campaign
			if pp == WORLD.player_character and pp.unit_of_warband and pp.unit_of_warband.status ~= "idle" then
				-- this is here just to guard against killing the player character on campaign in a warband
			elseif love.math.random() < math.max(death_rate, (starvation_check - min_life_satisfaction) / starvation_check) then
				to_remove[#to_remove + 1] = pp
			end
		elseif pp.age >= pp.race.teen_age then -- check if eligible to create more pop
			if a[pp.race] == nil then
				a[pp.race] = {
					[true] = 0,
					[false] = 0,
				}
			end
			a[pp.race][pp.female] = a[pp.race][pp.female] + 1
			eligible[pp] = pp
		end
		return a
	end)

	tabb.accumulate(eligible, to_add, function (a, _, pp)
		---@type POP
		pp = pp

		-- base on ratio of available breeding age pops
		local sex_prob = math.max(race_sex[pp.race][not pp.female] / race_sex[pp.race][pp.female], 0)

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

		-- Calculate the fraction symbolizing the amount of "overproduction" of food
		local food_satisfaction = tabb.accumulate(pp.need_satisfaction[NEED.FOOD], 1, function (b, k, v)
			local n = v.consumed / v.demanded
			if n < b then
				b = n
			end
			return b
		end)
		-- chance of child depends on pop's ability to secure enough food
		local dependents = tabb.size(tabb.filter(pp.children, function (d)
			return d.age < d.race.teen_age
		end))
		food_satisfaction = math.max(0, food_satisfaction - (starvation_check + dependents * starvation_check / pp.race.fecundity))
		base = base * food_satisfaction

		if love.math.random() < sex_prob * base * birth_rate * pp.race.fecundity then
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
		local amount = 0
		for _, v in pairs(needs[NEED.FOOD]) do
			amount = amount + v
		end
		local donation = math.max(math.min(pp.savings / 24, food_price * amount), 0)
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