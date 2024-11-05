--[====[
-- This file shouldn't ever be included.
-- It only servers as a template for copy pasting an event with all of its fields filled.

Event:new {
	name = "event-name",
	event_text = function(self, realm, associated_data)
		return "event text"
	end,
	event_background_path = "data/gfx/backgrounds/background.png",
	automatic = true,
	base_probability = 1 / 24,
	fallback = function (self, associated_data)
	end,
	trigger = function(self, realm)
		---@type Realm
		local realm
		return true
	end,
	on_trigger = function(self, realm)
		---@type Realm
		local realm = realm
	end,
	options = function(self, realm, associated_data)
		---@type Realm
		local realm = realm
		return {
			{
				text = "text",
				tooltip = "tooltip text",
				viable = function()
					return true
				end,
				outcome = function()
					if realm == WORLD.player_realm then
						WORLD:emit_notification("notification")
					end
				end,
				ai_preference = function()
					return 0.25
				end
			},
		}
	end
}



--]====]
