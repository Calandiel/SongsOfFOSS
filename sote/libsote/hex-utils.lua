local hu = {}

local mu = require "game.math-utils"
local cpml = require "cpml"
local vec2 = cpml.vec2
local vec3 = cpml.vec3

local eps = 1e-12

---@param tri_x number
---@param tri_y number
---@param ws number
---@return number, number, number
local function get_triangle_coords(tri_x, tri_y, ws)
	local tri_count = ws * 3

	local x = math.floor(tri_x * tri_count)
	local y = math.floor(tri_y * tri_count)
	local frac_x = tri_x * tri_count - x
	local frac_y = tri_y * tri_count - y

	return x, y, math.floor(frac_x + frac_y)
end

---@param tri_x number
---@param tri_y number
---@param tri_up number up or down triangle
---@param ws number
---@return number, number
local function triangle_coords_to_hex_coords(tri_x, tri_y, tri_up, ws)
	-- if pointing up
	if (tri_up == 0) then
		local offset_main_x = 0 + math.floor((tri_y + 1) / 3) -- Starting index
		local offset_main_y = ws - math.floor((tri_y + 2) / 3) - math.floor((tri_y + 1) / 3)

		local offset_loop_x = mu.pos_mod(-tri_y + 1, 3) -- Offset of the sequence
		local offset_loop_y = mu.pos_mod(-tri_y + 2, 3) -- Offset of the sequence

		return offset_main_x - math.floor((tri_x + offset_loop_x) / 3), offset_main_y - math.floor((tri_x + offset_loop_y) / 3)
	end

	-- if pointing down
	local offset_main_x = 0 + math.floor((tri_y + 1) / 3)
	local offset_main_y = ws - 1 - math.floor((tri_y + 1) / 3) - math.floor(tri_y / 3)

	local offset_loop_x = mu.pos_mod(-tri_y + 1, 3)
	local offset_loop_y = mu.pos_mod(-tri_y, 3)

	return offset_main_x - math.floor((tri_x + offset_loop_x) / 3), offset_main_y - math.floor((tri_x + offset_loop_y) / 3)
end

local latlon = require "game.latlon"
local ico_defines = require "libsote.icosa-defines"

function hu.latlon_to_hex_coords(lat, lon, ws)
	local colat = latlon.lat_to_colat(-lat) -- using -lat to flip the world vertically, so it matches the love2d y axis orientation
	colat = math.pi - colat

	lon = lon + math.pi -- move from [-pi, pi] to [0, 2pi]

	local cart = vec3(
		math.sin(colat) * math.cos(lon),
		math.cos(colat),
		math.sin(colat) * math.sin(lon)
	)

	local min_dist = 10000000000000000000.0
	local id = -1

	local verts = ico_defines.vertices
	local faces = ico_defines.face_vertices

	for fi = 1, 20 do
		local v = ico_defines.centers[fi]
		local dist = vec3.dot(v, cart)
		if dist < min_dist then
			min_dist = dist
			id = fi
		end
	end

	local face = id

	local p1 = verts[faces[face][1]]
	local v1 = vec2(0, 0)

	local p2 = verts[faces[face][3]]
	local v2 = vec2(1, 0)

	local p3 = verts[faces[face][2]]
	local v3 = vec2(0, 1)

	local pp1 = p1 - p3
	local pp2 = p2 - p3
	local norm = vec3.cross(pp1, pp2)

	cart = cart * vec3.dot(norm, p3) / vec3.dot(norm, cart)

	local weight1, weight2, weight3 = mu.barycentric_coordinates(cart, p1, p2, p3)
	local result = v1 * weight1 + v2 * weight2 + v3 * weight3
	result.y = 1 - result.x - result.y

	local tri_x, tri_y, tri_up = get_triangle_coords(result.x, result.y, ws)
	local q, r = triangle_coords_to_hex_coords(tri_x, tri_y, tri_up, ws)

	return q, r, face
end

