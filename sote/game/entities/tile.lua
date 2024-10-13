local tile = {}

local cube = require "game.cube"
local ll_utils = require "game.latlon"

tile.Tile = {}

---@param tile_world_id number
---@return tile_id
function tile.Tile:new(tile_world_id)
	local tile_dcon_id = DATA.create_tile()
	local tt = DATA.fatten_tile(tile_dcon_id)
	tt.world_id = tile_world_id

	WORLD.tile_from_world_id[tile_world_id --[[@as world_tile_id]]] = tile_dcon_id

	tt.is_land = false
	tt.is_fresh = false
	tt.elevation = 0
	tt.grass = 0
	tt.shrub = 0
	tt.conifer = 0
	tt.broadleaf = 0
	tt.ideal_grass = 0
	tt.ideal_shrub = 0
	tt.ideal_conifer = 0
	tt.ideal_broadleaf = 0
	tt.silt = 0
	tt.clay = 0
	tt.sand = 0
	tt.soil_minerals = 0
	tt.soil_organics = 0
	tt.january_waterflow = 0
	tt.july_waterflow = 0
	tt.has_river = false
	tt.has_marsh = false
	tt.ice = 0
	tt.ice_age_ice = 0
	tt.bedrock = 0
	tt.biome = 0
	tt.debug_r = 0.1
	tt.debug_g = 0.1
	tt.debug_b = 0.1
	tt.real_r = 0.1
	tt.real_g = 0.1
	tt.real_b = 0.1
	tt.pathfinding_index = 0

	return tile_dcon_id
end

---@param id tile_id
---@return province_id
function tile.province(id)
	local membership = DATA.get_tile_province_membership_from_tile(id)
	if membership == INVALID_ID then
		return INVALID_ID
	end
	return DATA.tile_province_membership_get_province(membership)
end

---@param id tile_id
---@return Realm
function tile.realm(id)
	if id < 1 then
		return INVALID_ID
	end
	local province = tile.province(id)
	local membership = DATA.get_realm_provinces_from_province(province)
	if membership == INVALID_ID then
		return INVALID_ID
	end
	return DATA.realm_provinces_get_realm(membership)
end

---@param id tile_id
function tile.plate(id)
	return WORLD.tile_to_plate[id]
end

---@param id tile_id
---@param plate Plate
function tile.set_plate(id, plate)
	WORLD.tile_to_plate[id] = plate
end

---Sets this tile's debug color
---@param tile_id tile_id
---@param r number between 0 and 1
---@param g number between 0 and 1
---@param b number between 0 and 1
function tile.set_debug_color(tile_id, r, g, b)
	DATA.tile_set_debug_r(tile_id, r);
	DATA.tile_set_debug_g(tile_id, g);
	DATA.tile_set_debug_b(tile_id, b);
end

---Sets this tile's real color
---@param tile_id tile_id
---@param r number between 0 and 1
---@param g number between 0 and 1
---@param b number between 0 and 1
function tile.set_real_color(tile_id, r, g, b)
	DATA.tile_set_real_r(tile_id, r);
	DATA.tile_set_real_g(tile_id, g);
	DATA.tile_set_real_b(tile_id, b);
end

---Returns latitude [-pi/2, pi/2] and longitude [-pi, pi]
---@param tile_id tile_id
---@return number, number
function tile.latlon(tile_id)
	local lat, lon = tile.get_lat_lon(tile_id)
	return lat, lon
end

---Returns a perlin noise value
---@param tile_id tile_id
---@param frequency number
---@param seed number
---@return number perlin_noise_value between 0 and 1
function tile.perlin(tile_id, frequency, seed)
	-- Get cartesian coordinates on a sphere in a cube [0, 1]^3
	local x, y, z = tile.get_cartesian(tile_id)
	x = (x + 1) / 2
	y = (y + 1) / 2
	z = (z + 1) / 2
	-- Apply frequency
	x = x * frequency
	y = y * frequency
	z = z * frequency
	-- Apply seed offset
	x = x + seed
	y = y + seed
	z = z + seed
	-- Return
	return love.math.noise(x, y, z)
end

---Returns average waterflow
---@param tile_id tile_id
---@return number average_yearly_waterflow
function tile.average_waterflow(tile_id)
	return (DATA.tile_get_january_waterflow(tile_id) + DATA.tile_get_july_waterflow(tile_id)) / 2
end

