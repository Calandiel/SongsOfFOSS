local Event = require "game.raws.events"
local EconomicEffects = require "game.raws.effects.economic"
local InterpersonalEffects = require "game.raws.effects.interpersonal"
local TRAIT = require "game.raws.traits.generic"
local AI_VALUE = require "game.raws.values.ai_preferences"
local uit = require "game.ui-utils"
local PoliticalEffects = require "game.raws.effects.political"

local calculate_power_base = require "game.raws.values.political".power_base


return function()
    Event:new {
        name = "attempt-coup",
        event_text = function(self, character, associated_data)
            local province = character.province
            if province == nil then return "No coup target." end
            local realm = character.province.realm
            if realm == nil then return "No coup target." end
            if realm.capitol ~= province then return "No coup target." end

            local introduction = "I am going to become a chief of " .. realm.name .. '.'

            local pretender_power = calculate_power_base(character, province)
            local target_power = calculate_power_base(realm.leader, province)
            
            local power_estimation_string = "I do not know the power of " .. realm.leader.name
            
            if target_power >= pretender_power then
                if target_power < pretender_power + 10  then
                    power_estimation_string = realm.leader.name .. " is slightly more powerful than me."
                else
                    power_estimation_string = realm.leader.name .. " is more powerful than me."
                end
            else 
                if target_power > pretender_power - 10  then
                    power_estimation_string = realm.leader.name .. " is slightly less powerful than me."
                else
                    power_estimation_string = realm.leader.name .. " is less powerful than me."
                end
            end

			return introduction .. " " .. power_estimation_string
		end,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		on_trigger = function(self, character, associated_data)
		end,
		options = function(self, character, associated_data)
            local treason_flag = true
            local province = character.province
            if province == nil then return
                {
                    {
                        text = "No target",
                        tooltip = "No target",
                        viable = function() return true end,
                        outcome = function() end,
                        ai_preference = function ()
                            return 1
                        end
                    }
                }
            end
            local realm = character.province.realm
            if realm == nil then return
                {
                    {
                        text = "No target",
                        tooltip = "No target",
                        viable = function() return true end,
                        outcome = function() end,
                        ai_preference = function ()
                            return 1
                        end
                    }
                }
            end

            local pretender_power = calculate_power_base(character, province)
            local target_power = calculate_power_base(realm.leader, province)

			return {
				{
					text = "Start",
					tooltip = "I will challenge " .. realm.leader.name .. '!',
					viable = function() return true end,
					outcome = function()
                        PoliticalEffects.coup(character)
					end,
					ai_preference = function()
                        if pretender_power > target_power then
                            return 1
                        end
                        return 0
                    end
				},
				{
					text = "Wait",
					tooltip = "I need more time.",
					viable = function() return true end,
					outcome = function()
                    end,
					ai_preference = function()
                        return 0.5
                    end
				}
			}
		end
    }
end