---@param x number
---@param y number
---@param z number
---@param f number
---@param ws number
---@return number, number
local function get_base_latlon(x, y, z, f, ws)
	local distcc = 0.7297276562
	local ssigma = 0.6070619982
	local eps = 0.000000001

	local c = math.sqrt(x * x + y * y + x * y)
	local beta, rho, lat, lon

	if f == 0 or f == 9 or f == 11 or f == 13 or f == 15 then
		beta = math.acos((c * c + y * y - z * z) / (2 * y * c))
		if z > 0 then
			beta = -beta
		end
		if y == 0 then
			if z < 0 then
				beta = 2 * math.pi / 3
			else
				beta = -math.pi / 3
			end
		end
	elseif f == 1 or f == 3 or f == 4 or f == 6 or f == 14 or f == 16 or f == 17 then
		beta = math.acos((c * c + x * x - y * y) / (2 * x * c))
		if y > 0 then
			beta = -beta
		end
		if x == 0 then
			if y < 0 then
				beta = 2 * math.pi / 3
			else
				beta = -math.pi / 3
			end
		end
	elseif f == 2 or f == 5 or f == 7 or f == 8 or f == 10 or f == 12 or f == 18 or f == 19 then
		beta = math.acos((c * c + z * z - x * x) / (2 * z * c))
		if x > 0 then
			beta = -beta
		end
		if z == 0 then
			if x < 0 then
				beta = 2 * math.pi / 3
			else
				beta = -math.pi / 3
			end
		end
	else
		error("latlong: face out of range.")
	end

	local r = ws / ssigma
	local h = math.sqrt(r * r - ws * ws)
	rho = math.atan(c / h)

	local nrho = math.acos(math.cos(distcc) * math.cos(rho) + math.sin(distcc) * math.sin(rho) * math.cos(beta))
	local nbeta = math.acos((math.cos(rho) - math.cos(distcc) * math.cos(nrho)) / (math.sin(distcc) * math.sin(nrho)))
	if beta < eps and beta > -eps then
		nbeta = 0
	end
	if beta - math.pi > -eps then
		nbeta = 0
	end
	if beta + math.pi < eps then
		nbeta = 0
	end
	if beta > 0 then
		nbeta = -nbeta
	end

	if f == 2 or f == 3 or f == 7 or f == 9 or f == 13 or f == 17 then
		nbeta = nbeta - 2 * math.pi / 3
		if nbeta < -math.pi then
			nbeta = nbeta + 2 * math.pi
		end
		rho = nrho
		beta = nbeta
	elseif f == 10 or f == 11 or f == 14 or f == 15 or f == 18 or f == 19 then
		nbeta = nbeta + 2 * math.pi / 3
		if nbeta > math.pi then
			nbeta = nbeta - 2 * math.pi
		end
		rho = nrho
		beta = nbeta
	end

	local sign = 1
	local latc = distcc
	if f == 0 then
		lat = rho
	elseif f == 4 then
		lat = math.pi - rho
	elseif f == 3 or f == 5 or f == 6 or f == 9 or f == 11 or f == 14 or f == 15 or f == 16 or f == 17 then
		sign = -1
		latc = math.pi - distcc
		lat = math.acos(math.cos(latc) * math.cos(rho) + sign * math.sin(latc) * math.sin(rho) * math.cos(beta))
	else
		lat = math.acos(math.cos(latc) * math.cos(rho) + sign * math.sin(latc) * math.sin(rho) * math.cos(beta))
	end

	lon = math.acos((math.cos(rho) - math.cos(latc) * math.cos(lat)) / (math.sin(latc) * math.sin(lat)))
	if beta < eps and beta > -eps then
		lon = 0
	end
	if beta - math.pi > -eps then
		lon = 0
	end
	if beta + math.pi < eps then
		lon = 0
	end
	if beta > 0 then
		lon = -lon
	end

	if f == 4 then
		beta = -beta + math.pi
		if beta > math.pi then
			beta = beta - 2 * math.pi
		end
		lon = beta
	elseif f == 0 then
		lon = beta
	elseif f == 7 or f == 8 or f == 10 then
		lon = lon + 2 * math.pi / 3
	elseif f == 12 or f == 13 or f == 18 then
		lon = lon - 2 * math.pi / 3
	elseif f == 3 or f == 5 or f == 11 then
		lon = -lon
		lon = lon + math.pi / 3
		if rho < eps then
			lon = math.pi / 3
		end
	elseif f == 14 or f == 16 or f == 17 then
		lon = -lon
		lon = lon - math.pi / 3
		if rho < eps then
			lon = -math.pi / 3
		end
	elseif f == 6 or f == 9 or f == 15 then
		lon = -lon
		lon = lon + math.pi
		if lon > math.pi then
			lon = lon - 2 * math.pi
		end
		if rho < eps then
			lon = math.pi
		end
	end

	return lat, lon
end

---@param q number
---@param r number
---@param f number
---@param ws number
---@return number, number
function hu.hex_coords_to_latlon(q, r, f, ws)
	local x = q
	local y = r
	local z = -(q + r)

	if f == 4 or f == 1 or f == 6 or f == 16 then
		y = q
		z = r
		x = -(q + r)
	elseif f == 0 then
		x = q
		y = r
		z = -(q + r)
	elseif f == 5 or f == 8 or f == 12 then
		z = q
		x = r
		y = -(q + r)
	else
		y = -q
		x = -r
		z = -(-q + -r)
	end
	local val_1_lat, _ = get_base_latlon(x, y, z, f, ws)

	if f == 4 or f == 1 or f == 6 then
		y = q
		z = r
		x = -(q + r)
	elseif f == 0 then
		x = q
		y = r
		z = -(q + r)
	else
		y = -q
		x = -r
		z = -(-q + -r)
	end
	local _, val_2_lon = get_base_latlon(x, y, z, f, ws)

	if f == 0 or f == 1 or f == 4 or f == 6 then
		return val_1_lat, -val_2_lon
	else
		return val_1_lat, val_2_lon
	end
end

return hu