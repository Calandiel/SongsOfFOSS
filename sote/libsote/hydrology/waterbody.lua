local waterbody = {}

local waterbody_types = require "libsote.hydrology.waterbody-type".types

function waterbody:new()
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj.tiles = {}
	obj.type = waterbody_types.invalid
	obj.waterlevel = 0

	return obj
end

function waterbody:build_perimeter(world)
end

function waterbody:set_lowest_shore_tile(world)
end

return waterbody