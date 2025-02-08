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
	obj.basin = nil
	obj.water_level = 0
	obj.river_slope = 0
	obj.perimeter = {}
	obj.lowest_shore_tile = nil
	obj.lake_open = false
	obj.source = {}
	obj.drain = nil
	obj.tmp_float_1 = 0
	obj.sand_load = 0
	obj.silt_load = 0
	obj.clay_load = 0
	obj.mineral_load = 0
	obj.organic_load = 0

	setmetatable(obj, self)
	self.__index = self

	return obj
end

function waterbody:kill()
	self.id = 0
	self.tiles = {}
	-- self.type = waterbody.TYPES.invalid
	self.basin = nil
	-- self.water_level = 0
	-- self.river_slope = 0
	self.perimeter = {}
	-- self.lowest_shore_tile = nil
	-- self.lake_open = false
	self.source = {}
	self.drain = nil
	-- self.tmp_float_1 = 0
end

---@return number
function waterbody:size()
	return #self.tiles
end

---@param ti number
function waterbody:add_tile(ti)
	table.insert(self.tiles, ti)
end

---@param wb table
function waterbody:add_source(wb)
	table.insert(self.source, wb)
end

-- ---@param callback fun(tile_index:number)
-- function waterbody:for_each_tile(callback)
-- 	for _, ti in ipairs(self.tiles) do
-- 		callback(ti)
-- 	end
-- end

-- ---@param callback fun(tile_index:number)
-- function waterbody:for_each_tile_in_perimeter(callback)
-- 	for ti, _ in pairs(self.perimeter) do
-- 		callback(ti)
-- 	end
-- end

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

	for _, ti in ipairs(self.tiles) do
		for i = 0, world:neighbors_count(ti) - 1 do
			local nti = world.neighbors[ti * 6 + i]
			if world.is_land[nti] then
				self:add_to_perimeter(nti)
			end
		end
	end
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

---@return boolean
function waterbody:is_lake_or_ocean()
	return self.type == waterbody.TYPES.freshwater_lake or self.type == waterbody.TYPES.saltwater_lake or self.type == waterbody.TYPES.ocean
end

function waterbody:is_salty()
	return self.type == waterbody.TYPES.saltwater_lake or self.type == waterbody.TYPES.ocean
end

return waterbody