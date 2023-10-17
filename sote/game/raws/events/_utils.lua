local Event = require "game.raws.events"

local utils = {}

---comment
---@param name string
---@param text fun(self:Event, root:Character, associated_data:table|nil):string
---@param option_name fun(root:Character, associated_data:table|nil):string
---@param tooltip fun(root:Character, associated_data:table|nil):string
function utils.notification_event(name, text, option_name, tooltip)
    Event:new {
		name = name,
		event_text = text,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		on_trigger = function(self, character, associated_data)
		end,
		options = function(self, character, associated_data)
			return {
				{
					text = option_name(character, associated_data),
					tooltip = tooltip(character, associated_data),
					viable = function() return true end,
					outcome = function()
					end,
					ai_preference = function ()
                        return 1
                    end
				}
			}
		end
	}
end

return utils