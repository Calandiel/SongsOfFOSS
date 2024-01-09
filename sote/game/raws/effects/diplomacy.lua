local economy_effects = require "game.raws.effects.economic"
local politics_effects = require "game.raws.effects.political"

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

	local reward_overlord = overlord.quests_raid[tributary] or 0
	overlord.quests_raid[tributary.capitol] = 0
	overlord.quests_patrol[tributary.capitol] = (overlord.quests_patrol[tributary.capitol] or 0) + reward_overlord

	local reward_tributary = tributary.quests_raid[tributary] or 0
	tributary.quests_raid[overlord.capitol] = 0
	tributary.quests_patrol[tributary.capitol] = (tributary.quests_patrol[tributary.capitol] or 0) + reward_tributary
end

---Removes the tributary relationship and explores provinces for the overlord
---@param overlord Realm
---@param tributary Realm
function effects.unset_tributary(overlord, tributary)
	overlord.tributaries[tributary] = nil
	tributary.paying_tribute_to[overlord] = nil
end

---Clears diplomatic relationships of the realms
---@param realm Realm
function effects.clear_diplomacy(realm)
	for _, tributary_realm in pairs(realm.tributaries) do
		tributary_realm.paying_tribute_to[realm] = nil
	end
	for _, overlord_realm in pairs(realm.paying_tribute_to) do
		overlord_realm.tributaries[realm] = nil
	end

	realm.paying_tribute_to = {}
	realm.tributaries = {}
end


---Clears realm and its diplomatic status.
---Does not handle characters because it's very context-dependent
---and it's better to do it separately
---@param realm Realm
function effects.dissolve_realm_and_clear_diplomacy(realm)
	effects.clear_diplomacy(realm)
	politics_effects.dissolve_realm(realm)
end

return effects
