---@alias WarbandStatus 'idle' | 'raiding' | 'preparing_raid'

---@class Warband
local warband = {
    name = "Warband",  ---@type string
    treasury = 0, ---@type number
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


function warband:size()
    local tabb = require "engine.table"
    return tabb.size(self.pops)
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