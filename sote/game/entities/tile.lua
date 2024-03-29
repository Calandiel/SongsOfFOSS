local tile = {}

local cube = require "game.cube"
local ll_utils = require "game.latlon"

---@class (exact) Tile
---@field __index Tile
---@field tile_id number
---@field is_land boolean
---@field is_fresh boolean
---@field plate ?Plate
---@field elevation number
---@field grass number
---@field shrub number
---@field conifer number
---@field broadleaf number
---@field ideal_grass number
---@field ideal_shrub number
---@field ideal_conifer number
---@field ideal_broadleaf number
---@field silt number
---@field clay number
---@field sand number
---@field soil_minerals number
---@field soil_organics number
---@field january_waterflow number
---@field july_waterflow number
---@field waterlevel number
---@field has_river boolean
---@field has_marsh boolean
---@field ice number
---@field ice_age_ice number
---@field bedrock Bedrock?
---@field biome Biome?
---@field climate_cell ClimateCell
---@field province Province
---@field debug_r number between 0 and 1, as per Love2Ds convention...
---@field debug_g number between 0 and 1, as per Love2Ds convention...
---@field debug_b number between 0 and 1, as per Love2Ds convention...
---@field real_r number between 0 and 1, as per Love2Ds convention...
---@field real_g number between 0 and 1, as per Love2Ds convention...
---@field real_b number between 0 and 1, as per Love2Ds convention...
---@field pathfinding_index number
---@field resource Resource?

---@class Tile
tile.Tile = {}
tile.Tile.__index = tile.Tile
function tile.Tile:new(tile_id)
	---@type Tile
	local tt = {}

	tt.tile_id = tile_id
	tt.is_land = false
	tt.is_fresh = false
	tt.plate = nil
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
	tt.bedrock = nil
	tt.biome = nil
	tt.debug_r = 0.1
	tt.debug_g = 0.1
	tt.debug_b = 0.1
	tt.real_r = 0.1
	tt.real_g = 0.1
	tt.real_b = 0.1
	tt.pathfinding_index = 0

	setmetatable(tt, self)
	return tt
end

---Sets this tile's debug color
---@param r number between 0 and 1
---@param g number between 0 and 1
---@param b number between 0 and 1
function tile.Tile:set_debug_color(r, g, b)
	self.debug_r = r
	self.debug_g = g
	self.debug_b = b
end

---Sets this tile's real color
---@param r number between 0 and 1
---@param g number between 0 and 1
---@param b number between 0 and 1
function tile.Tile:set_real_color(r, g, b)
	self.real_r = r
	self.real_g = g
	self.real_b = b
end

---Returns latitude [-pi/2, pi/2] and longitude [-pi, pi]
---@return number, number
function tile.Tile:latlon()
	local tile_id = self.tile_id
	local lat, lon = tile.get_lat_lon(tile_id)
	return lat, lon
end

---Returns a perlin noise value
---@param frequency number
---@param seed number
---@return number perlin_noise_value between 0 and 1
function tile.Tile:perlin(frequency, seed)
	-- Get cartesian coordinates on a sphere in a cube [0, 1]^3
	local x, y, z = tile.get_cartesian(self.tile_id)
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
---@return number average_yearly_waterflow
function tile.Tile:average_waterflow()
	return (self.january_waterflow + self.july_waterflow) / 2
end

---Returns climate data
---@return number january_rainfall
---@return number january_temperature
---@return number july_rainfall
---@return number july_temperature
function tile.Tile:get_climate_data()
	local ut = require "game.climate.utils"

	local ac, acf, bc, bcf, cc, ccf, dc, dcf = ut.get_tile_lerp_factors(self)

	local a = WORLD.climate_cells[ac]
	local b = WORLD.climate_cells[bc]
	local c = WORLD.climate_cells[cc]
	local d = WORLD.climate_cells[dc]

	local r_ja, t_ja, r_ju, t_ju = a.january_rainfall * acf + b.january_rainfall * bcf + c.january_rainfall * ccf +
		d.january_rainfall * dcf,
		a.january_temperature * acf + b.january_temperature * bcf + c.january_temperature * ccf +
		d.january_temperature * dcf,
		a.july_rainfall * acf + b.july_rainfall * bcf + c.july_rainfall * ccf + d.july_rainfall * dcf,
		a.july_temperature * acf + b.july_temperature * bcf + c.july_temperature * ccf + d.july_temperature * dcf

	local TEMP_DELTA_PER_KM = 4.3 --  0.0; --  4.3; --  temperatures decrease as you go up -- this controls how much
	local dd = self.elevation / 1000

	return r_ja, t_ja - TEMP_DELTA_PER_KM * dd, r_ju, t_ju - TEMP_DELTA_PER_KM * dd
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
---Returns a neighbor tile (as a reference!)
---@param self Tile
---@param neighbor_index neighbourID Ranges from 1 to 4 (both inclusive)
---@return Tile neigbhbor
function tile.Tile:get_neighbor(neighbor_index)
	local id = self.tile_id
	local x, y, f = tile.index_to_coords(id)
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
	return WORLD.tiles[ret_id]
