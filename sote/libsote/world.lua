local world = {
	world_size = nil,
	seed = nil,
	rng = nil,
	tile_count = 0,
	coord = nil,
	coord_by_tile_id = nil,

	colatitude = nil,
	minus_longitude = nil,
	elevation = nil,
	hilliness = nil,
	rock_type = nil,
	volcanic_activity = nil,
	is_land = nil,
	plate = nil,
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
	obj.tile_count = world_size * world_size * 30 + 2
	obj.coord = {}
	obj.coord_by_tile_id = {}

	obj.colatitude        = ffi.new("float["   .. obj.tile_count .. "]")
	obj.minus_longitude   = ffi.new("float["   .. obj.tile_count .. "]")
	obj.elevation         = ffi.new("float["   .. obj.tile_count .. "]")
	obj.hilliness         = ffi.new("float["   .. obj.tile_count .. "]")
	obj.rock_type         = ffi.new("uint8_t[" .. obj.tile_count .. "]")
	obj.volcanic_activity = ffi.new("int16_t[" .. obj.tile_count .. "]")
	obj.is_land           = ffi.new("bool["    .. obj.tile_count .. "]")
	obj.plate             = ffi.new("uint8_t[" .. obj.tile_count .. "]")

	obj.rocks             = ffi.new("material_template_t[" .. obj.tile_count .. "]")

	return obj
end

function world:is_valid(q, r, log)
	local s = -(q + r)
	-- if log then
	--     print("q", q, "r", r, "s", s, "q - s", q - s, "r - q", r - q, "s - r", s - r)
	-- end
	return q - s <= self.size and r - q <= self.size and s - r <= self.size
end

function world:is_edge(q, r)
	local s = -(q + r)
	return q - s == self.size or r - q == self.size or s - r == self.size
end

function world:is_penta(q, r)
	local s = -(q + r)
	return
		q - s == self.size and s - r == self.size or
		r - q == self.size and s - r == self.size or
		q - s == self.size and r - q == self.size
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
	self:_set_index(q, r, face, -1)
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
	local expected = 3 + 0.5 * (3 * (self.world_size - 1)^2 + 3 * (self.world_size - 1) + 2) + 3 * (self.world_size - 1)
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