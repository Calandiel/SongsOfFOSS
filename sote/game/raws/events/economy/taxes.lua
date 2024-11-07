local Event = require "game.raws.events"
local text = require "game.raws.events._localisation"
local AI_VALUE = require "game.raws.values.ai"

local economic_effects = require "game.raws.effects.economy"
local political_effects = require "game.raws.effects.politics"


return function ()
	Event:new {
		name = "tax-collection-1",
		event_text = text.tax_collection_1,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		fallback = function(self, associated_data)

		end,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			local ai_profit = 0
			if not WORLD:is_player(character) then
				ai_profit = economic_effects.collect_tax(character)
			end

			return {
				{
					text = "I am an honest tax collector...",
					tooltip = "Return with collected wealth to your chief",
					viable = function() return true end,
					outcome = function()
						local tax = ai_profit
						if tax == 0 then
							tax = economic_effects.collect_tax(character)
						end

						political_effects.small_popularity_decrease(character, REALM(character))

						economic_effects.register_income(REALM(character), tax * 0.9, ECONOMY_REASON.TAX)
						economic_effects.add_pop_savings(character, tax * 0.1, ECONOMY_REASON.TAX)

						UNSET_BUSY(character)
					end,
					ai_preference = AI_VALUE.generic_event_option_untargeted(character, ai_profit * 0.1, {})
				},
				{
					text = "Take the opportunity",
					tooltip = "Tax population twice",
					viable = function() return true end,
					outcome = function()
						local tax = ai_profit
						if tax == 0 then
							tax = economic_effects.collect_tax(character)
						end
						tax = tax + economic_effects.collect_tax(character)

						political_effects.medium_popularity_decrease(character, REALM(character))

						economic_effects.register_income(REALM(character), tax / 2 * 0.9, ECONOMY_REASON.TAX)
						economic_effects.add_pop_savings(character, tax / 2 * 1.1, ECONOMY_REASON.TAX)

						UNSET_BUSY(character)
					end,
					ai_preference = AI_VALUE.generic_event_option_untargeted(character, ai_profit * 1.8, {power_abuse = true})
				}
			}
		end
	}
end