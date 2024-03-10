local world = {
    world_size = nil,
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

-- local transform = {
--     -0.86615, 0,       -0.49979, 0,
--     -0.17829, 0.93420,  0.30899, 0,
--      0.46690, 0.35674, -0.80916, 0,
--      0,       0,        0,       1
-- }

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
    obj.coord_by_tile_id = {}

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

function world:is_valid(q, r, log)
    local s = -(q + r)
    -- if log then
    --     print("q", q, "r", r, "s", s, "q - s", q - s, "r - q", r - q, "s - r", s - r)
    -- end
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

local mu = require "game.math-utils"
local cpml = require "cpml"
local vec2 = cpml.vec2
local vec3 = cpml.vec3

local function get_triangle_coords(tri_x, tri_y, world_size)
    local tri_count = world_size * 3

    local x = math.floor(tri_x * tri_count)
    local y = math.floor(tri_y * tri_count)
    local frac_x = tri_x * tri_count - x
    local frac_y = tri_y * tri_count - y

    return vec3(x, y, math.floor(frac_x + frac_y))
end

local function triangle_coords_to_hex_coords(triangle_coords, world_size)
    local tri_x = triangle_coords.x
    local tri_y = triangle_coords.y

    local hex_y = math.floor((tri_y + 1) / 3)

    if (triangle_coords.z == 0) then
        local hex_y_adjusted = world_size - math.floor((tri_y + 2) / 3) - hex_y
        local tri_y_adjusted1 = mu.pos_mod(-tri_y + 1, 3)
        local tri_y_adjusted2 = mu.pos_mod(-tri_y + 2, 3)
        local hex_x = math.floor((tri_x + tri_y_adjusted1) / 3)

        return vec2(hex_y - hex_x, hex_y_adjusted - math.floor((tri_x + tri_y_adjusted2) / 3))
    end

    local hex_y_adjusted = world_size - 1 - hex_y - math.floor(tri_y / 3)
    local tri_y_adjusted1 = mu.pos_mod(-tri_y + 1, 3)
    local tri_y_adjusted2 = mu.pos_mod(-tri_y, 3)
    local hex_x = math.floor((tri_x + tri_y_adjusted1) / 3)

    return vec2(hex_y - hex_x, hex_y_adjusted - math.floor((tri_x + tri_y_adjusted2) / 3))
end

local eps = 1e-12

function world:latlon_to_hex_coords(lat, lon)
    local colatitude = require("game.latlon").lat_to_colat(lat)

    local spherical_coordinates_double = vec3(
        math.sin(colatitude) * math.cos(lon),
        math.cos(colatitude),
        math.sin(colatitude) * math.sin(lon)
    )

    local ico_defines = require("libsote.icosa_defines")
    local faces = ico_defines.face_vertices
    local vertices = ico_defines.vertices

    local closest_distance = 1E+19
    local closest_face_index = -1

    for face_index = 1, 20 do
        local vertex1 = vertices[faces[face_index][1]]
        local vertex2 = vertices[faces[face_index][2]]
        local vertex3 = vertices[faces[face_index][3]]

        local distance_to_face_sq = (vertex1 + vertex2 + vertex3 - spherical_coordinates_double * 3):len2()

        if distance_to_face_sq - eps < closest_distance then
            closest_distance = distance_to_face_sq
            closest_face_index = face_index
        end
    end

    local face = closest_face_index
    local face_vertex1 = vertices[faces[face][1]]
    local face_vertex2 = vertices[faces[face][3]]
    local face_vertex3 = vertices[faces[face][2]]

    local face_normal = vec3.cross(face_vertex1 - face_vertex3, face_vertex2 - face_vertex3)
    local point_on_face = spherical_coordinates_double * vec3.dot(face_normal, face_vertex3) / vec3.dot(face_normal, spherical_coordinates_double)
    local u, v, _ = mu.barycentric_coordinates(point_on_face, face_vertex1, face_vertex2, face_vertex3)
    local hexagonal_coordinates = triangle_coords_to_hex_coords(get_triangle_coords(v, u, self.world_size), self.world_size)

    return hexagonal_coordinates.x, hexagonal_coordinates.y, face
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
    self.coord_by_tile_id[tile_id] = {q, r, face}
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

function world:_investigate_tile(q, r, face)
    local investigate_index = self.coord[self:_key_from_coord(q, r, face)]
    print(q .. " " ..  r .. " " .. face .. " " .. investigate_index)
    if self:is_penta(q, r) then
        print("penta")
    elseif self:is_edge(q, r) then
        print("edge")
    end
    print("elev " .. self.elevation[investigate_index])

    for qc = -self.world_size, self.world_size do
        for rc = -self.world_size, self.world_size do
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