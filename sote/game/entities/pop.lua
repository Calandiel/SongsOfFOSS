local rtab = {}
rtab.POP = {}

---Creates a new POP
---@param race race_id
---@param faith Faith
---@param culture Culture
---@param female boolean
---@param age number
---@return pop_id
function rtab.POP.new(race, faith, culture, female, age)
	local r = DATA.fatten_pop(DATA.create_pop())

	r.race = race
	r.faith = faith
	r.culture = culture
	r.female = female
	r.age = age

	r.name = culture.language:get_random_name()
	r.busy                     = false

	local total_consumed, total_demanded = 0, 0

	for index = 0, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
		local need = DATA.race_get_male_needs_need(race, index)

		DATA.pop_set_need_satisfaction_demanded(r.id, index, 0)
		DATA.pop_set_need_satisfaction_need(r.id, index, need)
		local required = DATA.race_get_male_needs_required(race, index)
		if female then
			required = DATA.race_get_female_needs_required(race, index)
		end
		DATA.pop_set_need_satisfaction_consumed(r.id, index, 0)
		if DATA.need_get_life_need(need) then
			DATA.pop_set_need_satisfaction_consumed(r.id, index, required * 0.5)
			total_consumed = total_consumed + required * 0.5
		end
		total_demanded = total_demanded + required
	end

	r.forage_ratio = 0.75
	r.work_ratio = 0.25

	r.basic_needs_satisfaction = total_consumed / total_demanded
	r.life_needs_satisfaction = 0.5

	r.savings                  = 0
	r.dead                     = false
	r.former_pop               = false

	for i = 0, 19 do
		DATA.pop_set_dna(r.id, i, love.math.random())
	end

	return r.id
end

---@param pop_id pop_id
function rtab.POP.get_age_multiplier(pop_id)
	local age_multiplier = 1
	local age = DATA.pop_get_age(pop_id)
	local race = DATA.pop_get_race(pop_id)

	local child_age = DATA.race_get_child_age(race)
	local teen_age = DATA.race_get_teen_age(race)
	local adult_age = DATA.race_get_adult_age(race)
	local middle_age = DATA.race_get_middle_age(race)
	local elder_age = DATA.race_get_elder_age(race)
	local max_age = DATA.race_get_max_age(race)

	if age < child_age then
		age_multiplier = 0.25 -- baby
	elseif age < teen_age then
		age_multiplier = 0.5 -- child
	elseif age < adult_age then
		age_multiplier = 0.75 -- teen
	elseif age < middle_age then
		age_multiplier = 1 -- adult
	elseif age < elder_age then
		age_multiplier = 0.95 -- middle age
	elseif age < max_age then
		age_multiplier = 0.9 -- elder
	end
	return age_multiplier
end

--- Recalculate and return satisfaction percentage
---comment
---@param pop_id pop_id
---@return number
---@return number
function rtab.POP.update_satisfaction(pop_id)
	local total_consumed, total_demanded = 0, 0
	local life_consumed, life_demanded = 0, 0
	for i = 0, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
		local use_case = DATA.pop_get_need_satisfaction_use_case(pop_id, i)
		if use_case == 0 then
			break
		end
		local need = DATA.pop_get_need_satisfaction_need(pop_id, i)

		local consumed, demanded = 0, 0
		consumed = consumed + DATA.pop_get_need_satisfaction_consumed(pop_id, i)
		demanded = demanded + DATA.pop_get_need_satisfaction_demanded(pop_id, i)

		if DATA.need_get_life_need(need) then
			life_consumed = life_consumed + consumed
			life_demanded = life_demanded + demanded
		else
			total_consumed = total_consumed + consumed
			total_demanded = total_demanded + demanded
		end
	end
	local life_satisfaction = life_consumed / life_demanded
	local basic_satisfaction = (total_consumed + life_consumed) / (total_demanded + life_demanded)
	DATA.pop_set_life_needs_satisfaction(pop_id, life_satisfaction)
	DATA.pop_set_basic_needs_satisfaction(pop_id, basic_satisfaction)
	return life_satisfaction, basic_satisfaction
end

---Returns age adjusted size of pop
---@param pop pop_id
---@return number size
function rtab.POP.size(pop)
	local race = DATA.pop_get_race(pop)
	local age_multiplier = rtab.POP.get_age_multiplier(pop)
	if DATA.pop_get_female(pop) then
		return DATA.race_get_female_body_size(race) * age_multiplier
	end
	return DATA.race_get_male_body_size(race) * age_multiplier
end

---Returns age adjust racial efficiency
---@param pop pop_id
---@param jobtype JOBTYPE
---@return number
function rtab.POP.job_efficiency(pop, jobtype)
	local female = DATA.pop_get_female(pop)
	local race = DATA.pop_get_race(pop)
	local age_multiplier = rtab.POP.get_age_multiplier(pop)
	if female then
		return DATA.race_get_female_efficiency(race, jobtype) * age_multiplier
	end
	return DATA.race_get_male_efficiency(race, jobtype) * age_multiplier
end

---Returns age adjust demand for a (need, use case) pair
---@param pop pop_id
---@param need NEED
---@param use_case use_case_id
---@return number
function rtab.POP.calculate_need_use_case_satisfaction(pop, need, use_case)
	for i = 0, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
		if DATA.pop_get_need_satisfaction_use_case(pop, i) == 0 then
			break
		end
		if use_case == DATA.pop_get_need_satisfaction_use_case(pop, i) then
			if need == DATA.pop_get_need_satisfaction_need(pop, i) then
				return DATA.pop_get_need_satisfaction_demanded(pop, i)
			end
		end
	end
	return 0
