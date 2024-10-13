local economy_effects = require "game.raws.effects.economy"
local politics_effects = require "game.raws.effects.politics"

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

	overlord.tributary_status[tributary] = {
		warriors_contribution = false,
		wealth_transfer = true,
		goods_transfer = false,
		local_ruler = false,
		protection = false
	}

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

	for _, item in pairs(overlord.known_provinces) do
		WORLD.provinces_to_update_on_map[item] = item
	end
	WORLD.realms_changed = true
end

---Removes the tributary relationship and explores provinces for the overlord
---@param overlord Realm
---@param tributary Realm
function effects.unset_tributary(overlord, tributary)
	for _, item in pairs(overlord.known_provinces) do
		WORLD.provinces_to_update_on_map[item] = item
	end
	WORLD.realms_changed = true

	overlord.tributaries[tributary] = nil
	overlord.tributary_status[tributary] = nil
	tributary.paying_tribute_to[overlord] = nil
end

---Clears realm and its diplomatic status.
---Does not handle characters because it's very context-dependent
---and it's better to do it separately
---@param realm Realm
function effects.dissolve_realm_and_clear_diplomacy(realm)
	for _, item in pairs(DATA.realm_get_known_provinces(realm)) do
		WORLD.provinces_to_update_on_map[item] = item
	end
	WORLD.realms_changed = true

	politics_effects.dissolve_realm(realm)
end

return effects
