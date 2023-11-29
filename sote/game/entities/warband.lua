---@alias WarbandStatus 'idle' | 'raiding' | 'preparing_raid' | 'preparing_patrol' | 'patrol' | 'attacking'

---@class Warband
---@field name string
---@field treasury number
---@field leader Character?
---@field pops table<POP, POP> A set of pops
---@field units table<POP, UnitType> A table mapping pops to their unit types (as we don't store them on pops)
---@field units_current table<UnitType, number> Units currently in the warband
---@field units_target table<UnitType, number> Units to recruit
---@field status WarbandStatus
---@field total_upkeep number
---@field predicted_upkeep number
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
	morale = 0.5,
	total_upkeep = 0,
	predicted_upkeep = 0
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
		local c = pop.race.male_body_size
		if pop.female then
			c = pop.race.female_body_size
		end
		cap = cap + c + unit.supply_capacity / 4
	end
	if self.leader ~= nil then
		if self.leader.female then
			cap = cap + self.leader.race.female_body_size
		else
			cap = cap + self.leader.race.male_body_size
		end
	end
	return cap
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

	if self.status == 'idle' then
		result = result * 5
	end

	if self.status == 'patrol' then
		result = result * 10
	end

	return result
end

---comment
---@return integer
function warband:size()
    local tabb = require "engine.table"

	local size = tabb.size(self.pops)
	if self.leader ~= nil then
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
	self.units[pop] = unit
	self.pops[pop] = pop
	self.units_current[unit] = (self.units_current[unit] or 0) + 1
	self.total_upkeep = self.total_upkeep + unit.upkeep
end

---Handles pop firing logic on warband's side
---@param pop POP
function warband:fire_unit(pop)
	local unit = self.units[pop]

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
	for u, _ in pairs(self.units) do
		if love.math.random() < ratio then
			u.province:kill_pop(u)
			losses = losses + 1
		end
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

return warband