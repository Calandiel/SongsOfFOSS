local wl = {}

local world = require "game.entities.world"
local plate = require "game.entities.plate"
local color = require "game.color"
local tabb = require "engine.table"
local tile = require "game.entities.tile"

WORLD_PROGRESS = {total = 0, max = 0, is_loading = false}

local loader_error = nil -- write this in coroutines to transmit the error out of coroutines scope...
---
function wl.init()
	local tips = require "game.scenes.tips"
	local size = tabb.size(tips)
	print("Tip table size: " .. tostring(size))
	local r = love.math.random(size)
	print("Randomly rolled tip index: " .. tostring(r))
	wl.tip = tips[r]
end

---
---@param dt number
function wl.update(dt)

end

---
function wl.draw()
	local ui = require "engine.ui"
	ui.background(ASSETS.background)

	if wl.coroutine == nil then
		wl.message = "Initializing..."
		if DEFINES.empty then
			wl.coroutine = coroutine.create(wl.empty)
		elseif DEFINES.default then --(require "engine.table").contains(ARGS, "--dev") then
			-- We're loading a world from default pngs for debugging purposes...
			wl.coroutine = coroutine.create(wl.load_default)
		elseif DEFINES.world_gen then
			-- We're generating a world from scratch...
			wl.coroutine = coroutine.create(wl.generate)
		else
			-- We're loading a world from file...
			wl.coroutine = coroutine.create(wl.load_save)
		end
	end
	local output = {coroutine.resume(wl.coroutine)}

	ui.text_panel(wl.message, ui.fullscreen():subrect(
		0, 0, 300, 60, "center", "down"
	))
	ui.text_panel(wl.tip, ui.fullscreen():subrect(
		0, 0, 800, 60, "center", "up"
	))

	if coroutine.status(wl.coroutine) == "dead" then
		-- Well, if the coroutine is dead it means that loading finished...
		-- print(output[2])
		-- print(debug.traceback(wl.coroutine))
		if loader_error ~= nil then
			error(loader_error)
			return
		end
		wl.coroutine = nil
		local manager = require "game.scene-manager"
		manager.transition("game")
	end
end

---Given a tile ID and an image data, return the color for that tile
---@param tile_id tile_id
---@param map love.ImageData
---@return number r
---@return number g
---@return number b
local function read_pixel(tile_id, map)
	local lat, lon = tile.latlon(tile_id)
	local y = (lat + math.pi / 2) / math.pi
	y = math.min(1, math.max(0, y)) * map:getHeight()
	y = math.min(map:getHeight() - 1, math.max(0, y))
	local x = (lon + math.pi) / (2 * math.pi)
	x = math.min(1, math.max(0, x)) * map:getWidth()
	x = math.min(map:getWidth() - 1, math.max(0, x))
	local r, g, b, _ = map:getPixel(x, y)
	return r, g, b
end

function wl.empty()
	print("Loading an empty world...")
	coroutine.yield()
	wl.message = "Loading an empty world..."
	coroutine.yield()
	world.empty()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	require "game.raws.raws" ()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
end

