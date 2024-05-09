local tabb              = require "engine.table"
local path              = require "game.ai.pathfinding"

local province          = require "game.entities.province"
local realm             = require "game.entities.realm"

local Event             = require "game.raws.events"
local event_utils       = require "game.raws.events._utils"

local character_ranks   = require "game.raws.ranks.character_ranks"

local AI_VALUE          = require "game.raws.values.ai_preferences"
local TRAIT             = require "game.raws.traits.generic"

local pv                = require "game.raws.values.political"
local diplomacy_events  = require "game.raws.effects.diplomacy"
local economic_effects  = require "game.raws.effects.economic"
local military_effects  = require "game.raws.effects.military"
local political_effects = require "game.raws.effects.political"

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
		on_trigger = function(self, root, associated_data)
			root.busy = false

			---@type MigrationData
			associated_data = associated_data

			-- TODO:
			-- move all this into separate effects

			---@type POP[]
			local migration_pool_pops = {}

			-- warbands
			---@type Warband[]
			local migration_pool_warbands = {}

			-- characters which are currently in this province
			---@type Character[]
			local migration_pool_characters = {}

			-- characters which think that this province is their home
			---@type Character[]
			local migration_pool_characters_locals = {}

			-- local buildings
			---@type Building[]
			local migration_pool_buildings = {}

			---@type Technology[]
			local migration_pool_technology = {}


			-- populate temporary tables
			for _, pop in pairs(associated_data.origin_province.all_pops) do
				table.insert(migration_pool_pops, pop)
			end
			for _, warband in pairs(associated_data.origin_province.warbands) do
				table.insert(migration_pool_warbands, warband)
			end
			for _, character in pairs(associated_data.origin_province.characters) do
				table.insert(migration_pool_characters, character)
			end
			for _, character in pairs(associated_data.origin_province.home_to) do
				table.insert(migration_pool_characters_locals, character)
			end
			for _, building in pairs(associated_data.origin_province.buildings) do
				table.insert(migration_pool_buildings, building)
			end
			for _, technology in pairs(associated_data.origin_province.technologies_present) do
				table.insert(migration_pool_technology, technology)
			end

			-- move pops from origin province
			for _, pop in pairs(migration_pool_pops) do
				if not pop.employer or not pop.employer.type.movable then
					associated_data.origin_province:fire_pop(pop)
				end
				associated_data.origin_province:transfer_pop(pop, associated_data.target_province)
			end

			-- move warbands
			for _, warband in pairs(migration_pool_warbands) do
				associated_data.target_province.warbands[warband] = warband
				associated_data.origin_province.warbands[warband] = nil
			end

			-- move guest characters
			for _, character in pairs(migration_pool_characters) do
				associated_data.origin_province:transfer_character(character, associated_data.target_province)
			end

			-- set new home of characters
			for _, character in pairs(migration_pool_characters_locals) do
				associated_data.origin_province:transfer_home(character, associated_data.target_province)
			end

			-- remove ownership of buildings or move them if they are movable
			for _, building in pairs(migration_pool_buildings) do
				if building.type.movable then
					associated_data.origin_province.buildings[building] = nil
					associated_data.target_province.buildings[building] = building
				else
					economic_effects.unset_ownership(building)
				end
			end

			-- move technology
			for _, technology in pairs(migration_pool_technology) do
				associated_data.origin_province:forget(technology)
				associated_data.target_province:research(technology)
			end

			-- handle realms
			local target_realm = associated_data.target_province.realm

			---@type Realm
			local origin_realm = associated_data.origin_province.realm
			origin_realm.capitol = associated_data.target_province

			if target_realm then
				-- merge all local characters to this realm
				if associated_data.invasion then
					-- if it was an invasion, turn local nobles into nobles of invading realm
					for _, character in pairs(associated_data.target_province.home_to) do
						if character.realm == target_realm then
							character.realm = origin_realm
							character.rank = character_ranks.NOBLE
						end
					end

					-- destroy invaded realm
					diplomacy_events.dissolve_realm_and_clear_diplomacy(target_realm)
					origin_realm:add_province(associated_data.target_province)
				else
					for _, character in pairs(migration_pool_characters_locals) do
						character.realm = target_realm
						character.rank = character_ranks.NOBLE
					end
					-- destroy merged realm
					diplomacy_events.dissolve_realm_and_clear_diplomacy(origin_realm)
				end

				-- remove old province from the realm
				origin_realm:remove_province(associated_data.origin_province)
			else
				-- replace old province with new one
				origin_realm:add_province(associated_data.target_province)
				origin_realm:remove_province(associated_data.origin_province)

				WORLD:set_settled_province(associated_data.target_province)
			end

			WORLD:unset_settled_province(associated_data.origin_province)

			if associated_data.target_province.name == "<uninhabited>" then
				associated_data.target_province.name = origin_realm.leader.culture.language:get_random_culture_name()
			end

			origin_realm:explore(origin_realm.capitol)
		end
	}

	Event:new {
		name = "migration-colonize",
		automatic = false,
		on_trigger = function(self, root, associated_data)
			root.busy = false

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
				expedition_leader = political_effects.grant_nobility_to_random_pop(associated_data.origin_province,
					political_effects.reasons.ExpeditionLeader)
				if expedition_leader == nil then
					error("FAILED TO PICK EXPEDITION LEADER IN MIGRATION-COLONIZE")
					return
				end
			end

			-- populate temporary tables with not drafted pops	---collect colonization information
			---@param province any
			---@return table<POP, POP> valid_family_units
			---@return integer  valid_family_count
			local function valid_home_family_units(province)
				local family_units = tabb.filter(province.all_pops, function (a)
					return a.home_province == province and a.age >= a.race.teen_age and a.age < a.race.middle_age
				end)
				local family_count = tabb.size(family_units)
				return family_units, family_count
			end
			-- move up to 6 but no more than half the home family units
			local valid_family_units, _ = valid_home_family_units(root.realm.capitol)
			local candidates = 0

			for _, pop in pairs(valid_family_units) do
				if (not pop.unit_of_warband) then
					table.insert(migration_pool_pops, pop)
					candidates = candidates + 1
				end
				if candidates >= 6 then
					break
				end
			end

			for _, technology in pairs(associated_data.origin_province.technologies_present) do
				table.insert(migration_pool_technology, technology)
			end

			local pop_payment = associated_data.pop_payment
			-- move pops from origin province
			for _, pop in pairs(migration_pool_pops) do
				if not pop.employer or not pop.employer.type.movable then
					associated_data.origin_province:fire_pop(pop)
				end
				-- give half payment to migrating pop, keep other half for leader and realm
				if pop_payment then
					pop_payment = pop_payment * 0.5
					local family_payment = pop_payment / 6
					economic_effects.add_pop_savings(pop, family_payment, economic_effects.reasons.Donation)
				end
				-- need to set new home province first before transfering so children are pulled along
				associated_data.origin_province:transfer_home(pop, associated_data.target_province)
				associated_data.origin_province:transfer_pop(pop, associated_data.target_province)
			end

			--disolve warband to return warriors to home province before transfering character
			if expedition_leader.leading_warband then
				require "game.raws.effects.military".dissolve_warband(root)
			end

			-- set new home of character
			associated_data.origin_province:transfer_home(
				expedition_leader,
				associated_data.target_province
			)
			-- give half remaining payment to leader, rest to new realm
			if pop_payment then
				pop_payment = pop_payment * 0.5
				economic_effects.add_pop_savings(expedition_leader, pop_payment, economic_effects.reasons.Donation)
			end
			-- move character to new home
			associated_data.origin_province:transfer_character(
				expedition_leader,
				associated_data.target_province
			)

			-- move technology
			for _, technology in pairs(migration_pool_technology) do
				associated_data.target_province:research(technology)
			end

			-- handle realms
			local target_realm = associated_data.target_province.realm

			---@type Realm
			local colonizer_realm = associated_data.origin_province.realm

			-- create new realm
			-- TODO: MOVE TO SEPARATE FUNCTION WHEN THE NEED WILL ARISE
			local new_realm = realm.Realm:new()
			new_realm.capitol = associated_data.target_province
			new_realm.primary_race = colonizer_realm.primary_race
			new_realm.primary_culture = colonizer_realm.primary_culture
			new_realm.primary_faith = colonizer_realm.primary_faith

			-- give remaining payment to the new realm
			if pop_payment then
				economic_effects.change_treasury(new_realm, pop_payment, economic_effects.reasons.Donation)
			end

			-- Initialize realm colors
			new_realm.r = math.max(0, math.min(1, (colonizer_realm.primary_culture.r + (love.math.random() * 0.4 - 0.2))))
			new_realm.g = math.max(0, math.min(1, (colonizer_realm.primary_culture.g + (love.math.random() * 0.4 - 0.2))))
			new_realm.b = math.max(0, math.min(1, (colonizer_realm.primary_culture.b + (love.math.random() * 0.4 - 0.2))))

			new_realm.name = colonizer_realm.primary_culture.language:get_random_realm_name()
			new_realm:explore(associated_data.target_province)

			-- set new realm of expedition leader
			expedition_leader.realm = new_realm

			-- Mark the province as settled for processing...

			if target_realm then
				-- if it was an invasion, turn local nobles into nobles of invading realm
				for _, character in pairs(associated_data.target_province.home_to) do
					if character.realm == target_realm then
						character.realm = new_realm
						character.rank = character_ranks.NOBLE
					end
				end

				-- destroy invaded realm
				diplomacy_events.dissolve_realm_and_clear_diplomacy(target_realm)
				new_realm:add_province(associated_data.target_province)
			else
				-- replace old province with new one
				new_realm:add_province(associated_data.target_province)
				WORLD:set_settled_province(associated_data.target_province)
			end

			--if associated_data.target_province.name == "<uninhabited>" then
			associated_data.target_province.name = colonizer_realm.primary_culture.language:get_random_culture_name() -- manifest destiny!
			--end

			political_effects.transfer_power(new_realm, expedition_leader, political_effects.reasons.ExpeditionLeader)

			-- explore neighbour lands
			new_realm:explore(new_realm.capitol)

			diplomacy_events.set_tributary(colonizer_realm, new_realm)
		end
	}

	Event:new {
		name = "migration-swap",
		automatic = false,
		on_trigger = function(self, root, associated_data)
			local temp_target = province.Province:new(true)

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
			local name = associated_data.name

			local population_string =
				"There are "
				.. associated_data.realm.capitol:home_population() .. " commoners and "
				.. associated_data.realm.capitol:home_characters() .. " nobles in total."

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
					character.realm.capitol,
					associated_data.realm.capitol,
					character_values.travel_speed_race(character.realm.primary_race),
					character.realm.known_provinces
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
								associated_data.realm.name .. " into our lands.")
						end

						if associated_data == WORLD.player_character then
							WORLD:emit_notification(character.name .. " allowed us to migrate into their land.")
						end

						---@type MigrationData
						local migration_data = {
							organizer = associated_data,
							origin_province = associated_data.realm.capitol,
							target_province = character.realm.capitol,
							invasion = false
						}

						WORLD:emit_action("migration-merge", associated_data, migration_data, travel_time, false)
						WORLD:emit_immediate_event("migration-target-agrees", associated_data, character)
					end,
					ai_preference = function()
						if character.culture == associated_data.culture then
							return 1
						end
						if character.race == associated_data.race then
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
							WORLD:emit_notification(character.name .. " has not allowed us to migrate into their land.")
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
			local name = associated_data.name

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
					character.realm.capitol,
					associated_data.realm.capitol,
					character_values.travel_speed_race(character.realm.primary_race),
					character.realm.known_provinces
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
							origin_province = associated_data.realm.capitol,
							target_province = character.realm.capitol,
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
						WORLD:emit_immediate_event("migration-invasion-preparation", character, associated_data.realm)
					end,
					ai_preference = function()
						if character.traits[TRAIT.WARLIKE] then return 2 end
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
				.. associated_data.name
				.. " agreed to allow us into their land."
		end,
		function(root, associated_data)
			return "Finally!"
		end,
		function(root, associated_data)
			---@type Character
			associated_data = associated_data

			return "We will merge with the tribe under the leadership of " .. associated_data.name
		end
	)

	Event:new {
		name = "migration-target-refuses",
		event_text = function(self, character, associated_data)
			---@type Character
			associated_data = associated_data
			local name = associated_data.name

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
					character.realm.capitol,
					associated_data.realm.capitol,
					character_values.travel_speed_race(character.realm.primary_race),
					character.realm.known_provinces
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
						character.busy = false
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
						WORLD:emit_immediate_event("migration-invasion-preparation", character, associated_data.realm)
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
			local name = associated_data.name

			local my_warlords, my_power = pv.military_strength(character)
			local my_warlords_ready, my_power_ready = pv.military_strength_ready(character)
			local their_warlords, their_power = pv.military_strength(associated_data.leader)

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
			local their_warlords, their_power = pv.military_strength(target_realm.leader)

			return {
				{
					text = "Forward!",
					tooltip = "Launch the invasion",
					viable = function() return true end,
					outcome = function()
						local realm = character.realm

						local army = military_effects.gather_loyal_army_attack(character)
						if army == nil then
							if character == WORLD.player_character then
								WORLD:emit_notification("I had launched the invasion of " .. target_realm.name)
							end
						else
							local function callback(army, travel_time)
								---@type AttackData
								local data = {
									raider = character,
									origin = realm,
									target = target_realm.capitol,
									travel_time = travel_time,
									army = army
								}

								WORLD:emit_action('migration-invasion-attack', character, data, travel_time, true)
							end

							military_effects.send_army(army, character.province, target_realm.capitol, callback)

							if character == WORLD.player_character then
								WORLD:emit_notification("I had launched the invasion of " .. target_realm.name)
							end
						end
					end,

					ai_preference = function()
						local base_value = AI_VALUE.generic_event_option(character, target_realm.leader, 0, {
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
						local base_value = AI_VALUE.generic_event_option(character, target_realm.leader, 0, {
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
							WORLD:emit_notification("I decided to not attack " .. target_realm.leader.name)
						end
						character.busy = false
					end,
					ai_preference = AI_VALUE.generic_event_option(character, target_realm.leader, 0, {})
				}
			}
		end
	}

	Event:new {
		name = "migration-invasion-attack",
		automatic = false,
		on_trigger = function(self, root, associated_data)
			---@type AttackData
			associated_data = associated_data

			local raider = associated_data.raider
			local target = associated_data.target
			local travel_time = associated_data.travel_time
			local army = associated_data.army

			local province = target
			local realm = province.realm

			---@type MigrationData
			local migration_data = {
				organizer = root,
				target_province = target,
				origin_province = root.realm.capitol,
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
			local spot_test = province:army_spot_test(army, 10)

			-- First, raise the defending army.
			local def = realm:raise_local_army(province)
			local attack_succeed, attack_losses, def_losses = army:attack(province, spot_test, def)
			realm:disband_army(def) -- disband the army after battle

			-- migrating
			if attack_succeed then
				WORLD:emit_action("migration-merge", raider, migration_data, travel_time, true)
				WORLD:emit_immediate_event("migration-invasion-success", raider, army)
				for _, character in pairs(target.home_to) do
					if character:is_character() then
						WORLD:emit_immediate_event("migration-invasion-success-target", character, raider)
					end
				end
			else
				raider.busy = false
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
			root.realm:disband_army(associated_data)
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
			root.realm:disband_army(associated_data)
		end
	)

	event_utils.notification_event(
		"migration-invasion-success-target",
		function(self, root, associated_data)
			---@type Character
			associated_data = associated_data

			return "Our realm was invaded! We are subjects of " .. associated_data.name .. " now."
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
