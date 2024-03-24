local JOBTYPE = require "game.raws.job_types"

---@alias WarbandStatus "idle" | "raiding" | "preparing_raid" | "preparing_patrol" | "patrol" | "attacking" | "travelling" | "off_duty"
---@alias WarbandIdleStance "work"|"forage"

---@class Warband
---@field name string
---@field treasury number
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

---comment
---@return number
function warband:get_loot_capacity()
	local cap = 0.01
	for pop, unit in pairs(self.units) do
		local c = pop.race.male_efficiency[JOBTYPE.HAULING]
		if pop.female then
			c = pop.race.female_efficiency[JOBTYPE.HAULING]
		end
		cap = cap + c + unit.supply_capacity / 4
	end
	if self.leader ~= nil then
		if self.leader.female then
			cap = cap + self.leader.race.female_efficiency[JOBTYPE.HAULING]
		else
			cap = cap + self.leader.race.male_efficiency[JOBTYPE.HAULING]
		end
	end
	return cap
end


function warband:total_hauling()
	return self:get_loot_capacity()
end


---comment
---@return number
function warband:spotting()
	---@type number
	local result = 0
	for p, ut in pairs(self.units) do
		---@type number
		result = result + p.race.spotting
	end

	if self.status == "idle" then
		result = result * 5
	end

	if self.status == "patrol" then
		result = result * 10
	end

	return result
end

---Total size of warband
---@return integer
function warband:size()
	local tabb = require "engine.table"

	local size = tabb.size(self.pops)
	if self.commander ~= nil then
		size = size + 1
	end
	return size
end

---comment
---@return integer
function warband:pop_size()
	local tabb = require "engine.table"
	local size = tabb.size(self.pops)
	return size
end

function warband:decimate()
	self.pops = {}
	self.units = {}
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

	return result
end

---Kills ratio of army
---@param ratio number
function warband:kill_off(ratio)
	local losses = 0
	---@type POP[]
	local pops_to_kill = {}

	for pop, _ in pairs(self.units) do
		if love.math.random() < ratio then
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
	for _, pop in pairs(self.pops) do
		total = total + (pop.need_satisfaction[NEED.FOOD]['food'].demanded or 0)
	end

	if self.leader then
		total = total + (self.leader.need_satisfaction[NEED.FOOD]['food'].demanded or 0)
	end

	if self.recruiter then
		total = total + (self.recruiter.need_satisfaction[NEED.FOOD]['food'].demanded or 0)
	end

	return total * 1 / 30 / 2 --- assuming 1/2 demand used a month, months are 30 days
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

---Returns amount of days warband can travel depending on collected supplies
---@return number
function warband:days_of_travel()
	local supplies = self.leader:available_use_case_from_inventory('food')
	local per_day = self:daily_supply_consumption()

	if per_day == 0 then
		return 9999
	end
	return supplies / per_day
end

---Returns speed of exploration
---@return number
function warband:exploration_speed()
	return self:size() * (1 - self.current_free_time_ratio)
end

return warband