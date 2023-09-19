---@alias WarbandStatus 'idle' | 'raiding' | 'preparing_raid' | 'preparing_patrol' | 'patrol'

---@class Warband
---@field name string
---@field treasury number
---@field leader Character?
---@field pops table<POP, Province> A table mapping pops to their home provinces.
---@field units table<POP, UnitType> A table mapping pops to their unit types (as we don't store them on pops)
---@field status WarbandStatus
local warband = {
    name = "Warband",  ---@type string
    treasury = 0, ---@type number
	leader = nil, ---@type Character?
	pops = {}, ---@type table<POP, Province> A table mapping pops to their home provinces.
	units = {}, ---@type table<POP, UnitType> A table mapping pops to their unit types (as we don't store them on pops)
	status = "idle"  ---@type WarbandStatus
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

function warband:spotting()
	local result = 0
	for p, pr in pairs(self.pops) do
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

function warband:size()
    local tabb = require "engine.table"

	local size = tabb.size(self.pops)
	if self.leader ~= nil then
		size = size + 1
	end
    return size
end

function warband:pop_size()
	local tabb = require "engine.table"
	local size = tabb.size(self.pops)
    return size
end

function warband:decimate()
	self.pops = {}
	self.units = {}
end


---Kills ratio of army
---@param ratio number
function warband:kill_off(ratio)
	local losses = 0
	for u in pairs(self.units) do
		if love.math.random() < ratio then
			self.units[u] = nil
			self.pops[u] = nil
			losses = losses + 1
		end
	end
	return losses
end

return warband