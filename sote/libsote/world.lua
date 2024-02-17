local world = {
    world_size = nil,
    coord = nil,

    colatitude = nil,
    minus_longitude = nil,
    elevation = nil,
    hilliness = nil,
    rock_type = nil,
    volcanic_activity = nil,
    is_land = nil,
    plate = nil
}

---@enum rock_types
local rock_types = {
    no_type         = 0,
    acid_platonics  = 3,
    sandstone       = 4,
    siltstone       = 5,
    mudstone        = 7,
    limestone       = 10, -- 0x0000000A
    limestone_reef  = 12, -- 0x0000000C
    basic_volcanics = 22, -- 0x00000016
    basic_platonics = 23, -- 0x00000017
    mixed_volcanics = 24, -- 0x00000018
    mixed_platonics = 25, -- 0x00000019
    acid_volcanics  = 26, -- 0x0000001A
    slate           = 27, -- 0x0000001B
    marble          = 28, -- 0x0000001C
}

local function calc_tile_count(size)
    return size * size * 30 + 2
end

local ffi = require("ffi")

function world:new(world_size)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    obj.world_size = world_size
    obj.coord = {}

    local alloc_size = calc_tile_count(world_size)

    obj.colatitude        = ffi.new("float["   .. alloc_size .. "]")
    obj.minus_longitude   = ffi.new("float["   .. alloc_size .. "]")
    obj.elevation         = ffi.new("float["   .. alloc_size .. "]")
    obj.hilliness         = ffi.new("float["   .. alloc_size .. "]")
    obj.rock_type         = ffi.new("uint8_t[" .. alloc_size .. "]")
    obj.volcanic_activity = ffi.new("int16_t[" .. alloc_size .. "]")
    obj.is_land           = ffi.new("bool["    .. alloc_size .. "]")
    obj.plate             = ffi.new("uint8_t[" .. alloc_size .. "]")

    return obj
end

function world:is_valid(q, r)
    local s = -(q + r)
    return q - s <= self.world_size and r - q <= self.world_size and s - r <= self.world_size
end

function world:is_edge(q, r)
    local s = -(q + r)
    return q - s == self.world_size or r - q == self.world_size or s - r == self.world_size
end

function world:is_penta(q, r)
    local s = -(q + r)
    return q - s == self.world_size and s - r == self.world_size or
           r - q == self.world_size and s - r == self.world_size or
           q - s == self.world_size and r - q == self.world_size
end

local bit = require("bit")

local function hash(a, b, c)
    return bit.bor(bit.lshift(a, 16), bit.lshift(b, 5), c)
end

function world:_key_from_coord(q, r, face)
    return hash(q + self.world_size, r + self.world_size, face)
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
    local max_index = 3 + 0.5 * (3 * (self.world_size - 1)^2 + 3 * (self.world_size - 1) + 2) + 3 * (self.world_size - 1)
    max_index = max_index * 20

    for q = -self.world_size, self.world_size do
        for r = -self.world_size, self.world_size do
            if not self:is_valid(q, r) then goto continue end

            for fi = 1, 20 do
                local index = self.coord[self:_key_from_coord(q, r, fi)]
                if index < 0 or index >= max_index then
                    print("invalid index", self.coord[hash(q + self.world_size, r + self.world_size, fi)], "at", q, r, fi)
                    return false
                end
            end

            ::continue::
        end
    end

    return true
end

return world