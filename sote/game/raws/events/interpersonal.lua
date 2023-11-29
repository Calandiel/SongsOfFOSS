local Event = require "game.raws.events"
local EconomicEffects = require "game.raws.effects.economic"
local InterpersonalEffects = require "game.raws.effects.interpersonal"
local TRAIT = require "game.raws.traits.generic"
local AI_VALUE = require "game.raws.values.ai_preferences"
local uit = require "game.ui-utils"


return function ()
    Event:new {
		name = "request-loyalty",
		event_text = function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data

			local name = associated_data.name
			local temp = 'his'
			if associated_data.female then
				temp = 'her'
			end
			return name .. " requested my loyalty and assistance in " .. temp .. " future plans. What should I do?"
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
				WORLD:emit_notification("I was asked to assist " .. associated_data.name)
			end
		end,
		options = function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data

            local treason_flag = false
            if character.loyalty ~= associated_data and character.loyalty ~= nil then
                treason_flag = true
            end

			if associated_data.dead then
				return {
					text = "...",
					tooltip = "No loyalty to dead people.",
					viable = function() return true end,
					outcome = function()
					end,
					ai_preference = function ()
						return 1
					end
				}
			end

			return {
				{
					text = "Accept",
					tooltip = "Accept the request",
					viable = function() return true end,
					outcome = function()
						InterpersonalEffects.set_loyalty(character, associated_data)
                        -- WORLD:emit_notification("I agreed to assist " .. associated_data.name)
					end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data, 0, {
						treason = treason_flag,
						ambition = false,
						help = true,
						submission = true
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
					ai_preference = AI_VALUE.generic_event_option(character, associated_data, 0, {
						treason = false,
						ambition = false,
						help = false,
						submission = false
					})
				},
                {
                    text = "Ask for payment",
                    tooltip = "Ask for payment",
                    viable = function() return true end,
                    outcome = function()
                        WORLD:emit_immediate_event("request-loyalty-payment", associated_data, character)
                    end,
                    ai_preference = AI_VALUE.generic_event_option(character, associated_data, AI_VALUE.loyalty_price(associated_data), {
						treason = treason_flag,
						ambition = false,
						help = false,
						submission = true
					})
                }
			}
		end
	}

	Event:new {
		name = "request-loyalty-payment",
		event_text = function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data
			local name = associated_data.name
			local price = AI_VALUE.loyalty_price(associated_data)
			return name .. " will agree to my suggestion in exchange for a small gift."
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
				WORLD:emit_notification(associated_data.name .. "asked for a gift in exchange for loyalty.")
			end
		end,
        options = function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data

            local price = AI_VALUE.loyalty_price(associated_data)
			return {
				{
					text = "Pay " ..  uit.to_fixed_point2(price) .. MONEY_SYMBOL,
					tooltip = "Pay",
					viable = function() return true end,
					outcome = function()
                        EconomicEffects.add_pop_savings(character, -price, EconomicEffects.reasons.LoyaltyGift)
                        EconomicEffects.add_pop_savings(associated_data, price, EconomicEffects.reasons.LoyaltyGift)
						InterpersonalEffects.set_loyalty(associated_data, character)
                        -- WORLD:emit_notification("I asked for payment from " .. associated_data.name)
					end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data, -price, {
						treason = false,
						ambition = true,
						help = false,
						submission = false
					})
				},
				{
					text = "Refuse",
					tooltip = "Refuse to pay",
					viable = function() return true end,
					outcome = function() end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data, 0, {
						treason = false,
						ambition = false,
						help = false,
						submission = false
					})
				}
			}
		end
	}
end