---Returns climate data
---@param tile_id tile_id
---@return number january_rainfall
---@return number january_temperature
---@return number july_rainfall
---@return number july_temperature
function tile.get_climate_data(tile_id)
	local lat, lon = tile.latlon(tile_id)
	return require "game.climate.utils".get_climate_data(lat, lon, DATA.tile_get_elevation(tile_id))
end

---@alias neighbourID
---|1 top
---|2 bottom
---|3 right
---|4 left

-- constants for the neighbor ID
local NEIGH_TOP = 1
local NEIGH_BOTTOM = 2
local NEIGH_RIGHT = 3
local NEIGH_LEFT = 4

---Returns a neighbors tile_id
---@param tile_id tile_id
---@param neighbor_index neighbourID Ranges from 1 to 4 (both inclusive)
---@return tile_id neigbhbor
function tile.get_neighbor(tile_id, neighbor_index)
	local x, y, f = tile.index_to_coords(tile_id)
	local wsmo = WORLD.world_size - 1

	-- Return coordinates
	local rx = 0
	local ry = 0
	local rf = 0

	if neighbor_index == NEIGH_TOP then
		if y == wsmo then
			if f == cube.TOP then
				rf = cube.RIGHT
				rx = wsmo - x
				ry = wsmo
			elseif f == cube.BOTTOM then
				rf = cube.RIGHT
				rx = x
				ry = 0
			elseif f == cube.FRONT then
				rf = cube.TOP
				rx = wsmo
				ry = x
			elseif f == cube.BACK then
				rf = cube.TOP
				rx = 0
				ry = wsmo - x
			elseif f == cube.LEFT then
				rf = cube.TOP
				rx = x
				ry = 0
			elseif f == cube.RIGHT then
				rf = cube.TOP
				rx = wsmo - x
				ry = wsmo
			else
				error("UNKNOWN FACE: " .. tostring(f))
			end
		else
			rf = f
			rx = x
			ry = y + 1
		end
	elseif neighbor_index == NEIGH_BOTTOM then
		if y == 0 then
			if f == cube.TOP then
				rf = cube.LEFT
				rx = x
				ry = wsmo
			elseif f == cube.BOTTOM then
				rf = cube.LEFT
				rx = wsmo - x
				ry = 0
			elseif f == cube.FRONT then
				rf = cube.BOTTOM
				rx = 0
				ry = x
			elseif f == cube.BACK then
				rf = cube.BOTTOM
				rx = wsmo
				ry = wsmo - x
			elseif f == cube.LEFT then
				rf = cube.BOTTOM
				rx = wsmo - x
				ry = 0
			elseif f == cube.RIGHT then
				rf = cube.BOTTOM
				rx = x
				ry = wsmo
			else
				error("UNKNOWN FACE: " .. tostring(f))
			end
		else
			rf = f
			rx = x
			ry = y - 1
		end
	elseif neighbor_index == NEIGH_LEFT then
		if x == 0 then
			if f == cube.TOP then
				rf = cube.BACK
				rx = wsmo - y
				ry = wsmo
			elseif f == cube.BOTTOM then
				rf = cube.FRONT
				rx = y
				ry = 0
			elseif f == cube.FRONT then
				rf = cube.LEFT
				rx = wsmo
				ry = y
			elseif f == cube.BACK then
				rf = cube.RIGHT
				rx = wsmo
				ry = y
			elseif f == cube.LEFT then
				rf = cube.BACK
				rx = wsmo
				ry = y
			elseif f == cube.RIGHT then
				rf = cube.FRONT
				rx = wsmo
				ry = y
			else
				error("UNKNOWN FACE: " .. tostring(f))
			end
		else
			rf = f
			rx = x - 1
			ry = y
		end
	elseif neighbor_index == NEIGH_RIGHT then
		if x == wsmo then
			if f == cube.TOP then
				rf = cube.FRONT
				rx = y
				ry = wsmo
			elseif f == cube.BOTTOM then
				rf = cube.BACK
				rx = wsmo - y
				ry = 0
			elseif f == cube.FRONT then
				rf = cube.RIGHT
				rx = 0
				ry = y
			elseif f == cube.BACK then
				rf = cube.LEFT
				rx = 0
				ry = y
			elseif f == cube.LEFT then
				rf = cube.FRONT
				rx = 0
				ry = y
			elseif f == cube.RIGHT then
				rf = cube.BACK
				rx = 0
				ry = y
			else
				error("UNKNOWN FACE: " .. tostring(f))
			end
		else
			rf = f
			rx = x + 1
			ry = y
		end
	else
		local msg = "Invalid neighbor index: " .. tostring(neighbor_index)
		print(msg)
		error(msg)
	end

	local ret_id = tile.coords_to_index(rx, ry, rf)
	return WORLD.tile_from_world_id[ret_id]
