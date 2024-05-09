---@alias MapModeEntry { [1]: string, [2]: string, [3]: string, [4]: fun(clicked_tile_id: number), [5]: MAP_MODE_GRANULARITY, [6]: MAP_MODE_UPDATES_TYPE, [7]: fun()|nil }

---@class (exact) GameScene
---@field macrobuilder_public_mode boolean
---@field tile_inspector_tab TileInspectorTabs | nil
---@field realm_inspector_tab RealmInspectorTabs | nil
---@field realm_stockpile_scrollbar number
---@field realm_capacities_scrollbar number
---@field wars_slider_level number
---@field selected Selection
---@field show_map_mode_panel boolean
---@field map_mode_slider number
---@field game_canvas love.Canvas
---@field planet_mesh love.Mesh
---@field planet_shader love.Shader
---@field map_mode_data table<string, MapModeEntry>
---@field map_mode_tabs table TODO difficult to untangle, port to Teal
---@field init fun()
---@field handle_zoom fun()
---@field on_tile_click fun()
---@field _refresh_map_mode fun(async_flag: boolean?)
---@field debug_ui fun()
---@field paused boolean
---@field ticks_without_map_update number
---@field speed number
---@field camera_lock boolean
---@field turbo boolean
---@field handle_camera_controls fun()
---@field click_callback fun() | nil
---@field update_map_mode fun(string, async_flag: boolean?)
---@field map_update_progress number
---@field refresh_map_mode fun(async_flag: boolean?)
---@field map_mode string TODO this should be a map mode enum...
---@field camera_position any TODO type porting cpml is hell...
---@field tile_id_to_color_coords fun(Tile):number,number
---@field time_since_last_tick number
---@field load_camera_position_or_set_to_default fun()
---@field locked_screen_x number
---@field locked_screen_y number
---@field draw fun()
---@field click_tile fun(number)
---@field clicked_tile_id number
---@field clicked_tile Tile
---@field reset_decision_selection fun()
---@field notification_slider number
---@field outliner_slider number
---@field minimap love.Image
---
---@field recalculate_realm_map fun(update_all?: boolean)
---@field tile_neighbor_realm_data love.ImageData
---@field tile_neighbor_realm_texture love.Texture
---
---@field tile_color_texture love.Image
---@field tile_color_image_data love.ImageData
---@field tile_color_image_data_temp love.ImageData
---
---@field empty_texture_image_data love.ImageData
---@field empty_texture love.Image
---
---@field province_empty_data love.ImageData
---@field province_empty_texture love.Image
---
---@field _recalculate_province_texture fun()
---@field tile_province_id_data love.ImageData
---@field tile_province_id_texture love.Image
---
---@field _refresh_provincial_map_mode fun(use_secondary: boolean?, async_flag: boolean?)
---@field province_color_data_temp love.ImageData
---@field province_color_data love.ImageData
---@field province_color_texture love.Image
---
---@field _refresh_fog_of_war fun(async_flag: boolean?)
---@field fog_of_war_data love.ImageData
---@field fog_of_war_texture love.Image
---
---@field _refresh_mixed_map_mode fun(async_flag: boolean?)
---
---@field TILE_MAP_MODE_CACHE table<string, love.Image>
---@field TILE_MAP_MODE_DATA_CACHE table<string, love.ImageData>
---@field PROVINCE_MAP_MODE_CACHE table<string, love.Image>
---@field PROVINCE_MAP_MODE_DATA_CACHE table<string, love.ImageData>
---
---@field tile_neighbor_provinces_data love.ImageData
---@field tile_neighbor_provinces_texture love.Texture
---
---@field tile_province_texture love.Image
---@field tile_province_image_data love.ImageData
---
---@field update fun(number)
---@field outliner boolean
---@field map_mode_selected_tab MapModeTab
---@field inspector nil | InspectorType | MenuTypes
---@field recalculate_province_map fun()
---@field map_update_coroutine nil | thread
---@field recalculate_raiding_targets_map fun()
---@field decision_target_primary any TODO this is difficult to untangle, port to Teal to fix it
---@field decision_target_secondary any TODO this is difficult to untangle, port to Teal to fix it
---
---@field REALMS_NEIGBOURS_TEST_CACHE {[1]: number, [2]: number, [3]: number, [4]: number}[]
---@field BORDER_TILES_CACHE table<Tile, Tile>
---@field recalculate_smooth_data_map fun(data_function: TileForm, data_id: string, provinces_to_update: table<Province, Province>|Province[]|nil, direct_neigbours_weight: number?, secondary_neighbour_weight: number?)
---@field DATA_CACHE table<string, love.ImageData>
---@field DATA_TEXTURES_CACHE table<string, love.Image>
local gam = {}

---@alias TileForm fun(origin_tile: Tile, tile: Tile): number


---@alias InspectorType 'characters' | 'treasury-ledger' | 'character' | 'tile' | 'realm' | 'building' | 'war' | 'army' | 'character-decisions' | 'market' | 'population' | 'macrobuilder' | 'macrodecision' | 'warband' | 'property' | 'quests'
---@alias MenuTypes 'options' | 'confirm-exit' | 'preferences'
---@alias MapModeTab 'all' | 'debug' | 'demographic' | 'economic' | 'political'

---@alias TileInspectorTabs "GEN"
---@alias RealmInspectorTabs "GEN"

require "game.scenes.global-style"

local ui = require "engine.ui"

local cpml = require "cpml"
local world = require "game.entities.world"
local cube = require "game.cube"
local tile = require "game.entities.tile"
local tb = require "game.scenes.game.top-bar"
local callback = require "game.scenes.callbacks"
local tabb = require "engine.table"
local political = require "game.map-modes.political"
local mmut = require "game.map-modes.utils"

local plate_gen = require "game.world-gen.plate-gen"


local inspectors_table = {
	["characters"] = require "game.scenes.game.inspector-province-characters",
	["treasury-ledger"] = require "game.scenes.game.inspector-treasury-ledger",
	["character"] = require "game.scenes.game.inspector-character",
	["tile"] = require "game.scenes.game.tile-inspector",
	["realm"] = require "game.scenes.game.realm-inspector",
	["building"] = require "game.scenes.game.building-inspector",
	["war"] = require "game.scenes.game.war-inspector",
	["options"] = require "game.scenes.main-menu.options",
	["confirm-exit"] = require "game.scenes.game.confirm-exit",
	["army"] = require "game.scenes.game.inspector-military",
	["character-decisions"] = require "game.scenes.game.inspector-character-decisions",
	["market"] = require "game.scenes.game.inspectors.market",
	["population"] = require "game.scenes.game.inspectors.population",
	["macrobuilder"] = require "game.scenes.game.inspectors.macrobuilder",
	["macrodecision"] = require "game.scenes.game.inspectors.macrodecision",
	["warband"] = require "game.scenes.game.inspectors.warband",
	["property"] = require "game.scenes.game.inspectors.property",
	["preferences"] = require "game.scenes.game.inspectors.character_stance",
	["quests"] = require "game.scenes.game.inspectors.quests"
}

local tile_inspectors = {
	["tile"] = true,
	["realm"] = true,
	["market"] = true,
	["population"] = true,
	["character"] = true
}



---@class (exact) Selection
---@field character Character?
---@field tile Tile?
---@field province Province?
---@field realm Realm?
---@field building_type BuildingType?
---@field building Building?
---@field macrobuilder_building_type BuildingType?
---@field war War?
---@field warband Warband?
---@field decision DecisionCharacter?
---@field macrodecision DecisionCharacterProvince?
---@field tech Technology?
---@field cached_tech Technology?

