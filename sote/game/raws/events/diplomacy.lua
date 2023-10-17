local tabb = require "engine.table"
local Event = require "game.raws.events"
local gift_cost_per_pop = require "game.gifting".gift_cost_per_pop

local AI_VALUE = require "game.raws.values.ai_preferences"

local pv = require "game.raws.values.political"
local de = require "game.raws.effects.diplomacy"
local ev = require "game.raws.values.economical"
local ef = require "game.raws.effects.economic"


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
            if realm and realm.paying_tribute_to ~= associated_data.realm and realm.paying_tribute_to ~= nil then
                treason_flag = true
            end

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
            associated_data.tribute = ef.collect_tribute(root, associated_data.target)
            WORLD:emit_action("tribute-collection-2", root, associated_data, associated_data.travel_time, true)
		end,
	}

    Event:new {
		name = "tribute-collection-2",
		automatic = false,
		on_trigger = function(self, root, associated_data)
            ---@type TributeCollection
            associated_data = associated_data
            ef.return_tribute_home(root, associated_data.origin, associated_data.tribute)
            root.busy = false
		end,
	}
end

return load