end

---Returns the adjusted health value for the provided pop.
---@param pop pop_id
---@param unit unit_type_id
---@return number attack health modified by pop race and sex
function rtab.POP.get_health(pop, unit)
	return DATA.unit_type_get_base_health(unit) * rtab.POP.size(pop)
end

---Returns the adjusted attack value for the provided pop.
---@param pop pop_id
---@param unit unit_type_id
---@return number pop_adjusted attack modified by pop race and sex
function rtab.POP.get_attack(pop, unit)
	return DATA.unit_type_get_base_attack(unit) * rtab.POP.job_efficiency(pop, JOBTYPE.WARRIOR)
end

---Returns the adjusted armor value for the provided pop.
---@param pop pop_id
---@param unit unit_type_id
---@return number pop_adjusted armor modified by pop race and sex
function rtab.POP.get_armor(pop, unit)
	return DATA.unit_type_get_base_armor(unit)
end

---Returns the adjusted speed value for the provided pop.
---@param pop pop_id
---@param unit unit_type_id
---@return number pop_adjusted speed modified by pop race and sex
function rtab.POP.get_speed(pop, unit)
	if unit then
		return DATA.unit_type_get_speed(unit)
	end
	return 1
end

---Returns the adjusted combat strength values for the provided pop.
---@param pop pop_id
---@param unit unit_type_id
---@return number health
---@return number attack
---@return number armor
---@return number speed
function rtab.POP.get_strength(pop, unit)
	return rtab.POP.get_health(pop, unit), rtab.POP.get_attack(pop, unit), rtab.POP.get_armor(pop, unit), rtab.POP.get_speed(pop, unit)
end

---Returns the adjusted spotting value for the provided pop.
---@param pop pop_id
---@param unit unit_type_id
---@return number pop_adjusted spotting modified by pop race and sex
function rtab.POP.get_spotting(pop, unit)
	local race = DATA.pop_get_race(pop)
	local spotting = DATA.race_get_spotting(race)
	if unit then
		return DATA.unit_type_get_spotting(unit) * spotting
	end
	return spotting
end

---Returns the adjusted visibility value for the provided pop.
---@param pop pop_id
---@param unit unit_type_id
---@return number pop_adjusted visibility modified by pop race and sex
function rtab.POP.get_visibility(pop, unit)
	local race = DATA.pop_get_race(pop)
	local visibility = DATA.race_get_visibility(race)
	local mod = visibility * rtab.POP.size(pop)
	if unit then
		return DATA.unit_type_get_visibility(unit) * mod
	end
	return mod
end

---Returns the adjusted travel day cost value for the provided pop.
---@param pop pop_id
---@param unit unit_type_id
---@return number pop_adjusted food need modified by pop race and sex
function rtab.POP.get_supply_use(pop, unit)
	local pop_food = rtab.POP.calculate_need_use_case_satisfaction(pop, NEED.FOOD, CALORIES_USE_CASE)
	local base = 0
	if unit then
		base = base + DATA.unit_type_get_supply_used(unit)
	end

	return (base + pop_food) / 30
end

---Returns the adjusted hauling capacity value for the provided pop.
---@param pop pop_id
---@param unit unit_type_id
---@return number pop_adjusted hauling modified by pop race and sex
function rtab.POP.get_supply_capacity(pop, unit)
	local race = DATA.pop_get_race(pop)
	local job = DATA.race_get_male_efficiency(race, JOBTYPE.HAULING)
	if DATA.pop_get_female(pop) then
		job = DATA.race_get_female_efficiency(race, JOBTYPE.HAULING)
	end

	local base = 0
	if unit then
		base = base + DATA.unit_type_get_supply_capacity(unit)
	end

	return base + job
end



---Kills a single pop and removes it from all relevant references.
---@param pop pop_id
function rtab.POP.kill_pop(pop)
	-- print("kill " .. pop.name)
	rtab.POP.fire_pop(pop)
	rtab.POP.unregister_military(pop)
	DATA.delete_pop(pop)
end

---Fires an employed pop and adds it to the unemployed pops list.
---It leaves the "job" set so that inference of social class can be performed.
---@param pop pop_id
function rtab.POP.fire_pop(pop)
	local employment = DATA.get_employment_from_worker(pop)
	if employment ~= INVALID_ID then
		DATA.delete_employment(employment)
		local building = DATA.employment_get_building(employment)
		if #DATA.get_employment_from_building(building) == 0 then
			local fat = DATA.fatten_building(building)
			fat.last_income = 0
			fat.last_donation_to_owner = 0
			fat.subsidy_last = 0
		end
	end
end

---adds new trait to character
---@param pop pop_id
---@param trait TRAIT
function rtab.POP.add_trait(pop, trait)
	for i = 0, MAX_TRAIT_INDEX  do
		if DATA.pop_get_traits(pop, i) == TRAIT.INVALID then
			DATA.pop_set_traits(pop, i, trait)
			return
		end
	end
end

---adds new trait to character
---@param pop pop_id
---@param trait TRAIT
function rtab.POP.has_trait(pop, trait)
	for i = 0, MAX_TRAIT_INDEX  do
		if DATA.pop_get_traits(pop, i) == trait then
			return true
		end
	end
	return false
end

return rtab
