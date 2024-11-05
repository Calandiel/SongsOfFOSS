local world            = {}

local decide           = require "game.ai.decide"
local tile             = require "game.entities.tile"
local province_utils   = require "game.entities.province".Province
local warband_utils    = require "game.entities.warband"

local plate_utils      = require "game.entities.plate"
local utils            = require "game.ui-utils"

local military_effects = require "game.raws.effects.military"
local political_values = require "game.raws.values.politics"

local tabb             = require "engine.table"

local employ = require "game.economy.employment"
local building_update = require "game.economy.buildings-updates"
local production = require "game.economy.production-and-consumption"
local wealth_decay = require "game.economy.wealth-decay"
local upkeep = require "game.economy.upkeep"
local infrastructure = require "game.economy.province-infrastructure"
local research = require "game.society.research"
local recruit = require "game.society.recruitment"


local dbm              = require "game.economy.diet-breadth-model"

---@class (exact) DelayedEventData
---@field event_tag string
---@field root pop_id
---@field root_unique_id number
---@field event_data table|nil|number
---@field delay number

---@class (exact) PendingEventData
---@field event_tag string
---@field root pop_id
---@field root_unique_id number
---@field event_data table|nil|number

---@class (exact) PendingEventDisplay
---@field display_name string
---@field delay number

---@alias Notification string

---@class (exact) World
---@field __index World
---@field unique_id number
---@field player_character Character
---@field sub_hourly_tick number
---@field current_tick_in_month number
---@field current_tick_in_decade number
---@field hour number
---@field day number
---@field month number
---@field year number
---@field world_size number
---@field province_count number
---@field settled_provinces table<province_id, province_id>
---@field settled_provinces_by_identifier table<number, table<province_id, province_id>>
---@field climate_cells table<number, ClimateCell>
---@field tile_to_climate_cell table<tile_id, ClimateCell>
---@field climate_grid_size number number of climate grid cells along a grid edge
---@field entity_counter number -- a global counter for entities...
---@field notification_queue Queue<Notification>
---@field events_queue Queue<PendingEventData>
---@field deferred_events_queue Queue<DelayedEventData>
---@field deferred_actions_queue Queue<DelayedEventData>
---@field player_deferred_actions PendingEventDisplay[]
---@field treasury_effects Queue<TreasuryEffectRecord>
---@field old_treasury_effects Queue<TreasuryEffectRecord>
---@field pending_player_event_reaction boolean
---@field realms_changed boolean
---@field provinces_to_update_on_map table<province_id, province_id>

---@class World
world.World            = {}
world.World.__index    = world.World

---commenting
---@param w World
function world.reset_metatable(w)
	setmetatable(w, world.World)
	for _, item in pairs(w.climate_cells) do
		setmetatable(item, require "game.entities.climate-cell".ClimateCell)
	end

	local Queue = require "engine.queue"

	setmetatable(w.notification_queue, Queue)
	setmetatable(w.events_queue, Queue)
	setmetatable(w.deferred_events_queue, Queue)
	setmetatable(w.deferred_actions_queue, Queue)
	setmetatable(w.player_deferred_actions, Queue)
	setmetatable(w.treasury_effects, Queue)
	setmetatable(w.old_treasury_effects, Queue)

	--[[
	---@param container Queue
	---@param meta table
	local function reset_container_metatable(container, meta)
		for _, item in pairs(container) do
			setmetatable(item, meta)
		end
	end
	--]]
end