gam.selected = {}

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

			local climate_cell = WORLD.tile_to_climate_cell[tile]
			print("Climate Cell")
			tab.print(climate_cell)

			local la, lo = tile:latlon()
			print(la, lo)
			local utt = require "game.climate.utils"
			local x, y = utt.get_x_y(climate_cell.cell_id)
			local cla, clo = utt.latitude(y), utt.longitude(x)
			print(cla, clo)

			if tile.biome ~= nil then
				print("Biome:", tile.biome.name)
			else
				print("Biome:", nil)
			end

			if tile:province() then
				print("Foragers limit: ", tile:province().foragers_limit)
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
	-- global variable for events
	PAUSE_REQUESTED = false

	gam.show_map_mode_panel = false -- for rendering the panel
	gam.map_mode_slider = 0      -- for the map mode slider
	gam.game_canvas = love.graphics.newCanvas()
	gam.planet_mesh = require "game.scenes.game.planet".get_planet_mesh()
	gam.planet_shader = require "game.scenes.game.planet-shader".get_shader()
	gam.paused = true
	gam.ticks_without_map_update = 0

	gam.TILE_MAP_MODE_CACHE = {}
	gam.PROVINCE_MAP_MODE_CACHE = {}
	gam.TILE_MAP_MODE_DATA_CACHE = {}
	gam.PROVINCE_MAP_MODE_DATA_CACHE = {}

	gam.speed = 1
	gam.turbo = false

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

	-- Setup render textures for map modes
	local ws = WORLD.world_size
	local dim = ws * 3
	local imd = love.image.newImageData(dim, dim, "rgba8")
	for x = 1, dim do
		for y = 1, dim do
			imd:setPixel(x - 1, y - 1, 0.1, 0.1, 0.1, 1)
		end
	end
	gam.tile_color_image_data_temp = imd
	gam.tile_color_image_data = imd
	gam.tile_color_texture = love.graphics.newImage(imd)

	-- Empty texture for faster map mode switching
	gam.empty_texture_image_data = love.image.newImageData(dim, dim, "rgba8")
	for x = 1, dim do
		for y = 1, dim do
			gam.empty_texture_image_data:setPixel(x - 1, y - 1, 1, 1, 1, 1)
		end
	end
	gam.empty_texture = love.graphics.newImage(gam.empty_texture_image_data)

	-- A sanity check before we proceed further
	if WORLD.province_count > 256 * 256 then
		error(
			"Province count (" ..
			tostring(WORLD.province_count) ..
			") is larger than maximum province id texture size (" ..
			tostring(256 * 256) ..
			")! If you see this error message, please, notify the developers.")
	end

	-- Texture for empty province data for faster map mode switching
	gam.province_empty_data = love.image.newImageData(256, 256, "rgba8")
	for x = 1, 256 do
		for y = 1, 256 do
			gam.province_empty_data:setPixel(x - 1, y - 1, 1, 1, 1, 1)
		end
	end
	gam.province_empty_texture = love.graphics.newImage(gam.province_empty_data)

	gam.tile_province_id_data = love.image.newImageData(dim, dim, "rgba8")
	gam.tile_province_id_texture = love.graphics.newImage(gam.tile_province_id_data)
	gam.tile_province_id_texture:setFilter("nearest", "nearest")

	gam.fog_of_war_data = love.image.newImageData(256, 256, "rgba8")
	for x = 1, 256 do
		for y = 1, 256 do
			gam.fog_of_war_data:setPixel(x - 1, y - 1, 0.15, 0.15, 0.15, 1)
		end
	end
	gam.fog_of_war_texture = love.graphics.newImage(gam.fog_of_war_data)
	gam.fog_of_war_texture:setFilter("nearest", "nearest")

	gam.province_color_data_temp = love.image.newImageData(256, 256, "rgba8")
	gam.province_color_data = gam.province_color_data_temp
	gam.province_color_texture = love.graphics.newImage(gam.province_color_data)
	gam.province_color_texture:setFilter("nearest", "nearest")

	gam.BORDER_TILES_CACHE = {}

	gam._recalculate_province_texture()

	gam.REALMS_NEIGBOURS_TEST_CACHE = {}
	gam.DATA_CACHE = {}
	gam.DATA_TEXTURES_CACHE = {}

	gam.recalculate_realm_map(true)

	gam.refresh_map_mode(false)
	gam.click_tile(-1)

	gam.minimap = require "game.minimap".make_minimap(gam, nil, nil, false)

	for map_mode, _ in pairs(gam.map_mode_data) do
		if _[6] ~= mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC then
			gam.update_map_mode(map_mode, false)
		end
	end

	gam.update_map_mode('elevation', true)
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

--- The amount of time within a frame that can be spent on calculations in the update function
---@type number
local timer_threshold = 1 / 120

---@return boolean should_cancel_update Whether or not the calculations are proceeding and require returning in the update function
local function handle_map_refresh()
	if gam.map_update_coroutine ~= nil then
		local time = love.timer.getTime()
		while love.timer.getTime() - time < timer_threshold do
			coroutine.resume(gam.map_update_coroutine)
			if coroutine.status(gam.map_update_coroutine) == "dead" then
				gam.map_update_coroutine = nil
				goto stop_update
			end
		end
		::stop_update::
		return true
	end
	return false
end

gam.time_since_last_tick = 0
---@param dt number
function gam.update(dt)
	-- Handle map updates
	if handle_map_refresh() then
		return
	end

	if PAUSE_REQUESTED then
		gam.paused = true
		PAUSE_REQUESTED = false
	end

	if gam.paused and gam.ticks_without_map_update > world.ticks_per_hour * 24 * 10 then
		gam.ticks_without_map_update = 0
		gam.refresh_map_mode()

		if WORLD.realms_changed then
			gam.recalculate_realm_map()
		end
	end

	gam.speed = gam.speed or 1
	gam.time_since_last_tick = gam.time_since_last_tick + dt
	if gam.time_since_last_tick > 1 / 30 then
		gam.time_since_last_tick = 0
		if gam.paused ~= nil and not gam.paused and gam.selected.decision == nil and
			WORLD.pending_player_event_reaction == false then
			-- the game is unpaused, call tick on world!
			--print("-- tick start --")
			local start = love.timer.getTime()
			if gam.turbo then
				while true do
					WORLD:tick()
					if love.timer.getTime() - start > 1 / 10 then
						break
					end
				end
			else
				for _ = 1, 4 ^ gam.speed do
					WORLD:tick()
					gam.ticks_without_map_update = gam.ticks_without_map_update + 1
					if love.timer.getTime() - start > timer_threshold then
						break
					end
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

gam.locked_screen_x = 0
gam.locked_screen_y = 0

function gam.handle_camera_controls()
	local ui = require "engine.ui"
	if not gam.camera_lock then
		if gam.camera_position == nil then
			print("!!! Weird error during hot loading... Camera position was set to nil")
			gam.load_camera_position_or_set_to_default()
		end
		-- Handle camera controls...
		local up = up_direction
		---@type number
		local camera_speed = (gam.camera_position:len() - 0.75) * 0.0015
		if ui.is_key_held('lshift') then
			camera_speed = camera_speed * 3
		end
		if ui.is_key_held('lctrl') then
			camera_speed = camera_speed / 6
		end
		local mouse_zoom_sensor_size = 3
		local mouse_x, mouse_y = ui.mouse_position()
		--print(ui.mouse_position())

		if ui.is_mouse_pressed(2) then
			gam.locked_screen_x = mouse_x
			gam.locked_screen_y = mouse_y
		end

		local rotation_up = 0
		local rotation_right = 0

		local screen_x, screen_y = ui.get_reference_screen_dimensions()

		CACHED_CAMERA_POSITION = gam.camera_position
		if ui.is_mouse_held(2) then
			local len = gam.camera_position:len()

			rotation_up = (mouse_y - gam.locked_screen_y) / screen_y * len * len / 2
			rotation_right = (mouse_x - gam.locked_screen_x) / screen_x * len * len

			gam.locked_screen_x = mouse_x
			gam.locked_screen_y = mouse_y
		end

		if rotation_right ~= 0 or rotation_up ~= 0 then
			gam.camera_position = gam.camera_position:rotate(-rotation_right, up)
			local rot = gam.camera_position:cross(up)
			gam.camera_position = gam.camera_position:rotate(-rotation_up, rot)
		end

		camera_speed = camera_speed * OPTIONS['camera_sensitivity']

		if ui.is_key_held('a') or (mouse_x < mouse_zoom_sensor_size and mouse_x > -5) then
			gam.camera_position = gam.camera_position:rotate(-camera_speed, up)
		end
		if ui.is_key_held('d') or (mouse_x > screen_x - mouse_zoom_sensor_size and mouse_x <= screen_x + 5) then
			gam.camera_position = gam.camera_position:rotate(camera_speed, up)
		end
		if ui.is_key_held('w') or (mouse_y < mouse_zoom_sensor_size and mouse_y > -5) then
			local rot = gam.camera_position:cross(up)
			gam.camera_position = gam.camera_position:rotate(-camera_speed, rot)
		end
		if ui.is_key_held('s') or (mouse_y > screen_y - mouse_zoom_sensor_size and mouse_y <= screen_y + 5) then
			local rot = gam.camera_position:cross(up)
			gam.camera_position = gam.camera_position:rotate(camera_speed, rot)
		end

		-- At the end, perform a sanity check to avoid entering polar regions
		if gam.camera_position:normalize():sub(cpml.vec3.new(0, 1, 0)):len() < 0.01 or
			gam.camera_position:normalize():sub(cpml.vec3.new(0, -1, 0)):len() < 0.01 then
			gam.camera_position = CACHED_CAMERA_POSITION
		else
			CACHED_CAMERA_POSITION = gam.camera_position
		end
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
		-- We handle scrollin with two passes.
		-- First, we handle q/e, then we modify the zoom speed and handle the mouse wheel.
		-- We do it because the q/e are significantly faster than mouse wheel movement and need separate handling.
		local zoom_speed = 0.001 * OPTIONS['zoom_sensitivity']
		if ui.is_key_held('lshift') then
			zoom_speed = zoom_speed * 3
		end
		if ui.is_key_held('lctrl') then
			zoom_speed = zoom_speed / 6
		end
		if ui.is_key_held('e') then
			gam.camera_position = gam.camera_position * (1 + zoom_speed)
			local l = gam.camera_position:len()
			if l > 3 then
				gam.camera_position = gam.camera_position:normalize() * 3
			end
		end
		if ui.is_key_held('q') then
			gam.camera_position = gam.camera_position * (1 - zoom_speed)
			local l = gam.camera_position:len()
			if l < 1.015 then
				gam.camera_position = gam.camera_position:normalize() * 1.015
			end
		end
		zoom_speed = zoom_speed * 15
		if (ui.mouse_wheel() < 0) then
			gam.camera_position = gam.camera_position * (1 + zoom_speed)
			local l = gam.camera_position:len()
			if l > 3 then
				gam.camera_position = gam.camera_position:normalize() * 3
			end
		end
		if (ui.mouse_wheel() > 0) then
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

	if gam.clicked_tile then
		gam.selected.province = gam.clicked_tile:province()
	end

	gam.reset_decision_selection()
	---@type Tile
	if require "engine.table".contains(ARGS, "--dev") then
		CLICKED_TILE_GLOBAL = WORLD.tiles[tile_id]
	end
