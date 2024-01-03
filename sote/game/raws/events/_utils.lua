local Event = require "game.raws.events"

local utils = {}

---always returns false
---@param self table
---@param character Character
---@return boolean
function utils.constant_false(self, character)
	return false;
end

---comment
---@param name string
---@param text fun(self:Event, root:Character, associated_data:table|nil):string
---@param option_name fun(root:Character, associated_data:table|nil):string
---@param tooltip fun(root:Character, associated_data:table|nil):string
---@param effect fun(root:Character, associated_data:table|nil)?
function utils.notification_event(name, text, option_name, tooltip, effect)
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
						if effect ~= nil then
							effect(character, associated_data)
						end
					end,
					ai_preference = function ()
						return 1
					end
				}
			}
		end
	}
end

---Option which removes "busy" flag
---@param text string
---@param tooltip string
---@param ai_preference number
---@param root Character
---@return EventOption
function utils.option_stop(text, tooltip, ai_preference, root)
	---@type EventOption
	local option = {
		text = text,
		tooltip = tooltip,
		viable = function ()
			return true
		end,
		ai_preference = function ()
			return ai_preference
		end,
		outcome = function ()
			root.busy = false
		end
	}

	return option
end

---@type EventOption[]
utils.dead_options = {{
	text = "I am dead, there is nothing i could do.",
	tooltip = "",
	viable = function() return true end,
	outcome = function () end,
	ai_preference = function() return 1 end
}}

return utils