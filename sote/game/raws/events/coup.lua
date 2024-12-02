local Event = require "game.raws.events"
local E_ut = require "game.raws.events._utils"

local economic_effects = require "game.raws.effects.economy"
local InterpersonalEffects = require "game.raws.effects.interpersonal"
local AI_VALUE = require "game.raws.values.ai"
local uit = require "game.ui-utils"
local PoliticalEffects = require "game.raws.effects.politics"

local calculate_power_base = require "game.raws.values.politics".power_base


return function()
    Event:new {
        name = "attempt-coup",
        fallback = function(self, associated_data) end,
        event_text = function(self, character, associated_data)
            local province = PROVINCE(character)
            if province == INVALID_ID then return "No coup target." end
            local realm = LOCAL_REALM(character)
            if realm == INVALID_ID then return "No coup target." end
            if CAPITOL(realm) ~= province then return "No coup target." end

            local introduction = "I am going to become a chief of " .. REALM_NAME(realm) .. '.'

            local pretender_power = calculate_power_base(character, province)
            local target_power = calculate_power_base(LEADER(realm), province)

            local power_estimation_string = "I do not know the power of " .. NAME(LEADER(realm))

            if target_power >= pretender_power then
                if target_power < pretender_power + 10  then
                    power_estimation_string = NAME(LEADER(realm)) .. " is slightly more powerful than me."
                else
                    power_estimation_string = NAME(LEADER(realm)) .. " is more powerful than me."
                end
            else
                if target_power > pretender_power - 10  then
                    power_estimation_string = NAME(LEADER(realm)) .. " is slightly less powerful than me."
                else
                    power_estimation_string = NAME(LEADER(realm)) .. " is less powerful than me."
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
            local province = PROVINCE(character)
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
            local realm = LOCAL_REALM(character)
            if realm == INVALID_ID then return
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
            local target_power = calculate_power_base(LEADER(realm), province)

			return {
				{
					text = "Start",
					tooltip = "I will challenge " .. NAME(LEADER(realm)) .. '!',
					viable = function() return true end,
					outcome = function()
                        WORLD:emit_action("coup", character, associated_data, 0, true)
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

    Event:new {
		name = "coup",
        fallback = function(self, associated_data) end,
		automatic = false,
        event_background_path = "data/gfx/backgrounds/background.png",
		base_probability = 0,
		on_trigger = function(self, root, associated_data)
			local realm = REALM(root)

            if realm == nil then
                return
            end

            if PoliticalEffects.coup(root) then
                WORLD:emit_immediate_event("coup-success", root, associated_data)
            else
                WORLD:emit_immediate_event("coup-failure", root, associated_data)
            end
		end,
	}

    E_ut.notification_event(
        "coup-success",
        function(self, character, associated_data)
            return "Success! I managed to overthrow the chief!"
		end,
        function (root, associated_data)
            return "Nice!"
        end,
        function (root, associated_data)
            return "Another step forward."
        end
    )

    E_ut.notification_event(
        "coup-failure",
        function(self, character, associated_data)
            return "Failure! I haven't managed to overthrow the chief!"
		end,
        function (root, associated_data)
            return "I failed!"
        end,
        function (root, associated_data)
            return "What will happen next? Nothing..."
        end
    )
end
