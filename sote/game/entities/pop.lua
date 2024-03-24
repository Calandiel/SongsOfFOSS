local trade_good_use_case = require "game.raws.raws-utils".trade_good_use_case
local tabb = require "engine.table"

---@class POP
---@field race Race
---@field faith Faith
---@field culture Culture
---@field female boolean
---@field age number
---@field name string
---@field savings number
---@field parent POP?
---@field children table<POP, POP>
---@field get_need_satisfaction fun(self:POP):number,number
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
---@field inventory table <TradeGoodReference, number?>
---@field price_memory table<TradeGoodReference, number?>
---@field need_satisfaction table<NEED, table<TradeGoodUseCaseReference,{consumed:number, demanded:number}>>
---@field leading_warband Warband?
---@field recruiter_for_warband Warband?
---@field unit_of_warband Warband?
---@field busy boolean
---@field job Job?
---@field dead boolean
---@field get_age_multiplier fun(self:POP):number
---@field province Province Points to current position of pop/character.
---@field home_province Province Points to home of pop/character.
---@field realm Realm? Represents the home realm of the character
---@field leader_of table<Realm, Realm>
---@field rank CHARACTER_RANK?
---@field former_pop boolean

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

	r.busy = false
	r.owned_buildings = {}
	r.inventory = {}
	r.price_memory = {}
	r.children = {}
	r.successor_of = {}

	local need_satisfaction = race.male_needs
	if female then
		need_satisfaction = race.female_needs
	end
	r.need_satisfaction = tabb.accumulate(need_satisfaction, {}, function (a, need, values)
			local age_dependant = not NEEDS[need].age_independent
			a[need] = tabb.accumulate(values, {}, function (b, use_case, value)
				local demand = value
				if age_dependant then
					demand = demand * self.get_age_multiplier(r)
				end
				b[use_case] = {consumed = demand / 4, demanded = demand}
				return b
			end)
			return a
		end)

	r.basic_needs_satisfaction = 0.25
	r.life_needs_satisfaction = 0.25

	r.savings = 0
	r.popularity = {}
	r.loyalty = nil
	r.loyal	 = {}
	r.traits = {}

	r.leader_of = {}

	r.dead = false
	r.former_pop = false

	setmetatable(r, rtab.POP)

	return r
end

---Checks if pop belongs to characters table of current province
---@return boolean
function rtab.POP:is_character()
	return self.province.characters[self] == self
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
		age_multiplier = 0.1 -- baby
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

---@return number life_need
---@return number basic_need
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

---Returns available units for satisfying a use case from pop inventory
---@param use_case TradeGoodUseCaseReference
---@return number
function rtab.POP:available_use_case_from_inventory(use_case)
	local use = trade_good_use_case(use_case)
	local supply = tabb.accumulate(use.goods, 0, function (a, good, weight)
		local inventory = self.inventory[good]
		if inventory and inventory > 0 then
			a = a + inventory * weight
		end
		return a
	end)
	return supply
end
--- Consumes up to amount of use case from inventory proportially to availability.
--- Returns total amount able to be satisfied.
---@param use_case TradeGoodUseCaseReference
---@param amount number
---@return number consumed
function rtab.POP:consume_use_case_from_inventory(use_case, amount)
	local use = trade_good_use_case(use_case)
	local supply = self:available_use_case_from_inventory(use_case)
	local consumed = tabb.accumulate(use.goods, 0, function (a, good, weight)
		local inventory = self.inventory[good]
		if inventory > 0 then
			local available = inventory * weight
			local satisfied = amount * available / supply
			local used = satisfied / weight
			if satisfied + 0.01 > available
				or used + 0.01 > inventory
			then
				error("CONSUMED TOO MUCH: "
					.. "\n satisfied = "
					.. tostring(satisfied)
					.. "\n available = "
					.. tostring(available)
					.. "\n used = "
					.. tostring(used)
					.. "\n inventory = "
					.. tostring(inventory))
			end
			self.inventory[good] = math.max(0, self.inventory[good] - used)
			a = a + satisfied
		end
		return a
	end)

	if consumed + 0.01 > amount then
		error("CONSUMED TOO MUCH: "
			.. "\n consumed = "
			.. tostring(consumed)
			.. "\n amount = "
			.. tostring(amount))
	end

	return consumed
end

return rtab
