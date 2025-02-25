local wg = {}

---@enum states
local STATES = {
	init      = 0,
	error     = 1,
	retry     = 2,

	world_init = 10,
	load_maps  = 11,

	completed  = 1000
}

local cpml = require "cpml"
local world_generator = require "libsote.world-generator"

local debug = require "libsote.debug-control-panel"

local hex = require "libsote.hex-utils"
local function map_tiles_to_hex()
	for _, tile in pairs(WORLD.tiles) do
		local lat, lon = tile:latlon()
		local q, r, face = hex.latlon_to_hex_coords(lat, lon, wg.world.size)

		wg.world:cache_square_ti_by_hex_coords(q, r, face)
	end
end

local function load_mapping_from_file(file)
	for row in require("game.file-utils").csv_rows(file) do
		wg.world:cache_square_ti_by_hex_ti(tonumber(row[2]))
	end
end

local function cache_cube_world_tiles()
	print("Caching tile coordinates...")

	if debug.map_tiles_from_file then
		-- it's faster to load the pre-calculated coordinates from a file than to calculate them on the fly
		load_mapping_from_file("d:\\temp\\hex_mapping2.csv")
	else
		map_tiles_to_hex()
	end

	print("Done caching tile coordinates")
end

_coroutine_resume = coroutine.resume
function coroutine.resume(...)
	local state, result = _coroutine_resume(...)
	if not state then
		error(tostring(result), 2)
	end
end

function wg.init()
	wg.state = STATES.init
	wg.message = nil

	if not world_generator.init() then
		wg.state = STATES.error
		wg.message = world_generator.message
		return
	end

	wg.world_size = DEFINES.world_size
	local dim = wg.world_size * 3

	local imd = love.image.newImageData(dim, dim, "rgba8")
	for x = 1, dim do
		for y = 1, dim do
			imd:setPixel(x - 1, y - 1, 0.1, 0.1, 0.1, 1)
		end
	end
	wg.tile_color_image_data = imd
	wg.tile_color_texture = love.graphics.newImage(imd)

	wg.camera_position = cpml.vec3.new(0, 0, -2.5)
	wg.planet_mesh = require "game.scenes.game.planet".get_planet_mesh()
	wg.planet_shader = require "libsote.planet-shader".get_shader()
	wg.game_canvas = love.graphics.newCanvas()

	wg.coroutine = coroutine.create(wg.generate_coro)
	coroutine.resume(wg.coroutine)
end

local prof = require "libsote.profiling-helper"

function wg.generate_coro()
	math.randomseed(os.time())
	local seed = math.random(1, 100000)
	if debug.fixed_seed then
		seed = debug.fixed_seed
	end
	print("Seed: " .. seed)

	local worldgen_coro = coroutine.create(world_generator.get_gen_coro)
	while coroutine.status(worldgen_coro) ~= "dead" do
		coroutine.resume(worldgen_coro, seed)

		wg.message = world_generator.message

		if world_generator.state == world_generator.states.constraints_failed then
			wg.state = STATES.retry
			return
		elseif world_generator.state == world_generator.states.phase_02 and wg.state ~= STATES.world_init then
			wg.state = STATES.world_init

			wg.world = world_generator.world

			require "game.raws.raws"(false) -- no logging
			require "game.entities.world".empty()
			coroutine.yield()

			wg.message = "Caching tile coordinates"
			prof.run_with_profiling(function() cache_cube_world_tiles() end, "[scenes.world-gen]", "cache_cube_world_tiles")
			coroutine.yield()
		end

		coroutine.yield()
	end

	wg.state = STATES.load_maps
	local wl = require "libsote.world-loader"
	wl.load_maps_from(wg.world)
	coroutine.yield()

	if debug.save_maps then
		wl.dump_maps_from(wg.world)
		coroutine.yield()
	end

	local default_map_mode = "elevation"
	wg.map_mode = default_map_mode
	wg.refresh_map_mode()

	wg.state = STATES.completed
end

function wg.update(dt)
	if wg.coroutine == nil then
		return
	end

	coroutine.resume(wg.coroutine)
	if coroutine.status(wg.coroutine) == "dead" then
		wg.coroutine = nil
	end
end

local up_direction = cpml.vec3.new(0, 1, 0)
local origin_point = cpml.vec3.new(0, 0, 0)

wg.locked_screen_x = 0
wg.locked_screen_y = 0

local ui = require "engine.ui"