function wl.load_default()
	print("Loading default world...")
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	wl.message = "Loading default world..."
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	world.empty()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	require "game.raws.raws" ()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()

	-- After we create the empty world, we can fill it with data...
	do
		print("Loading tectonics map...")
		local time = love.timer.getTime()
		local tect = love.image.newImageData("default/tectonics.png")
		---@type table<number, plate_id>
		local found_plates = {}
		DATA.for_each_tile(function (tile_id)
			local r, g, b = read_pixel(tile_id, tect)

			---@type number
			local pixel_id = require "game.color".rgb_to_id(r, g, b)
			if found_plates[pixel_id] == nil then
				-- Unknown plate! Create a new one!
				print("New plate: ", r, g, b)
				found_plates[pixel_id] = plate.Plate:new()
			end
			plate.Plate.add_tile(found_plates[pixel_id], tile_id)
		end)
		print("Tectonic map loaded!")
		print(love.timer.getTime() - time)
	end

	coroutine.yield()
	coroutine.yield()

	do
		local time = love.timer.getTime()
		print("Loading hydrology maps...")
		local hydro_jan = love.image.newImageData("default/waterflow-january.png")
		local hydro_jul = love.image.newImageData("default/waterflow-july.png")
		DATA.for_each_tile(function (tile_id)
			local jan_r, jan_g, jan_b = read_pixel(tile_id, hydro_jan)
			local jul_r, jul_g, jul_b = read_pixel(tile_id, hydro_jul)
			jan_r, jan_g, jan_b = color.to_255(jan_r, jan_g, jan_b)
			jul_r, jul_g, jul_b = color.to_255(jul_r, jul_g, jul_b)

			local process_pixel = function(r, g, b)
				if color.equals(r, g, b, 30, 125, 255) then
					-- salty lake
					return false, false, 0
				elseif color.equals(r, g, b, 15, 239, 255) then
					-- freshwater lake
					return false, true, 0
				elseif color.equals(r, g, b, 2, 8, 209) then
					-- ocean
					return false, false, 0
				elseif color.equals(r, g, b, 129, 9, 9) then
					-- no water, red
					return true, false, 0
				elseif color.equals(r, g, b, 244, 17, 17) then
					return true, false, 800
				elseif color.equals(r, g, b, 255, 132, 17) then
					return true, false, 2000
				elseif color.equals(r, g, b, 250, 250, 10) then
					return true, false, 5259
				elseif color.equals(r, g, b, 28, 255, 122) then
					return true, false, 11250
				elseif color.equals(r, g, b, 15, 175, 255) then
					return true, false, 20000
				elseif color.equals(r, g, b, 24, 77, 249) then
					return true, false, 30000
				else
					local msg = "Unknown waterflow color: " .. tostring(r) .. ", " .. tostring(g) ", " .. tostring(b)
					print(msg)
					error(msg)
				end
				--- Returns "is land", "is fresh", "waterflow"
				return true, true, 0
			end
			local jan_is_land, jan_is_fresh, jan_waterflow = process_pixel(jan_r, jan_g, jan_b)
			local jul_is_land, jul_is_fresh, jul_waterflow = process_pixel(jul_r, jul_g, jul_b)

			DATA.tile_set_is_land(tile_id, jan_is_land or jul_is_land)
			DATA.tile_set_is_fresh(tile_id, jan_is_fresh or jul_is_fresh)
			DATA.tile_set_january_waterflow(tile_id, jan_waterflow)
			DATA.tile_set_january_waterflow(tile_id, jul_waterflow)
			DATA.tile_set_waterlevel(tile_id, 0) -- loaded tiles have a watertable of 0!
			local waterflow = (jan_waterflow + jul_waterflow) / 2
			if waterflow > 2500.0 then
				DATA.tile_set_has_river(tile_id, true)
			end
		end)
		print(love.timer.getTime() - time)
	end
	print("Hydrology maps loaded!")
	coroutine.yield()
	coroutine.yield()

	do
		print("Loading heightmap...")
		local time = love.timer.getTime()
		local height = love.image.newImageData("default/heightmap.png")
		DATA.for_each_tile(function (tile_id)
			local r, g, b = read_pixel(tile_id, height)
			r, g, b = color.to_255(r, g, b)

			local sea_level = 94
			local elev = r - sea_level
			if elev < 0 then
				elev = elev / sea_level * 8000
			else
				elev = elev / (255 - sea_level) * 8000
			end

			DATA.tile_set_elevation(tile_id, elev)
		end)
		print("Heightmap loaded!")
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	print("Correcting elevation...")
	do
		local time = love.timer.getTime()
		DATA.for_each_tile(function (tile_id)
			local elevation = DATA.tile_get_elevation(tile_id)
			if DATA.tile_get_is_land(tile_id) then
				DATA.tile_set_elevation(tile_id, math.max(1, elevation))
				DATA.tile_set_waterlevel(tile_id, 0)
				tile.waterlevel = 0
			else
				DATA.tile_set_elevation(tile_id, math.min(-1, elevation))
				DATA.tile_set_waterlevel(tile_id, 0)
			end
		end)
		print("Elevation corrected!")
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	print("Loading soils...")
	do
		local time = love.timer.getTime()
		local depth = love.image.newImageData("default/soil-depth.png")
		local organics = love.image.newImageData("default/soil-organics.png")
		local minerals = love.image.newImageData("default/soil-minerals.png")
		local texture = love.image.newImageData("default/soil-texture.png")
		local col_utils = require "game.color"
		DATA.for_each_tile(function (tile_id)
			local depth_r, depth_g, depth_b = read_pixel(tile_id, depth)
			local organics_r, organics_g, organics_b = read_pixel(tile_id, organics)
			local minerals_r, minerals_g, minerals_b = read_pixel(tile_id, minerals)
			local texture_r, texture_g, texture_b = read_pixel(tile_id, texture)

			local total = texture_r + texture_g + texture_b
			if total == 0 then
				total = 0.001 -- prevent NaNs from division by 0!
			end
			local sand = texture_r / total
			local silt = texture_g / total
			local clay = texture_b / total

			local hue_depth, _, _ = col_utils.rgb_to_hsv(depth_r, depth_g, depth_b)
			local depth = math.min(hue_depth, 235.0) / 235.0 * 10.0

			DATA.tile_set_sand(tile_id, sand * depth)
			DATA.tile_set_silt(tile_id, silt * depth)
			DATA.tile_set_clay(tile_id, clay * depth)
			if depth == 0 then
				DATA.tile_set_soil_minerals(tile_id, 0)
				DATA.tile_set_soil_organics(tile_id, 0)
			else
				local hue_organics, _, _ = col_utils.rgb_to_hsv(organics_r, organics_g, organics_b)
				DATA.tile_set_soil_organics(tile_id, math.min(hue_organics, 235.0) / 235.0)
				local hue_minerals, _, _ = col_utils.rgb_to_hsv(minerals_r, minerals_g, minerals_b)
				DATA.tile_set_soil_minerals(tile_id, math.min(hue_minerals, 235.0) / 235.0)
			end
		end)
		print("Soils loaded!")
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		print("Loading ice...")
		local ice = love.image.newImageData("default/ice.png")
		local ice_age_ice = love.image.newImageData("default/ice-age-ice.png")
		local get_ice = function(r, g, b)
			if g == 1.0 and b == 1.0 then
				local rr = r * 255.0
				if rr == 210.0 then return 10.0
				elseif rr == 225.0 then return 25.0
				elseif rr == 240.0 then return 40.0
				else return 0.0 end
			else return 0.0 end
		end
		DATA.for_each_tile(function (tile_id)
			local r, g, b = read_pixel(tile_id, ice)
			DATA.tile_set_ice(tile_id, get_ice(r, g, b))
			r, g, b = read_pixel(tile_id, ice)
			DATA.tile_set_ice_age_ice(tile_id, get_ice(r, g, b))
		end)
		print("Ice loaded!")
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	do
		local time = love.timer.getTime()
		print("Loading rocks")
		local rocks = love.image.newImageData("default/rocks.png")
		local color_utils = require "game.color"
		DATA.for_each_tile(function (tile_id)
			local r, g, b = read_pixel(tile_id, rocks)
			local id = color_utils.rgb_to_id(r, g, b)
			if RAWS_MANAGER.bedrocks_by_color_id[id] ~= nil then
				DATA.tile_set_bedrock(tile_id, RAWS_MANAGER.bedrocks_by_color_id[id])
			else
				DATA.tile_set_bedrock(tile_id, RAWS_MANAGER.bedrocks_by_name['limestone'])
			end
		end)
		print("Rocks loaded!")
		print(love.timer.getTime() - time)
	end

	coroutine.yield()
	coroutine.yield()

	---[[
	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		print("Generating climate...")
		require "game.climate.climate-simulation".run()

		DATA.for_each_tile(function (item)
			tile.update_climate_data(item)
		end)

		print("Climate generated!")
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		print("Generating plants...")
		require "game.ecology.plant-simulation".run()
		print("Plants generated!")
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		print("Generating biomes...")
		require "game.ecology.recalculate-biomes".run_fast()
		print("Biomes generated!")
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	--]]
	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		print("Generating provinces...")
		require "game.world-gen.province-gen".run()
		print("Provinces generated!")
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		print("Generating resources...")
		require "game.world-gen.resource-gen".run()
		print("Resources generated!")
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	---[[
	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		print("Calculating provincial movement costs...")
		require "game.world-gen.province-movement-cost".run()
		print("Provincial movement costs calculated!")
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		print("Recalculating provincial hydration...")
		require "game.world-gen.province-hydration".run()
		print("Provincial hydration recalculated!")
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		print("Calculating pathfinding indices")
		require "game.world-gen.determine-pathfinding-index".determine()
		print("Pathfinding indices calculated!")
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		print("Calculating carrying capacities...")
		require "game.ecology.carrying-capacity".calculate()
		print("Carrying capacities calculated!")
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		print("Spawning tribes...")
		require "game.world-gen.spawn-tribes".run()
		print("Tribes spawned!")
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		print("Initializing education...")
		require "game.world-gen.initialize_education".run()
		print("Education initialized!")
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()


	print("All maps loaded!")
	--]]
