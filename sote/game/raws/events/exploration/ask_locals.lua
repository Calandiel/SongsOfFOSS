local Event = require "game.raws.events"
local event_utils = require "game.raws.events._utils"
local ut = require "game.ui-utils"
local text = require "game.raws.events._localisation"
local economic_effects = require "game.raws.effects.economy"

local AI_VALUE = require "game.raws.values.ai_preferences"

return function()

	---@param character Character
	---@param associated_data ExplorationData
	local function help_outcome(character, associated_data)
		if associated_data.last_conversation.lied then
			associated_data._exploration_speed = associated_data._exploration_speed * 0.9
			if associated_data._exploration_speed < 0.5 then
				associated_data._exploration_speed = 0.5
			end
		else
			associated_data._exploration_speed = associated_data._exploration_speed * 2
		end

		WORLD:emit_immediate_event("exploration-progress", character, associated_data)
	end

	Event:new {
		name = "exploration-help",
		event_text = text.exploration_ask_locals_local,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = event_utils.constant_false,
		options = function(self, character, associated_data)
			---@type ExplorationData
			associated_data = associated_data

			local price = 5

			return {
				{
					text = "Request " .. tostring(price) .. MONEY_SYMBOL.. " for help.",
					tooltip = "A bit of wealth is always nice",
					viable = function() return true end,
					outcome = function ()
						associated_data.last_conversation.payment = price
						WORLD:emit_immediate_event("exploration-payment", associated_data.explorer, associated_data)
					end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data.explorer, price, {})
				},
				{
					text = "Help for free.",
					tooltip = "Helping others feel nice",
					viable = function() return true end,
					outcome = function ()
						associated_data.last_conversation.payment = 0
						WORLD:emit_immediate_event("exploration-help-received", associated_data.explorer, associated_data)
					end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data.explorer, 0, {
						help = true
					})
				}
			}
		end
	}

	Event:new {
		name = "exploration-payment",
		event_text = text.exploration_ask_locals_explorer_payment,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = event_utils.constant_false,
		options = function(self, character, associated_data)
			---@type ExplorationData
			associated_data = associated_data

			local price = associated_data.last_conversation.payment
			local partner = associated_data.last_conversation.partner

			local function outcome_refuse()
				WORLD:emit_immediate_event("exploration-progress", character, associated_data)
			end

			local function outcome_accept()
				economic_effects.add_pop_savings(character, -price, ECONOMY_REASON.EXPLORATION)
				economic_effects.add_pop_savings(partner, price, ECONOMY_REASON.EXPLORATION)
				help_outcome(character, associated_data)
				WORLD:emit_immediate_event("exploration-help-payment-received", partner, associated_data)
			end

			if price > character.savings then
				return {
					{
						text = "I do not have enough money",
						tooltip = "I lack " .. ut.to_fixed_point2(price - character.savings),
						viable = function() return true end,
						outcome = outcome_refuse,
						ai_preference = function() return 1 end
					}
				}
			else
				return {
					{
						text = "Pay " .. ut.to_fixed_point2(price) .. MONEY_SYMBOL,
						tooltip = "Pay",
						viable = function() return true end,
						outcome = outcome_accept,
						ai_preference = AI_VALUE.generic_event_option_untargeted(character, -price, {})
					},
					{
						text = "Refuse",
						tooltip = "Refuse to pay",
						viable = function() return true end,
						outcome = outcome_refuse,
						ai_preference = AI_VALUE.generic_event_option_untargeted(character, 0, {})
					}
				}
			end
		end
	}

	Event:new {
		name = "exploration-help-received",
		event_text = text.exploration_ask_locals_explorer_help_received,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = event_utils.constant_false,
		options = function(self, character, associated_data)
			---@type ExplorationData
			associated_data = associated_data

			local function outcome_accept()
				help_outcome(character, associated_data)
			end

			return {
				{
					text = "Thanks...",
					tooltip = "I get back to the exploration of local lands.",
					viable = function() return true end,
					outcome = outcome_accept,
					ai_preference = 1
				}
			}
		end
	}

	event_utils.notification_event(
		"exploration-help-payment-received",
		text.exploration_helper_payment_received,
		text.option_okay,
		text.tooltip_okay,
		function () end
	)
end