end

---Returns an iterator over all neighbors
---@param tile_id tile_id
---@return fun():(tile_id|nil)
function tile.iter_neighbors(tile_id)
	local neigh = 0
	return function()
		neigh = neigh + 1
		if neigh > 4 then
			return nil
		else
			return tile.get_neighbor(tile_id, neigh)
		end
	end
end

---Given a neighbor index, returns a new direction that can be iterated again and the neighbor
---@param tile_id tile_id
---@param neighbor_index number
---@return tile_id, number
function tile.move_across_face(tile_id, neighbor_index)
	local nn = tile.get_neighbor(tile_id, neighbor_index)

	local _, _, old_face = tile.index_to_coords(tile_id)
	local _, _, new_face = tile.index_to_coords(nn)
	local new_dir = neighbor_index

	if old_face == cube.LEFT then
		if new_face == cube.BOTTOM then
			new_dir = NEIGH_TOP
		end
	elseif old_face == cube.FRONT then
		if new_face == cube.BOTTOM then
			new_dir = NEIGH_RIGHT
		elseif new_face == cube.TOP then
			new_dir = NEIGH_LEFT
		end
	elseif old_face == cube.RIGHT then
		if new_face == cube.BOTTOM then
			new_dir = NEIGH_BOTTOM
		elseif new_face == cube.TOP then
			new_dir = NEIGH_BOTTOM
		end
	elseif old_face == cube.BACK then
		if new_face == cube.BOTTOM then
			new_dir = NEIGH_LEFT
		elseif new_face == cube.TOP then
			new_dir = NEIGH_RIGHT
		end
	elseif old_face == cube.TOP then
		if new_face == cube.RIGHT then
			new_dir = NEIGH_BOTTOM
		elseif new_face == cube.FRONT then
			new_dir = NEIGH_BOTTOM
		elseif new_face == cube.BACK then
			new_dir = NEIGH_BOTTOM
		end
	elseif old_face == cube.BOTTOM then
		if new_face == cube.LEFT then
			new_dir = NEIGH_TOP
		elseif new_face == cube.RIGHT then
			new_dir = NEIGH_TOP
		elseif new_face == cube.FRONT then
			new_dir = NEIGH_TOP
		elseif new_face == cube.BACK then
			new_dir = NEIGH_TOP
		end
	end

	return nn, new_dir
end

---Iterates a line of a given length
---@param tile_id tile_id
---@param direction number neighbor index
---@param length number
function tile.line_iterator(tile_id, direction, length)
	local curr = 0
	local tt = tile_id
	local dir = direction
	return function()
		curr = curr + 1
		if curr == length then
			return nil
		else
			tt, dir = tile.move_across_face(tile_id, dir)
			return tt
		end
	end
end

---Returns the soil depth, in meters
---@param tile_id tile_id
---@return number
function tile.soil_depth(tile_id)
	return DATA.tile_get_sand(tile_id) + DATA.tile_get_silt(tile_id) + DATA.tile_get_clay(tile_id)
end

---Returns soil permeability, as an abstract D-value (Demian value)
---@param tile_id tile_id
function tile.soil_permeability(tile_id)
	local tile_perm = 2.5

	local sand = DATA.tile_get_sand(tile_id)
	local silt = DATA.tile_get_silt(tile_id)
	local clay = DATA.tile_get_clay(tile_id)

	if sand > 0.15 then
		tile_perm = tile_perm - 2 * (sand - 0.15) / (1.0 - 0.15)
	end
	if silt > 0.85 then
		tile_perm = tile_perm - 0.25 * (silt - 0.85) / (1.0 - 0.85)
	end
	if clay > 0.2 then
		tile_perm = tile_perm - 1.25 * (clay - 0.2) / (1.0 - 0.2)
	end

	return tile_perm / 2.5
end

---Given a tile ID, returns x/y/f coordinates.
---@param tile_id tile_id
---@return number x
---@return number y
---@return number f
function tile.index_to_coords(tile_id)
	local world_id = DATA.tile_get_world_id(tile_id)
	world_id = world_id - 1
	local ws = WORLD.world_size
	local f = math.floor(world_id / (ws * ws))
	local remaining = world_id - f * ws * ws
	local y = math.floor(remaining / ws)
	local x = remaining - y * ws
	return x, y, f
