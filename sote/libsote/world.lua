local world = {
}

-- local transform = {
--     -0.86615, 0,       -0.49979, 0,
--     -0.17829, 0.93420,  0.30899, 0,
--      0.46690, 0.35674, -0.80916, 0,
--      0,       0,        0,       1
-- }

local ffi = require("ffi")

ffi.cdef[[
typedef struct {
	char name[256];
	double r, g, b;
} material_template_t
]]

function world:new(world_size, seed)
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj.size = world_size
	obj.seed = seed
	obj.rng = require("libsote.randomness"):new(seed)
	obj.tile_count = obj.size * obj.size * 30 + 2
	obj.coord = {}
	obj.coord_by_tile_id = {}
	obj.climate_cells = {}
	obj.waterbodies = {}

	obj.neighbors         = ffi.new("int32_t["  .. obj.tile_count * 6 .. "]")
	obj.waterbody_by_tile = ffi.new("uint32_t[" .. obj.tile_count .. "]")

	obj.colatitude        = ffi.new("float["    .. obj.tile_count .. "]")
	obj.minus_longitude   = ffi.new("float["    .. obj.tile_count .. "]")
	obj.elevation         = ffi.new("float["    .. obj.tile_count .. "]")
	obj.hilliness         = ffi.new("float["    .. obj.tile_count .. "]")
	obj.rock_type         = ffi.new("uint8_t["  .. obj.tile_count .. "]")
	obj.volcanic_activity = ffi.new("int16_t["  .. obj.tile_count .. "]")
	obj.is_land           = ffi.new("bool["     .. obj.tile_count .. "]")
	obj.plate             = ffi.new("uint8_t["  .. obj.tile_count .. "]")

	obj.rocks             = ffi.new("material_template_t[" .. obj.tile_count .. "]")
	obj.ice               = ffi.new("uint16_t["            .. obj.tile_count .. "]")

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

function world:get_colatitude(q, r, face)
	return self.colatitude[self.coord[self:_key_from_coord(q, r, face)]]
end

function world:get_minus_longitude(q, r, face)
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

function world:get_elevation(q, r, face)
	return self.elevation[self.coord[self:_key_from_coord(q, r, face)]]
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

function world:get_plate(q, r, face)
	return self.plate[self.coord[self:_key_from_coord(q, r, face)]]
end

function world:get_rocks(q, r, face)
	return self.rocks[self.coord[self:_key_from_coord(q, r, face)]]
end

function world:get_climate_data(q, r, face)
	local index = self.coord[self:_key_from_coord(q, r, face)]
	return require "game.climate.utils".get_climate_data(-llu.colat_to_lat(self.colatitude[index]), -self.minus_longitude[index], self.elevation[index])
end

--- Adjusted elevation for waterflow. Includes ice height.
---@param ti number 0-based tile index
function world:true_elevation_for_waterflow(ti)
	if self.elevation[ti] > 0 then
		return self.elevation[ti] + self.ice[ti]
	else
		return self.ice[ti] + self.elevation[ti] * 0.001 -- Subtract some of the ocean depth in order to give variation between some uniform ice tiles sitting on the ocean
	end
end

local wb = require("libsote.hydrology.waterbody")

---@return number new waterbody id
function world:create_new_waterbody()
	local id = #self.waterbodies + 1
	self.waterbodies[id] = wb:new()
	return id
end

---@param index number 0-based index
function world:is_waterbody_valid(index)
	return self.waterbody_by_tile[index] ~= 0
end

---@param callback fun(waterbody:table)
function world:for_each_waterbody(callback)
	for i = 1, #self.waterbodies do
		callback(self.waterbodies[i])
	end
end

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

return world