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

local cpml = require "cpml"
local vec2 = cpml.vec2
local vec3 = cpml.vec3
local vec3f = require "libsote.vec3f"
local mu = require "game.math-utils"

-- local transform = mu.table_to_float({
--     -0.86615, 0,       -0.49979, 0,
--     -0.17829, 0.93420,  0.30899, 0,
--      0.46690, 0.35674, -0.80916, 0,
--      0,       0,        0,       1
-- })

local ffi = require("ffi")
-- ffi.cdef[[
-- typedef float vec3[3];
-- typedef float mat4[16];
-- ]]
ffi.cdef[[
    float sinf(float x);
    float cosf(float x);
]]

-- local transform = ffi.new("mat4", {
--     -0.86615, 0,       -0.49979, 0,
--     -0.17829, 0.93420,  0.30899, 0,
--      0.46690, 0.35674, -0.80916, 0,
--      0,       0,        0,       1
-- })

-- local function mult_mat4_vec3(m, v)
--     local v3 = ffi.new("vec3")
--     v3[0], v3[1], v3[2] = v.x, v.y, v.z

--     local result = ffi.new("vec3")
--     for i = 0, 2 do
--         result[i] = m[i] * v3[0] + m[i+4] * v3[1] + m[i+8] * v3[2]
--     end
--     return vec3(result[0], result[1], result[2])
-- end

local function calc_tile_count(size)
    return size * size * 30 + 2
end

-- local ffi = require("ffi")

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

function world:is_valid(q, r, log)
    local s = -(q + r)
    if log then
        print("q", q, "r", r, "s", s, "q - s", q - s, "r - q", r - q, "s - r", s - r)
    end
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

local fmt = "%.17f"

local function num_to_string(n)
    return string.format(fmt, n)
end

local function vec3_to_string(v)
    return "(" .. string.format(fmt, v.x) .. ", " .. string.format(fmt, v.y) .. ", " .. string.format(fmt, v.z) .. ")"
end

local function get_triangle_coords(tri_x, tri_y, world_size)
    -- print("tri " .. num_to_string(tri_x) .. " " .. num_to_string(tri_y));
    local tri_count = world_size * 3
    -- print("tri_count " .. num_to_string(tri_count))
    local x = math.floor(tri_x * tri_count)
    local y = math.floor(tri_y * tri_count)
    -- print(num_to_string(x) .. " " .. num_to_string(y))
    local frac_x = mu.num_to_float(tri_x * tri_count - x)
    local frac_y = mu.num_to_float(tri_y * tri_count - y)
    -- print(num_to_string(frac_x) .. " " .. num_to_string(frac_y))
    -- print(num_to_string(math.floor(frac_x + frac_y)))
    return vec3f.new(x, y, math.floor(frac_x + frac_y))
end

local function triangle_coords_to_hex_coords(triangle_coords, world_size)
    local tri_x = triangle_coords[0]
    local tri_y = triangle_coords[1]
    -- print(num_to_string(tri_x) .. " " .. num_to_string(tri_y) .. " " .. num_to_string(triangle_coords[2]))

    local hex_y = math.floor((tri_y + 1) / 3)
    -- print("hex_y " .. num_to_string(hex_y))

    if (triangle_coords[2] == 0) then
        local hex_y_adjusted = world_size - math.floor((tri_y + 2) / 3) - hex_y
        local tri_y_adjusted1 = mu.pos_mod(-tri_y + 1, 3)
        local tri_y_adjusted2 = mu.pos_mod(-tri_y + 2, 3)
        local hex_x = math.floor((tri_x + tri_y_adjusted1) / 3)
        -- print("1 " .. num_to_string(hex_y - hex_x) .. " " .. num_to_string(hex_y_adjusted - math.floor((tri_x + tri_y_adjusted2) / 3)))
        return vec2(hex_y - hex_x, hex_y_adjusted - math.floor((tri_x + tri_y_adjusted2) / 3))
    end
    local hex_y_adjusted = world_size - 1 - hex_y - math.floor(tri_y / 3)
    local tri_y_adjusted1 = mu.pos_mod(-tri_y + 1, 3)
    local tri_y_adjusted2 = mu.pos_mod(-tri_y, 3)
    local hex_x = math.floor((tri_x + tri_y_adjusted1) / 3)
    -- print("2 " .. num_to_string(hex_y - hex_x) .. " " .. num_to_string(hex_y_adjusted - math.floor((tri_x + tri_y_adjusted2) / 3)))
    return vec2(hex_y - hex_x, hex_y_adjusted - math.floor((tri_x + tri_y_adjusted2) / 3))
end

local epsilon = 1e-12

