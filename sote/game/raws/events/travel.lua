local Event = require "game.raws.events"
local Event_utils = require "game.raws.events._utils"
local ge = require "game.raws.effects.generic"

local function load()
    Event:new {
		name = "travel",
		automatic = false,
		on_trigger = function(self, root, associated_data)
			---@type Province
			associated_data = associated_data
            
            ge.travel(root, associated_data)
            WORLD:emit_immediate_event('travel-end-notification', root, associated_data)
		end,
	}

    Event_utils.notification_event(
        "travel-end-notification",
        function (self, root, data)
            ---@type Province
            data = data
            return "I have arrived to " .. data.name .. ". "
                .. "This land is controlled by people of " .. data.realm.name .. ". "
                .. data.realm.leader.race.name .. " " .. data.realm.leader.name .. " rules over them."
        end,
        function (self, root, data)
            return "Finally!"
        end,
        function (self, root, data)
            return "What should I do now?"
        end
    )

end

return load