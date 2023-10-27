local gam = {}

local cpml = require "cpml"
local world = require "game.entities.world"
local cube = require "game.cube"
local tile = require "game.entities.tile"
local tb = require "game.scenes.game.top-bar"
local callback = require "game.scenes.callbacks"
local tabb = require "engine.table"
local political = require "game.map-modes.political"

local plate_gen = require "game.world-gen.plate-gen"

---@type Technology|nil
gam.cached_selected_tech = nil

---Called when a tile is clicked.
function gam.on_tile_click()
	local tile_id = gam.clicked_tile_id
	local tile = WORLD.tiles[tile_id]

	--[[
	print('REAL_NUTRIENT_IN_TILE:', REAL_NUTRIENT_IN_TILE[tile])
	print('WATER_IN_TILE_VALUES:', WATER_IN_TILE_VALUES[tile])
	print('RAINFALL_IN_TILE:', RAINFALL_IN_TILE[tile])
	print('PERMEABILITY_OF_TILE:', PERMEABILITY_OF_TILE[tile])
	print('SUNLIGHT_VALUES:', SUNLIGHT_VALUES[tile])
	print('SHRUB_COUNT:', SHRUB_COUNT[tile])
	print('WATER_MULTIPLIER:', WATER_MULTIPLIER[tile])
	print('NUTRIENT_MULTIPLIER:', NUTRIENT_MULTIPLIER[tile])
	print('LIGHT_MULTIPLIER:', LIGHT_MULTIPLIER[tile])
	print('BROADLEAF_TEMP_MULTIPLIER:', BROADLEAF_TEMP_MULTIPLIER[tile])
	print('SHRUB_COUNT:', SHRUB_COUNT[tile])
	print('GRASS_COUNT:', GRASS_COUNT[tile])
	print('CONIFER_COUNT:', CONIFER_COUNT[tile])
	print('BROADLEAF_COUNT:', BROADLEAF_COUNT[tile])
	print('DEBUG_1:', DEBUG_1[tile])
	print('DEBUG_2:', DEBUG_2[tile])
	print('DEBUG_3:', DEBUG_3[tile])
	print('DEBUG_4:', DEBUG_4[tile])
	print('BASE_GROWTH', BASE_GROWTH[tile])
	print('WATER_MULTIPLIER', WATER_MULTIPLIER[tile])
	print('NUTRIENT_MULTIPLIER', NUTRIENT_MULTIPLIER[tile])
	print('LIGHT_MULTIPLIER', LIGHT_MULTIPLIER[tile])
	print('SOILDEPTH_MULTIPLIER', SOILDEPTH_MULTIPLIER[tile])
	print('TEMP_MULTIPLIER', TEMP_MULTIPLIER[tile])
	print('KILL', KILL[tile])
	--]]


	if tile ~= nil then
		local tab = require "engine.table"
		if tab.contains(ARGS, "--dev") then
			print("Tile", tile_id)
			tab.print(tile)
			print("Climate Cell")
			tab.print(tile.climate_cell)

			local la, lo = tile:latlon()
			print(la, lo)
			local utt = require "game.climate.utils"
			local x, y = utt.get_x_y(tile.climate_cell.cell_id)
			local cla, clo = utt.latitude(y), utt.longitude(x)
			print(cla, clo)

			if tile.biome ~= nil then
				print("Biome:", tile.biome.name)
			else
				print("Biome:", nil)
			end

			if tile.province then
				print("Foragers limit: ", tile.province.foragers_limit)
			end
		end

		if gam.map_mode == "selected_tile" or gam.map_mode == "diplomacy" then
			gam.refresh_map_mode()
		end
	end
end

---Called in dev mode. Draws debuggig UI.
function gam.debug_ui()
	local ui = require "engine.ui"
	if ui.text_button("Run code", ui.rect(10, 10, 50, 50)) then
		print("running code!")
		--Add your code here!
		plate_gen.run()
		-- Refresh the map mode after loading!
		gam.refresh_map_mode()
		print("code finished running!")
	end
	if ui.text_button("Plates", ui.rect(10, 10 + 60, 50, 50)) then
		gam.update_map_mode("plates")
	end
	if ui.text_button("Selected tile", ui.rect(10, 10 + 60 * 2, 50, 50)) then
		gam.update_map_mode("selected_tile")
	end
	if ui.text_button("Debug", ui.rect(10, 10 + 60 * 3, 50, 50)) then
		gam.update_map_mode("debug")
	end
	if ui.text_button("Take\nsnapshot", ui.rect(10 + 60, 10, 75, 50)) then
		world.save("cache.snapshot")
		gam.refresh_map_mode()
	end
	if ui.text_button("Load\nsnapshot", ui.rect(10 + 60 + 85, 10, 75, 50)) then
		world.load("cache.snapshot")
		gam.refresh_map_mode()
	end
end

---Initializes the planet mesh and does some other, similar setup
function gam.init()
	gam.show_map_mode_panel = false -- for rendering the panel
	gam.map_mode_slider = 0 -- for the map mode slider
	gam.game_canvas = love.graphics.newCanvas()
	gam.planet_mesh = require "game.scenes.game.planet".get_planet_mesh()
	gam.planet_shader = require "game.scenes.game.planet-shader".get_shader()
	gam.paused = true
	gam.speed = 1
	
	gam.tile_province_image_data = nil
	gam.tile_province_texture = nil

	gam.tile_neighbor_provinces_data = nil
	gam.tile_neighbor_provinces_texture = nil

	gam.inspector = nil
	gam.load_camera_position_or_set_to_default()
	local default_map_mode = "elevation"
	gam.map_mode = default_map_mode
	if CACHED_MAP_MODE == nil then
		CACHED_MAP_MODE = gam.map_mode
	else
		gam.map_mode = CACHED_MAP_MODE
	end
	gam.camera_lock = false
	if CACHED_LOCK_STATE == nil then
		CACHED_LOCK_STATE = gam.camera_lock
	else
		gam.camera_lock = CACHED_LOCK_STATE
	end

	local ws = WORLD.world_size
	local dim = ws * 3
	local imd = love.image.newImageData(dim, dim, "rgba8")
	for x = 1, dim do
		for y = 1, dim do
			imd:setPixel(x - 1, y - 1, 0.1, 0.1, 0.1, 1)
		end
	end
	gam.tile_color_image_data = imd
	gam.tile_color_texture = love.graphics.newImage(imd)
    
	gam.empty_texture_image_data = love.image.newImageData(dim, dim, "rgba8")
	gam.empty_texture = love.graphics.newImage(gam.empty_texture_image_data)
    
    local imd2 = love.image.newImageData(dim, dim, "rgba8")
	for x = 1, dim do
		for y = 1, dim do
			imd2:setPixel(x - 1, y - 1, 0.1, 0.1, 0.1, 1)
		end
	end
	gam.tile_improvement_texture_data = imd2
	gam.tile_improvement_texture = love.graphics.newImage(imd2)
    
	gam.refresh_map_mode()
	gam.click_tile(-1)

	gam.minimap = require "game.minimap".make_minimap()


	gam.tile_inspector_scale = 1
