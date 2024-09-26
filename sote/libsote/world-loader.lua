local wl = {}

local function elev_to_gray(elev, is_land)
	local base_color_value = 94
	local land_delta = 161
	local sea_delta = 93

	local final_color_value = 0
	if is_land then
		local land_color_ratio = math.min(elev / 13000, 1)
		final_color_value = base_color_value + land_color_ratio * land_delta
	else
		local water_color_ratio = math.max(math.min(elev, 0) / 13000, -1)
		final_color_value = base_color_value + water_color_ratio * sea_delta - 1
	end

	final_color_value = math.floor(final_color_value + 0.5)
	return final_color_value
end

local function gen_water_movement_rank(val)
	if val < 100 then -- Clay Red
		return 0
	elseif val < 500 then -- Red
		return 1
	elseif val < 2000 then -- Orange
		return 2
	elseif val < 6000 then -- Yellow
		return 3
	elseif val < 15000 then -- Green
		return 4
	elseif val < 100000 then -- Aqua Blue
		return 5
	elseif val < 1000000 then -- Deep Blue
		return 6
	else
		-- print("Invalid water movement value: " .. val)
		return 7
	end
end

-- local hydro_open_issues = require "libsote.hydrology.open-issues"

-- local function process_rank(rank)
-- 	if rank == 0 then
-- 		return 0
-- 	elseif rank == 1 then
-- 		return 800
-- 	elseif rank == 2 then
-- 		return 2000
-- 	elseif rank == 3 then
-- 		return 5259
-- 	elseif rank == 4 then
-- 		return 11250
-- 	elseif rank == 5 then
-- 		return 20000
-- 	elseif rank == 6 then
-- 		return 30000
-- 	elseif rank == 7 then
-- 		return hydro_open_issues.waterflow_for_rank_7()
-- 	end
-- end

local function color_from_rank(rank)
	if rank == 0 then
		return 129, 9, 9
	elseif rank == 1 then
		return 244, 17, 17 -- red
	elseif rank == 2 then
		return 255, 132, 17 -- orange
	elseif rank == 3 then
		return 250, 250, 10 -- yellow
	elseif rank == 4 then
		return 28, 255, 122 -- green
	elseif rank == 5 then
		return 15, 175, 255 -- light blue
	elseif rank == 6 then
		return 24, 77, 249 -- dark blue
	elseif rank == 7 then
		return 2, 35, 209
	end
end

-- local function map_ice(ice)
-- 	if ice <= 0 then return 0 end

-- 	if ice > 3000 then
-- 		return 55
-- 	elseif ice > 1500 then
-- 		return 40
-- 	elseif ice > 750 then
-- 		return 25
-- 	else
-- 		return 10
-- 	end
-- end

local colors = {
	yellow = { 255, 255 * 47 / 51, 255 * 0.0156862754 },
	green = { 0, 255, 0 },
	blue = { 0, 0, 255 },
	cyan = { 0, 255, 255 },
	red = { 255, 0, 0 },
	magenta = { 255, 0, 255 }
}

local function get_waterbody_color(wb)
	if not wb or not wb:is_valid() then
		return 0, 0, 0
	end

	if wb.type == wb.TYPES.wetland then
		return 128, 128, 128
	end

	local rem = wb.id % 10

	if rem == 0 then
		return colors.yellow[1], colors.yellow[2], colors.yellow[3]
	elseif rem == 1 then
		return colors.green[1], colors.green[2], colors.green[3]
	elseif rem == 2 then
		return colors.blue[1], colors.blue[2], colors.blue[3]
	elseif rem == 3 then
		return colors.cyan[1], colors.cyan[2], colors.cyan[3]
	elseif rem == 4 then
		return colors.red[1], colors.red[2], colors.red[3]
	elseif rem == 5 then
		return colors.magenta[1], colors.magenta[2], colors.magenta[3]
	elseif rem == 6 then
		return 255, 111, 15 -- orange
	elseif rem == 7 then
		return 145, 0, 105 -- dark purple
	elseif rem == 8 then
		return 114, 79, 31 -- brown
	elseif rem == 9 then
		return 255, 125, 209 -- pink
	else
		return 159, 217, 108 -- green-ish
	end
end

local rock_layers = require "libsote.rock-layers"

