local ef = require "game.raws.effects.economic"

local effects = {}

---Sets the tributary relationship and explores provinces for the overlord
---@param overlord Realm
---@param tributary Realm
function effects.set_tributary(overlord, tributary)
	if overlord.paying_tribute_to[tributary] then
		overlord.paying_tribute_to[tributary] = nil
		tributary.tributaries[overlord] = nil
	end

	tributary.paying_tribute_to[overlord] = overlord
	overlord.tributaries[tributary] = tributary

	for k, v in pairs(tributary.provinces) do
		overlord:explore(v)
	end

	tributary.capitol.mood = tributary.capitol.mood - 0.05
	overlord.capitol.mood = overlord.capitol.mood + 0.05

	if WORLD:does_player_see_realm_news(overlord) then
		WORLD:emit_notification(tributary.name .. " now pays tribute to our tribe! Our people are rejoicing!")
	end

	if WORLD:does_player_see_realm_news(tributary) then
		WORLD:emit_notification("Our tribe now pays tribute to " .. overlord.name .. ". Outrageous!")
	end

	ef.remove_raiding_flags(overlord, tributary)
	ef.remove_raiding_flags(tributary, overlord)
end

return effects
