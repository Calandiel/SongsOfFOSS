local job_types = require "game.raws.job_types"
---@class (exact) POP
---@field __index POP
---@field race Race
---@field faith Faith
---@field culture Culture
---@field female boolean
---@field age number
---@field name string
---@field savings number
---@field parent POP?
---@field children table<POP, POP>
---@field life_needs_satisfaction number from 0 to 1
---@field basic_needs_satisfaction number from 0 to 1
---@field popularity table<Realm, number|nil>
---@field traits table<Trait, Trait>
---@field employer Building?
---@field loyalty POP?
---@field loyal table<POP, POP> who is loyal to this pop
---@field successor POP?
---@field successor_of table<POP, POP>
---@field owned_buildings table <Building, Building>
---@field has_trade_permits_in table<Realm, Realm>
---@field has_building_permits_in table<Realm, Realm>
---@field inventory table <TradeGoodReference, number?>
---@field price_memory table<TradeGoodReference, number?>
---@field need_satisfaction table<NEED, table<TradeGoodUseCaseReference,{consumed:number, demanded:number}>>
---@field forage_ratio number a number in (0, 1) interval representing a ratio of time pop spends to forage
---@field work_ratio number a number in (0, 1) interval representing a ratio of time workers spend on a job compared to maximal
---@field leading_warband Warband?
---@field recruiter_for_warband Warband?
---@field unit_of_warband Warband?
---@field busy boolean
---@field job Job?
---@field dead boolean
---@field province Province Points to current position of pop/character.
---@field home_province Province Points to home of pop/character.
---@field realm Realm? Represents the home realm of the character
---@field leader_of table<Realm, Realm>
---@field current_negotiations table<Character, Character>
---@field rank CHARACTER_RANK?
---@field former_pop boolean
---@field dna number[]

local rtab = {}

---@class POP
rtab.POP = {}
rtab.POP.__index = rtab.POP
---Creates a new POP
---@param race Race
---@param faith Faith
---@param culture Culture
---@param female boolean
---@param age number
---@param home Province
---@param location Province
---@param character_flag boolean?
---@return POP
function rtab.POP:new(race, faith, culture, female, age, home, location, character_flag)
	local tabb = require "engine.table"
	---@type POP
	local r = {}

	r.race = race
	r.faith = faith
	r.culture = culture
	r.female = female
	r.age = age

	r.name = culture.language:get_random_name()

	home:set_home(r)
	if character_flag then
		location:add_character(r)
	else
		location:add_guest_pop(r)
	end

	r.busy                     = false
	r.owned_buildings          = {}
	r.inventory                = {}
	r.price_memory             = {}
	r.children                 = {}
	r.successor_of             = {}
	r.current_negotiations     = {}

	local need_satisfaction = race.male_needs
	if female then
		need_satisfaction = race.female_needs
	end
	r.need_satisfaction = tabb.accumulate(need_satisfaction, {}, function (a, need, values)
			local age_dependant = not NEEDS[need].age_independent
			a[need] = tabb.accumulate(values, {}, function (b, use_case, value)
				local demand = value
				if age_dependant then
					demand = demand * rtab.POP.get_age_multiplier(r)
				end
				b[use_case] = {consumed = demand, demanded = demand}
				return b
			end)
			return a
		end)
	r.forage_ratio = 0.75
	r.work_ratio = 0.75

	r.basic_needs_satisfaction = 1
	r.life_needs_satisfaction = 1

	r.has_trade_permits_in     = {}
	r.has_building_permits_in  = {}

	r.savings                  = 0
	r.popularity               = {}
	r.loyalty                  = nil
	r.loyal                    = {}
	r.traits                   = {}

	r.leader_of                = {}

	r.dead                     = false
	r.former_pop               = false

	r.dna                      = {}
	for i = 1, 20 do
		table.insert(r.dna, love.math.random())
	end

	setmetatable(r, rtab.POP)

	return r
end

---Checks if pop belongs to characters table of current province
---@return boolean
function rtab.POP:is_character()
	return self.rank ~= nil
end

---Unregisters a pop as a military pop.  \
---The "fire" routine for soldiers. Also used in some other contexts?
function rtab.POP:unregister_military()
	if self.unit_of_warband then
		self.unit_of_warband:fire_unit(self)
	end