end

---Given x/y/f coordinates, returns a tile ID
---@param x number
---@param y number
---@param f number
---@return world_tile_id world_tile_id
function tile.coords_to_index(x, y, f)
	local ws = WORLD.world_size
	return 1 + (x + y * ws + f * ws * ws) --[[@as world_tile_id]]
end

---Given a 3d point on the surface of a sphere with radius one, return the tile_id for that point
---@param x number
---@param y number
---@param z number
---@return number
function tile.cart_to_index(x, y, z)
	local fx, fy, ff = cube.pos_to_cube(x, y, z)
	local ws = WORLD.world_size
	fx = math.floor(ws * fx)
	fy = math.floor(ws * fy)
	return tile.coords_to_index(fx, fy, ff)
end

---Given latitude [-pi/2, pi/2] and longitude [-pi,pi], return the tile ID
---@param lat number
---@param lon number
---@return number
function tile.lat_lont_to_index(lat, lon)
	local x, y, z = ll_utils.lat_lon_to_cart(lat, lon)
	return tile.cart_to_index(x, y, z)
end

---Given a tile ID, returns latitude [-pi/2, pi/2] and longitude [-pi, pi]
---@param tile_id tile_id
---@return number latitude
---@return number longitude
function tile.get_lat_lon(tile_id)
	local x, y, z = tile.get_cartesian(tile_id)
	local lat, lon = ll_utils.lat_lon_from_cart(x, y, z)
	return lat, lon
end

---Returns cartesian coordinates of the tile, on a sphere of radius 1
---@param tile_id tile_id
---@return number x
---@return number y
---@return number z
function tile.get_cartesian(tile_id)
	local x, y, f = tile.index_to_coords(tile_id)
	local ws = WORLD.world_size

	local fx, fy = 0, 0
	if f == cube.BOTTOM then
		fx = ws - 1 - x + 0.5
		fy = ws - 1 - y + 0.5
	else
		fx = x + 0.5
		fy = y + 0.5
	end

	fx = fx / ws
	fy = fy / ws

	local pos_x, pos_y, pos_z = cube.cube_to_pos(fx, fy, f)
	local rr = math.sqrt(pos_x * pos_x + pos_y * pos_y + pos_z * pos_z)
	return pos_x / rr, pos_y / rr, pos_z / rr
end

---Returns great circle distance to a tile.
---@param origin tile_id
---@param target tile_id
---@return number
function tile.distance_to(origin, target)
	local slat, slon = tile.latlon(origin)
	local olat, olon = tile.latlon(target)
	--[[ Spherical law of cosines
	local angle = math.acos(math.sin(slat) * math.sin(olat) +
		math.cos(slat) * math.cos(olat) * math.cos(math.abs(slon - olon)))
	--]]
	---[[ Vincenty's formula
	local sin_lat_1 = math.sin(slat)
	local sin_lon_1 = math.sin(slon)
	local cos_lat_1 = math.cos(slat)
	local cos_lon_1 = math.cos(slon)
	local sin_lat_2 = math.sin(olat)
	local sin_lon_2 = math.sin(olon)
	local cos_lat_2 = math.cos(olat)
	local cos_lon_2 = math.cos(olon)
	local sin_delta_lon = math.sin(math.abs(slon - olon))
	local cos_delta_lon = math.cos(math.abs(slon - olon))

	local a = cos_lat_2 * sin_delta_lon
	local b = cos_lat_1 * sin_lat_2 - sin_lat_1 * cos_lat_2 * cos_delta_lon
	local angle = math.atan2(
		math.sqrt(a * a + b * b),
		sin_lat_1 * sin_lat_2 + cos_lat_1 * cos_lat_2 * cos_delta_lon
	)
	--]]
	return angle * 6371
end

---@param tile_id tile_id
---@return boolean
function tile.is_coast(tile_id)
	if DATA.tile_get_is_land(tile_id) then
		for n in tile.iter_neighbors(tile_id) do
			if not DATA.tile_get_is_land(n) then
				return true
			end
		end
	else
		for n in tile.iter_neighbors(tile_id) do
			if DATA.tile_get_is_land(n) then
				return true
			end
		end
	end
	return false
end

return tile
