local JOBTYPE = require "game.raws.job_types"

---@alias WarbandStatus "idle" | "raiding" | "preparing_raid" | "preparing_patrol" | "patrol" | "attacking" | "travelling" | "off_duty"
---@alias WarbandIdleStance "work"|"forage"

---@class Warband
---@field name string
---@field treasury number
---@field guard_of Realm?
---@field leader Character?
---@field recruiter Character?
---@field commander Character?
---@field pops table<POP, POP> A set of pops
---@field units table<POP, UnitType> A table mapping pops to their unit types (as we don't store them on pops)
---@field units_current table<UnitType, number> Units currently in the warband
---@field units_target table<UnitType, number> Units to recruit
---@field status WarbandStatus
---@field idle_stance WarbandIdleStance
---@field current_free_time_ratio number How much of "idle" free time they are actually idle. Set by events.
---@field total_upkeep number
---@field predicted_upkeep number
---@field supplies number
---@field supplies_target_days number
---@field morale number
local warband = {
	name = "Warband",  ---@type string
	treasury = 0, ---@type number
	leader = nil, ---@type Character?
	pops = {}, ---@type table<POP, Province> A table mapping pops to their home provinces.
	units = {}, ---@type table<POP, UnitType> A table mapping pops to their unit types (as we don't store them on pops)
	units_current = {},
	units_target = {},
	status = "idle",  ---@type WarbandStatus
	supplies_target_days = 60,
	morale = 0.5,
	current_free_time_ratio = 1.0,
	total_upkeep = 0,
	predicted_upkeep = 0,
	idle_stance = "forage",
}
warband.__index = warband

---@return Warband
function warband:new()
	local o = {}
	for k, v in pairs(self) do
		if type(v) == "table" then
			o[k] = {}
		elseif type(v) == "function" then
			-- nothing to do, we're setting a metatable
		else
			o[k] = v
		end
	end
	setmetatable(o, warband)
	return o
end

---Returns location of province, either the leader's province or the guard realm
---@return Province
function warband:location()
	if self.leader then
		return self.leader.province
	else
		return self.guard_of.capitol
	end
end

---Returns location of province, either the leader's province or the guard realm
---@return Realm
function warband:realm()
	if self.leader then
		return self.leader.realm
	else
		return self.guard_of
	end
end

---Returns the warbands total loot capacity from combatants and noncombatants
---@return number
function warband:get_loot_capacity()
	local cap = 0.01
	for pop, unit in pairs(self.units) do
		local supply = unit:get_supply_capacity(pop)
		cap = cap + supply
	end
	-- noncombatant characters
	if self.recruiter and self.recruiter ~= self.commander
	then
		if self.recruiter.female then
			cap = cap + self.recruiter.race.female_efficiency[JOBTYPE.HAULING]
		else
			cap = cap + self.recruiter.race.male_efficiency[JOBTYPE.HAULING]
		end
	end
	if
		self.leader and self.leader ~= self.commander
			and self.leader ~= self.recruiter
	then
		if self.leader.female then
			cap = cap + self.leader.race.female_efficiency[JOBTYPE.HAULING]
		else
			cap = cap + self.leader.race.male_efficiency[JOBTYPE.HAULING]
		end
	end
	return cap
end


---Returns the warbands total hauling capacity from combatants and noncombatants
function warband:total_hauling()
	return self:get_loot_capacity()
end


---Returns the warbands total spotting bonus from combatants and noncombatants
---@return number
function warband:spotting()
	---@type number
	local result = 0
	for pop, unit in pairs(self.units) do
		local spot = unit:get_spotting(pop)
		result = result + spot
	end
	-- noncombatant characters
	if self.recruiter and self.recruiter ~= self.commander
	then
		result = result + self.recruiter.race.spotting
	end
	if self.leader and self.leader ~= self.commander
		and self.leader ~= self.recruiter
	then
		result = result + self.leader.race.spotting
	end

	if self.status == "idle" then
		result = result * 5
	end

	if self.status == "patrol" then
		result = result * 10
	end

	return result
end

---Total size of warband, combatants only
---@return integer
function warband:size()
	local tabb = require "engine.table"

	local size = tabb.size(self.units)
	return size
end

---Total target size of warband, combatants only
---@return integer
function warband:target_size()
	local tabb = require "engine.table"

	local size = tabb.accumulate(self.units_target, 0, function (a, k, v)
		return a + v
	end)
	-- commander unit only included in target if actually hired
	if self.commander then
		size = size + 1
	end
	return size
end

---Total warband size, combatant and non combatant
---@return integer
function warband:pop_size()
	local tabb = require "engine.table"
	local size = tabb.size(self.pops)
	if self.commander then
		size = size + 1
	end
	if self.recruiter and self.recruiter ~= self.commander then
		size = size + 1
	end
	if self.leader and self.leader ~= self.recruiter and self.leader ~= self.commander then
		size = size + 1
	end
	return size
end

function warband:decimate()
	self.pops = {}
	self.units = {}
	self.commander = nil
end


---Handles hiring logic on warband's side
---@param province Province
---@param pop POP
---@param unit UnitType
function warband:hire_unit(province, pop, unit)
	if pop.province == nil then
		error("ATTEMPT TO HIRE POP WITHOUT PROVINCE")
	end

	self.units[pop] = unit
	self.pops[pop] = pop
	self.units_current[unit] = (self.units_current[unit] or 0) + 1
	self.total_upkeep = self.total_upkeep + unit.upkeep
	pop.unit_of_warband = self
end

---Handles pop firing logic on warband's side
---@param pop POP
function warband:fire_unit(pop)
	-- print(pop.name, "leaves warband")

	local unit = self.units[pop]

	pop.unit_of_warband = nil
	self.units[pop] = nil
	self.pops[pop] = nil
	self.units_current[unit] = (self.units_current[unit] or 0) - 1
	self.total_upkeep = self.total_upkeep - unit.upkeep
end


---Predicts upkeep given the current units target of warbands
---@return number
function warband:predict_upkeep()
	local result = 0

	for unit, target in pairs(self.units_target) do
		result = result + target * unit.upkeep
	end
	if self.commander then
		result = result + self.units[self.commander].upkeep
	end

	return result
end

---Kills ratio of army
---@param ratio number
function warband:kill_off(ratio)
	local losses = 0
	---@type POP[]
	local pops_to_kill = {}

	for pop, _ in pairs(self.units) do
		if not pop:is_character() and love.math.random() < ratio then
			table.insert(pops_to_kill, pop)
			losses = losses + 1
		end
	end

	for i, pop in ipairs(pops_to_kill) do
		pop.province:kill_pop(pop)
	end

	return losses
end

---comment
---@return boolean
function warband:vacant()
	for unit, amount in pairs(self.units_target) do
		if amount > (self.units_current[unit] or 0) then
			return true
		end
	end

	return false
end

---Returns monthly budget
---@return number
function warband:monthly_budget()
	return self.treasury / 12
end

---Returs daily consumption of supplies.
---@return number
function warband:daily_supply_consumption()
	local total = 0
	for pop, unit in pairs(self.units) do
		local supply = unit:get_supply_use(pop)
		total = total + supply
	end
	-- noncombatant characters
	if self.recruiter and self.recruiter ~= self.commander
	then
		local food = self.recruiter.race.male_needs[NEED.FOOD]['food']
		if self.recruiter.female then
			food = self.recruiter.race.female_needs[NEED.FOOD]['food']
		end
		total = total + food / 30
	end
	if self.leader and self.leader ~= self.commander
		and self.leader ~= self.recruiter
	then
		local food = self.leader.race.male_needs[NEED.FOOD]['food']
		if self.leader.female then
			food = self.leader.race.female_needs[NEED.FOOD]['food']
		end
		total = total + food / 30
	end

	return total
end

function warband:supplies_target()
	return self:daily_supply_consumption() * self.supplies_target_days
end

---consumes `days` worth amount of supplies
---@param days number
---@return number
function warband:consume_supplies(days)
	local daily_consumption = self:daily_supply_consumption()
	local consumption = days * daily_consumption
	local consumed = self.leader:consume_use_case_from_inventory('food', consumption)
	if consumed > consumption then
		error("CONSUMED TOO LITTLE: "
			.. "\n consumed = "
			.. tostring(consumed)
			.. "\n consumption = "
			.. tostring(consumption)
			.. "\n daily_consumption = "
			.. tostring(daily_consumption)
			.. "\n days = "
			.. tostring(days))
	end
	return consumed
end

---Returns total food supply from warband
---@return number
function warband:get_supply_available()
	return (self.leader and self.leader:available_use_case_from_inventory('food')) or 0
end

---Returns amount of days warband can travel depending on collected supplies
---@return number
function warband:days_of_travel()
	local supplies = self:get_supply_available()
	local per_day = self:daily_supply_consumption()

	if per_day == 0 then
		return 9999
	end
	return supplies / per_day
end

---Returns average speed of warband, noncombatants included
---@return number total_speed
---@return number mean_speed
function warband:get_speed()
	local tabb = require "engine.table"
	local total_speed = tabb.accumulate(self.units, 0, function (a, k, v)
		return a + v:get_speed(k)
	end)
	if self.recruiter and self.recruiter ~= self.commander then
		total_speed = total_speed + 1
	end
	if self.leader and self.leader ~= self.recruiter and self.leader ~= self.commander then
		total_speed = total_speed + 1
	end
	return total_speed, math.max(0, total_speed / self:pop_size())
end

---Returns speed of exploration
---@return number
function warband:exploration_speed()
	return self:size() * (1 - self.current_free_time_ratio)
end

--- clears commander from office and units table
function warband:unset_commander()
	local commander = self.commander
	if commander then
		commander.unit_of_warband = nil
		self.total_upkeep = self.total_upkeep - self.units[commander].upkeep
		self.units[commander] = nil
		self.commander = nil
	end
end

--- sets a character as commander office and adds unit type to units table
---@param character Character
---@param unit UnitType
function warband:set_commander(character, unit)
	self:unset_commander()
	self.commander = character
	self.units[character] = unit
	self.total_upkeep = self.total_upkeep + self.units[character].upkeep
	character.unit_of_warband = self
end

---Returns the sum of all units health, attack, armor, and speed along with count
---@return number total_health
---@return number total_attack
---@return number total_armor
---@return number total_speed
---@return number total_count
function warband:get_total_strength()
	local total_health, total_attack, total_armor,total_speed, total_count = 0, 0, 0, 0 ,0
	for pop, unit in pairs(self.units) do
		local health, attack, armor, speed = unit:get_strength(pop)
		total_health = total_health + health
		total_attack = total_attack + attack
		total_armor = total_armor + armor
		total_speed = total_speed + speed
		total_count = total_count + 1
	end
	return total_health, total_attack, total_armor, total_speed, total_count
end

---Returns the total warbands visibility weighted by pop unit and character race values.
---@return number visibility
function warband:get_visibility()
	local total_visibility = 0
	for pop, unit in pairs(self.units) do
		total_visibility = total_visibility + unit:get_visibility(pop)
	end
	-- noncombatant characters
	if self.recruiter and self.recruiter ~= self.commander then
		local size = self.recruiter.race.male_body_size
		if self.recruiter.female then
			size = self.recruiter.race.female_body_size
		end
		total_visibility = total_visibility + self.recruiter.race.visibility * size
	end
	if self.leader and self.leader ~= self.commander and self.leader ~= self.recruiter then
		local size = self.leader.race.male_body_size
		if self.leader.female then
			size = self.leader.race.female_body_size
		end
		total_visibility = total_visibility + self.leader.race.visibility * size
	end
	return total_visibility
end

return warband