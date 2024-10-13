local tabb = require "engine.table"

local Event = require "game.raws.events"
local EventUtils = require "game.raws.events._utils"

local diplomacy_effects = require "game.raws.effects.diplomacy"
local political_values = require "game.raws.values.politics"
local economy_values = require "game.raws.values.economy"
local localisation = require "game.raws.events._localisation"
local AI_VALUE = require "game.raws.values.ai_preferences"

return function ()

	Event:new {
		name = "request-tribute",
		event_text = localisation.request_tribute,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type Character
			associated_data = associated_data

			local treason_flag = false
			local realm = character.realm

			-- character assumes that realm will lose money at least for a year
			local loss_of_money = 0
			if realm then
				loss_of_money = economy_values.potential_monthly_tribute_size(realm) * 12
			end

			local my_warlords, my_power = political_values.military_strength(character)
			local their_warlords, their_power = political_values.military_strength(associated_data)

			if realm == nil then
				return {{
					text = "I do not belong to any realm",
					tooltip = "",
					viable = function() return true end,
					outcome = function()
						WORLD:emit_immediate_event("invalid-target", associated_data, nil)
					end,
					ai_preference = function ()
						return 1
					end
				}}
			end

			if character.dead and realm.leader then
				return {{
					text = "I am dead; it's someone else's problem",
					tooltip = "",
					viable = function() return true end,
					outcome = function()
						WORLD:emit_immediate_event("request-tribute", realm.leader, associated_data)
					end,
					ai_preference = function ()
						return 1
					end
				}}
			end

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

						diplomacy_effects.set_tributary(associated_data.realm, character.realm)
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

						WORLD:emit_event("request-tribute-refusal", associated_data, character, 10)
					end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data, 0, {})
				}
			}
		end
	}

	Event:new {
		name = "request-tribute-refusal",
		event_text = localisation.request_tribute_refusal,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type Character
			associated_data = associated_data
			local target_realm = associated_data.realm
			assert(target_realm)

			-- character assumes that realm will gain money at least for a year
			local gain_of_money = 0

			gain_of_money = economy_values.potential_monthly_tribute_size(target_realm) * 12
			local my_warlords, my_power = political_values.military_strength(character)
			local their_warlords, their_power = political_values.military_strength(associated_data)


			if character.dead then
				return {{
					text = "I am dead; there is nothing I could do.",
					tooltip = "",
					viable = function() return true end,
					outcome = function () end,
					ai_preference = function() return 1 end
				}}
			end

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

						WORLD:emit_event("request-tribute-raid", character, target_realm, 10)
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
end