end

---Returns an iterator over all neighbors
---@return function
function tile.Tile:iter_neighbors()
	local neigh = 0
	return function()
		neigh = neigh + 1
		if neigh > 4 then
			return nil
		else
			return self:get_neighbor(neigh)
		end
	end
end

---Given a neighbor index, returns a new direction that can be iterated again and the neighbor
---@param self Tile
---@param neighbor_index number
---@return Tile
---@return number
function tile.Tile:move_across_face(neighbor_index)
	local nn = self:get_neighbor(neighbor_index)

	local _, _, old_face = tile.index_to_coords(self.tile_id)
	local _, _, new_face = tile.index_to_coords(nn.tile_id)
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
---@param self Tile
---@param direction number neighbor index
---@param length number
function tile.Tile:line_iterator(direction, length)
	local curr = 0
	local tt = self
	local dir = direction
	return function()
		curr = curr + 1
		if curr == length then
			return nil
		else
			tt, dir = tt:move_across_face(dir)
			return tt
		end
	end
end

---Returns the soil depth, in meters
---@return number
function tile.Tile:soil_depth()
	return self.sand + self.silt + self.clay
end

---Returns soil permeability, as an abstract D-value (Demian value)
function tile.Tile:soil_permeability()
	local tile_perm = 2.5

	if self.sand > 0.15 then
		tile_perm = tile_perm - 2 * (self.sand - 0.15) / (1.0 - 0.15)
	end
	if self.silt > 0.85 then
		tile_perm = tile_perm - 0.25 * (self.silt - 0.85) / (1.0 - 0.85)
	end
	if self.clay > 0.2 then
		tile_perm = tile_perm - 1.25 * (self.clay - 0.2) / (1.0 - 0.2)
	end

	return tile_perm / 2.5
end

---Given a tile ID, returns x/y/f coordinates.
---@param tile_id number
---@return number x
---@return number y
---@return number f
function tile.index_to_coords(tile_id)
	tile_id = tile_id - 1
	local ws = WORLD.world_size
	local f = math.floor(tile_id / (ws * ws))
	local remaining = tile_id - f * ws * ws
	local y = math.floor(remaining / ws)
	local x = remaining - y * ws
	return x, y, f
end

---Given x/y/f coordinates, returns a tile ID
---@param x number
---@param y number
---@param f number
---@return number tile_id
function tile.coords_to_index(x, y, f)
	local ws = WORLD.world_size
	return 1 + (x + y * ws + f * ws * ws)
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
	local clicked_tile = tile.coords_to_index(fx, fy, ff)
	return clicked_tile
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
---@param tile_id number
---@return number latitude
---@return number longitude
function tile.get_lat_lon(tile_id)
	local x, y, z = tile.get_cartesian(tile_id)
	local lat, lon = ll_utils.lat_lon_from_cart(x, y, z)
	return lat, lon
end

---Returns cartesian coordinates of the tile, on a sphere of radius 1
---@param tile_id number
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
---@param other Tile
---@return number
function tile.Tile:distance_to(other)
	local slat, slon = self:latlon()
	local olat, olon = other:latlon()
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

---@return boolean
function tile.Tile:is_coast()
	if self.is_land then
		for n in self:iter_neighbors() do
			if not n.is_land then
				return true
			end
		end
	else
		for n in self:iter_neighbors() do
			if n.is_land then
				return true
			end
		end
	end
	return false
end

return tile