end

---Call this to make sure that a camera position exists.
---Whenever possible, it'll load from a global instead.
function gam.load_camera_position_or_set_to_default()
	gam.camera_position = cpml.vec3.new(0, 0, -2.5)
	if CACHED_CAMERA_POSITION == nil then
		CACHED_CAMERA_POSITION = gam.camera_position
	else
		gam.camera_position = CACHED_CAMERA_POSITION
	end
end

gam.time_since_last_tick = 0
---@param dt number
function gam.update(dt)
	gam.speed = gam.speed or 1
	gam.time_since_last_tick = gam.time_since_last_tick + dt
	if gam.time_since_last_tick > 1 / 30 then
		gam.time_since_last_tick = 0
		if gam.paused ~= nil and not gam.paused and gam.selected_decision == nil and
			WORLD.pending_player_event_reaction == false then
			-- the game is unpaused, call tick on world!
			--print("-- tick start --")
			local start = love.timer.getTime()
			for _ = 1, 4 ^ gam.speed do
				WORLD:tick()
				if love.timer.getTime() - start > 1 / 15 then
					break
				end
			end
			--print("-- tick end --")
		else
			-- the game is paused, nothing to do!
		end
	end
	tb.update(dt)
end

local up_direction = cpml.vec3.new(0, 1, 0)
local origin_point = cpml.vec3.new(0, 0, 0)


function gam.handle_camera_controls()
	local ui = require "engine.ui"
	if not gam.camera_lock then
		if gam.camera_position == nil then
			print("!!! Weird error during hot loading... Camera position was set to nil")
			gam.load_camera_position_or_set_to_default()
		end
		-- Handle camera controls...
		local up = up_direction
		local camera_speed = (gam.camera_position:len() - 0.75) * 0.006
		if ui.is_key_held('lshift') then
			camera_speed = camera_speed * 3
		end
		if ui.is_key_held('lctrl') then
			camera_speed = camera_speed / 6
		end
		local mouse_zoom_sensor_size = 3
		local mouse_x, mouse_y = ui.mouse_position()
		--print(ui.mouse_position())
		local screen_x, screen_y = ui.get_reference_screen_dimensions()
		if ui.is_key_held('a') or mouse_x < mouse_zoom_sensor_size then
			gam.camera_position = gam.camera_position:rotate(-camera_speed, up)
		end
		if ui.is_key_held('d') or mouse_x > screen_x - mouse_zoom_sensor_size then
			gam.camera_position = gam.camera_position:rotate(camera_speed, up)
		end
		if ui.is_key_held('w') or mouse_y < mouse_zoom_sensor_size then
			local rot = gam.camera_position:cross(up)
			gam.camera_position = gam.camera_position:rotate(-camera_speed, rot)
		end
		if ui.is_key_held('s') or mouse_y > screen_y - mouse_zoom_sensor_size then
			local rot = gam.camera_position:cross(up)
			gam.camera_position = gam.camera_position:rotate(camera_speed, rot)
		end
		CACHED_CAMERA_POSITION = gam.camera_position
	end
	if ui.is_key_pressed("f8") then
		print("!")
		gam.camera_lock = not gam.camera_lock
		CACHED_LOCK_STATE = gam.camera_lock
	end
end

function gam.handle_zoom()
	local ui = require "engine.ui"
	if not gam.camera_lock then
		local zoom_speed = 0.02
		if ui.is_key_held('lshift') then
			zoom_speed = zoom_speed * 3
		end
		if ui.is_key_held('lctrl') then
			zoom_speed = zoom_speed / 6
		end
		if ui.is_key_held('e') or (ui.mouse_wheel() < 0) then
			gam.camera_position = gam.camera_position * (1 + zoom_speed)
			local l = gam.camera_position:len()
			if l > 3 then
				gam.camera_position = gam.camera_position:normalize() * 3
			end
		end
		if ui.is_key_held('q') or (ui.mouse_wheel() > 0) then
			gam.camera_position = gam.camera_position * (1 - zoom_speed)
			local l = gam.camera_position:len()
			if l < 1.015 then
				gam.camera_position = gam.camera_position:normalize() * 1.015
			end
		end
		CACHED_CAMERA_POSITION = gam.camera_position
	end
end

---@param tile_id number
function gam.click_tile(tile_id)
	gam.clicked_tile_id = tile_id
	gam.clicked_tile = WORLD.tiles[tile_id]
	gam.reset_decision_selection()
	---@type Tile
	if require "engine.table".contains(ARGS, "--dev") then
		CLICKED_TILE_GLOBAL = WORLD.tiles[tile_id]
	end
end

function gam.reset_decision_selection()
	gam.decision_target_primary = nil
	gam.decision_target_secondary = nil
	gam.selected_decision = nil
end

