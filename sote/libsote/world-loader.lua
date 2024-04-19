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

local color_utils = require "game.color"

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

		-------------------------------------------------

		local rocks = world:get_rocks(q, r, face)
		local id = color_utils.rgb_to_id(rocks.r, rocks.g, rocks.b)

		if RAWS_MANAGER.bedrocks_by_color[id] ~= nil then
			tile.bedrock = RAWS_MANAGER.bedrocks_by_color[id]
		else
			tile.bedrock = RAWS_MANAGER.bedrocks_by_name['limestone']
		end
	end

	local duration = love.timer.getTime() - start
	print("[worldgen profiling] loaded maps: " .. tostring(duration * 1000) .. "ms")
end

local hexu = require "libsote.hex-utils"
-- local cu = require "game.climate.utils"

-- local data_loader = require("libsote.debug_data_loader")
-- data_loader.loadDataFromFile("D:/temp/sote_output.txt")

function wl.dump_maps_from(world)
	print(love.filesystem.getSaveDirectory())
	-- local file = love.filesystem.newFile("latlon.txt", "w")

	local width = 1600
	local height = 800
	local image_elevation_data = love.image.newImageData(width, height)
	local image_rocks_data = love.image.newImageData(width, height)
	local image_jan_rainfall_data = love.image.newImageData(width, height)

	local col = require "cpml".color

	for x = 0, width - 1 do
		for y = 0, height - 1 do
			local lon = ((x + 0.5) / width * 2 - 1) * math.pi -- -1 to align with ich.io sote, no -1 otherwise
			local lat = ((y + 0.5) / height - 0.5) * math.pi
			local q, r, face = hexu.latlon_to_hex_coords(lat, lon, world.size)
			-- file:write(x .. " " .. y .. " " .. lat .. " " .. lon .. " " .. world:get_minus_longitude(q, r, face) .. "\n")

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

			local rocks = world:get_rocks(q, r, face)
			local id = color_utils.rgb_to_id(rocks.r, rocks.g, rocks.b)
			if RAWS_MANAGER.bedrocks_by_color[id] ~= nil then
				col_r = rocks.r
				col_g = rocks.g
				col_b = rocks.b
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
		end
	end

	-- Encode the ImageData to a PNG FileData
	local elevation_file_data = image_elevation_data:encode('png')
	local rocks_file_data = image_rocks_data:encode('png')
	local jan_rainfall_file_data = image_jan_rainfall_data:encode('png')

	-- Write the FileData to a file
	love.filesystem.write(world.seed .. '_elevation.png', elevation_file_data)
	love.filesystem.write(world.seed .. '_rocks.png', rocks_file_data)
	love.filesystem.write(world.seed .. '_jan_rain.png', jan_rainfall_file_data)

	-- file:close()
end

return wl