end

function wl.generate()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	wl.message = "Generating..."
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	world.empty()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	require "game.raws.raws" ()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()


	wl.message = "Generating climate..."
	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		require "game.climate.climate-simulation".run()
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	wl.message = "Generating plants..."
	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		require "game.ecology.plant-simulation".run()
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	wl.message = "Generating biomes..."
	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		require "game.ecology.recalculate-biomes".run()
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	wl.message = "Calculating pathfinding indices"
	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		require "game.world-gen.determine-pathfinding-index".determine()
		print(love.timer.getTime() - time)
	end
	coroutine.yield()
	coroutine.yield()

	wl.message = "Generating resources..."
	coroutine.yield()
	coroutine.yield()
	do
		local time = love.timer.getTime()
		require "game.world-gen.resource-gen".run()
		print(love.timer.getTime() - time)
	end
end

function wl.load_save()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	wl.message = "Loading save..."
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	coroutine.yield()
	world.empty()

	-- print('loading raws')
	-- require "game.raws.raws" ()

	LOAD_GAME_STATE()
	assert(WORLD)
	require "game.entities.world".reset_metatable(WORLD)
	require "game.raws.raws"(true, true)

	print("loading options")
	OPTIONS = require "game.options".load()
	require "game.options".verify()
	WORLD_PROGRESS.is_loading = false

	if WORLD == nil then
		return nil
	else
		loader_error = nil
	end
end

return wl
