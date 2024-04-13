local hu = {}

local mu = require "game.math-utils"
local cpml = require "cpml"
local vec2 = cpml.vec2
local vec3 = cpml.vec3

local eps = 1e-12

---@param tri_x number
---@param tri_y number
---@param world_size number
---@return table
local function get_triangle_coords(tri_x, tri_y, world_size)
	local tri_count = world_size * 3

	local x = math.floor(tri_x * tri_count)
	local y = math.floor(tri_y * tri_count)
	local frac_x = tri_x * tri_count - x
	local frac_y = tri_y * tri_count - y

	return vec3(x, y, math.floor(frac_x + frac_y))
end

---@param triangle_coords table
---@param world_size number
---@return table
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

---@param lat number
---@param lon number
---@param ws number
---@return number, number, number
function hu.latlon_to_hex_coords(lat, lon, ws)
	local colatitude = require("game.latlon").lat_to_colat(-lat) -- using -lat to flip the world vertically, so it matches the love2d y axis orientation

	local spherical_coordinates_double = vec3(
		math.sin(colatitude) * math.cos(lon),
		math.cos(colatitude),
		math.sin(colatitude) * math.sin(lon)
	)

	local ico_defines = require("libsote.icosa-defines")
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
	local hexagonal_coordinates = triangle_coords_to_hex_coords(get_triangle_coords(v, u, ws), ws)

	return hexagonal_coordinates.x, hexagonal_coordinates.y, face
end

return hu