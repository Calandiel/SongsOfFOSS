local tabb              = require "engine.table"
local path              = require "game.ai.pathfinding"

local province_utils    = require "game.entities.province".Province
local realm_utils       = require "game.entities.realm".Realm
local army_utils 		= require "game.entities.army"

local Event             = require "game.raws.events"
local event_utils       = require "game.raws.events._utils"


local AI_VALUE          = require "game.raws.values.ai"

local pv                 = require "game.raws.values.politics"
local diplomacy_events   = require "game.raws.effects.diplomacy"
local economic_effects   = require "game.raws.effects.economy"
local military_effects   = require "game.raws.effects.military"
local political_effects  = require "game.raws.effects.politics"
local demography_effects = require "game.raws.effects.demography"

local character_values  = require "game.raws.values.character"

local messages          = require "game.raws.effects.messages"

function load()
	---@class (exact) MigrationData
	---@field organizer Character?
	---@field leader Character?
	---@field travel_cost number?
	---@field pop_payment number?
	---@field target_province Province
	---@field origin_province Province
	---@field invasion boolean

	Event:new {
		name = "migration-merge",
		automatic = false,
		base_probability = 0,
		event_background_path = "",
		on_trigger = function(self, root, associated_data)
			UNSET_BUSY(root)

			---@type MigrationData
			associated_data = associated_data

			-- TODO:
			-- move all this into separate effects

			---@type Technology[]
			local migration_pool_technology = {}

			local origin = associated_data.origin_province
			local target = associated_data.target_province

			-- populate temporary tables

			---@type pop_location_id[]
			local pop_locations = {}
			DATA.for_each_pop_location_from_location(origin, function (item)
				table.insert(pop_locations, item)
			end)
			for _, item in pairs(pop_locations) do
				local pop = DATA.pop_location_get_pop(item)
				local employment = DATA.get_employment_from_worker(pop)
				if DATA.employment_get_building(employment) ~= INVALID_ID then
					local employer = DATA.employment_get_building(employment)
					local type_of = DATA.building_get_current_type(employer)
					local movable = DATA.building_type_get_movable(type_of)
					if not movable then
						demography_effects.fire_pop(pop)
					end
				end

				DATA.pop_location_set_location(item, target)
			end

			---@type warband_location_id[]
			local warband_locations = {}
			DATA.for_each_warband_location_from_location(origin, function (item)
				table.insert(warband_locations, item)
			end)
			for _, item in pairs(warband_locations) do
				DATA.warband_location_set_location(item, target)
			end

			---@type character_location_id[]
			local character_locations = {}
			DATA.for_each_character_location_from_location(origin, function (item)
				table.insert(character_locations, item)
			end)
			for _, item in pairs(character_locations) do
				DATA.character_location_set_location(item, target)
			end

			---@type home_id[]
			local homes = {}
			DATA.for_each_home_from_home(origin, function (item)
				table.insert(homes, item)
			end)
			for _, item in pairs(homes) do
				DATA.home_set_home(item, target)
			end

			---@type building_location_id[]
			local building_locations = {}
			DATA.for_each_building_location_from_location(origin, function (item)
				table.insert(building_locations, item)
			end)
			for _, item in pairs(building_locations) do
				local building = DATA.building_location_get_building(item)
				local type_of = DATA.building_get_current_type(building)
				local movable = DATA.building_type_get_movable(type_of)

				if movable then
					DATA.building_location_set_location(item, target)
				else
					economic_effects.unset_ownership(building)
				end
			end

			DATA.for_each_technology(function (item)
				if DATA.province_get_technologies_present(origin, item) == 1 then
					province_utils.forget(origin, item)
					province_utils.research(target, item)
				end
			end)

			-- handle realms
			local target_realm = PROVINCE_REALM(target)

			---@type Realm
			local origin_realm = PROVINCE_REALM(origin)
			DATA.realm_set_capitol(origin_realm, target)

			if target_realm ~= INVALID_ID then
				-- merge all local characters to this realm
				if associated_data.invasion then
					-- if it was an invasion, turn local nobles into nobles of invading realm

					---@type realm_pop_id[]
					local temp = {}
					DATA.for_each_realm_pop_from_realm(target_realm, function (item)
						table.insert(temp)
					end)
					for _, item in pairs(temp) do
						DATA.realm_pop_set_realm(item, origin_realm)
						local pop = DATA.realm_pop_get_pop(item)
						if DATA.pop_get_rank(pop) == CHARACTER_RANK.CHIEF then
							DATA.pop_set_rank(pop, CHARACTER_RANK.NOBLE)
						end
					end

					-- destroy invaded realm
					diplomacy_events.dissolve_realm_and_clear_diplomacy(target_realm)
					realm_utils.add_province(origin_realm, target)
				else
					---@type realm_pop_id[]
					local temp = {}
					DATA.for_each_realm_pop_from_realm(origin_realm, function (item)
						table.insert(temp)
					end)
					for _, item in pairs(temp) do
						DATA.realm_pop_set_realm(item, target_realm)
						local pop = DATA.realm_pop_get_pop(item)
						if DATA.pop_get_rank(pop) == CHARACTER_RANK.CHIEF then
							DATA.pop_set_rank(pop, CHARACTER_RANK.NOBLE)
						end
					end

					-- destroy merged realm
					diplomacy_events.dissolve_realm_and_clear_diplomacy(origin_realm)
				end

				-- remove old province from the realm
				realm_utils.remove_province(origin_realm, origin)
			else
				-- replace old province with new one
				realm_utils.add_province(origin_realm, target)
				realm_utils.remove_province(origin_realm, origin)

				WORLD:set_settled_province(target)
			end

			WORLD:unset_settled_province(origin)

			if PROVINCE_NAME(associated_data.target_province) == "<uninhabited>" then
				DATA.province_set_name(associated_data.target_province, DATA.pop_get_culture(LEADER(origin_realm)).language:get_random_culture_name())
			end

			realm_utils.explore(origin_realm, CAPITOL(origin_realm))
		end
	}

	Event:new {
		name = "migration-colonize",
		automatic = false,
		base_probability = 0,
		event_background_path = "",
		on_trigger = function(self, root, associated_data)
			UNSET_BUSY(root)

			---@type MigrationData
			associated_data = associated_data

			-- TODO:
			-- move all this into separate effects

			---@type POP[]
			local migration_pool_pops = {}
			---@type Technology[]
			local migration_pool_technology = {}

			local expedition_leader = associated_data.leader
			-- make new noble no leader character provided
			if expedition_leader == nil then
				expedition_leader = political_effects.grant_nobility_to_random_pop(
					associated_data.origin_province,
					POLITICS_REASON.EXPEDITIONLEADER
				)
				if expedition_leader == nil then
					local population = 0
					DATA.for_each_home_from_home(associated_data.origin_province, function (item)
						population = population + 1
					end)

					local characters = 0
					DATA.for_each_character_location_from_location(associated_data.origin_province, function (item)
						characters = characters + 1
					end)

					local pops = 0
					DATA.for_each_pop_location_from_location(associated_data.origin_province, function (item)
						pops = pops + 1
					end)

					error(
						"FAILED TO PICK EXPEDITION LEADER IN MIGRATION-COLONIZE IN PROVINCE WITH POPULATION "
						.. tostring(population) .. " " .. tostring(characters) .. " " .. tostring(pops)
					)
					return
				end
			end

			-- populate temporary tables with not drafted pops	---collect colonization information
			---@param province any
			---@return table<POP, POP> valid_family_units
			---@return integer  valid_family_count
			local function valid_home_family_units(province)
				local family_units = {}

				DATA.for_each_pop_location_from_location(province, function (item)
					local pop = DATA.pop_location_get_pop(item)
					local home = DATA.get_home_from_pop(pop)
					local home_province = DATA.home_get_home(home)
					local race = F_RACE(pop)
					if
						home_province == province
						and AGE(pop) >= race.teen_age
						and AGE(pop) < race.middle_age
					then
						table.insert(family_units, pop)
					end
				end)

				local family_count = tabb.size(family_units)
				return family_units, family_count
			end
			-- move up to 6 but no more than half the home family units
			local valid_family_units, _ = valid_home_family_units(CAPITOL(REALM(root)))
			local candidates = 0

			for _, pop in pairs(valid_family_units) do
				if UNIT_OF(pop) == INVALID_ID then
					table.insert(migration_pool_pops, pop)
					candidates = candidates + 1
				end
				if candidates >= 6 then
					break
				end
			end

			DATA.for_each_technology(function (item)
				if DATA.province_get_technologies_present(associated_data.origin_province, item) == 1 then
					table.insert(migration_pool_technology, item)
				end
			end)

			local pop_payment = associated_data.pop_payment
			-- move pops from origin province
			for _, pop in pairs(migration_pool_pops) do
				demography_effects.fire_pop(pop)

				-- give half payment to migrating pop, keep other half for leader and realm
				if pop_payment then
					pop_payment = pop_payment * 0.5
					local family_payment = pop_payment / 6
					economic_effects.add_pop_savings(pop, family_payment, ECONOMY_REASON.DONATION)
				end

				-- need to set new home province first before transfering so children are pulled along
				province_utils.transfer_home(associated_data.origin_province, pop, associated_data.target_province)
				province_utils.transfer_pop(pop, associated_data.target_province)
			end

			--disolve warband to return warriors to home province before transfering character
			if LEADER_OF_WARBAND(expedition_leader) then
				require "game.raws.effects.military".dissolve_warband(expedition_leader)
			end

			-- set new home of character

			province_utils.transfer_home(
				associated_data.origin_province,
				expedition_leader,
				associated_data.target_province
			)

			-- give half remaining payment to leader, rest to new realm
			if pop_payment then
				---@type number
				pop_payment = pop_payment * 0.5
				economic_effects.add_pop_savings(expedition_leader, pop_payment, ECONOMY_REASON.DONATION)
			end
			-- move character to new home
			province_utils.transfer_pop(
				expedition_leader,
				associated_data.target_province
			)

			-- move technology

			for _, technology in pairs(migration_pool_technology) do
				province_utils.research(associated_data.target_province, technology)
			end

			-- handle realms
			local target_realm = PROVINCE_REALM(associated_data.target_province)

			---@type Realm
			local colonizer_realm = PROVINCE_REALM(associated_data.origin_province)

			-- create new realm
			-- TODO: MOVE TO SEPARATE FUNCTION WHEN THE NEED WILL ARISE
			local new_realm = realm_utils.new()

			DATA.realm_set_capitol(new_realm, associated_data.target_province)
			DATA.realm_set_primary_race(new_realm, DATA.realm_get_primary_race(colonizer_realm))
			DATA.realm_set_primary_culture(new_realm, DATA.realm_get_primary_culture(colonizer_realm))
			DATA.realm_set_primary_culture(new_realm, DATA.realm_get_primary_culture(colonizer_realm))

			-- give remaining payment to the new realm
			if pop_payment then
				economic_effects.change_treasury(new_realm, pop_payment, ECONOMY_REASON.DONATION)
			end

			local fat = DATA.fatten_realm(new_realm)
			local fat_col = DATA.fatten_realm(colonizer_realm)

			-- Initialize realm colors
			fat.r = math.max(0, math.min(1, (fat_col.primary_culture.r + (love.math.random() * 0.4 - 0.2))))
			fat.g = math.max(0, math.min(1, (fat_col.primary_culture.g + (love.math.random() * 0.4 - 0.2))))
			fat.b = math.max(0, math.min(1, (fat_col.primary_culture.b + (love.math.random() * 0.4 - 0.2))))

			fat.name = fat_col.primary_culture.language:get_random_realm_name()

			realm_utils.explore(new_realm, associated_data.target_province)

			-- set new realm of expedition leader
			DATA.force_create_realm_pop(new_realm, expedition_leader)

			-- Mark the province as settled for processing...

			if target_realm ~= INVALID_ID then
				---@type realm_pop_id[]
				local temp = {}
				DATA.for_each_realm_pop_from_realm(target_realm, function (item)
					table.insert(temp)
				end)
				for _, item in pairs(temp) do
					DATA.realm_pop_set_realm(item, new_realm)
					local pop = DATA.realm_pop_get_pop(item)
					if DATA.pop_get_rank(pop) == CHARACTER_RANK.CHIEF then
						DATA.pop_set_rank(pop, CHARACTER_RANK.NOBLE)
					end
				end

				-- destroy invaded realm
				diplomacy_events.dissolve_realm_and_clear_diplomacy(target_realm)
				realm_utils.add_province(new_realm, associated_data.target_province)
			else
				-- replace old province with new one
				realm_utils.add_province(new_realm, associated_data.target_province)
				WORLD:set_settled_province(associated_data.target_province)
			end

			--if PROVINCE_NAME(associated_data.target_province) == "<uninhabited>" then
			DATA.province_set_name(associated_data.target_province, DATA.realm_get_primary_culture(colonizer_realm).language:get_random_culture_name()) -- manifest destiny!
			--end

			political_effects.transfer_power(new_realm, expedition_leader, POLITICS_REASON.EXPEDITIONLEADER)

			-- explore neighbour lands
			realm_utils.explore(new_realm, CAPITOL(new_realm))
			diplomacy_events.set_tributary(colonizer_realm, new_realm)
		end
	}

	Event:new {
		name = "migration-swap",
		automatic = false,
		base_probability = 0,
		event_background_path = "",
		on_trigger = function(self, root, associated_data)
			local temp_target = province_utils.new(true)

			---@type MigrationData
			associated_data = associated_data

			---@type MigrationData
			local migration_data_1 = {
				organizer = root,
				target_province = temp_target,
				origin_province = associated_data.origin_province,
				invasion = false
			}
			---@type MigrationData
			local migration_data_2 = {
				organizer = root,
				target_province = associated_data.origin_province,
				origin_province = associated_data.target_province,
				invasion = false
			}
			---@type MigrationData
			local migration_data_3 = {
				organizer = root,
				target_province = associated_data.target_province,
				origin_province = temp_target,
				invasion = false
			}

			WORLD:emit_immediate_action('migration-merge', root, migration_data_1)
			WORLD:emit_immediate_action('migration-merge', root, migration_data_2)
			WORLD:emit_immediate_action('migration-merge', root, migration_data_3)
		end
	}


	Event:new {
		name = "migration-request",
		event_text = function(self, character, associated_data)
			---@type Character
			associated_data = associated_data
			local name = NAME(associated_data)

			local population_string =
				"There are "
				.. province_utils.home_population(CAPITOL(REALM(associated_data))) .. " commoners and "
				.. province_utils.home_characters(CAPITOL(REALM(associated_data))) .. " nobles in total."

			return name
				.. " requested that I allow his people to migrate to my lands."
				.. population_string
				.. " What should I do?"
		end,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type Character
			associated_data = associated_data

			local travel_time, _ = path.hours_to_travel_days(
				path.pathfind(
					CAPITOL(REALM(character)),
					CAPITOL(REALM(associated_data)),
					character_values.travel_speed_race(DATA.realm_get_primary_race(REALM(character))),
					DATA.realm_get_known_provinces(REALM(character))
				)
			)
			if travel_time == math.huge then
				travel_time = 150
			end

			return {
				{
					text = "Accept",
					tooltip = "Accept the request",
					viable = function() return true end,
					outcome = function()
						if WORLD.player_character == character then
							WORLD:emit_notification("I agreed to allow migration of people of " ..
								REALM_NAME(REALM(associated_data)) .. " into our lands.")
						end

						if associated_data == WORLD.player_character then
							WORLD:emit_notification(NAME(character) .. " allowed us to migrate into their land.")
						end

						---@type MigrationData
						local migration_data = {
							organizer = associated_data,
							origin_province = CAPITOL(REALM(associated_data)),
							target_province = CAPITOL(REALM(character)),
							invasion = false
						}

						WORLD:emit_action("migration-merge", associated_data, migration_data, travel_time, false)
						WORLD:emit_immediate_event("migration-target-agrees", associated_data, character)
					end,
					ai_preference = function()
						if CULTURE(character) == CULTURE(associated_data) then
							return 1
						end
						if RACE(character) == RACE(associated_data) then
							return 0.5
						end
						return 0.25
					end
				},
				{
					text = "Refuse",
					tooltip = "Refuse the request",
					viable = function() return true end,
					outcome = function()
						if WORLD.player_character == character then
							WORLD:emit_notification("I refused to allow foreigners into our lands.")
						end

						if associated_data == WORLD.player_character then
							WORLD:emit_notification(NAME(character) .. " has not allowed us to migrate into their land.")
						end

						WORLD:emit_event("migration-target-refuses", associated_data, character, travel_time)
					end,
					ai_preference = function()
						return 0.4
					end
				},
				{
					text = "Suggest swapping lands",
					tooltip = "Suggest exchanging lands",
					viable = function() return true end,
					outcome = function()
						WORLD:emit_event("migration-suggest-swapping", associated_data, character, travel_time)
					end,
					ai_preference = function()
						return 0
					end
				}
			}
		end
	}

	Event:new {
		name = "migration-suggest-swapping",
		event_text = function(self, character, associated_data)
			---@type Character
			associated_data = associated_data
			local name = NAME(associated_data)

			return name
				.. " refused my request to allow our people to migrate to their lands, but suggested swapping our lands instead."
		end,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type Character
			associated_data = associated_data

			local travel_time, _ = path.hours_to_travel_days(
				path.pathfind(
					CAPITOL(REALM(character)),
					CAPITOL(REALM(associated_data)),
					character_values.travel_speed_race(DATA.realm_get_primary_race(REALM(character))),
					DATA.realm_get_known_provinces(REALM(character))
				)
			)
			if travel_time == math.huge then
				travel_time = 150
			end

			return {
				{
					text = "Accept",
					tooltip = "It sounds even better?",
					viable = function() return true end,
					outcome = function()
						---@type MigrationData
						local migration_data = {
							organizer = associated_data,
							origin_province = CAPITOL(REALM(associated_data)),
							target_province = CAPITOL(REALM(character)),
							invasion = false
						}

						WORLD:emit_action("migration-swap", associated_data, migration_data, travel_time, false)
						WORLD:emit_immediate_event("migration-target-agrees", associated_data, character)
					end,
					ai_preference = function()
						return 1
					end
				},
				{
					text = "Escalate",
					tooltip = "Prepare an invasion instead",
					viable = function() return true end,
					outcome = function()
						WORLD:emit_immediate_event("migration-invasion-preparation", character, REALM(associated_data))
					end,
					ai_preference = function()
						if HAS_TRAIT(character, TRAIT.WARLIKE) then return 2 end
						return 0.25
					end
				},
				{
					text = "Refuse",
					tooltip = "These conditions are not acceptable",
					viable = function() return true end,
					outcome = function()

					end,
					ai_preference = function()
						return 0
					end
				},
			}
		end
	}

	event_utils.notification_event(
		"migration-target-agrees",
		function(self, root, associated_data)
			---@type Character
			associated_data = associated_data

			return "After a short negotiation, "
				.. NAME(associated_data)
				.. " agreed to allow us into their land."
		end,
		function(root, associated_data)
			return "Finally!"
		end,
		function(root, associated_data)
			---@type Character
			associated_data = associated_data

			return "We will merge with the tribe under the leadership of " .. NAME(associated_data)
		end
	)

	Event:new {
		name = "migration-target-refuses",
		event_text = function(self, character, associated_data)
			---@type Character
			associated_data = associated_data
			local name = NAME(associated_data)

			return name
				.. " refused my request to allow our people to migrate to their lands."
		end,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type Character
			associated_data = associated_data

			local travel_time, _ = path.hours_to_travel_days(
				path.pathfind(
					CAPITOL(REALM(character)),
					CAPITOL(REALM(associated_data)),
					character_values.travel_speed_race(DATA.realm_get_primary_race(REALM(character))),
					DATA.realm_get_known_provinces(REALM(character))
				)
			)
			if travel_time == math.huge then
				travel_time = 150
			end

			return {
				{
					text = "Accept",
					tooltip = "We will not migrate to their lands.",
					viable = function() return true end,
					outcome = function()
						UNSET_BUSY(character)
					end,
					ai_preference = AI_VALUE.generic_event_option(
						character,
						associated_data,
						0,
						{
							aggression = false
						}
					)
				},
				{
					text = "Escalate",
					tooltip = "Prepare invasion",
					viable = function() return true end,
					outcome = function()
						print('Escalation')
						WORLD:emit_immediate_event("migration-invasion-preparation", character, REALM(associated_data))
					end,
					ai_preference = AI_VALUE.generic_event_option(
						character,
						associated_data,
						0,
						{
							aggression = true
						}
					)
				}
			}
		end
	}

	Event:new {
		name = "migration-invasion-preparation",
		event_text = function(self, character, associated_data)
			---@type Realm
			associated_data = associated_data
			local name = REALM_NAME(associated_data)

			local my_warlords, my_power = pv.military_strength(character)
			local my_warlords_ready, my_power_ready = pv.military_strength_ready(character)
			local their_warlords, their_power = pv.military_strength(LEADER(associated_data))

			local strength_estimation_string =
				"On my side there are "
				.. my_warlords
				.. " warlords with total strength of "
				.. my_power
				.. " warriors in total."
				.. "Currently, I have "
				.. my_warlords_ready
				.. " warlords with a total strength of "
				.. my_power_ready
				.. " ready to join my campaign."
				.. " Enemy's potential forces consist of "
				.. their_warlords
				.. " warlords with total size of "
				.. their_power
				.. " warriors."

			return " We are planning to invade and settle lands of "
				.. name
				.. ". "
				.. strength_estimation_string
				.. " What should I do?"
		end,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type Realm
			local target_realm = associated_data

			local my_warlords, my_power = pv.military_strength(character)
			local my_warlords_ready, my_power_ready = pv.military_strength_ready(character)
			local their_warlords, their_power = pv.military_strength(LEADER(target_realm))

			return {
				{
					text = "Forward!",
					tooltip = "Launch the invasion",
					viable = function() return true end,
					outcome = function()
						local realm = REALM(character)

						local army = military_effects.gather_loyal_army_attack(character)
						if army == nil then
							if character == WORLD.player_character then
								WORLD:emit_notification("I had launched the invasion of " .. REALM_NAME(target_realm))
							end
						else
							local function callback(army, travel_time)
								---@type AttackData
								local data = {
									raider = character,
									origin = realm,
									target = CAPITOL(target_realm),
									travel_time = travel_time,
									army = army
								}

								WORLD:emit_action('migration-invasion-attack', character, data, travel_time, true)
							end

							military_effects.send_army(army, PROVINCE(character), CAPITOL(target_realm), callback)

							if character == WORLD.player_character then
								WORLD:emit_notification("I had launched the invasion of " .. REALM_NAME(target_realm))
							end
						end
					end,

					ai_preference = function()
						local base_value = AI_VALUE.generic_event_option(character, LEADER(target_realm), 0, {
							aggression = true,
						})()

						base_value = base_value + (my_power_ready - their_power) * 20
						return base_value
					end
				},
				{
					text = "Wait for 10 days",
					tooltip = "Wait for our warlords to gather.",
					viable = function() return true end,
					outcome = function()
						if WORLD.player_character == character then
							WORLD:emit_notification("I have decided to wait. We need more forces.")
						end

						WORLD:emit_event('migration-invasion-preparation', character, target_realm, 10)
					end,
					ai_preference = function()
						local base_value = AI_VALUE.generic_event_option(character, LEADER(target_realm), 0, {
							aggression = true,
						})()

						base_value = base_value + (my_power - their_power) * 15
						return base_value
					end
				},
				{
					text = "Back down",
					tooltip = "We are not ready to fight",
					viable = function() return true end,
					outcome = function()
						if WORLD.player_character == character then
							WORLD:emit_notification("I decided to not attack " .. NAME(LEADER(target_realm)))
						end
						UNSET_BUSY(character)
					end,
					ai_preference = AI_VALUE.generic_event_option(character, LEADER(target_realm), 0, {})
				}
			}
		end
	}

	Event:new {
		name = "migration-invasion-attack",
		automatic = false,
		base_probability = 0,
		event_background_path = "",
		on_trigger = function(self, root, associated_data)
			---@type AttackData
			associated_data = associated_data

			local raider = associated_data.raider
			local target = associated_data.target
			local travel_time = associated_data.travel_time
			local army = associated_data.army

			local province = target
			local realm = PROVINCE_REALM(province)

			---@type MigrationData
			local migration_data = {
				organizer = root,
				target_province = target,
				origin_province = CAPITOL(REALM(root)),
				invasion = true
			}

			if not realm then
				-- The province doesn't have a realm! Total success.
				WORLD:emit_action('migration-merge', raider, migration_data, travel_time, false)
				return
			end

			-- Battle time!

			-- spot test
			-- it's an open attack, so our visibility is multiplied by 10
			local spot_test = province_utils.army_spot_test(province, army, 10)

			-- First, raise the defending army.
			local def = realm_utils.raise_local_army(realm, province)
			local attack_succeed, attack_losses, def_losses = military_effects.attack(army, def, spot_test)
			realm_utils.disband_army(realm, def) -- disband the army after battle

			-- migrating
			if attack_succeed then
				WORLD:emit_action("migration-merge", raider, migration_data, travel_time, true)
				WORLD:emit_immediate_event("migration-invasion-success", raider, army)

				DATA.for_each_home_from_home(target, function (item)
					local pop = DATA.home_get_pop(item)

					if IS_CHARACTER(pop) then
						WORLD:emit_immediate_event("migration-invasion-success-target", pop, raider)
					end
				end)
			else
				UNSET_BUSY(raider)
				WORLD:emit_immediate_event("migration-invasion-failure", raider, army)
			end
		end,
	}

	event_utils.notification_event(
		"migration-invasion-failure",
		function(self, root, associated_data)
			---@type Character
			associated_data = associated_data

			return "Our invasion failed!"
		end,
		function(root, associated_data)
			return "I see."
		end,
		function(root, associated_data)
			---@type Character
			associated_data = associated_data
			return "We will have another chance."
		end,
		function(root, associated_data)
			---@type Army
			associated_data = associated_data

			realm_utils.disband_army(REALM(root), associated_data)
		end
	)

	event_utils.notification_event(
		"migration-invasion-success",
		function(self, root, associated_data)
			return "Our invasion is successful!"
		end,
		function(root, associated_data)
			return "Our new home awaits."
		end,
		function(root, associated_data)
			return "Our tribe moves to the invaded province."
		end,
		function(root, associated_data)
			---@type Army
			associated_data = associated_data

			realm_utils.disband_army(REALM(root), associated_data)
		end
	)

	event_utils.notification_event(
		"migration-invasion-success-target",
		function(self, root, associated_data)
			---@type Character
			associated_data = associated_data

			return "Our realm was invaded! We are subjects of " .. NAME(associated_data) .. " now."
		end,
		function(root, associated_data)
			return "It's over."
		end,
		function(root, associated_data)
			return "At least I am alive."
		end
	)
end

return load
