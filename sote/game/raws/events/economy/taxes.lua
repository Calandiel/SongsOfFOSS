local Event = require "game.raws.events"
local text = require "game.raws.events._localisation"
local TRAIT = require "game.raws.traits.generic"
local AI_VALUE = require "game.raws.values.ai_preferences"

local economic_effects = require "game.raws.effects.economic"
local political_effects = require "game.raws.effects.political"


return function ()
	Event:new {
		name = "tax-collection-1",
		event_text = text.tax_collection_1,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)

			if character.dead then
				return {
					{
						text = "I am a dead tax collector...",
						tooltip = "Continue being dead",
						viable = function() return true end,
						outcome = function()
							character.busy = false
						end,
						ai_preference = function ()
							return 1
						end
					}
				}
			end

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

						political_effects.small_popularity_decrease(character, character.realm)

						economic_effects.register_income(character.realm, tax * 0.9, economic_effects.reasons.Tax)
						economic_effects.add_pop_savings(character, tax * 0.1, economic_effects.reasons.Tax)

						character.busy = false
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

						political_effects.medium_popularity_decrease(character, character.realm)

						economic_effects.register_income(character.realm, tax / 2 * 0.9, economic_effects.reasons.Tax)
						economic_effects.add_pop_savings(character, tax / 2 * 1.1, economic_effects.reasons.Tax)

						character.busy = false
					end,
					ai_preference = AI_VALUE.generic_event_option_untargeted(character, ai_profit * 1.8, {power_abuse = true})
				}
			}
		end
	}
end