function wl.load_maps_from(world)
	local start = love.timer.getTime()

	for _, tile in pairs(WORLD.tiles) do
		local q, r, face = world:get_tile_coord(tile.tile_id)
		local ti = world:get_tile_index(q, r, face)

		local is_land = world.is_land[ti]

		tile.elevation = world.elevation[ti]
		tile.is_land = is_land

		if is_land then
			tile.elevation = math.max(1, tile.elevation)
			tile.waterlevel = 0
		else
			tile.elevation = math.min(-1, tile.elevation)
			tile.waterlevel = 0
		end

		------------------------------------------------------------------

		local rock_type = world.rock_type[ti]
		local rock_layer_index = world.rock_layer[ti]
		local rock_layer = rock_layers[rock_type][rock_layer_index]

		if rock_layer ~= nil then
			tile.bedrock = rock_layer
		else
			tile.bedrock = RAWS_MANAGER.bedrocks_by_name['limestone']
		end

		-- water movement ------------------------------------------------
		-- local jan_water_movement = world:get_jan_water_movement(q, r, face)
		-- local jan_rank = gen_water_movement_rank(jan_water_movement)
		-- local jan_waterflow = process_rank(jan_rank)

		-- local jul_water_movement = world:get_jul_water_movement(q, r, face)
		-- local jul_rank = gen_water_movement_rank(jul_water_movement)
		-- local jul_waterflow = process_rank(jul_rank)

		local waterflow = 0
		if is_land then
			waterflow = world.water_movement[ti]
		end

		--tile.is_land = jan_is_land or jul_is_land
		--tile.is_fresh = jan_is_fresh or jul_is_fresh
		tile.january_waterflow = waterflow --jan_waterflow
		tile.july_waterflow = waterflow --jul_waterflow
		tile.waterlevel = 0 -- loaded tiles have a watertable of 0!
		-- local waterflow = (jan_waterflow + jul_waterflow) / 2
		-- if waterflow > 2500.0 then
		-- 	tile.has_river = true
		-- end

		-- ice ------------------------------------------------
		tile.ice, tile.ice_age_ice = world:get_ice_by_tile(ti)
	end

	local duration = love.timer.getTime() - start
	print("[world-loader] loaded maps: " .. string.format("%.2f", duration * 1000) .. "ms")
end

local hexu = require "libsote.hex-utils"
-- local cu = require "game.climate.utils"

local function alpha_blend(r1, g1, b1, a1, r2, g2, b2, a2)
	if a1 == 0 then
		-- Top layer is fully transparent
		return r2, g2, b2, a2
	elseif a2 == 0 then
		-- Base layer is fully transparent
		return r1, g1, b1, a1
	else
		-- Normal blending
		local a1_normalized = a1 / 255
		local a2_normalized = a2 / 255
		local inv_a1_normalized = 1 - a1_normalized
		local a_out = a1 + a2 * inv_a1_normalized
		local a_out_normalized = a_out / 255

		local r_out = (r1 * a1_normalized + r2 * a2_normalized * inv_a1_normalized) / a_out_normalized
		local g_out = (g1 * a1_normalized + g2 * a2_normalized * inv_a1_normalized) / a_out_normalized
		local b_out = (b1 * a1_normalized + b2 * a2_normalized * inv_a1_normalized) / a_out_normalized

		return math.floor(r_out + 0.5), math.floor(g_out + 0.5), math.floor(b_out + 0.5), math.floor(a_out + 0.5)
	end
end

local debug = require "libsote.debug-control-panel"
local debug_ms = debug.maps_selection

