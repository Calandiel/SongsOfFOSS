local world = {
}

-- local transform = {
--     -0.86615, 0,       -0.49979, 0,
--     -0.17829, 0.93420,  0.30899, 0,
--      0.46690, 0.35674, -0.80916, 0,
--      0,       0,        0,       1
-- }

local ffi = require("ffi")
local ffi_mem_tally = 0

local function allocate_array(name, size, type)
	ffi_mem_tally = ffi_mem_tally + size * ffi.sizeof(type) / 1024 / 1024
	print("[world allocation] " .. name .. " size: " .. string.format("%.2f", size * ffi.sizeof(type) / 1024 / 1024) .. " MB")
	return ffi.new(type .. "[?]", size)
end

function world:new(world_size, seed)
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj.size = world_size
	obj.seed = seed
	obj.rng = require("libsote.randomness"):new(seed)
	obj.tile_count = obj.size * obj.size * 30 + 2
	print("[world allocation] tile count: " .. obj.tile_count)
	obj.coord = {}
	obj.coord_by_tile_id = {}
	obj.climate_cells = {}
	obj.waterbodies = {}

	obj.neighbors             = allocate_array("neighbors",             obj.tile_count * 6, "int32_t")
	obj.waterbody_id_by_tile  = allocate_array("waterbody_id_by_tile",  obj.tile_count,     "uint32_t")
	obj.tiles_by_elevation    = allocate_array("tiles_by_elevation",    obj.tile_count,     "uint32_t")

	obj.colatitude        = allocate_array("colatitude",        obj.tile_count, "float")
	obj.minus_longitude   = allocate_array("minus_longitude",   obj.tile_count, "float")
	obj.elevation         = allocate_array("elevation",         obj.tile_count, "float")
	obj.hilliness         = allocate_array("hilliness",         obj.tile_count, "float")
	obj.rock_type         = allocate_array("rock_type",         obj.tile_count, "uint8_t")
	obj.volcanic_activity = allocate_array("volcanic_activity", obj.tile_count, "int16_t")
	obj.is_land           = allocate_array("is_land",           obj.tile_count, "bool")
	obj.plate             = allocate_array("plate",             obj.tile_count, "uint8_t")

	obj.rock_layer         = allocate_array("rock_layer",         obj.tile_count, "uint16_t")
	obj.jan_rainfall       = allocate_array("jan_rainfall",       obj.tile_count, "float")
	obj.jan_temperature    = allocate_array("jan_temperature",    obj.tile_count, "float")
	obj.jan_humidity	   = allocate_array("jan_humidity",       obj.tile_count, "float")
	obj.jan_water_movement = allocate_array("jan_water_movement", obj.tile_count, "float")
	obj.jul_rainfall       = allocate_array("jul_rainfall",       obj.tile_count, "float")
	obj.jul_temperature    = allocate_array("jul_temperature",    obj.tile_count, "float")
	obj.jul_humidity	   = allocate_array("jul_humidity",       obj.tile_count, "float")
	obj.jul_water_movement = allocate_array("jul_water_movement", obj.tile_count, "float")
	obj.water_movement     = allocate_array("water_movement",     obj.tile_count, "float")
	obj.ice                = allocate_array("ice",                obj.tile_count, "uint16_t")
	obj.snow               = allocate_array("snow",               obj.tile_count, "float")
	obj.sand               = allocate_array("sand",               obj.tile_count, "uint16_t")
	obj.silt               = allocate_array("silt",               obj.tile_count, "uint16_t")
	obj.clay               = allocate_array("clay",               obj.tile_count, "uint16_t")
	obj.soil_organics      = allocate_array("soil_organics",      obj.tile_count, "uint16_t")
	obj.soil_moisture      = allocate_array("soil_moisture",      obj.tile_count, "float")

	obj.tmp_float_1       = allocate_array("tmp_float_1", obj.tile_count, "float")
	obj.tmp_float_2       = allocate_array("tmp_float_2", obj.tile_count, "float")
	obj.tmp_float_3       = allocate_array("tmp_float_3", obj.tile_count, "float")
	obj.tmp_bool_1        = allocate_array("tmp_bool_1",  obj.tile_count, "bool")

	print("[world allocation] ffi mem TOTAL: " .. string.format("%.2f", ffi_mem_tally) .. " MB")

	return obj
