local Event = require "game.raws.events"
local EconomicEffects = require "game.raws.effects.economic"
local InterpersonalEffects = require "game.raws.effects.interpersonal"
local TRAIT = require "game.raws.traits.generic"
local AI_VALUE = require "game.raws.values.ai_preferences"
local uit = require "game.ui-utils"


local function load()
    Event:new {
		name = "request-help-overseer",
		event_text = function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data

			local name = associated_data.name
			local temp = 'his'
			if associated_data.female then
				temp = 'her'
			end
			return name .. " requested my participation in " .. temp .. " administration. My task would be overseering of construction and other public activities. What should I do?"
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
				WORLD:emit_notification("I was asked to assist " .. associated_data.name .. " with administrative tasks.")
			end
		end,
		options = function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data

			return {
				{
					text = "Accept",
					tooltip = "Accept the request",
					viable = function() return true end,
					outcome = function() 
						PoliticalEffects.set_overseer(associated_data.province.realm, character)
                        -- WORLD:emit_notification("I agreed to assist " .. associated_data.name)
					end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data, 0, {
						ambition = true,
						help = true,
                        work = true
					})
				},
				{
					text = "Refuse",
					tooltip = "Refuse the request",
					viable = function() return true end,
					outcome = function() 
						if associated_data == WORLD.player_character then
							WORLD:emit_notification(character.name .. " refused to assist me.")
						end
						if character == WORLD.player_character then
							WORLD:emit_notification("I refused to assist " .. associated_data.name)
						end
                    end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data, 0, {})
				}
			}
		end
	}
end

return load