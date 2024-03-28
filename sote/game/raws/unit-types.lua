local job_types = require "game.raws.job_types"
---@class UnitType
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field new fun(self:UnitType, o:UnitType):UnitType
---@field base_price number
---@field upkeep number
---@field supply_useds number how much food does this unit consume each month
---@field trade_good_requirements table<TradeGood, number>
---@field base_health number
---@field base_attack number
---@field base_armor number
---@field speed number
---@field foraging number how much food does this unit forage from the local province?
---@field bonuses table<UnitType, number>
---@field supply_capacity number how much food can this unit carry
---@field unlocked_by Technology|nil
---@field spotting number
---@field visibility number

---@class UnitType
local UnitType = {}
UnitType.__index = UnitType
---Creates a new unit type
---@param o UnitType
---@return UnitType
function UnitType:new(o)
	print("Unit Type: " .. tostring(o.name))
	---@type UnitType
	local r = {}

	r.name = "<unit type>"
	r.icon = 'uncertainty.png'
	r.description = "<unit type description>"
	r.r = 0
	r.g = 0
	r.b = 0
	r.base_price = 10
	r.upkeep = 0.5
	r.supply_useds = 1
	r.trade_good_requirements = {}
	r.base_health = 50
	r.base_attack = 5
	r.base_armor = 1
	r.speed = 1
	r.foraging = 0.1
	r.bonuses = {}
	r.supply_capacity = 5
	r.unlocked_by = nil
	r.spotting = 1
	r.visibility = 1


	for k, v in pairs(o) do
		r[k] = v
	end
	setmetatable(r, UnitType)
	if RAWS_MANAGER.unit_types_by_name[r.name] ~= nil then
		local msg = "Failed to load a unit type (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end
	RAWS_MANAGER.unit_types_by_name[r.name] = r
	return o
end

---Returns the adjusted health value for the provided pop.
---@param pop POP
---@return number attack health modified by pop race and sex
function UnitType:get_health(pop)
	local size = pop.race.male_body_size
	if pop.female then
		size = pop.race.female_body_size
	end
	return self.base_health * size
end

---Returns the adjusted attack value for the provided pop.
---@param pop POP
---@return number pop_adjusted attack modified by pop race and sex
function UnitType:get_attack(pop)
	local job = pop.race.male_efficiency[job_types.WARRIOR]
	if pop.female then
		job = pop.race.female_efficiency[job_types.WARRIOR]
	end
	return self.base_attack * job
end

---Returns the adjusted armor value for the provided pop.
---@param pop POP
---@return number pop_adjusted armor modified by pop race and sex
function UnitType:get_armor(pop)
	return self.base_armor
end

---Returns the adjusted speed value for the provided pop.
---@param pop POP
---@return number pop_adjusted speed modified by pop race and sex
function UnitType:get_speed(pop)
	return self.speed
end

---Returns the adjusted combat strength values for the provided pop.
---@param pop POP
---@return number health
---@return number attack
---@return number armor
---@return number speed
function UnitType:get_strength(pop)
	 local health = self:get_health(pop)
	 local attack = self:get_attack(pop)
	 local armor = self:get_armor(pop)
	 local speed = self:get_speed(pop)
	return health, attack, armor, speed
end

---Returns the adjusted spotting value for the provided pop.
---@param pop POP
---@return number pop_adjusted spotting modified by pop race and sex
function UnitType:get_spotting(pop)
	return self.spotting * pop.race.spotting
end

---Returns the adjusted visibility value for the provided pop.
---@param pop POP
---@return number pop_adjusted visibility modified by pop race and sex
function UnitType:get_visibility(pop)
	local size = pop.race.male_body_size
	if pop.female then
		size = pop.race.female_body_size
	end
	return self.visibility * pop.race.visibility * size
end

---Returns the adjusted travel day cost value for the provided pop.
---@param pop POP
---@return number pop_adjusted food need modified by pop race and sex
function UnitType:get_supply_use(pop)
	local food = pop.race.male_needs[NEED.FOOD]['food']
	if pop.female then
		food = pop.race.female_needs[NEED.FOOD]['food']
	end
	return (self.supply_useds + food) / 30
end

---Returns the adjusted hauling capacity value for the provided pop.
---@param pop POP
---@return number pop_adjusted hauling modified by pop race and sex
function UnitType:get_supply_capacity(pop)
	local job = pop.race.male_efficiency[job_types.HAULING]
	if pop.female then
		job = pop.race.female_efficiency[job_types.HAULING]
	end
	return self.supply_capacity / 4 + job
end

---Returns the adjusted foraging value for the provided pop.
---@param pop POP
---@return number pop_adjusted foraging modified by pop race and sex
function UnitType:get_foraging(pop)
	local job = pop.race.male_efficiency[job_types.FORAGER]
	if pop.female then
		job = pop.race.female_efficiency[job_types.FORAGER]
	end
	return self.foraging * job
end

return UnitType