---
function gam.draw()
	gam.click_callback = nil

	if WORLD == nil then
		return
	end
	local ui = require "engine.ui"

	if WORLD.pending_player_event_reaction then
		-- We need to draw the event and return!
		-- Doing it here will prevent rendering of the normal UI
		-- benri da yo ne
		require "game.scenes.game.event-screen".draw(gam)
		return
	end

	-- Reinitialize if needed, for example, after hot-loads
	if gam.planet_mesh == nil then
		gam.init()
	end

	gam.handle_camera_controls()

	local model = cpml.mat4.identity()
	local view = cpml.mat4.identity()
	-- local old_view = cpml.mat4.identity()

	local l = gam.camera_position:len()
	local t = math.min(math.max((2 - l), 0), 0.5)

	local z = gam.camera_position
	local x = cpml.vec3.cross(up_direction, gam.camera_position)
	local y = cpml.vec3.cross(x, z):normalize()
	local shift = y:scale(t)

	if not OPTIONS.rotation then
		shift = shift:scale(0)
	end

	local projection_z = z.x * z.x + z.z * z.z
	local projection_shift = shift.x * shift.x + shift.z * shift.z
	local sign = 1
	if ((projection_shift > projection_z) and (z.y > 0)) then
		sign = -1
	end

	-- love.graphics.print(tostring(projection_z) .. " " .. tostring(projection_shift) .. " " .. tostring(z.y) .. " " .. tostring(sign), 0, 0, 0)
	
	view:look_at(gam.camera_position, origin_point:add(shift), up_direction:scale(sign))
	

	-- local z = gam.camera_position:clone():normalize():rotate(t, rotation_axis)
	-- local x = cpml.vec3.cross(up_direction, z):normalize()
	-- local y = cpml.vec3.cross(z, x):normalize()
	-- local shift = {0, 0, -l}

	-- view[1], view[5], view[9] = x:unpack()
	-- view[2], view[6], view[10] = y:unpack()
	-- view[3], view[7], view[11] = z:unpack()
	-- view[13], view[14], view[15] = unpack(shift)

	-- view[13] = 0
	-- view[14] = 0 * (t) - (1.015) * (1 - t)
	-- view[15] = -l * (t) + 0.05 * (1 - t)
	-- view[16] = 1
	local projection = cpml.mat4.from_perspective(60, love.graphics.getWidth() / love.graphics.getHeight(), 0.01, 10)

	-- Screen point to ray maths!
	-- First, get the mouse position in a [0, 1] space
	local mp_x, mp_y = ui.mouse_position()
	local sd_x, sd_y = ui.get_reference_screen_dimensions()
	local mpfx = mp_x / sd_x
	local mpfy = mp_y / sd_y
	local vp = projection * view
	local inv_vp = cpml.mat4.identity()
	inv_vp:invert(vp)
	local cp = inv_vp * cpml.vec3.new(
		2 * mpfx - 1,
		2 * mpfy - 1,
		0
	)
	--print("===")
	local coll_point, dist = cpml.intersect.ray_sphere({
		position = gam.camera_position,
		direction = (cp - gam.camera_position):normalize()
	}, {
		position = origin_point,
		radius = 1.0
	})
	local click_detected = false
	local new_clicked_tile = gam.clicked_tile_id
	if coll_point then
		if ui.is_mouse_released(1) then
			new_clicked_tile = tile.cart_to_index(coll_point.x, coll_point.y, coll_point.z)
			click_detected = true
		end
	else

	end

	love.graphics.setCanvas({ gam.game_canvas, depth = true })
	love.graphics.setShader(gam.planet_shader)
	gam.planet_shader:send('model', 'column', model)
	gam.planet_shader:send('view', 'column', view)
	gam.planet_shader:send('projection', 'column', projection)
	if gam.planet_shader:hasUniform("tile_colors") then
		gam.planet_shader:send('tile_colors', gam.tile_color_texture)
	end
    if gam.planet_shader:hasUniform("tile_improvement_texture") then
		gam.planet_shader:send('tile_improvement_texture', gam.tile_improvement_texture)
	end
	if gam.planet_shader:hasUniform("world_size") then
		gam.planet_shader:send('world_size', WORLD.world_size)
	end
	if gam.planet_shader:hasUniform("clicked_tile") then
		gam.planet_shader:send('clicked_tile', gam.clicked_tile_id - 1) -- shaders use 0-indexed arrays!
	end
	if gam.planet_shader:hasUniform("player_tile") then
		local character = WORLD.player_character
		if character then
			local province = WORLD.player_character.province
			if province then
				gam.planet_shader:send('player_tile', province.center.tile_id - 1)
			end
		else 
			gam.planet_shader:send('player_tile', 0)
		end
	end
	if gam.planet_shader:hasUniform("camera_distance_from_sphere") then
		gam.planet_shader:send("camera_distance_from_sphere", gam.camera_position:len() - 1)
	end
	if gam.planet_shader:hasUniform("time") then
		gam.planet_shader:send("time", love.timer.getTime())
	end
	if gam.planet_shader:hasUniform("tile_provinces") then
		if gam.tile_province_texture == nil then
			gam.recalculate_province_map()
		end
		gam.planet_shader:send('tile_provinces', gam.tile_province_texture)
	end
	if gam.planet_shader:hasUniform("tile_neighbor_province") then
		gam.planet_shader:send('tile_neighbor_province', gam.tile_neighbor_provinces_texture)
	end
	if gam.planet_shader:hasUniform("tile_raiding_targets") then
		if gam.map_mode == "atlas" then
			gam.planet_shader:send('tile_raiding_targets', gam.tile_raiding_targets_texture or gam.empty_texture)
		else
			gam.planet_shader:send('tile_raiding_targets', gam.empty_texture)
		end
	end

	love.graphics.setDepthMode("lequal", true)
	love.graphics.clear()
	love.graphics.draw(gam.planet_mesh)
	love.graphics.setShader()
	love.graphics.setCanvas()
	love.graphics.draw(gam.game_canvas)

	-- love.graphics.print(old_view:to_string(), 10, 10)
	-- love.graphics.print(view:to_string(), 10, 30)
	-- love.graphics.print(z:to_string(), 10, 30)
	-- love.graphics.print(x:to_string(), 10, 50)
	-- love.graphics.print(y:to_string(), 10, 80)




	-- ##########
	-- ### UI ###
	-- ##########



	-- Just for debugging of tile graphics rendering
	local province_on_map_interaction = false

	if gam.camera_position:len() < 1.25 then
		local mpfx = 0.5
		local mpfy = 0.5
		local vp = projection * view
		local inv_vp = cpml.mat4.identity()
		inv_vp:invert(vp)
		local cp = inv_vp * cpml.vec3.new(
			2 * mpfx - 1,
			2 * mpfy - 1,
			0
		)
		local coll_point, dist = cpml.intersect.ray_sphere({
			position = gam.camera_position,
			direction = (cp - gam.camera_position):normalize()
		}, {
			position = origin_point,
			radius = 1.0
		})
		if coll_point then
			local refx, refy = ui.get_reference_screen_dimensions()
			local size = 35
			local draw_tile = function(tile)
				---@type Tile
				local tile = tile
				local lat, lon = tile:latlon()
				local ll = require "game.latlon"
				local cartx, carty, cartz = ll.lat_lon_to_cart(lat, lon)
				coll_point.x = cartx
				coll_point.y = carty
				coll_point.z = cartz
				local cart = coll_point;
				local vv = vp * cart
				vv.x = vv.x / 2
				vv.y = vv.y / 2
				vv.z = vv.z / 2
				local x = (vv.x + 0.5) * refx
				local y = (vv.y + 0.5) * refy

				local province_visible = true
				local character = WORLD.player_character
				if character and character.realm then
					province_visible = false
					if character.realm.known_provinces[tile.province] then
						province_visible = true
					end
				end
				if (tile.is_land and province_visible) then
					local rect = ui.rect(x - size / 2, y - size / 2, size, size)
					if tile.province.realm and tile.province.center == tile then
						if require "game.scenes.game.widgets.province-on-map" (gam, tile, rect, x, y, size) then
							gam.click_callback = callback.nothing()
						end
					elseif tile.resource then
						ui.image(ASSETS.get_icon(tile.resource.icon), rect)
						--elseif tile.tile_improvement then
						--ui.image(ASSETS.get_icon(tile.tile_improvement.type.map_texture), rect)
					else
						--[[
						if tile.elevation > 2500.0 then
							ui.image(ASSETS.get_icon("0_mountain.png"), rect)
						else
							ui.image(ASSETS.get_icon("oak.png"), rect)
						end
						--]]
					end
				end

				return false
			end

			local visited = {}
			---@type Queue<Tile>
			local qq = require "engine.queue":new()
			local to_draw = 3500
			local center_tile = WORLD.tiles[tile.cart_to_index(coll_point.x, coll_point.y, coll_point.z)]
			visited[center_tile] = center_tile
			qq:enqueue(center_tile)
			while qq:length() > 0 and to_draw > 0 do
				to_draw = to_draw - 1
				---@type Tile
				local td = qq:dequeue()
				draw_tile(td)
				for n in td:iter_neighbors() do
					if visited[n] then
					else
						visited[n] = n
						qq:enqueue(n)
					end
				end
			end
		end
	end

	local ut = require "game.ui-utils"

	local fs = ui.fullscreen()

	if gam.camera_lock then
		ui.text_panel("Camera locked! Press F8 to unlock it!",
			fs:subrect(0, 75, 300, ut.BASE_HEIGHT, "center", "up")
		)
	end

	-- Bottom UI
	local bottom_button_size = ut.BASE_HEIGHT * 2


	local bottom_right = fs:subrect(0, 0, 0, 0, "right", "down")
	local bottom_right_main_layout = ui.layout_builder()
		:vertical(true)
		:position(bottom_right.x, bottom_right.y)
		:flipped()
		:build()
	local _ = bottom_right_main_layout:next(ut.BASE_HEIGHT, bottom_button_size) -- skip!

	-- Bottom bar
	
	
	local bottom_bar = ui.layout_builder()
		:horizontal(true)
		:position(bottom_right.x, bottom_right.y)
		:flipped()
		:build()
	if ui.icon_button(
		ASSETS.icons["exit-door.png"],
		bottom_bar:next(bottom_button_size, bottom_button_size),
		"Quit"
	) then
		gam.inspector = "confirm-exit"
		gam.click_callback = callback.nothing()
	end
	if ui.icon_button(
		ASSETS.icons["save.png"],
		bottom_bar:next(bottom_button_size, bottom_button_size),
		"Save"
	) then
		DEFINES = require "game.defines".init()
		DEFINES.world_gen = false
		DEFINES.world_to_load = "quicksave.binbeaver"
		local manager = require "game.scene-manager"
		manager.transition("world-saver")
		return
		-- world.save("quicksave.binbeaver")
		-- gam.click_callback = callback.nothing()
		-- gam.refresh_map_mode()
	end
	if ui.icon_button(
		ASSETS.icons["load.png"],
		bottom_bar:next(bottom_button_size, bottom_button_size),
		"Load"
	) then
		-- world.load("quicksave.binbeaver")
		DEFINES = require "game.defines".init()
		DEFINES.world_gen = false
		DEFINES.world_to_load = "quicksave.binbeaver"
		local manager = require "game.scene-manager"
		manager.transition("world-loader")
		return
		-- require "game.scenes.bitser-world-loading"()
		-- gam.click_callback = callback.nothing()
		-- gam.refresh_map_mode()
	end
	if ui.icon_button(
		ASSETS.icons["treasure-map.png"],
		bottom_bar:next(bottom_button_size, bottom_button_size),
		"Export map"
	) then
		local to_save = require "game.minimap".make_minimap_image_data(1600, 800)
		to_save:encode("png", gam.map_mode .. ".png")
		gam.click_callback = callback.nothing()
	end
	if ui.icon_button(
		ASSETS.icons["war-pick.png"],
		bottom_bar:next(bottom_button_size, bottom_button_size),
		"Options"
	) then
		gam.inspector = "options"
		gam.click_callback = callback.nothing()
	end
	if WORLD.player_character then
		if ui.icon_button(ASSETS.icons["magnifying-glass.png"], bottom_bar:next(bottom_button_size, bottom_button_size),
			"Change country") then

			require "game.raws.effects.player".to_observer()
			gam.refresh_map_mode()
			gam.click_callback = callback.nothing()
		end
	end
	-- Minimap
	if require "game.minimap".draw(
		gam.minimap,
		gam.camera_position,
		bottom_right_main_layout:next(300, 150)
	) then
		gam.click_callback = callback.nothing()
	end


	-- Draw the calendar
	if ut.calendar(gam) then
		gam.click_callback = callback.nothing()
	end


	-- Draw notifications
	if WORLD.player_character ~= nil then


		if gam.outliner then
			-- "Mask" the mouse interaction
			local notif_panel = fs:subrect(0, ut.BASE_HEIGHT, ut.BASE_HEIGHT * 17, ut.BASE_HEIGHT * 9, "right", 'up')
			if ui.trigger(notif_panel) then
				gam.click_callback = callback.nothing()
			end
			--- Draw outliner
			local outliner_panel = fs:subrect(0, ut.BASE_HEIGHT * 10, ut.BASE_HEIGHT * 17, ut.BASE_HEIGHT * 6, "right", 'up')
			if ui.trigger(outliner_panel) then
				gam.click_callback = callback.nothing()
			end
			gam.notification_slider = require "game.scenes.game.widgets.news"(notif_panel, gam.notification_slider)
			gam.outliner_slider = require "game.scenes.game.widgets.outliner"(outliner_panel, gam.outliner_slider)

			local outliner_rect = outliner_panel:subrect(0, 0, ut.BASE_HEIGHT * 3, ut.BASE_HEIGHT * 1, "left", 'down')

			if ui.text_button('Collapse', outliner_rect, "Hide outliner") then
				gam.outliner = false
				gam.click_callback = callback.nothing()
			end
		else
			local outliner_rect = fs:subrect(0, ut.BASE_HEIGHT, ut.BASE_HEIGHT * 3, ut.BASE_HEIGHT * 1, "right", 'up')

			if ui.text_button('Outliner', outliner_rect, "Show outliner") then
				gam.outliner = true
				gam.click_callback = callback.nothing()
			end
		end
	end

		-- Map mode tab
	if ui.trigger(ui.fullscreen():subrect(
		0, 0, 300, ut.BASE_HEIGHT * 2 + 150, "right", 'down'
	)) then
		gam.click_callback = callback.nothing()
	end

	local map_mode_bar = bottom_right_main_layout:next(300, ut.BASE_HEIGHT)
	local map_mode_bar_layout = ui.layout_builder()
		:horizontal()
		:position(map_mode_bar.x, map_mode_bar.y)
		:build()
	if ui.icon_button(
		ASSETS.icons["plain-arrow.png"],
		map_mode_bar_layout:next(ut.BASE_HEIGHT, ut.BASE_HEIGHT),
		"Show all map modes"
	) then
		gam.show_map_mode_panel = true
		gam.click_callback = callback.nothing()
	end

	if ui.icon_button(
		ASSETS.icons[gam.map_mode_data['atlas'][2]],
		map_mode_bar_layout:next(ut.BASE_HEIGHT, ut.BASE_HEIGHT), gam.map_mode_data['atlas'][3]) then
		gam.click_callback = callback.update_map_mode(gam, "atlas")
	end
	if ui.icon_button(
		ASSETS.icons[gam.map_mode_data['diplomacy'][2]],
		map_mode_bar_layout:next(ut.BASE_HEIGHT, ut.BASE_HEIGHT), gam.map_mode_data['diplomacy'][3]) then
		gam.click_callback = callback.update_map_mode(gam, "diplomacy")
	end
	if ui.icon_button(
		ASSETS.icons[gam.map_mode_data['elevation'][2]],
		map_mode_bar_layout:next(ut.BASE_HEIGHT, ut.BASE_HEIGHT), gam.map_mode_data['elevation'][3]) then
		gam.click_callback = callback.update_map_mode(gam, "elevation")
	end
	if ui.icon_button(
		ASSETS.icons[gam.map_mode_data['biomes'][2]],
		map_mode_bar_layout:next(ut.BASE_HEIGHT, ut.BASE_HEIGHT), gam.map_mode_data['biomes'][3]) then
		gam.click_callback = callback.update_map_mode(gam, "biomes")
	end
	if ui.icon_button(
		ASSETS.icons[gam.map_mode_data['koppen'][2]],
		map_mode_bar_layout:next(ut.BASE_HEIGHT, ut.BASE_HEIGHT), gam.map_mode_data['koppen'][3]) then
		gam.click_callback = callback.update_map_mode(gam, "koppen")
	end

	-- Map modes tab
	if gam.show_map_mode_panel then
		local ttab = require "engine.table"
		local mm_panel_height = ut.BASE_HEIGHT * (1 + 5)
		local panel = bottom_right_main_layout:next(300, mm_panel_height)
		if ui.trigger(panel) then
			gam.click_callback = callback.nothing()
		end
		ui.panel(panel)

		-- bottom right for closing the panel
		if ui.icon_button(ASSETS.icons["cancel.png"], panel:subrect(
			0, 0, ut.BASE_HEIGHT, ut.BASE_HEIGHT, "right", "up"
		)) then
			gam.click_callback = callback.close_map_mode_panel(gam)
			-- gam.show_map_mode_panel = false
		end
		-- buttons for map mode tabs
		local map_tabs_buttons_width = ut.BASE_HEIGHT * 2
		local top_panels = {
			panel:subrect(0 * map_tabs_buttons_width, 0, map_tabs_buttons_width, ut.BASE_HEIGHT, "left", "up"),
			panel:subrect(1 * map_tabs_buttons_width, 0, map_tabs_buttons_width, ut.BASE_HEIGHT, "left", "up"),
			panel:subrect(2 * map_tabs_buttons_width, 0, map_tabs_buttons_width, ut.BASE_HEIGHT, "left", "up"),
			panel:subrect(4 * map_tabs_buttons_width, 0, map_tabs_buttons_width, ut.BASE_HEIGHT, "left", "up"),
			panel:subrect(3 * map_tabs_buttons_width, 0, map_tabs_buttons_width, ut.BASE_HEIGHT, "left", "up"),
			panel:subrect(5 * map_tabs_buttons_width, 0, map_tabs_buttons_width, ut.BASE_HEIGHT, "left", "up"),
			panel:subrect(6 * map_tabs_buttons_width, 0, map_tabs_buttons_width, ut.BASE_HEIGHT, "left", "up"),
			panel:subrect(7 * map_tabs_buttons_width, 0, map_tabs_buttons_width, ut.BASE_HEIGHT, "left", "up"),
		}
		ui.tooltip("All", top_panels[1])
		if gam.map_mode_selected_tab == 'all' then
			ui.centered_text("ALL", top_panels[1])
		else
			if ui.text_button("ALL", top_panels[1]) then
				gam.click_callback = callback.nothing()
				gam.map_mode_selected_tab = 'all'
			end
		end
		ui.tooltip("Political", top_panels[2])
		if gam.map_mode_selected_tab == 'political' then
			ui.centered_text("POL", top_panels[2])
		else
			if ui.text_button("POL", top_panels[2]) then
				gam.click_callback = callback.nothing()
				gam.map_mode_selected_tab = 'political'
			end
		end
		ui.tooltip("Demographic", top_panels[3])
		if gam.map_mode_selected_tab == 'demographic' then
			ui.centered_text("DEM", top_panels[3])
		else
			if ui.text_button("DEM", top_panels[3]) then
				gam.click_callback = callback.nothing()
				gam.map_mode_selected_tab = 'demographic'
			end
		end
		ui.tooltip("Economic", top_panels[4])
		if gam.map_mode_selected_tab == 'economic' then
			ui.centered_text("ECN", top_panels[4])
		else
			if ui.text_button("ECN", top_panels[4]) then
				gam.click_callback = callback.nothing()
				gam.map_mode_selected_tab = 'economic'
			end
		end
		ui.tooltip("Debug", top_panels[7])
		if gam.map_mode_selected_tab == 'debug' then
			ui.centered_text("DEB", top_panels[7])
		else
			if ui.text_button("DEB", top_panels[7]) then
				gam.click_callback = callback.nothing()
				gam.map_mode_selected_tab = 'debug'
			end
		end

		local scrollview_rect = panel:subrect(0, 0, 300, mm_panel_height - ut.BASE_HEIGHT, "right", 'down')
		local mms = gam.map_mode_tabs[gam.map_mode_selected_tab]
		gam.map_mode_slider = ui.scrollview(
			scrollview_rect,
			function(i, rect)
				local mm_key = mms[i]
				local mm_data = gam.map_mode_data[mm_key]
				if mm_data ~= nil then
					local button_rect = rect:copy()
					button_rect.width = button_rect.height
					if ui.icon_button(ASSETS.icons[
						mm_data[2]
						], button_rect,
						mm_data[3]
					) then
						gam.click_callback = callback.update_map_mode(gam, mm_key)
						gam.update_map_mode(mm_key)
					end
					rect.x = rect.x + rect.height
					rect.width = rect.width - rect.height
					ui.text_panel(mm_data[1], rect)
				else
				end
			end,
			ut.BASE_HEIGHT,
			ttab.size(mms),
			ut.BASE_HEIGHT,
			gam.map_mode_slider
		)
	end

	-- Draw the top bar
	tb.draw(gam)
	require "game.scenes.game.inspectors.left-side-bar".draw(gam)

	-- Debugging screen thingy in top left
	local tt = require "engine.table"
	if tt.contains(ARGS, "--dev") == true then
		gam.debug_ui()
	end

	-- At the end, handle tile clicks.
	-- Make sure you add triggers for detecting clicks over UI!

	local click_success = false
	if gam.inspector == nil then
		click_success = true
	elseif gam.inspector == "characters" then
		click_success = require "game.scenes.game.inspector-province-characters".mask()
	elseif gam.inspector == 'treasury-ledger' then
		click_success = require "game.scenes.game.inspector-treasury-ledger".mask()
	elseif gam.inspector == "character" then
		click_success = require "game.scenes.game.inspector-character".mask()
	elseif gam.inspector == "tile" then
		click_success = require "game.scenes.game.tile-inspector".mask(gam)
	elseif gam.inspector == "realm" then
		click_success = require "game.scenes.game.realm-inspector".mask()
	elseif gam.inspector == "building" then
		click_success = require "game.scenes.game.building-inspector".mask()
	elseif gam.inspector == "war" then
		click_success = require "game.scenes.game.war-inspector".mask()
	elseif gam.inspector == "options" then
		click_success = require "game.scenes.main-menu.options".mask() 
	elseif gam.inspector == "confirm-exit" then
		click_success = require "game.scenes.game.confirm-exit".mask()
	elseif gam.inspector == "army" then
		click_success = require "game.scenes.game.inspector-military".mask()
	elseif gam.inspector == "character-decisions" then
		click_success = require "game.scenes.game.inspector-character-decisions".mask()
	elseif gam.inspector == 'reward-flag' then
		click_success = require "game.scenes.game.inspector-reward-flag".mask()
	elseif gam.inspector == 'reward-flag-edit' then
		click_success = require "game.scenes.game.inspector-reward-flag-edit".mask()
	elseif gam.inspector == 'market' then
		click_success = require "game.scenes.game.inspectors.market".mask()
	elseif gam.inspector == 'macrobuilder' then
		click_success = require "game.scenes.game.inspectors.macrobuilder".mask()
	end

	if gam.click_callback == nil then
		if click_success then 
			gam.handle_zoom()
		end
	else
		if click_success then
			gam.click_callback()
		end
	end

	if click_detected and click_success then
		if (gam.click_callback == nil) and ((tb.mask(gam) and require "game.scenes.game.inspectors.left-side-bar".mask())) and not province_on_map_interaction then
			
			gam.click_tile(new_clicked_tile)
			gam.on_tile_click()
			local skip_frame = false
			if gam.inspector == nil then
				skip_frame = true
			end

			local realm = WORLD.tiles[new_clicked_tile].province.realm

			if gam.inspector == "character" and realm then
				if WORLD.tiles[new_clicked_tile].province.realm ~= nil then
					if gam.selected_character == realm.leader then
						gam.inspector = "tile"
					else
						gam.selected_character = realm.leader
					end
				end
			elseif gam.inspector == "realm" then
				if WORLD.tiles[new_clicked_tile].province.realm ~= nil then
					if gam.selected_realm == WORLD.tiles[new_clicked_tile].province.realm then
						-- If we double click a realm, change the inspector to tile
						gam.inspector = "tile"
					else
						gam.selected_realm = WORLD.tiles[new_clicked_tile].province.realm
					end
				end
			elseif gam.inspector == "market" then

			else
				gam.inspector = "tile"
			end
			if skip_frame then
				return
			end
		end
	end

	-- ##################
	-- ### INSPECTORS ###
	-- ##################
	local tile_data_viewable = true
	if WORLD.tiles[gam.clicked_tile_id] ~= nil then

		if WORLD.player_character ~= nil then
			local realm = WORLD.player_character.realm
			local current_pro = WORLD.player_character.province
			local pro = WORLD.tiles[gam.clicked_tile_id].province

			if realm then
				if (realm.known_provinces[pro] == nil) and (pro ~= current_pro) then
					tile_data_viewable = false
				end
			end
		end
	end

	if gam.inspector == "options" then
		local response = require "game.scenes.main-menu.options".draw()
		if response == "main" then
			gam.inspector = nil
		end
	elseif gam.inspector == "confirm-exit" then
		local response = require "game.scenes.game.confirm-exit".draw(gam)
		if response then
			---@type World|nil
			WORLD = nil -- drop the world so that it gets garbage collected..
			local manager = require "game.scene-manager"
			manager.transition("main-menu")
			return
		end
	elseif gam.inspector == "characters" then
		require "game.scenes.game.inspector-province-characters".draw(gam, gam.selected_province)
	elseif gam.inspector == "macrobuilder" then
		require "game.scenes.game.inspectors.macrobuilder".draw(gam)
	elseif gam.inspector == 'treasury-ledger' then
		require "game.scenes.game.inspector-treasury-ledger".draw(gam)
	elseif gam.inspector == 'character' then
		require "game.scenes.game.inspector-character".draw(gam, gam.selected_character)
	elseif gam.inspector == "reward-flag" then
		require "game.scenes.game.inspector-reward-flag".draw(gam)
	elseif gam.inspector == 'reward-flag-edit' then
		require "game.scenes.game.inspector-reward-flag-edit".draw(gam, gam.selected_reward_flag)
	elseif gam.inspector == "army" then
		local character = WORLD.player_character
		if character then
			require "game.scenes.game.inspector-military".draw(gam, character.province.realm)
		end
	elseif gam.inspector == "character-decisions" then
		require "game.scenes.game.inspector-character-decisions".draw(gam)
	elseif tile_data_viewable then
		if gam.inspector == "tile" then
			require "game.scenes.game.tile-inspector".draw(gam)
		elseif gam.inspector == "realm" then
			require "game.scenes.game.realm-inspector".draw(gam)
		elseif gam.inspector == "building" then
			require "game.scenes.game.building-inspector".draw(gam)
		elseif gam.inspector == "war" then
			require "game.scenes.game.war-inspector".draw(gam)
		elseif gam.inspector == 'market' then
			require "game.scenes.game.inspectors.market".draw(gam)
		end
	else
		gam.inspector = nil
	end

	if ui.is_key_pressed('escape') then
		gam.inspector = nil
	end


	if PROFILE_FLAG then
		local profile_rect = ui.fullscreen():subrect(0, 0, 600, 200, "center", "center")
		ui.panel(profile_rect)
		local logs_length = #PROFILER.actions
		local observed_logs_length = 60
		local logs_start = math.max(1, logs_length - observed_logs_length)

		local mean_actions = 0
		local mean_events = 0
		local mean_provinces = 0
		local total_mean = 0

		for i = logs_start, logs_length do
			mean_actions = mean_actions + PROFILER.actions[i]
			mean_events = mean_events + PROFILER.events[i]
			mean_provinces = mean_provinces + PROFILER.province_update[i]
			total_mean = total_mean + PROFILER.world_tick[i]
		end

		local rect_data = profile_rect:subrect(0, 0, profile_rect.width / 2, 25, "left", "up")
		if total_mean > 0 then
			ut.color_coded_percentage(mean_actions / total_mean, rect_data, false)
			rect_data.y = rect_data.y + 25
			ut.color_coded_percentage(mean_events / total_mean, rect_data, false)
			rect_data.y = rect_data.y + 25
			ut.color_coded_percentage(mean_provinces / total_mean, rect_data, false)
			rect_data.y = rect_data.y + 25
		
			ut.data_entry(observed_logs_length .. " daily ticks: ", ut.to_fixed_point2(total_mean), rect_data)
		end		
	end
