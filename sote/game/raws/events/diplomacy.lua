local tabb = require "engine.table"
local Event = require "game.raws.events"
local gift_cost_per_pop = require "game.gifting".gift_cost_per_pop
local character_ranks   = require "game.raws.ranks.character_ranks"

local AI_VALUE = require "game.raws.values.ai_preferences"

local pv = require "game.raws.values.political"
local de = require "game.raws.effects.diplomacy"
local ev = require "game.raws.values.economical"
local economic_effects = require "game.raws.effects.economic"


---@class TributeCollection
---@field origin Realm
---@field target Realm
---@field travel_time number
---@field tribute number


local function load()

    Event:new {
		name = "request-tribute",
		event_text = function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data

			local name = associated_data.name
			local temp = 'him'
			if associated_data.female then
				temp = 'her'
			end

            local my_warlords, my_power = pv.military_strength(character)
            local their_warlords, their_power = pv.military_strength(associated_data)

            local strength_estimation_string =
                "There are "
                .. my_warlords
                .. " warlords on my side with total strength of "
                .. my_power
                .. " warriors. And on their side there are "
                .. their_warlords
                .. " warlords with total strength of "
                .. their_power
                .. " warriors."

			return name
                .. " requested me to pay tribute to "
                .. temp .. ". "
                .. strength_estimation_string
                .. " What should I do?"
		end,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		on_trigger = function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data
			if WORLD.player_character == character then
				WORLD:emit_notification("I was asked to start paying tribute to " .. associated_data.name)
			end
		end,
		options = function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data

            local treason_flag = false
            local realm = character.realm

            -- character assumes that realm will lose money at least for a year
            local loss_of_money = 0
            if realm then
                loss_of_money = ev.potential_monthly_tribute_size(realm) * 12
            end

            local my_warlords, my_power = pv.military_strength(character)
            local their_warlords, their_power = pv.military_strength(associated_data)

			return {
				{
					text = "Accept",
					tooltip = "Accept the request",
					viable = function() return true end,
					outcome = function()
                        if WORLD.player_character == character then
                            WORLD:emit_notification("I agreed to pay tribute to " .. associated_data.name)
                        end

                        if associated_data == WORLD.player_character then
                            WORLD:emit_notification(character.name .. " agreed to pay tribute to my tribe")
                        end

                        de.set_tributary(associated_data.realm, character.realm)
					end,

					ai_preference = function ()
                        local base_value = AI_VALUE.generic_event_option(character, associated_data, 0, {
                            treason = treason_flag,
                            submission = true
                        })()
                        base_value = base_value - AI_VALUE.money_utility(character) * loss_of_money
                        base_value = base_value + (their_power - my_power) * 20
                        return base_value
                    end
				},
				{
					text = "Refuse",
					tooltip = "Refuse the request",
					viable = function() return true end,
					outcome = function()
                        if WORLD.player_character == character then
                            WORLD:emit_notification("I refused to pay tribute to " .. associated_data.name)
                        end

                        WORLD:emit_event('request-tribute-refusal', associated_data, character, 10)
                    end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data, 0, {})
				}
			}
		end
	}

        Event:new {
		name = "request-tribute-refusal",
		event_text = function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data

			local name = associated_data.name
			local temp = 'him'
			if associated_data.female then
				temp = 'her'
			end

            local my_warlords, my_power = pv.military_strength(character)
            local their_warlords, their_power = pv.military_strength(associated_data)

            local strength_estimation_string =
                "There are "
                .. my_warlords
                .. " warlords on my side with total strength of "
                .. my_power
                .. " warriors. And on their side there are "
                .. their_warlords
                .. " warlords with total strength of "
                .. their_power
                .. " warriors."

			return name
                .. " refused to pay tribute to me. "
                .. strength_estimation_string
                .. " What should I do?"
		end,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		on_trigger = function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data
			if WORLD.player_character == character then
				WORLD:emit_notification(associated_data.name .. " refused to pay tribute to me.")
			end
		end,
		options = function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data
            local target_realm = associated_data.realm

            -- character assumes that realm will gain money at least for a year
            local gain_of_money = 0
            if target_realm then
                gain_of_money = ev.potential_monthly_tribute_size(target_realm) * 12
            end

            local my_warlords, my_power = pv.military_strength(character)
            local their_warlords, their_power = pv.military_strength(associated_data)

			return {
				{
					text = "To arms!",
					tooltip = "Prepare the invasion",
					viable = function() return true end,
					outcome = function()
                        if associated_data == WORLD.player_character then
                            WORLD:emit_notification(character.name .. " refused to pay tribute to my tribe. Time to teach them a lesson!")
                        end

                        local realm = character.realm
                        realm.prepare_attack_flag = true

                        character.busy = true

                        WORLD:emit_event('request-tribute-raid', character, target_realm, 10)
					end,

					ai_preference = function ()
                        local base_value = AI_VALUE.generic_event_option(character, associated_data, 0, {
                            ambition = true,
                            aggression = true,
                        })()
                        base_value = base_value + AI_VALUE.money_utility(character) * gain_of_money
                        base_value = base_value + (my_power - their_power) * 20
                        return base_value
                    end
				},
				{
					text = "Back down",
					tooltip = "We are not ready to fight",
					viable = function() return true end,
					outcome = function()
                        if WORLD.player_character == character then
                            WORLD:emit_notification("I decided to not attack " .. associated_data.name)
                        end
                    end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data, 0, {})
				}
			}
		end
	}

	Event:new {
		name = "tribute-collection-1",
		automatic = false,
		on_trigger = function(self, root, associated_data)
            ---@type TributeCollection
            associated_data = associated_data
            associated_data.tribute = economic_effects.collect_tribute(root, associated_data.target)
            WORLD:emit_action("tribute-collection-2", root, associated_data, associated_data.travel_time, true)
		end,
	}

    Event:new {
		name = "tribute-collection-2",
		automatic = false,
		on_trigger = function(self, root, associated_data)
            ---@type TributeCollection
            associated_data = associated_data
            economic_effects.return_tribute_home(root, associated_data.origin, associated_data.tribute)
            root.busy = false
		end,
	}

    ---@class MigrationData
    ---@field target_province Province
    ---@field origin_province Province

    Event:new {
        name = "migration-merge",
        automatic = false,
        on_trigger = function(self, root, associated_data)
            print('MIGRATION')

            ---@type MigrationData
            associated_data = associated_data

            -- TODO:
            -- move all this into separate effects

            ---@type POP[]
            local migration_pool_pops = {}

            -- drafted pops
            ---@type table<POP, UnitType>
            local migration_pool_soldiers = {}

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

            -- populate temporary tables
            for _, pop in pairs(associated_data.origin_province.all_pops) do
                table.insert(migration_pool_pops, pop)
            end
            for pop, unit in pairs(associated_data.origin_province.soldiers) do
                migration_pool_soldiers[pop] = unit
            end
            for _, warband in pairs (associated_data.origin_province.warbands) do
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

            -- move pops from origin province
            for _, pop in pairs(migration_pool_pops) do
                associated_data.origin_province:fire_pop(pop)
                associated_data.origin_province:take_away_pop(pop)

                associated_data.target_province:add_pop(pop)
            end

            -- move soldier status of pops
            for pop, unit in pairs(migration_pool_soldiers) do
                associated_data.target_province.soldiers[pop] = unit
                associated_data.origin_province.soldiers[pop] = nil
            end

            -- move warbands
            for _, warband in pairs(migration_pool_warbands) do
                associated_data.target_province.warbands[warband] = warband
                associated_data.origin_province.warbands[warband] = nil
            end

            -- move guest characters
            for _, character in pairs(migration_pool_characters) do
                associated_data.origin_province:remove_character(character)
                associated_data.target_province:add_character(character)
            end

            -- set new home of characters
            for _, character in pairs(migration_pool_characters_locals) do
                associated_data.origin_province:unset_home(character)
                associated_data.target_province:set_home(character)
            end

            -- remove ownership of buildings
            for _, building in pairs(migration_pool_buildings) do
                economic_effects.unset_ownership(building)
            end


            -- handle realms
            local target_realm = associated_data.target_province.realm

            ---@type Realm
            local origin_realm = associated_data.origin_province.realm

            if target_realm then
                -- merge all local characters to this realm
                for _, character in pairs(migration_pool_characters_locals) do
                    character.realm = target_realm
                    character.rank = character_ranks.NOBLE
                end

                -- destroy realm
                origin_realm:remove_province(associated_data.origin_province)
                WORLD:unset_settled_province(associated_data.origin_province)
                WORLD.realms[origin_realm.realm_id] = nil
            else
                -- replace old province with new one
                origin_realm:add_province(associated_data.target_province)
                origin_realm.capitol = associated_data.target_province
                origin_realm:remove_province(associated_data.origin_province)

                WORLD:set_settled_province(associated_data.target_province)
                WORLD:unset_settled_province(associated_data.origin_province)
            end

            if associated_data.target_province.name == "<uninhabited>" then
                associated_data.target_province.name = origin_realm.leader.culture.language:get_random_culture_name()
            end
        end
    }
end

return load