local Event = require "game.raws.events"
local economic_effects = require "game.raws.effects.economy"
local economy_values = require "game.raws.values.economy"
local InterpersonalEffects = require "game.raws.effects.interpersonal"
local AI_VALUE = require "game.raws.values.ai"
local uit = require "game.ui-utils"

local retrieve_use_case = require "game.raws.raws-utils".trade_good_use_case


return function ()
    Event:new {
		name = "request-loyalty",
		event_text = function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data

			local name = NAME(associated_data)
			local temp = 'his'
			if DATA.pop_get_female(associated_data) then
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
				WORLD:emit_notification("I was asked to assist " .. NAME(associated_data))
			end
		end,
		options = function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data

            local treason_flag = false
            if LOYAL_TO(character) ~= associated_data and LOYAL_TO(character) ~= INVALID_ID then
                treason_flag = true
            end

			if DEAD(associated_data) then
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
                        -- WORLD:emit_notification("I agreed to assist " .. NAME(associated_data))
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
							WORLD:emit_notification(NAME(character) .. " refused to assist me.")
						end
						if character == WORLD.player_character then
							WORLD:emit_notification("I refused to assist " .. NAME(associated_data))
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
			local name = NAME(associated_data)
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
				WORLD:emit_notification(NAME(associated_data) .. "asked for a gift in exchange for loyalty.")
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
                        economic_effects.add_pop_savings(character, -price, ECONOMY_REASON.LOYALTY_GIFT)
                        economic_effects.add_pop_savings(associated_data, price, ECONOMY_REASON.LOYALTY_GIFT)
						InterpersonalEffects.set_loyalty(associated_data, character)
                        -- WORLD:emit_notification("I asked for payment from " .. NAME(associated_data))
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

    Event:new {
		name = "request-migration-colonize",
		---@param associated_data MigrationData
		event_text = function(self, character, associated_data)
			local name = NAME(associated_data.leader)
			local temp = 'He'
			if DATA.pop_get_female(associated_data.leader) then
				temp = 'She'
			end
			return name .. " requested to split off from out tribe and colonize " .. PROVINCE_NAME(associated_data.target_province) "." .. temp .. " promises to pay tribute to us. What should I do?"
		end,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		---@param associated_data MigrationData
		on_trigger = function(self, character, associated_data)
			if WORLD.player_character == character then
				WORLD:emit_notification("I was asked for permission to colonize " .. PROVINCE_NAME(associated_data.target_province)
					.. " by " .. NAME(associated_data.leader) .. ".")
			end
		end,
		---@param associated_data MigrationData
		options = function(self, character, associated_data)
			if DEAD(associated_data.organizer) then
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
					tooltip = "Allow " .. NAME(associated_data.leader) .. "to colonize " .. PROVINCE_NAME(associated_data.target_province) .. ".",
					viable = function() return true end,
					outcome = function()
						local character_calories_in_inventory = economy_values.available_use_case_from_inventory(associated_data.leader, CALORIES_USE_CASE)
						local remaining_calories_needed = math.max(0, associated_data.travel_cost - character_calories_in_inventory)
						-- buy remaining calories from market
						economic_effects.character_buy_use(associated_data.leader, CALORIES_USE_CASE, remaining_calories_needed)
						-- consume food from character inventory
						economic_effects.consume_use_case_from_inventory(associated_data.leader, CALORIES_USE_CASE, associated_data.travel_cost)
						-- give out payment to expedition
						economic_effects.add_pop_savings(associated_data.leader, -associated_data.pop_payment, ECONOMY_REASON.COLONISATION)
						WORLD:emit_immediate_action('migration-colonize', associated_data.leader, associated_data)
					end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data.leader, 0, {
						ambition = true,
						work = true,
						help = true
					})
				},
				{
					text = "Refuse",
					tooltip = "Refuse " .. NAME(associated_data.leader) .. "'s request to colonize " .. PROVINCE_NAME(associated_data.target_province) .. ".",
					viable = function() return true end,
					outcome = function()
						if associated_data == WORLD.player_character then
							WORLD:emit_notification(NAME(character) .. " refused to allow me to colonize " .. PROVINCE_NAME(associated_data.target_province) .. ".")
						end
						if character == WORLD.player_character then
							WORLD:emit_notification("I refused to allow " .. NAME(associated_data.leader) " to start a tributary tribe.")
						end
                    end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data.leader, 0, {
						help = false,
					})
				}
			}
		end
	}
end