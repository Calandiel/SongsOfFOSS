local tabb = require "engine.table"
local Event = require "game.raws.events"
local gift_cost_per_pop = require "game.gifting".gift_cost_per_pop

local function load()

	Event:new {
		name = "war-declaration",
		automatic = false,
		on_trigger = function(self, root, associated_data)
			---@type Realm
			local realm = root.province.realm
			---@type Realm
			local agg = associated_data.aggresor
			if WORLD:does_player_see_realm_news(realm) then
				WORLD:emit_notification(agg.name .. " declared war against us!")
			end
		end,
	}
end

return load