---Returns a new World object
---@return World
function world.World:new()
	---@type World
	local w = {}

	---@type World|nil
	WORLD = w

	-- require the tile file to make sure that the tile was declared...
	local tile_t = require "game.entities.tile"
	local cells = require "game.entities.climate-cell"

	-- Register classes and stuff...
	local ws = DEFINES.world_size

	w.unique_id = 1

	w.player_character = INVALID_ID

	w.settled_provinces = {}
	w.province_count = 0
	w.settled_provinces_by_identifier = {}

	w.climate_cells = {}
	w.tile_to_climate_cell = {}

	w.entity_counter = 2
	w.world_size = ws
	w.climate_grid_size = 256
	w.sub_hourly_tick = 0
	w.hour = 0
	w.day = 0
	w.month = 0
	w.year = 0
	w.current_tick_in_month = 0
	w.current_tick_in_decade = 0
	w.pending_player_event_reaction = false
	w.notification_queue = require "engine.queue":new()
	w.events_queue = require "engine.queue":new()
	w.deferred_events_queue = require "engine.queue":new()
	w.deferred_actions_queue = require "engine.queue":new()
	w.player_deferred_actions = {}
	w.treasury_effects = require "engine.queue":new()
	w.old_treasury_effects = require "engine.queue":new()

	w.realms_changed = false
	w.provinces_to_update_on_map = {}
	for tile_id = 1, 6 * ws * ws do
		tile_t.Tile:new(tile_id)
	end
	for cell = 1, w.climate_grid_size * w.climate_grid_size do
		table.insert(w.climate_cells, cells.ClimateCell:new(cell))
	end
	local ut = require "game.climate.utils"

	DATA.for_each_tile(function (item)
		w.tile_to_climate_cell[item] = ut.get_climate_cell(tile.latlon(item))
	end)
	setmetatable(w, self)
	return w
end

---@return number
function world.World:base_visibility(size)
	local humans_id = RAWS_MANAGER.races_by_name['human']
	local raiders = RAWS_MANAGER.unit_types_by_name["raiders"]

	return DATA.race_get_visibility(humans_id) * DATA.unit_type_get_visibility(raiders) * size
end

--- Set province as settled: it enables updates of this province.
---@param province province_id
function world.World:set_settled_province(province)
	self.settled_provinces[province] = province
	local _, lon = tile.latlon(DATA.province_get_center(province))
	lon = lon + math.pi
	lon = lon / math.pi
	lon = lon / 2
	local world_sections = world.ticks_per_hour * 24 * 30
	local timz = math.ceil(math.min(world_sections, math.max(0.001, lon * world_sections)))
	if self.settled_provinces_by_identifier[timz] == nil then
		self.settled_provinces_by_identifier[timz] = {}
	end
	self.settled_provinces_by_identifier[timz][province] = province
end

--- Unset province as settled: it disables updates of this province.
---@param province province_id
function world.World:unset_settled_province(province)
	self.settled_provinces[province] = nil
	local _, lon = tile.latlon(DATA.province_get_center(province))
	lon = lon + math.pi
	lon = lon / math.pi
	lon = lon / 2
	local world_sections = world.ticks_per_hour * 24 * 30
	local timz = math.ceil(math.min(world_sections, math.max(0.001, lon * world_sections)))
	self.settled_provinces_by_identifier[timz][province] = nil
end

---Returns number of tiles in the world
---@return number
function world.World:tile_count()
	return self.world_size * self.world_size * 6
end

---Returns a randomly selected tile
---@return tile_id
function world.World:random_tile()
	local tc = self:tile_count()

	return TILE_FROM_WORLD_ID[love.math.random(tc)]
end

---Creates and returns a new plate
---@return plate_id
function world.World:new_plate()
	return plate_utils.Plate:new()
end

---Creates a new, empty world and writes it to the `WORLD` global
function world.empty()
	print("World allocated!")
	world.World:new()
end

---Schedules an event
---@param event string
---@param root Character
---@param associated_data table|number|nil
---@param delay number|nil In days
---@param root_unique_id number|nil
function world.World:emit_event(event, root, associated_data, delay, root_unique_id)
	---#logging LOGS:write("emit event " .. event .. "\n")
	---#logging LOGS:flush()

	local uid = DATA.pop_get_unique_id(root)
	if root_unique_id ~= nil then
		uid = root_unique_id
	end

	assert(root ~= INVALID_ID, "Attempt to call event for invalid root")
	assert(root ~= nil, "Attempt to call event for nil root")

	if delay then
		---@type DelayedEventData
		local event_data = {
			event_tag = event,
			root = root,
			root_unique_id = uid,
			event_data = associated_data,
			delay = delay
		}

		self.deferred_events_queue:enqueue(event_data)
	else
		---@type PendingEventData
		local event_data = {
			event_tag = event,
			root = root,
			root_unique_id = uid,
			event_data = associated_data,
		}
		self.events_queue:enqueue(event_data)
	end
end

