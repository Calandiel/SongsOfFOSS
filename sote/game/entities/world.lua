local world = {}

local decide = require "game.ai.decide"

local plate_utils = require "game.entities.plate"
local utils       = require "game.ui-utils"

---@alias ActionData { [1]: Event, [2]: Realm, [3]: table, [4]: number}

---@class World
---@field player_realm Realm?
---@field player_character Character?
---@field player_province Province?
---@field sub_hourly_tick number
---@field hour number
---@field day number
---@field month number
---@field year number
---@field world_size number
---@field tiles table<number, Tile>
---@field plates table<number, Plate>
---@field provinces table<number, Province>
---@field settled_provinces table<Province, Province>
---@field settled_provinces_by_identifier table<number, table<Province, Province>>
---@field realms table<number, Realm>
---@field climate_cells table<number, ClimateCell>
---@field climate_grid_size number number of climate grid cells along a grid edge
---@field tile_count fun(self:World):number returns number of tiles
---@field random_tile fun(self:World):Tile returns a random tile
---@field new_plate fun(self:World):Plate creates and returns a new plate
---@field new fun(self:World):World
---@field entity_counter number -- a global counter for entities...
---@field tick fun(self:World)
---@field emit_notification fun(self:World, notification:string)
---@field emit_event fun(self:World, event:Event, target:Realm, associated_data:table|nil, delay: number|nil)
---@field emit_action fun(self:World, event:Event, origin: Realm, target:Realm, associated_data:table|nil, delay: number, hidden: boolean)
---@field emit_immediate_event fun(self:World, event:Event, target:Realm, associated_data:table|nil)
---@field notification_queue Queue
---@field events_queue Queue
---@field deferred_events_queue Queue
---@field deferred_actions_queue Queue
---@field player_deferred_actions table<ActionData, ActionData>
---@field treasury_effects Queue
---@field old_treasury_effects Queue
---@field emit_treasury_change_effect fun(self:World, amount:number, reason: string, character_flag: boolean?)
---@field pending_player_event_reaction boolean
---@field does_player_control_realm fun(self:World, realm:Realm?):boolean
---@field does_player_see_realm_news fun(self:World, realm:Realm):boolean
--- RAWS
---@field biomes_by_name table<string, Biome>
---@field biomes_load_order table<number, Biome>
---@field bedrocks_by_name table<string, Bedrock>
---@field bedrocks_by_color table<number, Bedrock>
---@field biogeographic_realms_by_name table<string, BiogeographicRealm>
---@field biogeographic_realms_by_color table<number, BiogeographicRealm>
---@field races_by_name table<string, Race>
---@field building_types_by_name table<string, BuildingType>
---@field trade_goods_by_name table<string, TradeGood>
---@field jobs_by_name table<string, Job>
---@field technologies_by_name table<string, Technology>
---@field production_methods_by_name table<string, ProductionMethod>
---@field resources_by_name table<string, Resource>
---@field decisions_by_name table<string, DecisionRealm>
---@field decisions_characters_by_name table<string, DecisionCharacter>
---@field events_by_name table<string, Event>
---@field unit_types_by_name table<string, UnitType>
---@field base_visibility fun(self:World, size: number):number

---@type World
world.World = {}
world.World.__index = world.World

