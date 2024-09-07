local pg = {}

local pop_utils = require "game.entities.pop".POP
local province_utils = require "game.entities.province".Province
local tabb = require "engine.table"
local economy_values = require "game.raws.values.economy"
local economic_effects = require "game.raws.effects.economy"
local demography_effects = require "game.raws.effects.demography"


---Runs natural growth and decay on a single province.
---@param province_id Province
function pg.growth(province_id)
	local province = DATA.fatten_province(province_id)

	-- First, get the carrying capacity...
	local cc = province.foragers_limit
	local cc_used = province_utils.population_weight(province_id)
	local min_life_need = 0.125
	local death_rate = 0.003333333 -- 4% per year
	local birth_rate = 0.005833333 -- 7% per year

	-- Mark pops for removal...
	---@type POP[]
	local to_remove = {}
	---@type POP[]
	local to_add = {}

	DATA.for_each_outlaw_location_from_location(province_id, function (item)
		local pop = DATA.outlaw_location_get_outlaw(item)
		local race = DATA.pop_get_race(pop)
		local age = DATA.pop_get_age(pop)
		local max_age = DATA.race_get_max_age(race)
		if age > max_age then
			to_remove[#to_remove + 1] = pop
		end
	end)

	local starvation_check = min_life_need * 2
	---@type pop_id[]
	local pops_and_characters = {}
	DATA.for_each_pop_location(function (item)
		local pop = DATA.pop_location_get_pop(item)
		table.insert(pops_and_characters, pop)
	end)
	DATA.for_each_character_location(function (item)
		local pop = DATA.character_location_get_character(item)
		table.insert(pops_and_characters, pop)
	end)

	---maps pops eligible to breed to their satisfaction
	---@type table<pop_id, number>
	local eligible_to_breed = {}

	for _, pop in ipairs(pops_and_characters) do
		local age_adjusted_starvation_check = starvation_check / pop_utils.get_age_multiplier(pop)
		local min_life_satisfaction = 3
		for index = 0, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
			local use_case = DATA.pop_get_need_satisfaction_use_case(pop, index)
			if use_case == 0 then
				break
			end
			local need = DATA.pop_get_need_satisfaction_need(pop, index)
			local demanded = DATA.pop_get_need_satisfaction_demanded(pop, index)
			local consumed = DATA.pop_get_need_satisfaction_consumed(pop, index)

			local ratio = consumed / demanded
			if min_life_satisfaction > ratio then
				min_life_satisfaction = ratio
			end
		end

		local race = DATA.pop_get_race(pop)
		local age = DATA.pop_get_age(pop)
		local max_age = DATA.race_get_max_age(race)
		local teen_age = DATA.race_get_teen_age(race)
		local elder_age = DATA.race_get_elder_age(race)

		-- first remove all pop that reach max age
		if age > max_age then
			table.insert(to_remove, pop)
		-- next check for starvation
		elseif min_life_satisfaction < age_adjusted_starvation_check then -- prevent births if not at least 25% food and water
			-- children are more likely to die of starvation
			if (age_adjusted_starvation_check - min_life_satisfaction) / age_adjusted_starvation_check * love.math.random() < death_rate then
				table.insert(to_remove, pop)
			end
		elseif age >= elder_age then
			if love.math.random() < (max_age - age) / (max_age - elder_age) * death_rate then
				table.insert(to_remove, pop)
			end
		-- finally, pop is eligable to breed if old enough
		elseif age >= teen_age then
			eligible_to_breed[pop] = min_life_satisfaction
		end
	end

	tabb.accumulate(eligible_to_breed, to_add, function (a, pop, min_life_satisfaction)
		---@type POP
		pop = pop

		local race = DATA.pop_get_race(pop)
		local age = DATA.pop_get_age(pop)
		local middle_age = DATA.race_get_middle_age(race)
		local adult_age = DATA.race_get_adult_age(race)
		local teen_age = DATA.race_get_teen_age(race)
		local elder_age = DATA.race_get_elder_age(race)
		local fecundity = DATA.race_get_fecundity(race)

		-- teens and older adults have reduced chance to conceive
		local base = 1
		if age < adult_age then
			base = base * (age - teen_age) / (adult_age - teen_age)
		elseif age >= middle_age then
			base = base * (1 - (age - middle_age) / (elder_age - middle_age))
		end

		if love.math.random() < base * birth_rate * fecundity then
			-- yay! spawn a new pop!
			table.insert(to_add, pop)
		end
		return a
	end)

	-- Kill old pops...
	for _, pp in pairs(to_remove) do
		if IS_CHARACTER(pp) then
			WORLD:emit_immediate_event("death", pp, province_id)
		else
			demography_effects.kill_pop(pp)
		end
	end

	-- Add new pops...
	local food_price = economy_values.get_local_price_of_use(province_id, CALORIES_USE_CASE)
	for _, pp in pairs(to_add) do
		local character = IS_CHARACTER(pp)

		local race = DATA.pop_get_race(pp)
		local faith = DATA.pop_get_faith(pp)
		local culture = DATA.pop_get_culture(pp)
		local fat_race = DATA.fatten_race(race)

		local parent_province = PROVINCE(pp)
		local parent_home_province = HOME(pp)

		-- TODO figure out beter way to keep character count lower
		-- spawn orphan pop instead of character child if too many nobles to home pop

		local nobles = province_utils.home_characters(province_id)
		local total_pop = province_utils.home_population(province_id)
		local ratio = (nobles + 3) / (total_pop + 3)
		local newborn = INVALID_ID
		if character and ratio > 0.3 then -- if twice more than ideal noble percentage
			newborn = pop_utils.new(
				race,
				faith,
				culture,
				love.math.random() > fat_race.males_per_hundred_females / (100 + fat_race.males_per_hundred_females),
				fat_race.teen_age -- otherwise fails at foraging and instantly dies without market surplus
			)
			province_utils.set_home(parent_home_province, newborn)
			province_utils.add_character(parent_province, newborn)
		else
			character = false
			newborn = pop_utils.new(
				race,
				faith,
				culture,
				love.math.random() > fat_race.males_per_hundred_females / (100 + fat_race.males_per_hundred_females),
				0
			)
			province_utils.set_home(parent_home_province, newborn)
			province_utils.add_pop(parent_province, newborn)
		end

		local parenthood = DATA.create_parent_child_relation()
		local fat_parenthood = DATA.fatten_parent_child_relation(parenthood)
		fat_parenthood.parent = pp
		fat_parenthood.child = newborn

		-- set newborn to parents satisfaction
		for index = 0, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
			local use_case = DATA.pop_get_need_satisfaction_use_case(pp, index)
			if use_case == 0 then
				break
			end
			local demanded = DATA.pop_get_need_satisfaction_demanded(pp, index)
			local consumed = DATA.pop_get_need_satisfaction_consumed(pp, index)
			local satisfaction_ratio = consumed / demanded
			local demanded_by_newborn = DATA.pop_get_need_satisfaction_demanded(newborn, index)

			DATA.pop_set_need_satisfaction_consumed(newborn, index, demanded_by_newborn * satisfaction_ratio)

			-- donate a small amount of funds should it suddenly be left without a parent
			if use_case == CALORIES_USE_CASE then
				local savings = DATA.pop_get_savings(pp)
				local donation = math.max(math.min(savings / 12, food_price * demanded_by_newborn), 0)
				economic_effects.add_pop_savings(pp, -donation, ECONOMY_REASON.DONATION)
				economic_effects.add_pop_savings(newborn, donation, ECONOMY_REASON.DONATION)
			end
		end
		pop_utils.update_satisfaction(newborn)


		if character then
			DATA.pop_set_rank(newborn, CHARACTER_RANK.NOBLE)
			WORLD:emit_immediate_event('character-child-birth-notification', pp, newborn)
		end
	end

	-- province:validate_population()
end

return pg