---Schedules an event immediately
---@param event string
---@param root Character
---@param associated_data table|nil|number
function world.World:emit_immediate_event(event, root, associated_data)
	assert(root ~= INVALID_ID, "Attempt to call event for invalid root")
	assert(root ~= nil, "Attempt to call event for nil root")

	if root == self.player_character then
		print('player event: ', event)
	end

	---@type PendingEventData
	local event_data = {
		event_tag = event,
		root = root,
		root_unique_id = DATA.pop_get_unique_id(root),
		event_data = associated_data,
	}

	self.events_queue:enqueue_front(event_data)
	self:event_tick(event, root, event_data.root_unique_id, associated_data)
end

---comment
---@param event string
---@param root POP
---@param associated_data table?
function world.World:emit_immediate_action(event, root, associated_data)
	if root == nil then
		error("Attempt to call action for nil root")
	end

	local event_data = RAWS_MANAGER.events_by_name[event]
	event_data:on_trigger(root, associated_data)
end

---Schedules an action (actions are events but we execute their "on trigger" instead of showing them and asking AI for reaction)
---@param event string
---@param root Character
---@param associated_data table|number|nil
---@param delay number In days
---@param hidden boolean
function world.World:emit_action(event, root, associated_data, delay, hidden)
	if root == nil then
		error("Cannot emit an action without a root!")
	end

	---@type DelayedEventData
	local event_data = {
		event_tag = event,
		root = root,
		root_unique_id = DATA.pop_get_unique_id(root),
		event_data = associated_data,
		delay = delay
	}

	-- print('add new action:' .. event)
	self.deferred_actions_queue:enqueue(event_data)
	if WORLD:does_player_see_realm_news(REALM(root)) and not hidden then
		---@type PendingEventDisplay
		local display = {
			display_name = event,
			delay = delay
		}

		table.insert(self.player_deferred_actions, display)
	end
end

---Handles events
---@param event string
---@param root POP
---@param unique_id number
---@param associated_data any
local function handle_event(event, root, unique_id, associated_data)
	-- Handle the event here

	-- LOGS:write(
	-- 	"\n Handling event: " .. event .. "\n" ..
	-- 	"root: " .. NAME(root) .. "(".. tostring(root) .. ")" .. "\n"
	-- )

	-- assert(PROVINCE(target_realm) ~= INVALID_ID, "INVALID PROVINCE")
	if RAWS_MANAGER.events_by_name[event] == nil then
		error(event .. " is not a valid event!")
	end

	assert(root ~= INVALID_ID, "CHARACTER DOES NOT EXIST")

	-- sanity check to weed out dead characters:
	if(DATA.pop_get_unique_id(root) ~= unique_id) then
		RAWS_MANAGER.events_by_name[event]:fallback(associated_data)
		return
	end

	-- First, find the best option
	local opts = RAWS_MANAGER.events_by_name[event]:options(root, associated_data)
	local best = opts[1]
	local best_am = nil
	---#logging LOGS:write("choosing option")
	for _, o in pairs(opts) do
		---@type EventOption
		local oo = o
		if oo.viable() then
			local pre = oo.ai_preference()

			assert(pre ~= nil, "Option " .. tostring(_) .. " of event " .. event .. " produced nil ai_preference")

			-- print(oo.text)
			-- print(oo.ai_preference())

			if (best_am == nil) or (pre > best_am) then
				best_am = pre
				best = oo
			end
		end
	end
	---#logging LOGS:write("implementing option " .. best.text .. "\n")
	---#logging LOGS:flush()
	if best.viable() then
		assert(best.outcome, "Option of event " .. event .. " doesn't have outcome")
		best.outcome()
	end
end

---Returns true if player event and false otherwise
---@param eve string
---@param root Character
---@param unique_id number
---@param dat any
---@return boolean
function world.World:event_tick(eve, root, unique_id, dat)
	---#logging LOGS:write("event tick " .. eve .. " " .. tostring(root) .. "\n")
	---#logging LOGS:flush()
	assert(root ~= INVALID_ID)

	if WORLD.player_character == root then
		-- This is a player event!
		-- print("player event options: ", eve)
		WORLD.pending_player_event_reaction = true
		return true
	else
		---#logging LOGS:write("event tick AI \n")
		---#logging LOGS:flush()

		WORLD.events_queue:dequeue()
		handle_event(eve, root, unique_id, dat)

		if DATA.pop_get_unique_id(root) == unique_id then
			assert(PROVINCE(root) ~= INVALID_ID, "character is alive but province is nil after event " .. eve)
		end
		return false
	end