function wg.handle_camera_controls()
	local up = up_direction
	local camera_speed = (wg.camera_position:len() - 0.75) * 0.0015

	if ui.is_key_held('lshift') then
		camera_speed = camera_speed * 3
	end
	if ui.is_key_held('lctrl') then
		camera_speed = camera_speed / 6
	end

	local mouse_x, mouse_y = ui.mouse_position()

	if ui.is_mouse_pressed(1) then
		wg.locked_screen_x = mouse_x
		wg.locked_screen_y = mouse_y
	end

	local rotation_up = 0
	local rotation_right = 0

	local screen_x, screen_y = ui.get_reference_screen_dimensions()

	CACHED_CAMERA_POSITION = wg.camera_position
	if ui.is_mouse_held(1) then
		local len = wg.camera_position:len()

		rotation_up = (mouse_y - wg.locked_screen_y) / screen_y * len * len / 2
		rotation_right = (mouse_x - wg.locked_screen_x) / screen_x * len * len

		wg.locked_screen_x = mouse_x
		wg.locked_screen_y = mouse_y
	end

	if rotation_right ~= 0 or rotation_up ~= 0 then
		wg.camera_position = wg.camera_position:rotate(-rotation_right, up)
		local rot = wg.camera_position:cross(up)
		wg.camera_position = wg.camera_position:rotate(-rotation_up, rot)
	end

	camera_speed = camera_speed * 10

	if ui.is_key_held('a') then
		wg.camera_position = wg.camera_position:rotate(-camera_speed, up)
	end
	if ui.is_key_held('d') then
		wg.camera_position = wg.camera_position:rotate(camera_speed, up)
	end
	if not (ui.is_key_held('lshift') or ui.is_key_held('rshift')) and ui.is_key_held('w') then
		local rot = wg.camera_position:cross(up)
		wg.camera_position = wg.camera_position:rotate(-camera_speed, rot)
	end
	if ui.is_key_held('s') then
		local rot = wg.camera_position:cross(up)
		wg.camera_position = wg.camera_position:rotate(camera_speed, rot)
	end

	local zoom_speed = 0.001 * 2
	zoom_speed = zoom_speed * 15
	if (ui.mouse_wheel() < 0) then
		wg.camera_position = wg.camera_position * (1 + zoom_speed)
		local l = wg.camera_position:len()
		if l > 3 then
			wg.camera_position = wg.camera_position:normalize() * 3
		end
	end
	if (ui.mouse_wheel() > 0) then
		wg.camera_position = wg.camera_position * (1 - zoom_speed)
		local l = wg.camera_position:len()
		if l < 1.015 then
			wg.camera_position = wg.camera_position:normalize() * 1.015
		end
	end

	-- At the end, perform a sanity check to avoid entering polar regions
	if wg.camera_position:normalize():sub(cpml.vec3.new(0, 1, 0)):len() < 0.01 or
		wg.camera_position:normalize():sub(cpml.vec3.new(0, -1, 0)):len() < 0.01 then
		wg.camera_position = CACHED_CAMERA_POSITION
	else
		CACHED_CAMERA_POSITION = wg.camera_position
	end
end

local is_jan_rain = true
local is_jan_temp = true
local is_jan_water = true

function wg.handle_keyboard_input()
	if (ui.is_key_held('lshift') or ui.is_key_held('rshift')) and ui.is_key_pressed('r') then
		wg.update_map_mode("rocks")
	elseif ui.is_key_pressed('e') then
		wg.update_map_mode("elevation")
	elseif ui.is_key_pressed('r') then
		wg.update_map_mode(is_jan_rain and "jan_rain" or "jul_rain")
		is_jan_rain = not is_jan_rain
	elseif ui.is_key_pressed('t') then
		wg.update_map_mode(is_jan_temp and "jan_temp" or "jul_temp")
		is_jan_temp = not is_jan_temp
	elseif ui.is_key_pressed('k') then
		wg.update_map_mode("koppen")
	elseif (ui.is_key_held('lshift') or ui.is_key_held('rshift')) and ui.is_key_pressed('w') then
		wg.update_map_mode(is_jan_water and "jan_flow" or "jul_flow")
		is_jan_water = not is_jan_water
	end
end