end

function world:is_valid(q, r)
	local s = -(q + r)
	return q - s <= self.size and r - q <= self.size and s - r <= self.size
end

function world:is_edge(q, r)
	local s = -(q + r)
	return q - s == self.size or r - q == self.size or s - r == self.size
end

function world:is_subedge(q, r)
	local s = -(q + r)
	return q - s == self.size - 1 or r - q == self.size - 1 or s - r == self.size - 1
end

function world:is_penta(q, r)
	local s = -(q + r)
	return q == self.size or r == self.size or s == self.size;
end

function world:is_subpenta(q, r)
	local s = -(q + r)
	return q == self.size - 1 or r == self.size - 1 or s == self.size - 1;
end

local bit = require("bit")

local function hash(a, b, c)
	return bit.bor(bit.lshift(a, 16), bit.lshift(b, 5), c)
end

function world:_key_from_coord(q, r, face)
	return hash(q + self.size, r + self.size, face)
end

function world:_set_index(q, r, face, index)
	self.coord[self:_key_from_coord(q, r, face)] = index
end

function world:_set_empty(q, r, face)
	self.coord[self:_key_from_coord(q, r, face)] = -1
end

---@param callback fun(tile_index:number, world:table)
function world:for_each_tile(callback)
	for ti = 0, self.tile_count - 1 do
		callback(ti, self)
	end
end

---@param callback fun(tile_index:number, q:number, r:number, face:number, world:table)
function world:for_each_hex(callback)
	for q = -self.size, self.size do
		for r = -self.size, self.size do
			if not self:is_valid(q, r) then goto continue end

			for fi = 1, 20 do
				local index = self.coord[self:_key_from_coord(q, r, fi)]
				callback(index, q, r, fi, self)
			end

			::continue::
		end
	end
end

function world:_init_neighbours()
	for i = 0, self.tile_count * 6 - 1 do
		self.neighbors[i] = -1
	end
end

function world:_set_neighbors(q, r, face, neighbors)
	local index = self.coord[self:_key_from_coord(q, r, face)] * 6

	for i = 1, #neighbors do
		self.neighbors[index + i - 1] = self.coord[self:_key_from_coord(neighbors[i].q, neighbors[i].r, neighbors[i].f)]
	end
end

---@param index number 0-based index
---@param callback fun(neighbor_tile_index:number)
function world:for_each_neighbor(index, callback)
	index = index * 6
	local neighbor_count = self.neighbors[index + 5] == -1 and 5 or 6

	for i = 0, neighbor_count - 1 do
		callback(self.neighbors[index + i])
	end
end

function world:_set_latlon(index, colatitude, minus_longitude)
	self.colatitude[index] = colatitude
	self.minus_longitude[index] = minus_longitude
end

function world:set_tile_data(q, r, face, data)
	local index = self.coord[self:_key_from_coord(q, r, face)]

	self.colatitude[index] = data.latitude
	self.minus_longitude[index] = data.longitude
	self.elevation[index] = data.elevation
	self.hilliness[index] = data.rugosity
	self.rock_type[index] = data.rock_type
	self.volcanic_activity[index] = data.volcanic_activity
	self.is_land[index] = data.is_land
	self.plate[index] = data.plate
end

function world:cache_tile_coord(tile_id, q, r, face)
	self.coord_by_tile_id[tile_id] = { q, r, face }
end

function world:get_tile_coord(tile_id)
	local coord = self.coord_by_tile_id[tile_id]
	return coord[1], coord[2], coord[3]
end

function world:get_raw_colatitude(q, r, face)
	return self.colatitude[self.coord[self:_key_from_coord(q, r, face)]]
end

function world:get_raw_minus_longitude(q, r, face)
	return self.minus_longitude[self.coord[self:_key_from_coord(q, r, face)]]
end

local llu = require("game.latlon")

function world:get_latlon(q, r, face)
	local index = self.coord[self:_key_from_coord(q, r, face)]
	return -llu.colat_to_lat(self.colatitude[index]), -self.minus_longitude[index] -- using -lat to flip the world vertically, so it matches the love2d y axis orientation
end

---@param ti number 0-based tile index
function world:get_latlon_by_tile(ti)
	return -llu.colat_to_lat(self.colatitude[ti]), -self.minus_longitude[ti] -- using -lat to flip the world vertically, so it matches the love2d y axis orientation