end

---Performs a single tick update.
function world.World:tick()
	-- print('tick')

	PROFILER:start_timer("tick")

	WORLD.pending_player_event_reaction = false
	local counter = 0
	while WORLD.events_queue:length() > 0 do
		-- print('event queue pop')
		counter = counter + 1
		-- Read the event data to check it
		local ev = WORLD.events_queue:peek()

		if WORLD:event_tick(ev.event_tag, ev.root, ev.root_unique_id, ev.event_data) then
			return
		end

		--if counter > 10000 then
		--	print("FAIL! " .. tostring(WORLD.events_queue:length()))
		--end
		--print("event")
	end

	-- print('current events updated')

	WORLD.sub_hourly_tick = WORLD.sub_hourly_tick + 1
	WORLD.current_tick_in_month = WORLD.current_tick_in_month + 1

	if WORLD.current_tick_in_month == 1 then
		PROFILER:start_timer("vegetation")

		DCON.update_vegetation(VEGETATION_GROWTH)

		PROFILER:end_timer("vegetation")

		PROFILER:start_timer("production")

		production.run_fast()

		PROFILER:end_timer("production")
	end

	if WORLD.settled_provinces_by_identifier[WORLD.current_tick_in_month] ~= nil then

		-- Monthly tick per realm
		local ta = WORLD.settled_provinces_by_identifier[WORLD.current_tick_in_month]

		local t = love.timer.getTime()

		-- print("vegetation")

		PROFILER:start_timer("dbm")

		-- tiles update in settled_province:
		for _, settled_province in pairs(ta) do
			-- update targets from accumulated foraging data
			local amounts = dbm.total_foraging_amounts(settled_province)
			dbm.set_foraging_targets(settled_province, amounts)
			local weight = WORLD.current_tick_in_month % 10
			if (weight == WORLD.month and weight == (WORLD.year % 12)) then
				dbm.cultural_foragable_targets(settled_province)
			end
		end

		PROFILER:end_timer("dbm")

		-- print("realm pre update")

		-- "Realm" pre-update
		local realm_economic_update = require "game.economy.realm-economic-update"
		---@type province_id[]
		local to_remove = {}
		for _, settled_province in pairs(ta) do
			local realm = province_utils.realm(settled_province)
			if realm == INVALID_ID then
				table.insert(to_remove, settled_province)
			else
				local capitol = DATA.realm_get_capitol(realm)
				if capitol == settled_province then
					--print("Econ prerun")
					realm_economic_update.prerun(realm)
				end
			end
		end
		for _, province in pairs(to_remove) do
			ta[province] = nil
		end

		-- "Province" update

		for _, settled_province in pairs(ta) do
			--print("employ")
			PROFILER:start_timer("employ")
			employ.run(settled_province)
			PROFILER:end_timer("employ")

			PROFILER:start_timer("buildings")
			building_update.run(settled_province)
			PROFILER:end_timer("buildings")

			-- PROFILER:start_timer("production")
			-- production.run(settled_province)
			-- PROFILER:end_timer("production")

			PROFILER:start_timer("province")
			upkeep.run(settled_province)
			wealth_decay.run(settled_province)
			infrastructure.run(settled_province)
			research.run(settled_province)
			recruit.run(settled_province)
			PROFILER:end_timer("province")

			PROFILER:start_timer("growth")
			-- "POP" update
			local pop_growth = require "game.society.pop-growth"
			--print("Pop growth")
			pop_growth.growth(settled_province)
			PROFILER:end_timer("growth")

			--print("done")
		end


		-- "Realm" update
		-- local decide = require "game.ai.decide"
		local events = require "game.ai.events"
		local education = require "game.society.education"
		local court = require "game.society.court"
		local construct = require "game.ai.construction"
		for _, settled_province in pairs(ta) do
			local realm = province_utils.realm(settled_province)
			assert(realm ~= INVALID_ID)
			local overseer = political_values.overseer(realm)
			assert(overseer ~= INVALID_ID, province_utils.local_population(settled_province))
			local capitol = DATA.realm_get_capitol(realm)

			if realm ~= nil and capitol == settled_province then
				PROFILER:start_timer("realm")

				-- Run the realm AI once a month
				if not WORLD:does_player_control_realm(realm) then
					local explore = require "game.ai.exploration"
					local treasury = require "game.ai.treasury"
					local military = require "game.ai.military"
					explore.run(realm)
					treasury.run(realm)
					military.run(realm)
				else
					self:emit_treasury_change_effect(0, ECONOMY_REASON.NEW_MONTH)
					self:emit_treasury_change_effect(0, ECONOMY_REASON.NEW_MONTH, true)
				end
				--print("Construct")
				PROFILER:start_timer("realm-construct-update")
				construct.run(realm) -- This does an internal check for "AI" control to construct buildings for the realm but we keep it here so that we can have prettier code for POPs constructing buildings instead!
				PROFILER:end_timer("realm-construct-update")

				--print("Court")
				court.run(realm)
				--print("Edu")
				education.run(realm)
				--print("Econ")

				PROFILER:start_timer("realm-eco-update")
				realm_economic_update.run(realm)
				PROFILER:end_timer("realm-eco-update")
				-- Handle events!
				--print("Event handling")
				events.run(realm)

				PROFILER:end_timer("realm")

				PROFILER:start_timer("war")
				-- launch patrols
				for target, warbands in pairs(DATA.realm_get_patrols(realm)) do
					local units = 0
					if warbands ~= nil then
						for _, warband in pairs(warbands) do
							---@type number
							units = units + warband_utils.size(warband)
						end
					end
					-- launch the patrol
					if (units > 0) then
						military_effects.patrol(realm, target)
					end
				end

				PROFILER:end_timer("war")

				t = love.timer.getTime()
			end
		end

		PROFILER:start_timer("decisions")


		for _, settled_province in pairs(ta) do
			DATA.for_each_character_location_from_location(settled_province, function (item)
				local character = DATA.character_location_get_character(item)
				if character ~= WORLD.player_character then
					decide.run_character(character)
				end
			end)
		end

		---#logging LOGS:write("decisions end\n")
		---#logging LOGS:flush()

		PROFILER:end_timer("decisions")
	end

	-- print('simulation update')

	---#logging LOGS:write("scripted events updates\n")
	---#logging LOGS:flush()

	if WORLD.sub_hourly_tick == world.ticks_per_hour then
		WORLD.sub_hourly_tick = 0
		WORLD.hour = WORLD.hour + 1
		-- hourly tick

		if WORLD.hour == 24 then
			WORLD.hour = 0
			WORLD.day = WORLD.day + 1
			-- daily tick

			PROFILER:start_timer("events_queue")

			---#logging LOGS:write("events\n")
			---#logging LOGS:flush()

			-- events
			local l = WORLD.deferred_events_queue:length()
			for i = 1, l do
				-- print("def. event" .. tostring(i))
				local check = WORLD.deferred_events_queue:dequeue()
				check.delay = check.delay - 1
				if check.delay <= 0 then
					-- Reemit the event as a "real" even!
					WORLD:emit_event(check.event_tag, check.root, check.event_data, nil, check.root_unique_id)
					-- print("ontrig")
				else
					WORLD.deferred_events_queue:enqueue(check)
				end
			end

			---#logging LOGS:write("actions\n")
			---#logging LOGS:flush()

			-- actionas
			local l = WORLD.deferred_actions_queue:length()
			for i = 1, l do
				--print("def. action " .. tostring(i))
				local check = WORLD.deferred_actions_queue:dequeue()
				check.delay = check.delay - 1
				if check.delay <= 0 then
					local character = check.root
					local event = RAWS_MANAGER.events_by_name[check.event_tag]
					---#logging LOGS:write(
						-- "\n Handling action: " .. check[1] .. "\n" ..
						-- "root: " .. NAME(character) .. "\n"
					-- )
					---#logging LOGS:flush()
					if DATA.pop_get_unique_id(character) ~= check.root_unique_id then
						event:fallback(check.event_data)
					else
						event:on_trigger(character, check.event_data)
					end
					--print("ontrig")
					self.player_deferred_actions[check] = nil
				else
					WORLD.deferred_actions_queue:enqueue(check)
				end
				--print("donedef. action " .. tostring(i))
			end

			-- print('deferred actions update')
			PROFILER:end_timer("events_queue")

			if WORLD.day == 31 then
				WORLD.day = 0
				WORLD.current_tick_in_month = 0
				WORLD.month = WORLD.month + 1
				-- monthly tick
				--print("Monthly tick")
				if WORLD.month == 12 then
					WORLD.month = 0
					WORLD.year = WORLD.year + 1
					-- yearly tick
					--print("Yearly tick!")

					---#logging LOGS:write("aging\n")
					---#logging LOGS:flush()

					local pop_aging = require "game.society.pop-aging"
					pop_aging.age()
					DATA.for_each_realm(function (realm)
						DATA.realm_set_budget_tax_collected_this_year(realm, 0)
					end)
				end

				---#logging LOGS:write("month end\n")
				---#logging LOGS:flush()

				--print("Monthly tick end, refreshing")
				if OPTIONS.update_map then
					require "game.scenes.game".refresh_map_mode()
				end
				--print("Refresh finished")
			end
		end
		--print("tick end")

		---#logging LOGS:write("tick end\n")
		---#logging LOGS:flush()
	end

	PROFILER:end_timer("tick")