end

function rtab.POP:get_age_multiplier()
	local age_multiplier = 1
	if self.age < self.race.child_age then
		age_multiplier = 0.25 -- baby
	elseif self.age < self.race.teen_age then
		age_multiplier = 0.5 -- child
	elseif self.age < self.race.adult_age then
		age_multiplier = 0.75 -- teen
	elseif self.age < self.race.middle_age then
		age_multiplier = 1 -- adult
	elseif self.age < self.race.elder_age then
		age_multiplier = 0.95 -- middle age
	elseif self.age < self.race.max_age then
		age_multiplier = 0.9 -- elder
	end
	return age_multiplier
end

--- Recalculate and return satisfaction percentage
function rtab.POP:get_need_satisfaction()
	local total_consumed, total_demanded = 0, 0
	local life_consumed, life_demanded = 0, 0
	for need, cases in pairs(self.need_satisfaction) do
		local consumed, demanded = 0, 0
		for case, values in pairs(cases) do
			consumed = consumed + values.consumed
			demanded = demanded + values.demanded
		end
		if NEEDS[need].life_need then
			life_consumed = life_consumed + consumed
			life_demanded = life_demanded + demanded
		else
			total_consumed = total_consumed + consumed
			total_demanded = total_demanded + demanded
		end
	end
	self.life_needs_satisfaction = life_consumed / life_demanded
	self.basic_needs_satisfaction = (total_consumed + life_consumed) / (total_demanded + life_demanded)
	return self.life_needs_satisfaction, self.basic_needs_satisfaction
end


---Returns the adjusted health value for the provided pop.
---@param unit UnitType
---@return number attack health modified by pop race and sex
function rtab.POP:get_health(unit)
	local size = self.race.male_body_size
	if self.female then
		size = self.race.female_body_size
	end
	return unit.base_health * size
end

---Returns the adjusted attack value for the provided pop.
---@param unit UnitType
---@return number pop_adjusted attack modified by pop race and sex
function rtab.POP:get_attack(unit)
	local job = self.race.male_efficiency[job_types.WARRIOR]
	if self.female then
		job = self.race.female_efficiency[job_types.WARRIOR]
	end
	return unit.base_attack * job
end

---Returns the adjusted armor value for the provided pop.
---@param unit UnitType
---@return number pop_adjusted armor modified by pop race and sex
function rtab.POP:get_armor(unit)
	return unit.base_armor
end

---Returns the adjusted speed value for the provided pop.
---@param unit UnitType
---@return number pop_adjusted speed modified by pop race and sex
function rtab.POP:get_speed(unit)
	return unit.speed
end

---Returns the adjusted combat strength values for the provided pop.
---@param unit UnitType
---@return number health
---@return number attack
---@return number armor
---@return number speed
function rtab.POP:get_strength(unit)
	return self:get_health(unit), self:get_attack(unit), self:get_armor(unit), self:get_speed(unit)
end

---Returns the adjusted spotting value for the provided pop.
---@param unit UnitType
---@return number pop_adjusted spotting modified by pop race and sex
function rtab.POP:get_spotting(unit)
	return unit.spotting * self.race.spotting
end

---Returns the adjusted visibility value for the provided pop.
---@param unit UnitType
---@return number pop_adjusted visibility modified by pop race and sex
function rtab.POP:get_visibility(unit)
	local size = self.race.male_body_size
	if self.female then
		size = self.race.female_body_size
	end
	return unit.visibility * self.race.visibility * size
end

---Returns the adjusted travel day cost value for the provided pop.
---@param unit UnitType
---@return number pop_adjusted food need modified by pop race and sex
function rtab.POP:get_supply_use(unit)
	local food = self.race.male_needs[NEED.FOOD]['calories']
	if self.female then
		food = self.race.female_needs[NEED.FOOD]['calories']
	end
	return (unit.supply_useds + food) / 30
end

---Returns the adjusted hauling capacity value for the provided pop.
---@param unit UnitType
---@return number pop_adjusted hauling modified by pop race and sex
function rtab.POP:get_supply_capacity(unit)
	local job = self.race.male_efficiency[job_types.HAULING]
	if self.female then
		job = self.race.female_efficiency[job_types.HAULING]
	end
	return unit.supply_capacity / 4 + job
end

return rtab