---Returns a new World object
---@return World
function world.World:new()
	---@type World
	local w = {}

	-- require the tile file to make sure that the tile was declared...
	local tile = require "game.entities.tile"
	local cells = require "game.entities.climate-cell"

	-- Register classes and stuff...
	local ws = DEFINES.world_size

	w.tiles = {}
	w.plates = {}
	w.provinces = {}
	w.settled_provinces = {}
	w.settled_provinces_by_identifier = {}
	for i = 1, 30 do
		w.settled_provinces_by_identifier[i] = {}
	end
	w.realms = {}
	w.climate_cells = {}
	w.entity_counter = 2
	w.world_size = ws
	w.climate_grid_size = 256
	w.sub_hourly_tick = 0
	w.hour = 0
	w.day = 0
	w.month = 0
	w.year = 0
	w.player_realm = nil
	w.pending_player_event_reaction = false
	w.notification_queue = require "engine.queue":new()
	w.events_queue = require "engine.queue":new()
	w.deferred_events_queue = require "engine.queue":new()
	w.deferred_actions_queue = require "engine.queue":new()
	w.player_deferred_actions = {}
	w.treasury_effects = require "engine.queue":new()
	w.old_treasury_effects =require "engine.queue":new()

	for tile_id = 1, 6 * ws * ws do
		table.insert(w.tiles, tile.Tile:new(tile_id))
	end
	for cell = 1, w.climate_grid_size * w.climate_grid_size do
		table.insert(w.climate_cells, cells.ClimateCell:new(cell))
	end
	local ut = require "game.climate.utils"
	---@type World|nil
	WORLD = w
	for _, tile in pairs(w.tiles) do
		ut.set_climate_cell(tile)
	end

	w.building_types_by_name = {}
	w.biomes_by_name = {}
	w.biomes_load_order = {}
	w.bedrocks_by_name = {}
	w.bedrocks_by_color = {}
	w.biogeographic_realms_by_name = {}
	w.biogeographic_realms_by_color = {}
	w.races_by_name = {}
	w.trade_goods_by_name = {}
	w.jobs_by_name = {}
	w.technologies_by_name = {}
	w.production_methods_by_name = {}
	w.resources_by_name = {}
	w.decisions_by_name = {}
	w.decisions_characters_by_name = {}
	w.events_by_name = {}
	w.unit_types_by_name = {}
	setmetatable(w, self)
	return w
end

function world.World:base_visibility(size)
	return self.races_by_name['human'].visibility * WORLD.unit_types_by_name["raiders"].visibility * size
end

---Returns number of tiles in the world
---@return number
function world.World:tile_count()
	return self.world_size * self.world_size * 6
end

---Returns a randomly selected tile
---@return Tile
function world.World:random_tile()
	local tc = self:tile_count()
	return self.tiles[love.math.random(tc)]
end

---Creates and returns a new plate
---@return Plate
function world.World:new_plate()
	return plate_utils.Plate:new()
end

---Creates a new, empty world and writes it to the `WORLD` global
function world.empty()
	print("World allocated!")
	world.World:new()
end

---Given a file, saves the world
---@param file string
function world.save(file)
	--love.filesystem.newFile(file)
	print("Saving?" .. file)
	local bs = require "engine.bitser"
	print("Processing starts...")
	bs.dumpLoveFile(file, WORLD) -- when it crashes its just a stack overflow due to province neighbors
	print("Processing ends!")
end

---Given a file, loads the world and assigns it to the WORLD global
---@param file any
function world.load(file)
	local bs = require "engine.bitser"
	---@type World|nil
	WORLD = bs.loadLoveFile(file)
end

---Schedules an event
---@param event Event
---@param target_realm Realm
---@param associated_data table
---@param delay number|nil In days
function world.World:emit_event(event, target_realm, associated_data, delay)
	if delay then
		self.deferred_events_queue:enqueue({
			event, target_realm, associated_data, delay
		})
	else
		self.events_queue:enqueue({
			event, target_realm, associated_data
		})
	end
end

---Schedules an event immediately
---@param event Event
---@param target_realm Realm
---@param associated_data table
function world.World:emit_immediate_event(event, target_realm, associated_data)
	self.events_queue:enqueue_front({
		event, target_realm, associated_data
	})
end

---Schedules an action (actions are events but we execute their "on trigger" instead of showing them and asking AI for reaction)
---@param event Event
---@param origin Realm
---@param target_realm Realm
---@param associated_data table
---@param delay number In days
---@param hidden boolean
function world.World:emit_action(event, origin, target_realm, associated_data, delay, hidden)
	local action_data = {
		event,
		target_realm, 
		associated_data, 
		delay
	}
	self.deferred_actions_queue:enqueue(action_data)
	if WORLD:does_player_see_realm_news(origin) and not hidden then
		self.player_deferred_actions[action_data] = action_data
	end	
end

local function handle_event(event, target_realm, associated_data)
	-- Handle the event here
	-- First, find the best option
	local opts = event:options(target_realm, associated_data)
	local best = opts[1]
	local best_am = 0
	for _, o in pairs(opts) do
		---@type EventOption
		local oo = o
		if oo.viable() then
			local pre = oo.ai_preference()
			if pre > best_am then
				best_am = pre
				best = oo
			end
		end
	end
	if best.viable() then
		best.outcome()
	end