end

---Emits a notification
---@param notification string
function world.World:emit_notification(notification)
	local date = tostring(WORLD.day) .. ' ' .. utils.months[WORLD.month + 1] .. ' of ' .. tostring(WORLD.year)
	self.notification_queue:enqueue(date .. ':  ' .. notification)
end

---@class (exact) TreasuryEffectRecord
---@field amount number
---@field reason ECONOMY_REASON
---@field day number
---@field month number
---@field year number
---@field character_flag boolean

---Emits a treasury change to player
---@param amount number
---@param reason ECONOMY_REASON
---@param character_flag boolean?
function world.World:emit_treasury_change_effect(amount, reason, character_flag)
	if character_flag == nil then
		character_flag = false
	end
	---@type TreasuryEffectRecord
	local effect = {
		amount = amount,
		reason = reason,
		day = self.day,
		month = self.month,
		year = self.year,
		character_flag =
			character_flag
	}
	if reason == nil then
		error("NO REASON GIVEN!")
	end
	self.treasury_effects:enqueue(effect)
end

---Checks if given character is a player
---@param character Character?
---@return boolean
function world.World:is_player(character)
	if character == nil then
		return false
	end
	if WORLD.player_character == character then
		return true
	end
	return false
end

---Checks if player owns the building
---@param building building_id
---@return boolean
function world.World:player_is_owner(building)
	if building == INVALID_ID then
		return false
	end

	local ownership = DATA.get_ownership_from_building(building)
	local owner = DATA.ownership_get_owner(ownership)

	if owner == self.player_character then
		return true
	end

	return false