function world:latlon_to_hex_coords(lat, lon, file)
    -- file:write(lat .. " " ..  lon .. "\n")
    -- print(num_to_string(lat) .. " " .. num_to_string((lon)))
    -- print(num_to_string(mu.num_to_float(lat)) .. " " .. num_to_string(mu.num_to_float((lon))))
    local colatitude = require("game.latlon").lat_to_colat(lat)
    -- print(num_to_string(colatitude))

    local spherical_coordinates_double = vec3(
        math.sin(colatitude) * math.cos(lon),
        math.cos(colatitude),
        math.sin(colatitude) * math.sin(lon)
    )
    local spherical_coordinates = vec3f.new(
        math.sin(colatitude) * math.cos(lon),
        math.cos(colatitude),
        math.sin(colatitude) * math.sin(lon)
    )
    -- print("y " .. vec3f.to_string(spherical_coordinates))
    -- file:write(vec_to_string(spherical_coordinates) .. "\n")

    local ico_defines = require("libsote.icosa_defines")
    local faces = ico_defines.face_vertices
    local vertices = ico_defines.vertices
    -- local transformed_vertices = ico_defines.transformed_vertices

    local closest_distance = 1E+19
    local closest_face_index = -1

    for face_index = 1, 20 do
        -- file:write("face " .. face_index .. "\n")

        -- local vertex1f = icosahedron_vertices[icosahedron_faces[face_index][1]]
        -- local vertex2f = icosahedron_vertices[icosahedron_faces[face_index][2]]
        -- local vertex3f = icosahedron_vertices[icosahedron_faces[face_index][3]]

        -- local vertex1 = mu.mult_mat4_vec3(transform, vertex1f)
        -- local vertex2 = mu.mult_mat4_vec3(transform, vertex2f)
        -- local vertex3 = mu.mult_mat4_vec3(transform, vertex3f)
        -- file:write("\t" .. vec_to_string(vertex1f) .. "\n")
        -- file:write("\t" .. vec_to_string(vertex1) .. "\n")
        -- file:write("\t" .. vec_to_string(vertex2f) .. "\n")
        -- file:write("\t" .. vec_to_string(vertex2) .. "\n")
        -- file:write("\t" .. vec_to_string(vertex3f) .. "\n")
        -- file:write("\t" .. vec_to_string(vertex3) .. "\n")
        -- local dist = vertex1 + vertex2 + vertex3 - mu.vec3_to_float(spherical_coordinates) * 3
        -- file:write("\t" .. vec_to_string(dist) .. "\n")
        -- local mag = dist:len()
        -- file:write("\t" .. mag .. "\n")

        local vertex1 = vertices[faces[face_index][1]]
        local vertex2 = vertices[faces[face_index][2]]
        local vertex3 = vertices[faces[face_index][3]]

        -- local distance_to_face = math.sqrt((vertex1.x + vertex2.x + vertex3.x - 3 * spherical_coordinates.x) ^ 2 + (vertex1.y + vertex2.y + vertex3.y - 3 * spherical_coordinates.y) ^ 2 + (vertex1.z + vertex2.z + vertex3.z - 3 * spherical_coordinates.z) ^ 2)
        local vsum = vec3f.add3(vertex1, vertex2, vertex3)
        local distance_to_face_sq = vec3f.len2(vec3f.sub(vsum, vec3f.scale(spherical_coordinates, 3)))
        -- file:write("\t" .. distance_to_face .. "\n")

        if distance_to_face_sq - epsilon < closest_distance then
            closest_distance = distance_to_face_sq
            closest_face_index = face_index
        end
    end
    -- file:write("index " .. closest_face_index .. "\n")

    local face = closest_face_index
    local face_vertex1 = vertices[faces[face][1]]
    local face_vertex2 = vertices[faces[face][3]]
    local face_vertex3 = vertices[faces[face][2]]

    -- print(num_to_string(face_vertex1[2]) .. " " .. face_vertex3[2])
    local diff_13 = vec3f.sub(face_vertex1, face_vertex3)
    -- print("x.x " .. vec3f.to_string(diff_13))
    local diff_23 = vec3f.sub(face_vertex2, face_vertex3)
    -- print("x.y " .. vec3f.to_string(diff_23))
    -- a[2] * b[0] - a[0] * b[2],
    -- print(num_to_string(diff_13[2]) .. " " .. num_to_string(diff_23[0]) .. " " .. num_to_string(diff_13[0]) .. " " .. num_to_string(diff_23[2]))
    -- print(num_to_string(mu.num_to_float(diff_13[2] * diff_23[0])) .. " " .. num_to_string(mu.num_to_float(diff_13[0] * diff_23[2])))
    local face_normal = vec3f.cross(diff_13, diff_23)
    -- print("x " .. vec3f.to_string(face_normal))
    -- print(num_to_string(face_normal:dot(spherical_coordinates)))
    -- print(num_to_string(face_normal:dot(face_vertex3)))
    -- print(num_to_string(face_normal[0] * spherical_coordinates_double.x) .. " " .. num_to_string(face_normal[1] * spherical_coordinates_double.y) .. " " .. num_to_string(face_normal[2] * spherical_coordinates_double.z))
    -- print(num_to_string(vec3f.dot(face_normal, face_vertex3)) .. " " .. num_to_string(vec3.dot(vec3(face_normal[0], face_normal[1], face_normal[2]), spherical_coordinates_double)))
    -- print(vec3_to_string(spherical_coordinates_double * vec3f.dot(face_normal, face_vertex3)))
    local point_on_face = spherical_coordinates_double * vec3f.dot_double(face_normal, face_vertex3) / vec3.dot(vec3(face_normal[0], face_normal[1], face_normal[2]), spherical_coordinates_double)
    -- print("p " .. vec3f.to_string(vec3f.new(point_on_face.x, point_on_face.y, point_on_face.z)))

    -- local barycentric_coordinate_u = 0.0
    -- local barycentric_coordinate_v = 0.0
    -- local barycentric_coordinate_w = 0.0
    -- MathUtility.Barycentric(point_on_face, face_vertex1, face_vertex2, face_vertex3, barycentric_coordinate_u, barycentric_coordinate_v, barycentric_coordinate_w)
    local u, v, w = mu.barycentric_coordinates(vec3f.new(point_on_face.x, point_on_face.y, point_on_face.z), face_vertex1, face_vertex2, face_vertex3)
    u = mu.num_to_float(u)
    v = mu.num_to_float(v)
    w = mu.num_to_float(w)
    -- print("b " .. num_to_string(u) .. " " .. num_to_string(v) .. " " .. num_to_string(w))

    local triangle_vertex1 = vec2(0.0, 0.0)
    local triangle_vertex2 = vec2(1.0, 0.0)
    local triangle_vertex3 = vec2(0.0, 1.0)

    -- local point_in_triangle = {triangle_vertex1[1] * barycentric_coordinate_u + triangle_vertex2[1] * barycentric_coordinate_v + triangle_vertex3[1] * barycentric_coordinate_w, triangle_vertex1[2] * barycentric_coordinate_u + triangle_vertex2[2] * barycentric_coordinate_v + triangle_vertex3[2] * barycentric_coordinate_w}
    -- point_in_triangle = {point_in_triangle[1], 1.0 - point_in_triangle[1] - point_in_triangle[2]}
    -- local point_in_triangle = triangle_vertex1 * u + triangle_vertex2 * v + triangle_vertex3 * w
    -- point_in_triangle = vec2(point_in_triangle.x, 1.0 - point_in_triangle.x - point_in_triangle.y)
    local triangle_coords = get_triangle_coords(v, mu.num_to_float(1 - v) - w, self.world_size)
    -- print("t " .. vec3f.to_string(triangle_coords))
    local hexagonal_coordinates = triangle_coords_to_hex_coords(triangle_coords, self.world_size)

    -- return Tile.FromInt(self.GetTile(hexagonal_coordinates[1], hexagonal_coordinates[2], face))
    -- local key = self:_key_from_coord(hexagonal_coordinates.x, hexagonal_coordinates.y, face)
    -- if key > calc_tile_count(self.world_size) then
    --     print("key", key, "is out of bounds", calc_tile_count(self.world_size))
    --     print("hexagonal_coordinates", hexagonal_coordinates.x, hexagonal_coordinates.y)
    --     print("face", face)
    --     print("lat", lat, "lon", lon)
    --     return 0, 0, 1
    -- else
    --     print("key", key, "is in bounds", calc_tile_count(self.world_size))
    -- end

    -- file:write(hexagonal_coordinates.x .. " " .. hexagonal_coordinates.y .. " " .. face .. " =============================================\n");
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

    if face == 15 and q == 59 and r == -121
    or face == 17 and q == 121 and r == -59
    then
        print("setting " .. q .. " " .. r .. " " .. face .. ": " .. index .. "; elev " .. data.elevation)
    end

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
    -- local index = self.coord[self:_key_from_coord(q, r, face)]
    -- if index == nil then
    --     -- local is_valid = self:is_valid(q, r, true)
    --     -- print("index is nil for", q, r, face, "is_valid", is_valid)
    --     return 0
    -- end
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
    local index = self.coord[self:_key_from_coord(q, r, face)]
    if index == nil then
        -- print("index is nil for", q, r, face)
        return false
    end
    return self.is_land[self.coord[self:_key_from_coord(q, r, face)]]
end

function world:get_plate(q, r, face)
    return self.plate[self.coord[self:_key_from_coord(q, r, face)]]
end

function world:investigate_tile(q, r, face)
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
    -- if not self:_check_probe_indices(1) then return false end

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

function world:_check_probe_indices(face)

end

return world