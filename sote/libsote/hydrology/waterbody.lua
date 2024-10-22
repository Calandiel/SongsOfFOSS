local waterbody = {}

---@enum waterbody_type
waterbody.TYPES = {
	ocean           = 0,
	sea             = 1,
	saltwater_lake  = 2,
	freshwater_lake = 3,
	river           = 4,
	wetland         = 5,
	invalid         = 6
}

function waterbody:new(id)
	local obj = {}

	obj.id = id or 0
	obj.tiles = {}
	obj.type = waterbody.TYPES.invalid
	obj.water_level = 0
	obj.perimeter = {}
	obj.lowest_shore_tile = nil
	obj.lake_open = false
	obj.tmp_float_1 = 0

	setmetatable(obj, self)
	self.__index = self

	return obj
end

function waterbody:kill()
	self.id = 0
	self.tiles = {}
	self.type = waterbody.TYPES.invalid
	self.water_level = 0
	self.perimeter = {}
	self.lowest_shore_tile = nil
	self.lake_open = false
	self.tmp_float_1 = 0
end

---@return number
function waterbody:size()
	return #self.tiles
end

---@param ti number
function waterbody:add_tile(ti)
	table.insert(self.tiles, ti)
end

---@param callback fun(tile_index:number)
function waterbody:for_each_tile(callback)
	for _, ti in ipairs(self.tiles) do
		callback(ti)
	end
end

---@param ti number
function waterbody:add_to_perimeter(ti)
	self.perimeter[ti] = true
end

---@param ti number
function waterbody:remove_from_perimeter(ti)
	self.perimeter[ti] = nil
end

---@param world table
function waterbody:build_perimeter(world)
	self.perimeter = {}

	self:for_each_tile(function(ti)
		world:for_each_neighbor(ti, function(nti)
			if not world.is_land[nti] then return end

			self:add_to_perimeter(nti)
		end)
	end)
end

---@param world table
function waterbody:set_lowest_shore_tile(world)
	self.lowest_shore_tile = nil

	local lowest_elev = 100000;
	for ti, _ in pairs(self.perimeter) do
		local true_elev_for_waterflow = world:true_elevation_for_waterflow(ti) -- perimeter tiles are always land tiles

		if lowest_elev > true_elev_for_waterflow  then
			self.lowest_shore_tile = ti
			lowest_elev = true_elev_for_waterflow
		end
	end
end

---@return boolean
function waterbody:is_valid()
	return self.id > 0
end

return waterbody