end

-- #################
-- ### MAP MODES ###
-- #################
gam.map_mode_data = {}
gam.map_mode_tabs = {}
gam.map_mode_selected_tab = "all"
gam.map_mode_tabs.all = {}
gam.map_mode_tabs.debug = {}
require "game.scenes.game.map-modes".set_up_map_modes(gam)

---Given a tile coordinate, returns x/y coordinates on a texture to write!
---@param tile Tile
function gam.tile_id_to_color_coords(tile)
	local tile_id = tile.tile_id
	local ws = WORLD.world_size
	local tile_utils = require "game.entities.tile"

	local x, y, f = tile_utils.index_to_coords(tile_id)

	local fx = 0
	local fy = 0
	if f == 0 then
		-- nothing to do!
	elseif f == 1 then
		fx = ws
	elseif f == 2 then
		fx = 2 * ws
	elseif f == 3 then
		fy = ws
	elseif f == 4 then
		fy = ws
		fx = ws
	elseif f == 5 then
		fy = ws
		fx = 2 * ws
	else
		error("Invalid face: " .. tostring(f))
	end

	return x + fx, y + fy
end

---Changes the map mode to a new one
---@param new_map_mode string Valid map mode ID
function gam.update_map_mode(new_map_mode)
	gam.map_mode = new_map_mode
	gam.refresh_map_mode()
	CACHED_MAP_MODE = new_map_mode