function wl.dump_maps_from(world)
	local elev_range = 1
	local min_elev = 100000
	if debug_ms.elevation then
		local max_elev = -100000
		world:for_each_tile(function(ti)
			min_elev = math.min(min_elev, world.elevation[ti])
			max_elev = math.max(max_elev, world.elevation[ti])
		end)
		elev_range = max_elev - min_elev
	end

	local width = 2000
	local height = 1000

	local image_elevation_data
	local image_rocks_data
	local image_jan_rainfall_data
	local image_jan_waterflow_data
	local image_waterbodies_data
	local image_debug_data_1
	local image_debug_data_2

	if debug_ms.elevation then
		image_elevation_data = love.image.newImageData(width, height, "rgba16")
	end
	if debug_ms.rocks then
		image_rocks_data = love.image.newImageData(width, height)
	end
	if debug_ms.climate then
		image_jan_rainfall_data = love.image.newImageData(width, height)
	end
	if debug_ms.waterflow then
		image_jan_waterflow_data = love.image.newImageData(width, height)
	end
	if debug_ms.waterbodies then
		image_waterbodies_data = love.image.newImageData(width, height)
	end
	if debug_ms.debug then
		image_debug_data_1 = love.image.newImageData(width, height)
		image_debug_data_2 = love.image.newImageData(width, height)
	end

	local col = require "cpml".color

	for x = 0, width - 1 do
		for y = 0, height - 1 do
			local lon = ((x + 0.5) / width * 2 - 1) * math.pi -- (x + 0.5) / width * 2 - 1 to align with ich.io sote, no -1 otherwise
			local lat = ((y + 0.5) / height - 0.5) * math.pi
			local q, r, face = hexu.latlon_to_hex_coords(lat, lon, world.size)
			local ti = world:get_tile_index(q, r, face)
			local is_land = world.is_land[ti]
			local elevation = world.elevation[ti]

			local col_r, col_g, col_b

			-- elevation -----------------------------------------------------
			if debug_ms.elevation then
				local normalized_elev = (elevation - min_elev) / elev_range
				image_elevation_data:setPixel(x, y, normalized_elev, normalized_elev, normalized_elev, 1)
			end

			-- rocks ---------------------------------------------------------
			if debug_ms.rocks then
				local rock_type = world.rock_type[ti]
				local rock_layer_index = world.rock_layer[ti]
				local rock_layer = rock_layers[rock_type][rock_layer_index]

				if rock_layer ~= nil then
					col_r = rock_layer.r
					col_g = rock_layer.g
					col_b = rock_layer.b
				else
					col_r = RAWS_MANAGER.bedrocks_by_name['limestone'].r
					col_g = RAWS_MANAGER.bedrocks_by_name['limestone'].g
					col_b = RAWS_MANAGER.bedrocks_by_name['limestone'].b
				end

				image_rocks_data:setPixel(x, y, col_r, col_g, col_b, 1)
			end

			-- climate -------------------------------------------------------
			if debug_ms.climate then
				if is_land then
					local r_ja, t_ja, r_ju, t_ju = world:get_climate_data(q, r, face, true)
					-- local r_ja, t_ja, r_ju, t_ju = cu.get_climate_data(lat, lon, generated_elev)
					local val = 1 - math.min(1, r_ja / 250.0)
					local hue = math.min(1, math.max(0, val)) * 0.7
					local rgb = col.from_hsv(hue, 1, 0.75 + val / 4)
					col_r, col_g, col_b = rgb:unpack()
				else
					col_r = 0.1
					col_g = 0.1
					col_b = 0.1
				end

				image_jan_rainfall_data:setPixel(x, y, col_r, col_g, col_b, 1)
			end

			local wb = world:get_waterbody_by_tile(ti)

			-- water movement ------------------------------------------------
			if debug_ms.waterflow then
				col_r, col_g, col_b = 2, 8, 209
				if is_land then
					local water_movement = world.water_movement[ti]
					local rank = gen_water_movement_rank(water_movement)
					col_r, col_g, col_b = color_from_rank(rank)
				else
					if wb and wb.type == wb.TYPES.freshwater_lake then
						col_r, col_g, col_b = 15, 239, 255
					elseif wb and wb.type == wb.TYPES.saltwater_lake then
						col_r, col_g, col_b = 30, 125, 255
					end
				end

				image_jan_waterflow_data:setPixel(x, y, col_r / 255, col_g / 255, col_b / 255, 1)
			end

			-- waterbodies ---------------------------------------------------
			if debug_ms.waterbodies then
				col_r, col_g, col_b = get_waterbody_color(wb)
				image_waterbodies_data:setPixel(x, y, col_r / 255, col_g / 255, col_b / 255, 1)
			end

			-- debug ---------------------------------------------------------
			if debug_ms.debug then
				col_r, col_g, col_b, _ = world:get_debug_rgba_by_tile(ti, 1)
				image_debug_data_1:setPixel(x, y, col_r / 255, col_g / 255, col_b / 255, 1)

				col_r, col_g, col_b, _ = world:get_debug_rgba_by_tile(ti, 2)
				image_debug_data_2:setPixel(x, y, col_r / 255, col_g / 255, col_b / 255, 1)
				-- local r_blend, g_blend, b_blend, a_blend = world:get_debug_rgba(world.num_debug_channels, q, r, face)
				-- for channel = world.num_debug_channels - 1, 1, -1 do
				-- 	local cr, cg, cb, ca = world:get_debug_rgba(channel, q, r, face)
				-- 	r_blend, g_blend, b_blend, a_blend = alpha_blend(r_blend, g_blend, b_blend, a_blend, cr, cg, cb, ca)
				-- end
				-- image_debug_data:setPixel(x, y, r_blend / 255, g_blend / 255, b_blend / 255, a_blend)
			end
		end
	end

	if debug_ms.elevation then
		local elevation_file_data = image_elevation_data:encode('png', world.seed .. '_elevation.png')
		love.filesystem.write(world.seed .. '_elevation.png', elevation_file_data)
	end
	if debug_ms.rocks then
		local rocks_file_data = image_rocks_data:encode('png', world.seed .. '_rocks.png')
		love.filesystem.write(world.seed .. '_rocks.png', rocks_file_data)
	end
	if debug_ms.climate then
		local jan_rainfall_file_data = image_jan_rainfall_data:encode('png', world.seed .. '_jan_rain.png')
		love.filesystem.write(world.seed .. '_jan_rain.png', jan_rainfall_file_data)
	end
	if debug_ms.waterflow then
		local jan_waterflow_file_data = image_jan_waterflow_data:encode('png')
		love.filesystem.write(world.seed .. '_waterflow.png', jan_waterflow_file_data)
	end
	if debug_ms.waterbodies then
		local waterbodies_file_data = image_waterbodies_data:encode('png')
		love.filesystem.write(world.seed .. '_waterbodies.png', waterbodies_file_data)
	end
	if debug_ms.debug then
		local debug_file_data_1 = image_debug_data_1:encode('png')
		local debug_file_data_2 = image_debug_data_2:encode('png')

		love.filesystem.write(world.seed .. '_debug_1.png', debug_file_data_1)
		love.filesystem.write(world.seed .. '_debug_2.png', debug_file_data_2)
	end
end

return wl