end

---@param ti number 0-based tile index
function world:is_in_northern_hemisphere(ti)
	return -llu.colat_to_lat(self.colatitude[ti]) >= 0
end

---@param ti number 0-based tile index
function world:is_in_southern_hemisphere(ti)
	return -llu.colat_to_lat(self.colatitude[ti]) < 0
end

function world:get_elevation(q, r, face)
	return self.elevation[self.coord[self:_key_from_coord(q, r, face)]]
end

function world:get_elevation_by_index(index)
	return self.elevation[index - 1]
end

function world:get_hilliness(q, r, face)
	return self.hilliness[self.coord[self:_key_from_coord(q, r, face)]]
end

function world:get_rock_type(q, r, face)
	return self.rock_type[self.coord[self:_key_from_coord(q, r, face)]]
end

function world:get_volcanic_activity(q, r, face)
	return self.volcanic_activity[self.coord[self:_key_from_coord(q, r, face)]]
end

function world:get_is_land(q, r, face)
	return self.is_land[self.coord[self:_key_from_coord(q, r, face)]]
end

function world:get_is_land_by_index(index)
	return self.is_land[index - 1]
end

function world:get_plate(q, r, face)
	return self.plate[self.coord[self:_key_from_coord(q, r, face)]]
end

function world:get_rock_layer(q, r, face)
	return self.rock_layer[self.coord[self:_key_from_coord(q, r, face)]]
end

function world:get_water_movement(q, r, face)
	return self.water_movement[self.coord[self:_key_from_coord(q, r, face)]]
end

function world:get_jan_water_movement(q, r, face)
	return self.jan_water_movement[self.coord[self:_key_from_coord(q, r, face)]]
end

function world:get_jul_water_movement(q, r, face)
	return self.jul_water_movement[self.coord[self:_key_from_coord(q, r, face)]]
end

---@param ti number 0-based tile index
function world:soil_depth_raw(ti)
	return self.sand[ti] + self.silt[ti] + self.clay[ti]
end

---------------------------------------------------------------------------------------------------

local cu = require "game.climate.utils"

function world:_get_climate_data_by_tile(ti)
	local lat = -llu.colat_to_lat(self.colatitude[ti])
	local lon = -self.minus_longitude[ti]
	local r_jan, t_jan, r_jul, t_jul = cu.get_climate_data(lat, lon, self.elevation[ti])
	local h_jan, h_jul = cu.get_humidity(lat, lon)
	return r_jan, t_jan, r_jul, t_jul, h_jan, h_jul
end

function world:cache_climate_data()
	for ti = 0, self.tile_count - 1 do
		local r_jan, t_jan, r_jul, t_jul, h_jan, h_jul = self:_get_climate_data_by_tile(ti)

		self.jan_rainfall[ti]    = r_jan
		self.jan_temperature[ti] = t_jan
		self.jul_rainfall[ti]    = r_jul
		self.jul_temperature[ti] = t_jul
		self.jan_humidity[ti]    = h_jan
		self.jul_humidity[ti]    = h_jul
	end
end

function world:get_climate_data(q, r, face)
	local index = self.coord[self:_key_from_coord(q, r, face)]
	return self.jan_rainfall[index], self.jan_temperature[index], self.jul_rainfall[index], self.jul_temperature[index]
end

local math_utils = require "game.math-utils"

---@param ti number 0-based tile index
---@param month number 0-based month
function world:get_temperature_for(ti, month)
	return math_utils.lerp(self.jan_temperature[ti], self.jul_temperature[ti], 1 - math.abs(month - 6) / 6);
end

---@param ti number 0-based tile index
---@param month number 0-based month
function world:get_rainfall_for(ti, month)
	local base_val = math_utils.lerp(self.jan_rainfall[ti], self.jul_rainfall[ti], 1 - math.abs(month - 6) / 6);
	return math.max(0, base_val)
end

function world:get_humidity_for(ti, month)
	local base_val = math_utils.lerp(self.jan_humidity[ti], self.jul_humidity[ti], 1 - math.abs(month - 6) / 6);
	return math.max(0, base_val)
end

---@param ti number 0-based tile index
function world:get_climate_cell_by_tile(ti)
	return self.climate_cells[ti + 1]
end

---------------------------------------------------------------------------------------------------