end

---comment
---@param realm Realm
---@return boolean
function world.World:does_player_control_realm(realm)
	if realm == INVALID_ID then
		return false
	end
	if self.player_character == INVALID_ID then
		return false
	end
	local leadership = DATA.get_realm_leadership_from_realm(realm)
	if leadership == INVALID_ID then
		return false
	end
	if DATA.realm_leadership_get_leader(leadership) == self.player_character then
		return true
	end
	return false
end

function world.World:player_province()
	if self.player_character == INVALID_ID then
		return INVALID_ID
	end

	return PROVINCE(self.player_character)
end

function world.World:player_realm()
	if self.player_character == INVALID_ID then
		return INVALID_ID
	end

	return REALM(self.player_character)
end

---comment
---@param realm Realm?
---@return boolean
function world.World:does_player_see_realm_news(realm)
	if realm == INVALID_ID then return false end
	if self.player_character == INVALID_ID then
		return false
	end
	local location = PROVINCE(self.player_character)
	local local_realm = province_utils.realm(location)
	return (local_realm == realm)
end

---comment
---@param province province_id
---@return boolean
function world.World:does_player_see_province_news(province)
	if self.player_character == INVALID_ID then
		return false
	end

	return (self:player_province() == province)
end

world.ticks_per_hour = 120
world.ticks_per_month = 30 * 24 * world.ticks_per_hour

return world