end

local function neighbor_data(tile)
	local up_neigh = tile.get_neighbor(tile, 1)
	local down_neigh = tile.get_neighbor(tile, 2)
	local right_neigh = tile.get_neighbor(tile, 3)
	local left_neigh = tile.get_neighbor(tile, 4)
	local r = 0
	local g = 0
	local b = 0
	local a = 0
	if up_neigh.province ~= tile.province then
		r = 1
	end
	if down_neigh.province ~= tile.province then
		g = 1
	end
	if right_neigh.province ~= tile.province then
		b = 1
	end
	if left_neigh.province ~= tile.province then
		a = 1
	end
	return r, g, b, a
end

local function neighbor_neighbor_data(tile)
	local up_neigh = tile.get_neighbor(tile, 1)
	local down_neigh = tile.get_neighbor(tile, 2)
	local right_neigh = tile.get_neighbor(tile, 3)
	local left_neigh = tile.get_neighbor(tile, 4)

	local up_r, up_g, up_b, up_a = neighbor_data(up_neigh)
	local down_r, down_g, down_b, down_a = neighbor_data(down_neigh)
	local right_r, right_g, right_b, right_a = neighbor_data(right_neigh)
	local left_r, left_g, left_b, left_a = neighbor_data(left_neigh)

	local r = (up_r + down_r + right_r + left_r) / 4
	local g = (up_g + down_g + right_g + left_g) / 4
	local b = (up_b + down_b + right_b + left_b) / 4
	local a = (up_a + down_a + right_a + left_a) / 4

	return r, g, b, a
