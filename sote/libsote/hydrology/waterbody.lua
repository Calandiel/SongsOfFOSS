local waterbody = {}

local waterbody_types = require "libsote.hydrology.waterbody-type".types

function waterbody:new()
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj.id = nil
	obj.tiles = {}
	obj.type = waterbody_types.invalid
	obj.waterlevel = 0
	obj.perimeter = {}
	obj.lowest_shore_tile = nil

	return obj
end

---@param callback fun(tile_index:number)
function waterbody:for_each_tile(callback)
	for _, ti in pairs(self.tiles) do
		callback(ti)
	end
end

-- used?!
function waterbody:build_perimeter(world)
	for k, _ in pairs(self.perimeter) do self.perimeter[k] = nil end

	self:for_each_tile(function(ti)
		world:for_each_neighbor(ti, function(nti)
			if not world.is_land[nti] then return end

			self.perimeter[nti] = true
		end)
	end)
end

-- used?!
function waterbody:set_lowest_shore_tile(world)
	self.lowest_shore_tile = nil

	local lowest_elev = 100000;
	for ti, _ in pairs(self.perimeter) do
		local true_elev_for_waterflow = world:true_elevation(ti) -- perimeter tiles are always land tiles

		if true_elev_for_waterflow < lowest_elev then
			self.lowest_shore_tile = ti
			lowest_elev = true_elev_for_waterflow
		end
	end

	-- print(" Lowest shore tile: " .. self.lowest_shore_tile .. " Elev: " .. lowest_elev)
end

return waterbody