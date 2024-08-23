local ut = {}

---Returns value of the sigmoid function evaluated at a given point; f(x) = 1 / (1 + e^x)
---@param value number
---@return number
function ut.sigmoid(value)
	return 1.0 / (1.0 + math.exp(-value))
end

---Given an X coordinate, returns the "real" X coordinate.
---@param x number
---@return number
function ut.get_x(x)
	local xx = x
	if xx < 0 then
		xx = xx + WORLD.climate_grid_size
	end
	if xx >= WORLD.climate_grid_size then
		xx = xx - WORLD.climate_grid_size
	end
	return xx
end

---Given an Y coordinate, returns the "real" Y coordinate.
---@param y number
---@return number
function ut.get_y(y)
	return math.max(
		0, math.min(
			y, WORLD.climate_grid_size - 1
		)
	)
end

---Given an index, returns the x and y coordinates of a cell
---@param index number
---@return number
---@return number
function ut.get_x_y(index)
	local i = index - 1 -- "real" index for compatibility with equations we had in Rust!
	local x = i % WORLD.climate_grid_size;
	local y = math.floor(i / WORLD.climate_grid_size);
	return x, y
end

---Given x/y coordinates, returns the index into the climate grid.
---@param x number
---@param y number
---@return number
function ut.get_id(x, y)
	local id = x + y * WORLD.climate_grid_size
	return id + 1
end

---Returns longitude for a given x coordinate of climate cells, in radians
---@param x number
---@return number
function ut.longitude(x)
	x = x + 0.5
	x = x / WORLD.climate_grid_size
	x = x * 2
	x = x - 1
	return x * math.pi
end

---Returns latitude for a given y coordinate of climate cells, in radians
---@param y number
---@return number
function ut.latitude(y)
	y = y + 0.5
	y = y / WORLD.climate_grid_size
	y = y - 0.5
	return -y * math.pi
end

---Returns latitude for a given y coordinate of climate cells, in degrees
---@param y number
---@return number
function ut.latitude_degrees(y)
	y = y + 0.5
	y = y / WORLD.climate_grid_size
	y = y - 0.5
	return -y * 180
end

---Returns whether or not a cell at a given y-coordinate is in bounds
---@param y number
---@return boolean
function ut.in_bounds(y)
	return not (y < 0 or y >= WORLD.climate_grid_size)
end

---Returns the climate cell at a given latitude and longitude
---@param lat number
---@param lon number
---@return ClimateCell
function ut.get_climate_cell(lat, lon)
	local climate_cell_x = 0.5 + 0.5 * lon / math.pi
	climate_cell_x = climate_cell_x * WORLD.climate_grid_size
	climate_cell_x = math.floor(climate_cell_x)
	climate_cell_x = math.max(0, math.min(WORLD.climate_grid_size - 1, climate_cell_x))
	local climate_cell_y = 0.5 + lat / math.pi
	climate_cell_y = climate_cell_y * WORLD.climate_grid_size
	climate_cell_y = math.floor(climate_cell_y)
	climate_cell_y = math.max(0, math.min(WORLD.climate_grid_size - 1, climate_cell_y))

	local cell_id = climate_cell_x + climate_cell_y * WORLD.climate_grid_size
	local lua_cell_id = cell_id + 1

	return WORLD.climate_cells[lua_cell_id]
end

---Returns lerp factors for climate data
---@param lat number
---@param lon number
---@return number cell
---@return number cell_lerp_factor
---@return number right_cell
---@return number right_cell_lerp_factor
---@return number up_cell
---@return number up_cell_lerp_factor
---@return number up_right_cell
---@return number up_right_cell_lerp_factor
local function get_tile_lerp_factors(lat, lon)
	local x_coord = (0.5 * lon / math.pi + 0.5) * WORLD.climate_grid_size
	local x_cell = math.floor(x_coord)
	x_cell = math.max(0, math.min(WORLD.climate_grid_size - 1, x_cell))
	local x_delta = x_coord - x_cell

	local y_coord = (lat / math.pi + 0.5) * WORLD.climate_grid_size
	local y_cell = math.floor(y_coord)
	y_cell = math.max(0, math.min(WORLD.climate_grid_size - 1, y_cell))
	local y_delta = y_coord - y_cell

	local cell = ut.get_id(x_cell, y_cell)
	local right_cell = ut.get_id(ut.get_x(x_cell + 1), y_cell)
	local up_cell = ut.get_id(x_cell, ut.get_y(y_cell + 1))
	local up_right_cell = ut.get_id(ut.get_x(x_cell + 1), ut.get_y(y_cell + 1))

	return cell, (1 - x_delta) * (1 - y_delta),
		right_cell, x_delta * (1 - y_delta),
		up_cell, (1 - x_delta) * y_delta,
		up_right_cell, x_delta * y_delta
end

---Returns climate data
---@param lat number
---@param lon number
---@param elevation number
---@return number january_rainfall
---@return number january_temperature
---@return number july_rainfall
---@return number july_temperature
function ut.get_climate_data(lat, lon, elevation)
	local ac, acf, bc, bcf, cc, ccf, dc, dcf = get_tile_lerp_factors(lat, lon)

	local a = WORLD.climate_cells[ac]
	local b = WORLD.climate_cells[bc]
	local c = WORLD.climate_cells[cc]
	local d = WORLD.climate_cells[dc]

	local r_ja, t_ja, r_ju, t_ju =
		a.january_rainfall * acf + b.january_rainfall * bcf + c.january_rainfall * ccf + d.january_rainfall * dcf,
		a.january_temperature * acf + b.january_temperature * bcf + c.january_temperature * ccf + d.january_temperature * dcf,
		a.july_rainfall * acf + b.july_rainfall * bcf + c.july_rainfall * ccf + d.july_rainfall * dcf,
		a.july_temperature * acf + b.july_temperature * bcf + c.july_temperature * ccf + d.july_temperature * dcf

	local TEMP_DELTA_PER_KM = 4.3 --  0.0; --  4.3; --  temperatures decrease as you go up -- this controls how much
	local dd = elevation / 1000

	return r_ja, t_ja - TEMP_DELTA_PER_KM * dd, r_ju, t_ju - TEMP_DELTA_PER_KM * dd
end

---Returns humidity data
---@param lat number
---@param lon number
---@return number january_humidity
---@return number july_humidity
function ut.get_humidity(lat, lon)
	local ac, acf, bc, bcf, cc, ccf, dc, dcf = get_tile_lerp_factors(lat, lon)

	local a = WORLD.climate_cells[ac]
	local b = WORLD.climate_cells[bc]
	local c = WORLD.climate_cells[cc]
	local d = WORLD.climate_cells[dc]

	return a.january_humidity * acf + b.january_humidity * bcf + c.january_humidity * ccf + d.january_humidity * dcf,
		a.july_humidity * acf + b.july_humidity * bcf + c.july_humidity * ccf + d.july_humidity * dcf
end

return ut