end

function gam.recalculate_province_map()
	local dim = WORLD.world_size * 3
	gam.tile_province_image_data = gam.tile_province_image_data or love.image.newImageData(dim, dim, "rgba8")
	gam.tile_neighbor_provinces_data = gam.tile_neighbor_provinces_data or love.image.newImageData(dim, dim, "rgba8")
	for _, tile in pairs(WORLD.tiles) do
		local x, y = gam.tile_id_to_color_coords(tile)
		if tile.province then
			local r = tile.province.r
			local g = tile.province.g
			local b = tile.province.b
			gam.tile_province_image_data:setPixel(x, y, r, g, b, 1)
		end

		local r, g, b, a = neighbor_data(tile)

		if (math.max(r, g, b, a) < 0.1) then
			r, g, b, a = neighbor_neighbor_data(tile)
		end

		gam.tile_neighbor_provinces_data:setPixel(x, y, r, g, b, a)
	end

	gam.tile_province_texture = love.graphics.newImage(gam.tile_province_image_data, {
		mipmaps = false,
		linear = true
	})
	gam.tile_province_texture:setFilter("nearest", "nearest")

	gam.tile_neighbor_provinces_texture = love.graphics.newImage(gam.tile_neighbor_provinces_data, {
		mipmaps = false,
		linear = true
	})
	gam.tile_neighbor_provinces_texture:setFilter("nearest", "nearest")