end

function gam.reset_decision_selection()
	gam.decision_target_primary = nil
	gam.decision_target_secondary = nil
	gam.selected.decision = nil
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
		gam.paused = true
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
	if gam.planet_shader:hasUniform("province_colors") then
		gam.planet_shader:send('province_colors', gam.province_color_texture)
	end
	if gam.planet_shader:hasUniform("fog_of_war") then
		gam.planet_shader:send('fog_of_war', gam.fog_of_war_texture)
	end
	if gam.planet_shader:hasUniform("province_index") then
		gam.planet_shader:send('province_index', gam.tile_province_id_texture)
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
		if gam.tile_neighbor_provinces_texture == nil then
			gam.recalculate_province_map()
		end
		gam.planet_shader:send('tile_neighbor_province', gam.tile_neighbor_provinces_texture)
	end

	if gam.planet_shader:hasUniform("tile_corner_neighbor_realm") then
		if gam.DATA_TEXTURES_CACHE["tile_corner_neighbor_realm"] == nil then
			gam.recalculate_realm_map()
		end
		gam.planet_shader:send('tile_corner_neighbor_realm', gam.DATA_TEXTURES_CACHE["tile_corner_neighbor_realm"])
	end

	if gam.planet_shader:hasUniform("tile_corner_neighbor_realm") then
		if gam.tile_neighbor_realm_texture == nil then
			gam.recalculate_realm_map()
		end
		gam.planet_shader:send('tile_neighbor_realm', gam.tile_neighbor_realm_texture)
	end

	--- example of usage of recalculate_smooth_data_map
	--[[
	if gam.planet_shader:hasUniform("tile_sea") then
		if gam.DATA_TEXTURES_CACHE["sea"] == nil then
			gam.recalculate_smooth_data_map(sea, "sea")
		end
		gam.planet_shader:send("tile_sea", gam.DATA_TEXTURES_CACHE["sea"])
	end
	--]]

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

	local starting_call_point = coll_point:clone()

	local refx, refy = ui.get_reference_screen_dimensions()
	local size = 35

	local rect_for_icons = ui.rect(0, 0, size, size)

	---comment
	---@param tile Tile
	---@return number
	---@return number
	---@return number
	local function tile_to_x_y(tile)
		local lat, lon = tile:latlon()
		local ll = require "game.latlon"
		local cartx, carty, cartz = ll.lat_lon_to_cart(lat, lon)
		coll_point.x = cartx
		coll_point.y = carty
		coll_point.z = cartz
		local cart = coll_point
		local vv = vp * cart
		vv.x = vv.x / 2
		vv.y = vv.y / 2
		vv.z = vv.z / 2
		local x = (vv.x + 0.5) * refx
		local y = (vv.y + 0.5) * refy

		local z = gam.camera_position:dot(cart)

		return x, y, z
	end

	local draw_distance = 1.075
	local flood_fill = 200

	if coll_point and (gam.camera_position:len() < draw_distance) then
		local draw_tile = function(tile)
			---@type Tile
			local tile = tile
			local x, y = tile_to_x_y(tile)

			local province_visible = true
			local character = WORLD.player_character
			if character and character.realm then
				province_visible = false
				if character.realm.known_provinces[tile:province()] then
					province_visible = true
				end
			end
			if (tile.is_land and province_visible) then
				rect_for_icons.x = x - size / 2
				rect_for_icons.y = y - size / 2
				if tile.resource then
					ui.image(ASSETS.get_icon(tile.resource.icon), rect_for_icons)
				end
			end

			return false
		end

		---@type table<Province, Province>
		local visited = {}
		---@type Queue<Province>
		local qq = require "engine.queue":new()
		local to_draw = flood_fill
		local center_tile = WORLD.tiles
			[tile.cart_to_index(starting_call_point.x, starting_call_point.y, starting_call_point.z)]
		visited[center_tile:province()] = center_tile:province()
		qq:enqueue(center_tile:province())
		while qq:length() > 0 and to_draw > 0 do
			to_draw = to_draw - 1
			local td = qq:dequeue()

			for _, data in ipairs(td.local_resources_location) do
				draw_tile(data[1])
			end

			for _, n in pairs(td.neighbors) do
				if visited[n] then
				else
					visited[n] = n
					qq:enqueue(n)
				end
			end
		end
	end

	if coll_point and ((gam.camera_position:len() < draw_distance) or (gam.inspector == 'macrobuilder') or (gam.inspector == 'macrodecision')) then
		province_on_map_interaction = true
		---comment
		---@param province Province
		---@param mode 'path' | 'label' | 'decision' | 'macrobuilder'
		local function draw_province(province, mode)
			-- sanity checks
			local visibility = true
			if WORLD.player_character then
				visibility = false
				if WORLD.player_character.realm.known_provinces[province] then
					visibility = true
				end
			end

			if not visibility then
				return
			end

			local tile = province.center

			-- if not province.realm then
			-- 	return
			-- end

			-- get screen coordinates
			local x, y, z = tile_to_x_y(tile)
			rect_for_icons.x = x - size / 2
			rect_for_icons.y = y - size / 2
			rect_for_icons.width = size
			rect_for_icons.height = size

			-- check if on screen
			if x < -refx * 0.1 or x > 1.1 * refx or y < -refy * 0.1 or y > 1.1 * refy then
				return
			end

			-- check if on the opposite side of the globe
			if z < 0 then
				return
			end

			-- draw
			local result = nil
			if mode == "path" then
				local decision = gam.selected.macrodecision
				if decision == nil then
					return
				end
				local player = WORLD.player_character
				if player == nil then
					return
				end

				if not decision.clickable(player, province) then
					return
				end

				if decision.path == nil then
					return
				end

				local hours, path = decision.path(player, province)

				if path then
					table.insert(path, player.province)
					result = require "game.scenes.game.widgets.onmap.path" (gam, rect_for_icons, hours, path, tile_to_x_y)
				end
			end

			if mode == "label" then
				result = require "game.scenes.game.widgets.onmap.province" (gam, tile, rect_for_icons, x, y, size)
			end

			if mode == "decision" then
				result = require "game.scenes.game.widgets.onmap.decision" (gam, tile, rect_for_icons)
			end

			if mode == "macrobuilder" then
				result = require "game.scenes.game.widgets.onmap.macrobuilder" (gam, tile, rect_for_icons, x, y, size)
			end

			if result then
				gam.click_callback = result
			else
				province_on_map_interaction = false
			end
		end

		-- drawing provinces
		if gam.inspector == 'macrodecision' then
			local character = WORLD.player_character
			if character then
				for _, province in pairs(character.realm.known_provinces) do
					draw_province(province, 'path')
				end
				for _, province in pairs(character.realm.known_provinces) do
					draw_province(province, 'decision')
				end
			end
		elseif gam.inspector == 'macrobuilder' then
			local character = WORLD.player_character
			if character then
				for _, province in pairs(character.realm.known_provinces) do
					draw_province(province, 'macrobuilder')
				end
			end
		else
			---@type Province[]
			local provinces_to_draw = {}

			---@type table<Province, Province>
			local visited = {}
			---@type Queue<Province>
			local qq = require "engine.queue":new()
			local to_draw = flood_fill
			local center_tile = WORLD.tiles
				[tile.cart_to_index(starting_call_point.x, starting_call_point.y, starting_call_point.z)]
			visited[center_tile:province()] = center_tile:province()
			qq:enqueue(center_tile:province())
			while qq:length() > 0 and to_draw > 0 do
				to_draw = to_draw - 1
				local td = qq:dequeue()

				local x, y, z = tile_to_x_y(td.center)

				rect_for_icons.x = x - size / 2
				rect_for_icons.y = y - size / 2
				rect_for_icons.width = size
				rect_for_icons.height = size
				--
				table.insert(provinces_to_draw, td)
				for _, n in pairs(td.neighbors) do
					if visited[n] then
					else
						visited[n] = n
						qq:enqueue(n)
					end
				end
			end

			table.sort(provinces_to_draw, function(a, b)
				local x1, y1, z1 = tile_to_x_y(a.center)
				local x2, y2, z2 = tile_to_x_y(b.center)
				return (z2 - z1) > 0
			end)

			for _, province in ipairs(provinces_to_draw) do
				-- draw an icon on map
				local tile = province.center

				local visibility = true
				if WORLD.player_character then
					visibility = false
					if WORLD.player_character.realm.known_provinces[province] then
						visibility = true
					end
				end

				if province.realm and visibility then
					-- get screen coordinates
					local x, y, z = tile_to_x_y(tile)
					rect_for_icons.x = x - size / 2
					rect_for_icons.y = y - size / 2
					rect_for_icons.width = size
					rect_for_icons.height = size

					ui.image(ASSETS.get_icon('village.png'), rect_for_icons)
				end
			end

			for _, province in ipairs(provinces_to_draw) do
				draw_province(province, "label")
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
			local outliner_panel = fs:subrect(0, ut.BASE_HEIGHT * 10, ut.BASE_HEIGHT * 17, ut.BASE_HEIGHT * 6, "right",
				'up')
			if ui.trigger(outliner_panel) then
				gam.click_callback = callback.nothing()
			end
			gam.notification_slider = require "game.scenes.game.widgets.news" (notif_panel, gam.notification_slider)
			gam.outliner_slider = require "game.scenes.game.widgets.outliner" (outliner_panel, gam.outliner_slider)

			local outliner_rect = outliner_panel:subrect(0, 0, ut.BASE_HEIGHT * 3, ut.BASE_HEIGHT * 1, "left", 'down')

			if ui.text_button('Collapse', outliner_rect, "Hide outliner") then
				gam.outliner = false
				gam.click_callback = callback.nothing()
			end
		else
			local outliner_rect = fs:subrect(0, ut.BASE_HEIGHT, ut.BASE_HEIGHT * 3, ut.BASE_HEIGHT * 1, "right", 'up')

			if ui.text_button('Outliner', outliner_rect, "Show outliner") then
				gam.outliner = true
				gam.show_map_mode_panel = false
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

	local map_mode_bar = bottom_right_main_layout:next(300, UI_STYLE.square_button_large)
	local map_mode_bar_layout = ui.layout_builder()
		:horizontal()
		:position(map_mode_bar.x, map_mode_bar.y)
		:build()
	if ut.icon_button(
			ASSETS.icons["plain-arrow.png"],
			map_mode_bar_layout:next(UI_STYLE.square_button_large, UI_STYLE.square_button_large),
			"Show all map modes"
		) then
		gam.show_map_mode_panel = true
		gam.outliner = false
		gam.click_callback = callback.nothing()
	end

	if ut.icon_button(
			ASSETS.icons[gam.map_mode_data['atlas'][2]],
			map_mode_bar_layout:next(UI_STYLE.square_button_large, UI_STYLE.square_button_large), gam.map_mode_data['atlas'][3]) then
		gam.click_callback = callback.update_map_mode(gam, "atlas")
	end
	if ut.icon_button(
			ASSETS.icons[gam.map_mode_data['diplomacy'][2]],
			map_mode_bar_layout:next(UI_STYLE.square_button_large, UI_STYLE.square_button_large), gam.map_mode_data['diplomacy'][3]) then
		gam.click_callback = callback.update_map_mode(gam, "diplomacy")
	end
	if ut.icon_button(
			ASSETS.icons[gam.map_mode_data['elevation'][2]],
			map_mode_bar_layout:next(UI_STYLE.square_button_large, UI_STYLE.square_button_large), gam.map_mode_data['elevation'][3]) then
		gam.click_callback = callback.update_map_mode(gam, "elevation")
	end
	if ut.icon_button(
			ASSETS.icons[gam.map_mode_data['biomes'][2]],
			map_mode_bar_layout:next(UI_STYLE.square_button_large, UI_STYLE.square_button_large), gam.map_mode_data['biomes'][3]) then
		gam.click_callback = callback.update_map_mode(gam, "biomes")
	end
	if ut.icon_button(
			ASSETS.icons[gam.map_mode_data['koppen'][2]],
			map_mode_bar_layout:next(UI_STYLE.square_button_large, UI_STYLE.square_button_large), gam.map_mode_data['koppen'][3]) then
		gam.click_callback = callback.update_map_mode(gam, "koppen")
	end

	-- Map modes tab
	if gam.show_map_mode_panel then
		local ttab = require "engine.table"
		local mm_panel_height = ut.BASE_HEIGHT * (22)
		local panel = bottom_right_main_layout:next(300, mm_panel_height)
		if ui.trigger(panel) then
			gam.click_callback = callback.nothing()
		end
		ui.panel(panel)

		-- bottom right for closing the panel
		if ut.icon_button(ASSETS.icons["cancel.png"], panel:subrect(
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

		local all_active = gam.map_mode_selected_tab == 'all'
		if ut.text_button("ALL", top_panels[1], "All", not all_active, all_active) then
			gam.click_callback = callback.nothing()
			gam.map_mode_selected_tab = 'all'
		end

		local pol_active = gam.map_mode_selected_tab == 'political'
		if ut.text_button("POL", top_panels[2], "Political", not pol_active, pol_active) then
			gam.click_callback = callback.nothing()
			gam.map_mode_selected_tab = 'political'
		end

		local dem_active = gam.map_mode_selected_tab == 'demographic'
		if ut.text_button("DEM", top_panels[3], "Demographic", not dem_active, dem_active) then
			gam.click_callback = callback.nothing()
			gam.map_mode_selected_tab = 'demographic'
		end

		local eco_active = gam.map_mode_selected_tab == 'economic'
		if ut.text_button("ECN", top_panels[4], "Economic", not eco_active, eco_active) then
			gam.click_callback = callback.nothing()
			gam.map_mode_selected_tab = 'economic'
		end

		local deb_active = gam.map_mode_selected_tab == 'debug'
		if ut.text_button("DEB", top_panels[7], "Debug", not deb_active, deb_active) then
			gam.click_callback = callback.nothing()
			gam.map_mode_selected_tab = 'debug'
		end

		local scrollview_rect = panel:subrect(0, 0, 300, mm_panel_height - ut.BASE_HEIGHT - 10, "right", 'down')
		local mms = gam.map_mode_tabs[gam.map_mode_selected_tab]

		gam.map_mode_slider = ut.scrollview(
			scrollview_rect,
			function(i, rect)
				local mm_key = mms[i]
				local mm_data = gam.map_mode_data[mm_key]
				if mm_data ~= nil then
					local button_rect = rect:copy()
					button_rect.width = button_rect.height
					if ut.icon_button(ASSETS.icons[
							mm_data[2]
							], button_rect,
							mm_data[3]
						) then
						gam.click_callback = callback.update_map_mode(gam, mm_key)
						gam.update_map_mode(mm_key)
					end
					rect.x = rect.x + rect.height
					rect.width = rect.width - rect.height
					ui.left_text(mm_data[1], rect)
				else
				end
			end,
			UI_STYLE.scrollable_list_large_item_height,
			ttab.size(mms),
			UI_STYLE.slider_width,
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

	local tile_data_viewable = true
	if WORLD.tiles[gam.clicked_tile_id] ~= nil then
		if WORLD.player_character ~= nil then
			local realm = WORLD.player_character.realm
			local current_pro = WORLD.player_character.province
			local pro = WORLD.tiles[gam.clicked_tile_id]:province()
			if realm then
				if (realm.known_provinces[pro] == nil) and (pro ~= current_pro) then
					tile_data_viewable = false
				end
			end
		end
	end

	local click_success = false
	if gam.inspector == nil then
		click_success = true
	else
		if tile_inspectors[gam.inspector] then
			if tile_data_viewable then
				click_success = inspectors_table[gam.inspector].mask(gam)
			else
				click_success = true
			end
		else
			click_success = inspectors_table[gam.inspector].mask(gam)
		end
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

			local realm = WORLD.tiles[new_clicked_tile]:province().realm

			if gam.inspector == "character" and realm then
				if WORLD.tiles[new_clicked_tile]:province().realm ~= nil then
					if gam.selected.character == realm.leader then
						gam.inspector = "tile"
					else
						gam.selected.character = realm.leader
					end
				end
			elseif gam.inspector == "realm" then
				if WORLD.tiles[new_clicked_tile]:province().realm ~= nil then
					if gam.selected.realm == WORLD.tiles[new_clicked_tile]:province().realm then
						-- If we double click a realm, change the inspector to tile
						gam.inspector = "tile"
					else
						gam.selected.realm = WORLD.tiles[new_clicked_tile]:province().realm
					end
				end
			elseif gam.inspector == "army" then
				if WORLD.tiles[new_clicked_tile]:province().realm ~= nil then
					if gam.selected.realm == WORLD.tiles[new_clicked_tile]:province().realm then
						-- If we double click a realm, change the inspector to tile
						gam.inspector = "tile"
					else
						gam.selected.province = WORLD.tiles[new_clicked_tile]:province()
					end
				end
			elseif tile_inspectors[gam.inspector] then

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

	if gam.inspector == "options" then
		local response = require "game.scenes.main-menu.options".draw()
		if response == "main" then
			gam.inspector = nil
		end
	elseif gam.inspector == "confirm-exit" then
		local response = require "game.scenes.game.confirm-exit".draw(gam)
		if response == true then
			---@type World|nil
			WORLD = nil -- drop the world so that it gets garbage collected..
			local manager = require "game.scene-manager"
			manager.transition("main-menu")
			return
		end

		if response == "stop" then
			return
		end
	else
		if tile_inspectors[gam.inspector] then
			if tile_data_viewable then
				inspectors_table[gam.inspector].draw(gam)
			end
		elseif gam.inspector then
			inspectors_table[gam.inspector].draw(gam)
		end
	end

	if ui.is_key_pressed('escape') then
		if gam.inspector == nil then
			gam.inspector = 'confirm-exit'
		else
			gam.inspector = nil
		end
	end

	-- DRAWING AN ARROW TOWARD PLAYERS PROVINCE
	local player = WORLD.player_character
	if player and gam.inspector == nil then
		local province = player.province
		if province then
			local lat, lon = province.center:latlon()
			local x, y, z = require "game.latlon".lat_lon_to_cart(lat, lon)
			local target = cpml.vec3.new(x, y, z)
			local plane_geodesic = gam.camera_position:cross(target)
			local geodesic_tangent = (plane_geodesic:cross(gam.camera_position)):normalize()

			local screen_projection = (projection * view * geodesic_tangent):normalize()

			local width, height = love.graphics.getDimensions()

			local x_screen = screen_projection.x * width / 20
			local y_screen = screen_projection.y * height / 20

			local norm = math.sqrt(x_screen * x_screen + y_screen * y_screen)

			local x_screen = x_screen / norm * 20
			local y_screen = y_screen / norm * 20

			local orthogonal_x_screen = -y_screen / 3
			local orthogonal_y_screen = x_screen / 3

			local triangle = {
				width / 2 + orthogonal_x_screen, height / 2 + orthogonal_y_screen,
				width / 2 + x_screen, height / 2 + y_screen,
				width / 2 - orthogonal_x_screen, height / 2 - orthogonal_y_screen
			}


			local r, g, b, a = love.graphics.getColor()

			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.polygon('fill', triangle)
			love.graphics.setColor(0, 0, 0, 1)
			love.graphics.polygon('line', triangle)

			love.graphics.setColor(r, g, b, a)
		end
	end


	if (gam.map_update_coroutine ~= nil) and (gam.map_update_progress ~= nil) then
		local loading_rect = ui.fullscreen():subrect(0, 100, 300, 50, "center", "up")
		ui.panel(loading_rect)
		local progress = 0
		if gam.map_mode_data[gam.map_mode][5] == mmut.MAP_MODE_GRANULARITY.TILE then
			progress = gam.map_update_progress / WORLD:tile_count() * 300
		elseif gam.map_mode_data[gam.map_mode][5] == mmut.MAP_MODE_GRANULARITY.PROVINCE then
			progress = gam.map_update_progress / WORLD.province_count * 300
		else
			progress = gam.map_update_progress / (WORLD.province_count + WORLD:tile_count()) * 300
		end
		local progress_bar = loading_rect:subrect(0, 0, progress, 50, "left", "up")
		local temporary_r = ui.style.panel_inside.r
		ui.style.panel_inside.r = 1.0
		ui.panel(progress_bar)
		ui.style.panel_inside.r = temporary_r

		ui.text("Updating the map...", loading_rect, "center", "center")
	end


	if PROFILE_FLAG then
		local profile_rect = ui.fullscreen():subrect(0, 0, 800, 300, "center", "center")
		ui.panel(profile_rect)

		local layout = ui.layout_builder()
			:position(profile_rect.x, profile_rect.y)
			:spacing(0)
			:grid(4)
			:build()

		local tick_time = PROFILER.data["tick"] or 1

		for tag, value in pairs(PROFILER.data) do
			if value / tick_time > 0.005 then
				ut.data_entry_percentage(tag, value / tick_time, layout:next(profile_rect.width / 4, 25), nil, false)
			end
		end

		ut.sqrt_number_entry("average tick", (PROFILER.mean["tick"] or 0) * 1000 * 1000,
			layout:next(profile_rect.width / 4, 25))

		if ut.text_button("RESET", layout:next(profile_rect.width / 4, 25)) then
			PROFILER:clear()
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
---@return number, number
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
---@param async_flag boolean|nil True by default
function gam.update_map_mode(new_map_mode, async_flag)
	if async_flag == nil then
		async_flag = true
	end

	gam.map_mode = new_map_mode
	gam.refresh_map_mode(async_flag)
	CACHED_MAP_MODE = new_map_mode
end

---@param tile Tile
---@return number
---@return number
---@return number
---@return number
local function neighbor_data(tile)
	local up_neigh = tile.get_neighbor(tile, 1)
	local down_neigh = tile.get_neighbor(tile, 2)
	local right_neigh = tile.get_neighbor(tile, 3)
	local left_neigh = tile.get_neighbor(tile, 4)
	local r = 0
	local g = 0
	local b = 0
	local a = 0
	if up_neigh:province() ~= tile:province() then
		r = 1
	end
	if down_neigh:province() ~= tile:province() then
		g = 1
	end
	if right_neigh:province() ~= tile:province() then
		b = 1
	end
	if left_neigh:province() ~= tile:province() then
		a = 1
	end
	return r, g, b, a
end

---@param tile Tile
---@return number
---@return number
---@return number
---@return number
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


---Returns 0 if both tiles are owned by same unique overlord and 1 otherwise
---@param tile1 Tile
---@param tile2 Tile
---@return integer
local function same_realm_test(tile1, tile2)
	local realm_1 = tile1:province().realm
	local realm_2 = tile2:province().realm

	if realm_1 == nil then
		if realm_2 == nil then
			return 0
		end
		return 1
	end

	if realm_2 == nil then
		return 1
	end

	local overlords_1 = realm_1:get_top_realm()
	local overlords_2 = realm_2:get_top_realm()

	if tabb.size(overlords_1) ~= tabb.size(overlords_2) then
		return 1
	end

	if realm_1 == realm_2 then
		return 0
	end

	if tabb.size(overlords_1) == 1 and tabb.size(overlords_2) == 1 then
		if tabb.nth(overlords_1, 1) == tabb.nth(overlords_2, 1) then
			return 0
		end
	end

	return 1
end

---Returns 1 in according channel if some border tile has a different overlord
---Returns 0 0 0 0 otherwise
---@param tile Tile
---@return integer
---@return integer
---@return integer
---@return integer
local function realm_neighbor_data(tile)
	if gam.REALMS_NEIGBOURS_TEST_CACHE[tile.tile_id] ~= nil then
		local r = gam.REALMS_NEIGBOURS_TEST_CACHE[tile.tile_id][1]
		local g = gam.REALMS_NEIGBOURS_TEST_CACHE[tile.tile_id][2]
		local b = gam.REALMS_NEIGBOURS_TEST_CACHE[tile.tile_id][3]
		local a = gam.REALMS_NEIGBOURS_TEST_CACHE[tile.tile_id][4]

		return r, g, b, a
	end

	-- retrieve tile neigbours
	local up_neigh = tile.get_neighbor(tile, 1)
	local down_neigh = tile.get_neighbor(tile, 2)
	local right_neigh = tile.get_neighbor(tile, 3)
	local left_neigh = tile.get_neighbor(tile, 4)

	-- set base color to black
	local r = same_realm_test(tile, up_neigh)
	local g = same_realm_test(tile, down_neigh)
	local b = same_realm_test(tile, right_neigh)
	local a = same_realm_test(tile, left_neigh)

	gam.REALMS_NEIGBOURS_TEST_CACHE[tile.tile_id] = { r, g, b, a }

	return r, g, b, a
end

---comment
---@param tile Tile
---@return number
---@return number
---@return number
---@return number
local function realm_neighbor_neighbor_data(tile)
	local up_neigh = tile.get_neighbor(tile, 1)
	local down_neigh = tile.get_neighbor(tile, 2)
	local right_neigh = tile.get_neighbor(tile, 3)
	local left_neigh = tile.get_neighbor(tile, 4)

	local up_r, up_g, up_b, up_a = realm_neighbor_data(up_neigh)
	local down_r, down_g, down_b, down_a = realm_neighbor_data(down_neigh)
	local right_r, right_g, right_b, right_a = realm_neighbor_data(right_neigh)
	local left_r, left_g, left_b, left_a = realm_neighbor_data(left_neigh)

	local r = (up_r + down_r + right_r + left_r) / 4
	local g = (up_g + down_g + right_g + left_g) / 4
	local b = (up_b + down_b + right_b + left_b) / 4
	local a = (up_a + down_a + right_a + left_a) / 4

	return r, g, b, a
end



function gam.recalculate_province_map()
	---@type table<Tile, Tile>
	gam.BORDER_TILES_CACHE = {}

	local dim = WORLD.world_size * 3

	gam.tile_province_image_data = gam.tile_province_image_data or love.image.newImageData(dim, dim, "rgba8")
	gam.tile_neighbor_provinces_data = gam.tile_neighbor_provinces_data or love.image.newImageData(dim, dim, "rgba8")

	---@type number[]
	local pointer = require("ffi").cast("uint8_t*", gam.tile_province_image_data:getFFIPointer())
	---@type number[]
	local pointer_neigbours = require("ffi").cast("uint8_t*", gam.tile_neighbor_provinces_data:getFFIPointer())

	for _, tile in pairs(WORLD.tiles) do
		local x, y = gam.tile_id_to_color_coords(tile)
		local pixel_index = x + y * dim

		if tile:province() then
			pointer[pixel_index * 4 + 0] = 255 * tile:province().r
			pointer[pixel_index * 4 + 1] = 255 * tile:province().g
			pointer[pixel_index * 4 + 2] = 255 * tile:province().b
			pointer[pixel_index * 4 + 3] = 255 * 1
		end

		local r, g, b, a = neighbor_data(tile)
		if (math.max(r, g, b, a) < 0.1) then
			r, g, b, a = neighbor_neighbor_data(tile)
		end

		if (math.max(r, g, b, a) >= 0.1) then
			gam.BORDER_TILES_CACHE[tile] = tile
		end

		pointer_neigbours[pixel_index * 4 + 0] = 255 * r
		pointer_neigbours[pixel_index * 4 + 1] = 255 * g
		pointer_neigbours[pixel_index * 4 + 2] = 255 * b
		pointer_neigbours[pixel_index * 4 + 3] = 255 * a
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

local function get_pair_index(embedding)
	if embedding[1] + embedding[3] == 2 then
		return 1
	end
	if embedding[3] + embedding[2] == 2 then
		return 2
	end
	if embedding[2] + embedding[4] == 2 then
		return 3
	end
	if embedding[4] + embedding[1] == 2 then
		return 4
	end
end

--- Takes scalar field on tiles and turns it into love.Image
--- which stores average values of a provided function on corners of tile in according channels
---@param data_function TileForm
---@param data_id string
---@param provinces_to_update table<Province, Province>|Province[]|nil
---@param direct_neigbours_weight number?
---@param secondary_neighbour_weight number?
function gam.recalculate_smooth_data_map(data_function, data_id, provinces_to_update, direct_neigbours_weight, secondary_neighbour_weight)
	local dim = WORLD.world_size * 3

	if direct_neigbours_weight == nil then
		direct_neigbours_weight = 1
	end

	if secondary_neighbour_weight == nil then
		secondary_neighbour_weight = 1
	end

	if provinces_to_update == nil then
		provinces_to_update = WORLD.provinces
	end

	local data = gam.DATA_CACHE[data_id]
	if data == nil then
		data = love.image.newImageData(dim, dim, "rgba8")
		gam.DATA_CACHE[data_id] = data
	end

	---@type number[]
	local pointer = require("ffi").cast("uint8_t*", data:getFFIPointer())

	print("calculating ", data_id)

	local corners = 0

	if TILE_FRIENDS == nil then
		TILE_FRIENDS = {}
	end

	for _, province in pairs(provinces_to_update) do
		for _, tile in pairs(province.tiles) do
			local current_tile_data = {0, 0, 0, 0}
			local x, y = gam.tile_id_to_color_coords(tile)
			local pixel_index = x + y * dim

			if TILE_FRIENDS[tile] ~= nil then
				for i = 1, 4 do
					local csum = 0
					local count = 3

					csum = csum + data_function(tile, tile)
					csum = csum + data_function(tile, TILE_FRIENDS[tile][i][2]) * direct_neigbours_weight
					csum = csum + data_function(tile, TILE_FRIENDS[tile][i][3]) * direct_neigbours_weight

					if TILE_FRIENDS[tile][i][4] ~= nil then
						csum = csum + data_function(tile, TILE_FRIENDS[tile][i][4]) * secondary_neighbour_weight
						count = count + 1
					end

					current_tile_data[i] = csum / count
				end

				goto save_data_to_texture_data
			end

			do
				local neighbours = {tile:get_neighbor(1), tile:get_neighbor(2), tile:get_neighbor(3), tile:get_neighbor(4)}

				TILE_FRIENDS[tile] = {{}, {}, {}, {}}

				local corner_flag = false
				local corner_pair = {0, 0, 0, 0}

				for n_index, neighbour in ipairs(neighbours) do
					for neighbour_of_neighour in neighbour:iter_neighbors() do
						if neighbour_of_neighour == tile then
							goto continue
						end
						local counter = 0
						local visiter_neigbours = {0, 0, 0, 0}

						-- how many neighbours of neighbours of neighbor are neighbours of initial tile
						for neighbour_of_neighour_of_neigbour in neighbour_of_neighour:iter_neighbors() do
							for _, cached_neighbour in ipairs(neighbours) do
								if cached_neighbour == neighbour_of_neighour_of_neigbour then
									counter = counter + 1
									visiter_neigbours[_] = 1
								end

								if neighbour_of_neighour_of_neigbour == tile then
									corner_flag = true
									corner_pair[n_index] = 1
								end
							end
						end

						if counter == 2 then
							local pair_index = get_pair_index(visiter_neigbours)
							current_tile_data[pair_index] = data_function(tile, tile)
							table.insert(TILE_FRIENDS[tile][pair_index], tile)
							for _, cached_neigbour in ipairs(neighbours) do
								if visiter_neigbours[_] == 1 then
									current_tile_data[pair_index] = current_tile_data[pair_index] + data_function(tile, cached_neigbour) * direct_neigbours_weight
									table.insert(TILE_FRIENDS[tile][pair_index], cached_neigbour)
								end
							end
							current_tile_data[pair_index] = current_tile_data[pair_index] + data_function(tile, neighbour_of_neighour) * secondary_neighbour_weight
							table.insert(TILE_FRIENDS[tile][pair_index], neighbour_of_neighour)
							current_tile_data[pair_index] = current_tile_data[pair_index] * 0.25
						end
						::continue::
					end
				end

				if corner_flag then
					corners = corners + 1
					local pair_index = get_pair_index(corner_pair)
					current_tile_data[pair_index] = data_function(tile, tile)
					table.insert(TILE_FRIENDS[tile][pair_index], tile)
					for _, cached_neigbour in pairs(neighbours) do
						if corner_pair[_] == 1 then
							current_tile_data[pair_index] = current_tile_data[pair_index] + data_function(tile, cached_neigbour) * direct_neigbours_weight
							table.insert(TILE_FRIENDS[tile][pair_index], cached_neigbour)
						end
					end
					current_tile_data[pair_index] = current_tile_data[pair_index] / 3
				end
			end

			::save_data_to_texture_data::

			pointer[pixel_index * 4 + 0] = 255 * current_tile_data[1]
			pointer[pixel_index * 4 + 1] = 255 * current_tile_data[2]
			pointer[pixel_index * 4 + 2] = 255 * current_tile_data[3]
			pointer[pixel_index * 4 + 3] = 255 * current_tile_data[4]
		end

	end


	gam.DATA_TEXTURES_CACHE[data_id] =
		love.graphics.newImage(data, {
			mipmaps = false,
			linear = true
		})

	gam.DATA_TEXTURES_CACHE[data_id]:setFilter("nearest", "nearest")
end

function gam.recalculate_realm_map(update_all)
	if update_all then
		gam.recalculate_smooth_data_map(same_realm_test, "tile_corner_neighbor_realm", nil, 0, 1)
	else
		gam.recalculate_smooth_data_map(same_realm_test, "tile_corner_neighbor_realm", WORLD.provinces_to_update_on_map, 0, 1)
	end

	-- sanity check:
	if tabb.size(gam.BORDER_TILES_CACHE) == 0 then
		gam.recalculate_province_map()
	end

	local dim = WORLD.world_size * 3
	gam.tile_neighbor_realm_data = gam.tile_neighbor_realm_data or love.image.newImageData(dim, dim, "rgba8")

	-- imageData has one byte per channel per pixel.
	---@type number[]
	local pointer_neigbours = require("ffi").cast("uint8_t*", gam.tile_neighbor_realm_data:getFFIPointer())

	local provinces_to_update = WORLD.provinces
	if update_all then
		print("UPDATING ALL REALM BORDERS")
	else
		print("UPDATING REALM BORDERS")
		provinces_to_update = WORLD.provinces_to_update_on_map
	end

	-- clear cached values
	for _, province in pairs(provinces_to_update) do
		for _, tile in pairs(province.tiles) do
			if gam.BORDER_TILES_CACHE[tile] == nil then
				goto continue
			end
			gam.REALMS_NEIGBOURS_TEST_CACHE[tile.tile_id] = nil
			::continue::
		end
	end

	for _, province in pairs(provinces_to_update) do
		for _, tile in pairs(province.tiles) do
			if gam.BORDER_TILES_CACHE[tile] == nil then
				goto continue
			end

			local x, y = gam.tile_id_to_color_coords(tile)
			local pixel_index = x + y * dim

			local r2, g2, b2, a2 = realm_neighbor_data(tile)
			if (math.max(r2, g2, b2, a2) < 0.1) then
				r2, g2, b2, a2 = realm_neighbor_neighbor_data(tile)
			end

			pointer_neigbours[pixel_index * 4 + 0] = 255 * r2
			pointer_neigbours[pixel_index * 4 + 1] = 255 * g2
			pointer_neigbours[pixel_index * 4 + 2] = 255 * b2
			pointer_neigbours[pixel_index * 4 + 3] = 255 * a2

			::continue::
		end
	end

	gam.tile_neighbor_realm_texture = love.graphics.newImage(gam.tile_neighbor_realm_data, {
		mipmaps = false,
		linear = true
	})
	gam.tile_neighbor_realm_texture:setFilter("nearest", "nearest")


	WORLD.realms_changed = false
	WORLD.provinces_to_update_on_map = {}
end

function gam.refresh_map_mode(async_flag)
	if async_flag == nil then
		async_flag = true
	end

	if WORLD.realms_changed then
		gam.recalculate_realm_map()
	end

	if gam.map_update_coroutine == nil then
		print('create map update coroutine')
		local function update_function()
			return
		end

		if gam.map_mode_data[gam.map_mode][5] == mmut.MAP_MODE_GRANULARITY.TILE then
			print("tile map mode")
			gam.map_update_progress = 0

			function update_function()
				gam.province_color_data = gam.province_empty_data
				gam.province_color_texture = gam.province_empty_texture
				gam._refresh_map_mode(async_flag)
				gam.minimap = require "game.minimap".make_minimap(gam, nil, nil, false)
			end
		elseif gam.map_mode_data[gam.map_mode][5] == mmut.MAP_MODE_GRANULARITY.PROVINCE then
			print("province map mode")
			gam.map_update_progress = 0

			function update_function()
				gam.tile_color_image_data = gam.empty_texture_image_data
				gam.tile_color_texture = gam.empty_texture
				gam._refresh_provincial_map_mode(false, async_flag)
				gam.minimap = require "game.minimap".make_minimap(gam, nil, nil, true)
			end

		elseif gam.map_mode_data[gam.map_mode][5] == mmut.MAP_MODE_GRANULARITY.MIXED then
			print("mixed map mode")
			gam.map_update_progress = 0

			function update_function()
				gam._refresh_mixed_map_mode(async_flag)
				gam.minimap = require "game.minimap".make_minimap(gam, nil, nil, true)
			end
		end

		if async_flag then
			gam.map_update_coroutine = coroutine.create(update_function)
		else
			update_function()
		end

		gam._refresh_fog_of_war(false)
	end
end

function gam._recalculate_province_texture()
	---@type number[]
	local pointer_province_id = require("ffi").cast("uint8_t*", gam.tile_province_id_data:getFFIPointer())

	local dim = WORLD.world_size * 3
	local id_r = 0
	local id_g = 0
	local id_b = 0

	for _, province in ipairs(WORLD.ordered_provinces_list) do
		for _, tile in pairs(province.tiles) do
			local x, y = gam.tile_id_to_color_coords(tile)
			local pixel_index = x + y * dim
			pointer_province_id[pixel_index * 4 + 0] = id_r
			pointer_province_id[pixel_index * 4 + 1] = id_g
			pointer_province_id[pixel_index * 4 + 2] = id_b
		end
		id_r = id_r + 1
		if id_r == 256 then
			id_r = 0
			id_g = id_g + 1
			if id_g == 256 then
				error("Too many provinces! The renderer cannot support this!")
			end
		end
	end

	gam.tile_province_id_texture = love.graphics.newImage(gam.tile_province_id_data)
	gam.tile_province_id_texture:setFilter("nearest", "nearest")
end

---commenting
---@param async_flag boolean|nil
function gam._refresh_mixed_map_mode(async_flag)
	gam._refresh_provincial_map_mode(true, async_flag)
	gam._refresh_map_mode(async_flag)
end

---Update province texture
---@param use_secondary boolean? Use secondary update function in map mode definition if true
---@param async_flag boolean|nil
function gam._refresh_provincial_map_mode(use_secondary, async_flag)
	if async_flag == nil then
		async_flag = true
	end
	local tim = love.timer.getTime()

	if gam.tile_neighbor_realm_data == nil then
		gam.recalculate_realm_map(true)
	end

	---@type number[]
	local pointer_province_color = require("ffi").cast("uint8_t*", gam.province_color_data_temp:getFFIPointer())
	gam.province_color_data = gam.province_color_data_temp

	print(gam.map_mode)
	local dat = gam.map_mode_data[gam.map_mode]

	if dat[6] == mmut.MAP_MODE_UPDATES_TYPE.STATIC then
		if gam.PROVINCE_MAP_MODE_CACHE[gam.map_mode] == nil then
			print("static map mode but not found in cache: recalculating province colors...")
			gam.PROVINCE_MAP_MODE_DATA_CACHE[gam.map_mode] = love.image.newImageData(256, 256, "rgba8")
			for x = 1, 256 do
				for y = 1, 256 do
					gam.PROVINCE_MAP_MODE_DATA_CACHE[gam.map_mode]:setPixel(x - 1, y - 1, 1, 1, 1, 1)
				end
			end
			pointer_province_color = require("ffi").cast("uint8_t*", gam.PROVINCE_MAP_MODE_DATA_CACHE[gam.map_mode]:getFFIPointer())
			gam.province_color_data = gam.PROVINCE_MAP_MODE_DATA_CACHE[gam.map_mode]
		else
			print("province map mode loaded from cache")
			gam.province_color_data = gam.PROVINCE_MAP_MODE_DATA_CACHE[gam.map_mode]
			gam.province_color_texture = gam.PROVINCE_MAP_MODE_CACHE[gam.map_mode]
			goto finalize
		end
	end

	do
		print("calculate province colors")
		local func = dat[4]
		if use_secondary then
			func = dat[7]
		end
		assert(func ~= nil, "Map mode " .. gam.map_mode .. " lacks requested update function")
		func(gam.clicked_tile_id) -- set "real color" on central tiles

		local id = 0

		print("update texture data")
		for _, province in ipairs(WORLD.ordered_provinces_list) do
			local can_set = true
			local player_character = WORLD.player_character
			if player_character and player_character.realm then
				can_set = false
				if player_character.realm.known_provinces[province] then
					can_set = true
				end
			end

			gam.map_update_progress = gam.map_update_progress + 1
			if async_flag and gam.map_update_progress % 100 == 0 then
				coroutine.yield(false)
			end

			local current_tile = province.center

			if can_set or gam.map_mode_data[gam.map_mode][6] == mmut.MAP_MODE_UPDATES_TYPE.STATIC then
				pointer_province_color[id * 4 + 0] = 255 * current_tile.real_r
				pointer_province_color[id * 4 + 1] = 255 * current_tile.real_g
				pointer_province_color[id * 4 + 2] = 255 * current_tile.real_b
				pointer_province_color[id * 4 + 3] = 255 * 1
			else
				--pointer_province_color[id * 4 + 0] = 255 * 0.15
				--pointer_province_color[id * 4 + 1] = 255 * 0.15
				--pointer_province_color[id * 4 + 2] = 255 * 0.15
				--pointer_province_color[id * 4 + 3] = 255 * 0
			end

			id = id + 1
		end

		print("generate texture from data")
		gam.province_color_texture = love.graphics.newImage(gam.province_color_data)
		gam.province_color_texture:setFilter("nearest", "nearest")

		if
			dat[6] == mmut.MAP_MODE_UPDATES_TYPE.STATIC
		then
			print("map mode was cached!")
			gam.PROVINCE_MAP_MODE_CACHE[gam.map_mode] = gam.province_color_texture
		end
	end

	::finalize::

	local time = love.timer.getTime() - tim
	print("Map mode update time: " .. tostring(time * 1000) .. "ms")

	if async_flag then
		coroutine.yield(true)
	end
end

---Refreshes the map mode
---@param async_flag boolean?
function gam._refresh_map_mode(async_flag)
	if async_flag == nil then
		async_flag = true
	end

	local tim = love.timer.getTime()

	-- Sanity check in case the function is called before init
	if gam.tile_neighbor_realm_data == nil then
		gam.recalculate_realm_map(true)
	end

	local dim = WORLD.world_size * 3
	---@type number[]
	local pointer_tile_color = require("ffi").cast("uint8_t*", gam.tile_color_image_data_temp:getFFIPointer())
	gam.tile_color_image_data = gam.tile_color_image_data_temp

	print(gam.map_mode)
	local dat = gam.map_mode_data[gam.map_mode]

	if
		dat[6] == mmut.MAP_MODE_UPDATES_TYPE.STATIC
		or dat[6] == mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC_PROVINCE_STATIC_TILE
	then
		if gam.TILE_MAP_MODE_CACHE[gam.map_mode] == nil then
			print("static map mode but not found in cache: recalculating tile colors...")
			local imd = love.image.newImageData(dim, dim, "rgba8")
			for x = 1, dim do
				for y = 1, dim do
					imd:setPixel(x - 1, y - 1, 0.1, 0.1, 0.1, 1)
				end
			end
			gam.TILE_MAP_MODE_DATA_CACHE[gam.map_mode] = imd
			pointer_tile_color = require("ffi").cast("uint8_t*", imd:getFFIPointer())
			gam.tile_color_image_data = imd
		else
			print("tile map mode loaded from cache")
			gam.tile_color_image_data = gam.TILE_MAP_MODE_DATA_CACHE[gam.map_mode]
			gam.tile_color_texture = gam.TILE_MAP_MODE_CACHE[gam.map_mode]
			goto finalize
		end
	end

	do
		local func = dat[4]
		func(gam.clicked_tile_id) -- set "real color" on tiles

		-- Apply the color

		for _, province in pairs(WORLD.provinces) do
			-- TODO: we should loop over provinces first so that visibility checks can happen for multiple provinces at once...
			local can_set = true
			local player_character = WORLD.player_character
			if player_character and player_character.realm then
				can_set = false
				if player_character.realm.known_provinces[province] then
					can_set = true
				end
			end
			for _, tile in pairs(province.tiles) do
				gam.map_update_progress = gam.map_update_progress + 1

				if async_flag and gam.map_update_progress % 1000 == 0 then
					coroutine.yield(false)
				end

				local x, y = gam.tile_id_to_color_coords(tile)
				local pixel_index = x + y * dim

				if can_set
					or gam.map_mode_data[gam.map_mode][6] == mmut.MAP_MODE_UPDATES_TYPE.STATIC
					or gam.map_mode_data[gam.map_mode][6] == mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC_PROVINCE_STATIC_TILE
				then
					local r = tile.real_r
					local g = tile.real_g
					local b = tile.real_b

					pointer_tile_color[pixel_index * 4 + 0] = 255 * r
					pointer_tile_color[pixel_index * 4 + 1] = 255 * g
					pointer_tile_color[pixel_index * 4 + 2] = 255 * b
					pointer_tile_color[pixel_index * 4 + 3] = 255 * 1
				else
					--pointer_tile_color[pixel_index * 4 + 0] = 255 * 0.15
					--pointer_tile_color[pixel_index * 4 + 1] = 255 * 0.15
					--pointer_tile_color[pixel_index * 4 + 2] = 255 * 0.15
					--pointer_tile_color[pixel_index * 4 + 3] = 255 * 0
				end
			end
		end
		-- Update the texture
		gam.tile_color_texture = love.graphics.newImage(gam.tile_color_image_data)
		gam.tile_color_texture:setFilter("nearest", "nearest")

		if
			dat[6] == mmut.MAP_MODE_UPDATES_TYPE.STATIC
			or dat[6] == mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC_PROVINCE_STATIC_TILE
		then
			gam.TILE_MAP_MODE_CACHE[gam.map_mode] = gam.tile_color_texture
		end
	end

	::finalize::

	local time = love.timer.getTime() - tim
	print("Map mode update time: " .. tostring(time * 1000) .. "ms")

	if async_flag then
		coroutine.yield(true)
	end
end

function gam._refresh_fog_of_war(async_flag)
	if async_flag == nil then
		async_flag = true
	end

	local tim = love.timer.getTime()

	---@type number[]
	local pointer_province_color = require("ffi").cast("uint8_t*", gam.fog_of_war_data:getFFIPointer())

	print("update fog of war")

	do
		local id = 0
		for _, province in ipairs(WORLD.ordered_provinces_list) do
			local can_set = true
			local player_character = WORLD.player_character
			if player_character and player_character.realm then
				can_set = false
				if player_character.realm.known_provinces[province] then
					can_set = true
				end
			end

			gam.map_update_progress = gam.map_update_progress + 1
			if async_flag then
				coroutine.yield(false)
			end

			if can_set then
				pointer_province_color[id * 4 + 3] = 0
			else
				pointer_province_color[id * 4 + 3] = 255
			end

			id = id + 1
		end

		print("generate texture from data")
		gam.fog_of_war_texture = love.graphics.newImage(gam.fog_of_war_data)
		gam.fog_of_war_texture:setFilter("nearest", "nearest")
	end


	local time = love.timer.getTime() - tim
	print("Fog of war update time: " .. tostring(time * 1000) .. "ms")

	if async_flag then
		coroutine.yield(true)
	end
end

return gam