end

---Performs a single tick update.
function world.World:tick()
	WORLD.pending_player_event_reaction = false
	local counter = 0
	while WORLD.events_queue:length() > 0 do
		counter = counter + 1
		-- Read the event data to check it
		local ev = WORLD.events_queue:peek()
		---@type Event
		local eve = ev[1]
		---@type Realm
		local rea = ev[2]
		local dat = ev[3]

		if WORLD:does_player_control_realm(rea) then
			-- This is a player event!
			WORLD.pending_player_event_reaction = true
			return
		else
			WORLD.events_queue:dequeue()
			handle_event(eve, rea, dat)
		end

		--if counter > 10000 then
		--	print("FAIL! " .. tostring(WORLD.events_queue:length()))
		--end
		--print("event")
	end

	WORLD.sub_hourly_tick = WORLD.sub_hourly_tick + 1
	if WORLD.sub_hourly_tick == world.ticks_per_hour then
		WORLD.sub_hourly_tick = 0
		WORLD.hour = WORLD.hour + 1
		-- hourly tick

		if WORLD.hour == 24 then
			WORLD.hour = 0
			WORLD.day = WORLD.day + 1
			-- daily tick

			-- events
			local l = WORLD.deferred_events_queue:length()
			for i = 1, l do
				--print("def. event" .. tostring(i))
				local check = WORLD.deferred_events_queue:dequeue()
				check[4] = check[4] - 1
				if check[4] <= 0 then
					-- Reemit the event as a "real" even!
					WORLD:emit_event(check[1], check[2], check[3])
					--print("ontrig")
				else
					WORLD.deferred_events_queue:enqueue(check)
				end
			end

			-- actionas
			local l = WORLD.deferred_actions_queue:length()
			for i = 1, l do
				--print("def. action " .. tostring(i))
				local check = WORLD.deferred_actions_queue:dequeue()
				check[4] = check[4] - 1
				if check[4] <= 0 then
					---@type Event
					local event = check[1]
					event:on_trigger(check[2], check[3])
					--print("ontrig")
					self.player_deferred_actions[check] = nil
				else
					WORLD.deferred_actions_queue:enqueue(check)
				end
				--print("donedef. action " .. tostring(i))
			end

			if WORLD.settled_provinces_by_identifier[WORLD.day] ~= nil then
				-- Monthly tick per realm
				local ta = WORLD.settled_provinces_by_identifier[WORLD.day]

				-- "Realm" pre-update
				local realm_economic_update = require "game.economy.realm-economic-update"
				for _, settled_province in pairs(ta) do
					if settled_province.realm.capitol == settled_province then
						--print("Econ prerun")
						realm_economic_update.prerun(settled_province.realm)
					end
				end

				-- "POP" update
				local pop_growth = require "game.society.pop-growth"
				for _, settled_province in pairs(ta) do
					--print("Pop growth")
					pop_growth.growth(settled_province)
				end

				-- "Province" update
				local employ = require "game.economy.employment"
				local production = require "game.economy.production-and-consumption"
				local wealth_decay = require "game.economy.wealth-decay"
				local upkeep = require "game.economy.upkeep"
				local infrastructure = require "game.economy.province-infrastructure"
				local research = require "game.society.research"
				local recruit = require "game.society.recruitment"
				for _, settled_province in pairs(ta) do
					--print("employ")
					employ.run(settled_province)
					production.run(settled_province)
					upkeep.run(settled_province)
					wealth_decay.run(settled_province)
					infrastructure.run(settled_province)
					research.run(settled_province)
					recruit.run(settled_province)
					--print("done")
				end

				-- "Realm" update
				-- local decide = require "game.ai.decide"
				local events = require "game.ai.events"
				local education = require "game.society.education"
				local court = require "game.society.court"
				local construct = require "game.ai.construction"
				for _, settled_province in pairs(ta) do
					local realm = settled_province.realm
					if realm ~= nil and settled_province.realm.capitol == settled_province then
						-- Run the realm AI once a month
						if not WORLD:does_player_control_realm(realm) then
							local explore = require "game.ai.exploration"
							local treasury = require "game.ai.treasury"
							local military = require "game.ai.military"
							explore.run(realm)
							treasury.run(realm)
							military.run(realm)
						else
							self:emit_treasury_change_effect(0, "new month")
						end
						--print("Construct")
						construct.run(realm) -- This does an internal check for "AI" control to construct buildings for the realm but we keep it here so that we can have prettier code for POPs constructing buildings instead!
						--print("Court")
						court.run(realm)
						--print("Edu")
						education.run(realm)
						--print("Econ")
						realm_economic_update.run(realm)
						-- Handle events!
						--print("Event handling")
						events.run(realm)


						-- assign warbands to patrols
						for _, province in pairs(realm.provinces) do
							for _, warband in pairs(province.warbands) do
								if (warband.status == "idle") and (love.math.random() > 0.5) and (warband:size() > 0) then
									realm:add_patrol(province, warband)
								end
							end
						end

						-- launch patrols
						for _, target in pairs(realm.provinces) do
							local warbands = realm.patrols[target]
							local units = 0
							if warbands ~= nil then
								for _, warband in pairs(warbands) do
									units = units + warband:size()
								end
							end
							-- launch the patrol
							if (units > 0) then
								MilitaryEffects.patrol(realm, target)
							end
						end

						-- assign raiders to targets
						for _, province in pairs(realm.provinces) do
							for _, warband in pairs(province.warbands) do
								if warband.status == "idle" and warband:size() > 0 then
									local target = realm:roll_reward_flag()
									realm:add_raider(target, warband)
								end
							end
						end

						-- launch raids
						for _, target in pairs(realm.reward_flags) do
							local warbands = realm.raiders_preparing[target]
							local units = 0
							for _, warband in pairs(warbands) do
								units = units + warband:size()
							end
							
							-- with some probability, launch the raid
							-- larger groups launch raids faster
							if (units > 0) and (love.math.random() > 0.5 + 1 / (units + 10)) then
								MilitaryEffects.covert_raid(realm, target)
							end
						end


						-- Run AI decisions at the very end (they're moddable, it'll be better to do them last...)
						if not WORLD:does_player_control_realm(realm) then
							--print("Decide")
							decide.run(realm)
						end
					end
				end

				
				for _, settled_province in pairs(ta) do
					for _, character in pairs(settled_province.characters) do
						if character ~= WORLD.player_character then
							decide.run_character(character)
						end			
					end
				end
			end

			if WORLD.day == 31 then
				WORLD.day = 0
				WORLD.month = WORLD.month + 1
				-- monthly tick
				--print("Monthly tick")
				if WORLD.month == 12 then
					WORLD.month = 0
					WORLD.year = WORLD.year + 1
					-- yearly tick
					--print("Yearly tick!")
					local pop_aging = require "game.society.pop-aging"
					for _, settled_province in pairs(WORLD.provinces) do
						pop_aging.age(settled_province)
					end
				end

				--
				--print("Monthly tick end, refreshing")
				require "game.scenes.game".refresh_map_mode()
				--print("Refresh finished")
			end
		end
		--print("tick end")
	end
end

---Emits a notification
---@param notification string
function world.World:emit_notification(notification)
	local date = tostring(WORLD.day) .. ' ' .. utils.months[WORLD.month + 1] .. ' of ' .. tostring(WORLD.year)
	self.notification_queue:enqueue(date .. ':  ' .. notification)
end

---Emits a treasury change to player
---@param amount number
---@param reason EconomicReason
---@param character_flag boolean?
function world.World:emit_treasury_change_effect(amount, reason, character_flag)
	if character_flag == nil then
		character_flag = false
	end
	self.treasury_effects:enqueue({amount = amount, reason = reason, day = self.day, month = self.month, year = self.year, character_flag = character_flag})
end

function world.World:does_player_control_realm(realm)
	return (realm ~= nil) and (self.player_character == realm.leader) and (self.player_character ~= nil)
end

function world.World:does_player_see_realm_news(realm)
	return (self.player_realm == realm) and (self.player_realm ~= nil)
end

world.ticks_per_hour = 120

return world