end

function gam.recalculate_raiding_targets_map()
	local dim = WORLD.world_size * 3
	gam.tile_raiding_targets_image_data = love.image.newImageData(dim, dim, "rgba8")
	
	gam.tile_raiding_targets_texture = love.graphics.newImage(gam.tile_raiding_targets_image_data, {
		mipmaps = false,
		linear = true
	})
	gam.tile_raiding_targets_texture:setFilter("nearest", "nearest")
end

---Refreshes the map mode
function gam.refresh_map_mode(preserve_efficiency)
	local tim = love.timer.getTime()

	-- if not OPTIONS.update_map then
	-- 	return
	-- end

	if not preserve_efficiency then
		gam.selected_building_type = nil
	end

	print(gam.map_mode)
	local dat = gam.map_mode_data[gam.map_mode]
	local func = dat[4]
	func(gam.clicked_tile_id) -- set "real color" on tiles

	local province = nil
	local best_eff = 0
	if (gam.clicked_tile) then
		province = gam.clicked_tile.province
		if province and gam.selected_building_type then
			for _, p_tile in pairs(province.tiles) do
				if not p_tile.tile_improvement then
					best_eff = math.max(best_eff, gam.selected_building_type.production_method:get_efficiency(p_tile))
				end
			end
		end
	end

	-- Apply the color
	for _, tile in pairs(WORLD.tiles) do
		local can_set = true
		local player_character = WORLD.player_character
		if player_character and player_character.realm then
			can_set = false
			if player_character.realm.known_provinces[tile.province] then
				can_set = true
			end
		end
		local x, y = gam.tile_id_to_color_coords(tile)
		if can_set then
			local r = tile.real_r
			local g = tile.real_g
			local b = tile.real_b
			gam.tile_color_image_data:setPixel(x, y, r, g, b, 1)
            if tile.tile_improvement and gam.map_mode == "atlas" then
                gam.tile_improvement_texture_data:setPixel(x, y, 1, 0, 0, 1)
            else 
                gam.tile_improvement_texture_data:setPixel(x, y, 0, 0, 0, 1)
            end

			if gam.selected_building_type ~= nil then
				if tile.tile_improvement then
					gam.tile_color_image_data:setPixel(x, y, 0.4, 0.5, 0.9, 1)
				else
					local eff = gam.selected_building_type.production_method:get_efficiency(tile)
					local r, g, b = political.hsv_to_rgb(eff * 90, 0.4, math.min(eff / 3 + 0.2))
					gam.tile_color_image_data:setPixel(x, y, r, g, b, 1)

					if tile.province == province and eff == best_eff then
						local r, g, b = political.hsv_to_rgb(eff * 90, 1, 1)
						gam.tile_color_image_data:setPixel(x, y, r, g, b, 1)
					end
				end
			end
		else
			gam.tile_color_image_data:setPixel(x, y, 0.15, 0.15, 0.15, -1)
		end
	end
	-- Update the texture
	gam.tile_color_texture = love.graphics.newImage(gam.tile_color_image_data)
	gam.tile_color_texture:setFilter("nearest", "nearest")
    
    gam.tile_improvement_texture = love.graphics.newImage(gam.tile_improvement_texture_data)
    gam.tile_improvement_texture:setFilter("nearest", "nearest")
    
	-- Update the minimap
	gam.minimap = require "game.minimap".make_minimap()

	local time = love.timer.getTime() - tim
	print("Map mode update time: " .. tostring(time * 1000) .. "ms")
end

return gam
