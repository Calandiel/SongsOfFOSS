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

-- local rank_0_count = 0
-- local rank_1_count = 0
-- local rank_2_count = 0
-- local rank_3_count = 0
-- local rank_4_count = 0
-- local rank_5_count = 0
-- local rank_6_count = 0
-- local rank_7_count = 0

local hydro_open_issues = require "libsote.hydrology.open-issues"

local function process_rank(rank)
	if rank == 0 then
		-- rank_0_count = rank_0_count + 1
		return 0
	elseif rank == 1 then
		-- rank_1_count = rank_1_count + 1
		return 800
	elseif rank == 2 then
		-- rank_2_count = rank_2_count + 1
		return 2000
	elseif rank == 3 then
		-- rank_3_count = rank_3_count + 1
		return 5259
	elseif rank == 4 then
		-- rank_4_count = rank_4_count + 1
		return 11250
	elseif rank == 5 then
		-- rank_5_count = rank_5_count + 1
		return 20000
	elseif rank == 6 then
		-- rank_6_count = rank_6_count + 1
		return 30000
	elseif rank == 7 then
		-- rank_7_count = rank_7_count + 1
		return hydro_open_issues.waterflow_for_rank_7()
	end
end

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

local rock_layers = require "libsote.rock-layers"

function wl.load_maps_from(world)
	local start = love.timer.getTime()

	for _, tile in pairs(WORLD.tiles) do
		local q, r, face = world:get_tile_coord(tile.tile_id)

		-- local sqlat, sqlon = tile:latlon()
		-- local hexlat, hexlon = world:get_latlon(q, r, face)
		-- print("sq latlon", sqlat, sqlon, "hex latlon", hexlat, hexlon)

		local generated_elev = world:get_elevation(q, r, face)
		local is_land = world:get_is_land(q, r, face)
		local elev_as_grey = elev_to_gray(generated_elev, is_land)

		local sea_level = 94
		local elev = elev_as_grey - sea_level
		if elev < 0 then
			elev = elev / sea_level * 8000
		else
			elev = elev / (255 - sea_level) * 8000
		end

		tile.elevation = elev
		tile.is_land = is_land

		if tile.is_land then
			tile.elevation = math.max(1, tile.elevation)
			tile.waterlevel = 0
		else
			tile.elevation = math.min(-1, tile.elevation)
			tile.waterlevel = 0
		end

		------------------------------------------------------------------

		local rock_type = world:get_rock_type(q, r, face)
		local rock_layer_index = world:get_rock_layer(q, r, face)
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
			local water_movement = world:get_water_movement(q, r, face)
			local rank = gen_water_movement_rank(water_movement)
			waterflow = process_rank(rank)
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
	end

	local duration = love.timer.getTime() - start
	print("[worldgen profiling] loaded maps: " .. tostring(duration * 1000) .. "ms")

	-- print("Rank 0: " .. rank_0_count)
	-- print("Rank 1: " .. rank_1_count)
	-- print("Rank 2: " .. rank_2_count)
	-- print("Rank 3: " .. rank_3_count)
	-- print("Rank 4: " .. rank_4_count)
	-- print("Rank 5: " .. rank_5_count)
	-- print("Rank 6: " .. rank_6_count)
	-- print("Rank 7: " .. rank_7_count)
end

local hexu = require "libsote.hex-utils"
-- local cu = require "game.climate.utils"

-- local data_loader = require("libsote.debug_data_loader")
-- data_loader.loadDataFromFile("D:/temp/sote_output.txt")

function wl.dump_maps_from(world)
	-- print(love.filesystem.getSaveDirectory())
	-- local latlon_logger = require "libsote.debug-loggers".get_latlon_logger("d:/temp")

	local width = 1600
	local height = 800
	local image_elevation_data = love.image.newImageData(width, height)
	local image_rocks_data = love.image.newImageData(width, height)
	local image_jan_rainfall_data = love.image.newImageData(width, height)
	local image_jan_waterflow_data = love.image.newImageData(width, height)

	local col = require "cpml".color

	for x = 0, width - 1 do
		for y = 0, height - 1 do
			local lon = ((x + 0.5) / width * 2) * math.pi -- (x + 0.5) / width * 2 - 1 to align with ich.io sote, no -1 otherwise
			local lat = ((y + 0.5) / height - 0.5) * math.pi
			local q, r, face = hexu.latlon_to_hex_coords(lat, lon, world.size)
			-- latlon_logger:log(x .. " " .. y .. " " .. lat .. " " .. lon .. " " .. world:get_raw_minus_longitude(q, r, face))

			-- elevation -----------------------------------------------------

			local generated_elev = world:get_elevation(q, r, face)
			-- local imported_vals = data_loader.getValuesForCoordinates(x, y)
			local is_land = world:get_is_land(q, r, face)
			-- local is_land = imported_vals[5]
			local elev_as_grey = elev_to_gray(generated_elev, is_land)

			local col_r = elev_as_grey / 255
			local col_g = elev_as_grey / 255
			local col_b = elev_as_grey / 255

			image_elevation_data:setPixel(x, y, col_r, col_g, col_b, 1)

			-- rocks ---------------------------------------------------------

			local rock_type = world:get_rock_type(q, r, face)
			local rock_layer_index = world:get_rock_layer(q, r, face)
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

			-- climate -------------------------------------------------------

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

			-- water movement ------------------------------------------------

			col_r, col_g, col_b = 2, 8, 209
			if is_land then
				local water_movement = world:get_water_movement(q, r, face)
				local rank = gen_water_movement_rank(water_movement)
				col_r, col_g, col_b = color_from_rank(rank)
			else
				local waterbody = world:get_waterbody(q, r, face)
				if waterbody.type == waterbody.types.freshwater_lake then
					col_r, col_g, col_b = 15, 239, 255
				elseif waterbody.type == waterbody.types.saltwater_lake then
					col_r, col_g, col_b = 30, 125, 255
				end
			end

			image_jan_waterflow_data:setPixel(x, y, col_r / 255, col_g / 255, col_b / 255, 1)
		end
	end

	-- Encode the ImageData to a PNG FileData
	local elevation_file_data = image_elevation_data:encode('png')
	local rocks_file_data = image_rocks_data:encode('png')
	local jan_rainfall_file_data = image_jan_rainfall_data:encode('png')
	local jan_waterflow_file_data = image_jan_waterflow_data:encode('png')

	-- Write the FileData to a file
	love.filesystem.write(world.seed .. '_elevation.png', elevation_file_data)
	love.filesystem.write(world.seed .. '_rocks.png', rocks_file_data)
	love.filesystem.write(world.seed .. '_jan_rain.png', jan_rainfall_file_data)
	love.filesystem.write(world.seed .. '_waterflow.png', jan_waterflow_file_data)
end

return wl