-- We want to determine whether we are measuring waterlevel or elevation. Then we add ice on top of that if there is ice.
---@param ti number 0-based tile index
function world:true_elevation(ti)
	if self.is_land[ti] then -- If land, consider elevation and ice
		if self.elevation[ti] > 0 then
			return self.elevation[ti] + self.ice[ti]
		else
			return self.elevation[ti] * 0.001 + self.ice[ti] -- Subtract some of the ocean depth in order to give variation between some uniform ice tiles sitting on the ocean
		end
	end

	-- If lake or ocean, consider water level of the lake + ice

	if self:is_tile_waterbody_valid(ti) then
		return self.waterbodies[self.waterbody_id_by_tile[ti]].waterlevel + self.ice[ti] + 0.0001
	else
		return 0
	end
end

function world:create_elevation_list()
	self.tiles_by_elevation = require("libsote.heap-sort").heap_sort_indices(function(i) return self:true_elevation(i) end, self.tile_count, true)
end

---@param callback fun(tile_index:number, world:table)
function world:for_each_tile_by_elevation(callback)
	for ti = 0, self.tile_count - 1 do
		callback(self.tiles_by_elevation[ti], self)
	end
end

---------------------------------------------------------------------------------------------------

local wb = require("libsote.hydrology.waterbody")

---@return number new waterbody id
function world:create_new_waterbody()
	local id = #self.waterbodies + 1
	self.waterbodies[id] = wb:new()
	return id
end

function world:get_waterbody(q, r, face)
	return self.waterbodies[self.waterbody_id_by_tile[self.coord[self:_key_from_coord(q, r, face)]]]
end

---@param ti number 0-based index
function world:get_waterbody_by_tile(ti)
	return self.waterbodies[self.waterbody_id_by_tile[ti]]
end

---@param ti number 0-based index
function world:is_tile_waterbody_valid(ti)
	if self.waterbody_id_by_tile[ti] == 0 then return false end
	return self.waterbodies[self.waterbody_id_by_tile[ti]]:is_valid()
end

---@param callback fun(waterbody:table)
function world:for_each_waterbody(callback)
	for i = 1, #self.waterbodies do
		callback(self.waterbodies[i])
	end
end

---------------------------------------------------------------------------------------------------

function world:_investigate_tile(q, r, face)
	local investigate_index = self.coord[self:_key_from_coord(q, r, face)]
	print(q .. " " .. r .. " " .. face .. " " .. investigate_index)
	if self:is_penta(q, r) then
		print("penta")
	elseif self:is_edge(q, r) then
		print("edge")
	end
	print("elev " .. self.elevation[investigate_index])

	for qc = -self.size, self.size do
		for rc = -self.size, self.size do
			if not self:is_valid(qc, rc) then goto continue end

			for fi = 1, 20 do
				local index = self.coord[self:_key_from_coord(qc, rc, fi)]
				if index == investigate_index then
					print("found " .. qc .. " " .. rc .. " " .. fi)
				end
			end

			::continue::
		end
	end

	print("-------------------------------------------------")
end

function world:check()
	if not self:_check_collisions() then return false end
	if not self:_check_valid_indices() then return false end

	return true
end

function world:_check_collisions()
	local expected = 3 + 0.5 * (3 * (self.size - 1)^2 + 3 * (self.size - 1) + 2) + 3 * (self.size - 1)
	expected = expected * 20

	local count = 0
	for _ in pairs(self.coord) do
		count = count + 1
	end
	if count ~= expected then
		print("hash function is not good enough, got collisions; expected", expected, "got", count)
		return false
	end

	return true
end

function world:_check_valid_indices()
	local max_index = self.tile_count - 1

	for q = -self.size, self.size do
		for r = -self.size, self.size do
			if not self:is_valid(q, r) then goto continue end

			for fi = 1, 20 do
				local index = self.coord[self:_key_from_coord(q, r, fi)]
				if index < 0 or index > max_index then
					print("invalid index", self.coord[hash(q + self.size, r + self.size, fi)], "at", q, r, fi)
					return false
				end
			end

			::continue::
		end
	end

	return true
end

-- Careful here, not all arrays are of tile_count size (e.g. neighbors)
function world:fill_ffi_array(array, val)
	for i = 0, self.tile_count - 1 do
		array[i] = val
	end
end

return world