function wg.draw()
	local ui = require "engine.ui"
	local fs = ui.fullscreen()

	if wg.state == STATES.error or wg.state == STATES.retry then
		ui.text_panel(wg.message, ui.fullscreen():subrect(0, 0, 300, 60, "center", "down"))

		local menu_button_width = 380
		local menu_button_height = 30
		local base = fs:subrect(0, 20, 400, 300, "center", "center")
		ui.panel(base)

		local ll = base:subrect(0, 10, 0, 0, "center", "up")
		local layout = ui.layout_builder()
			:position(ll.x, ll.y)
			:vertical()
			:centered()
			:spacing(10)
			:build()

		local ut = require "game.ui-utils"

		if wg.state == STATES.retry then
			if ut.text_button(
				"Retry",
				layout:next(menu_button_width, menu_button_height)
			) then
				wg.state = STATES.init
				wg.coroutine = coroutine.create(wg.generate_coro)
				coroutine.resume(wg.coroutine)
			end
		end
		if ut.text_button(
			"Quit",
			layout:next(menu_button_width, menu_button_height)
		) then
			love.event.quit()
		end
	elseif wg.state == STATES.completed then
		-- ui.text_panel(wg.message, ui.fullscreen():subrect(0, 0, 300, 60, "center", "down"))

		wg.handle_camera_controls()
		wg.handle_keyboard_input()

		local model = cpml.mat4.identity()
		local view = cpml.mat4.identity()

		local l = wg.camera_position:len()
		local t = math.min(math.max((2 - l), 0), 0.5)

		local z = wg.camera_position
		local x = cpml.vec3.cross(up_direction, wg.camera_position)
		local y = cpml.vec3.cross(x, z):normalize()
		local shift = y:scale(t)

		shift = shift:scale(0)

		local projection_z = z.x * z.x + z.z * z.z
		local projection_shift = shift.x * shift.x + shift.z * shift.z
		local sign = 1
		if (projection_shift > projection_z and z.y > 0) then
			sign = -1
		end

		view:look_at(wg.camera_position, origin_point:add(shift), up_direction:scale(sign))

		local projection = cpml.mat4.from_perspective(60, love.graphics.getWidth() / love.graphics.getHeight(), 0.01, 10)

		love.graphics.setCanvas({ wg.game_canvas, depth = true })
		love.graphics.setShader(wg.planet_shader)
		wg.planet_shader:send('model', 'column', model)
		wg.planet_shader:send('view', 'column', view)
		wg.planet_shader:send('projection', 'column', projection)
		wg.planet_shader:send('tile_colors', wg.tile_color_texture)

		love.graphics.setDepthMode("lequal", true)
		love.graphics.clear()
		love.graphics.draw(wg.planet_mesh)
		love.graphics.setShader()
		love.graphics.setCanvas()
		love.graphics.draw(wg.game_canvas)
	else
		ui.background(ASSETS.background)
		ui.left_text(VERSION_STRING, fs:subrect(5, 0, 400, 30, "left", "down"))
	end
end

---@type table<string, MapModeEntry
wg.map_mode_data = {}
require "game.scenes.game.map-modes".set_up_map_modes(wg)

function wg.refresh_map_mode()
	print(wg.map_mode)
	local dat = wg.map_mode_data[wg.map_mode]
	local func = dat.recalculation
	func() -- set "real color" on tiles

	local pointer_tile_color = require("ffi").cast("uint8_t*", wg.tile_color_image_data:getFFIPointer())

	local dim = wg.world_size * 3

	for _, tile in pairs(WORLD.tiles) do
		local x, y = wg.tile_id_to_color_coords(tile)
		local pixel_index = x + y * dim

		local r = tile.real_r
		local g = tile.real_g
		local b = tile.real_b

		local result_pixel = { r, g, b, 1 }

		pointer_tile_color[pixel_index * 4 + 0] = 255 * result_pixel[1]
		pointer_tile_color[pixel_index * 4 + 1] = 255 * result_pixel[2]
		pointer_tile_color[pixel_index * 4 + 2] = 255 * result_pixel[3]
		pointer_tile_color[pixel_index * 4 + 3] = 255 * result_pixel[4]
	end

	wg.tile_color_texture = love.graphics.newImage(wg.tile_color_image_data)
	wg.tile_color_texture:setFilter("nearest", "nearest")
end

function wg.tile_id_to_color_coords(tile)
	local tile_id = tile.tile_id
	local tile_utils = require "game.entities.tile"
	local x, y, f = tile_utils.index_to_coords(tile_id)
	local fx = 0
	local fy = 0
	if f == 0 then
		-- nothing to do!
	elseif f == 1 then
		fx = wg.world_size
	elseif f == 2 then
		fx = 2 * wg.world_size
	elseif f == 3 then
		fy = wg.world_size
	elseif f == 4 then
		fy = wg.world_size
		fx = wg.world_size
	elseif f == 5 then
		fy = wg.world_size
		fx = 2 * wg.world_size
	else
		error("Invalid face: " .. tostring(f))
	end

	return x + fx, y + fy
end

---@param new_map_mode string Valid map mode ID
function wg.update_map_mode(new_map_mode)
	wg.map_mode = new_map_mode
	wg.refresh_map_mode()
end

return wg
