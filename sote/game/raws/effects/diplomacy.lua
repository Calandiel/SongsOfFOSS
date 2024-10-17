local economy_effects = require "game.raws.effects.economy"
local politics_effects = require "game.raws.effects.politics"
local realm_utils = require "game.entities.realm".Realm

local effects = {}

---Sets the tributary relationship and explores provinces for the overlord
---@param overlord Realm
---@param tributary Realm
function effects.set_tributary(overlord, tributary)

	local tributary_is_overlord_of_overlord = false
	local to_delete = INVALID_ID

	DATA.for_each_realm_subject_relation_from_subject(overlord, function (item)
		local overlord_of_overlord = DATA.realm_subject_relation_get_overlord(item)

		if overlord_of_overlord == tributary then
			to_delete = item
		end
	end)

	if to_delete ~= INVALID_ID then
		DATA.delete_realm_subject_relation(to_delete)
	end

	local new_rel = DATA.force_create_realm_subject_relation(overlord, tributary)
	DATA.realm_subject_relation_set_wealth_transfer(new_rel, true)

	realm_utils.explore(overlord, CAPITOL(tributary))

	DATA.province_inc_mood(CAPITOL(tributary), -0.05)
	DATA.province_inc_mood(CAPITOL(overlord), -0.05)


	if WORLD:does_player_see_realm_news(overlord) then
		WORLD:emit_notification(REALM_NAME(tributary) .. " now pays tribute to our tribe! Our people are rejoicing!")
	end

	if WORLD:does_player_see_realm_news(tributary) then
		WORLD:emit_notification("Our tribe now pays tribute to " .. REALM_NAME(overlord) .. ". Outrageous!")
	end

	-- clean up raiding rewards



	local old_reward_raid_overlord = DATA.realm_get_quests_raid(overlord)[CAPITOL(tributary)] or 0
	local old_patrol_reward_overlord = DATA.realm_get_quests_patrol(overlord)[CAPITOL(tributary)] or 0
	DATA.realm_get_quests_raid(overlord)[CAPITOL(tributary)] = 0
	DATA.realm_get_quests_patrol(overlord)[CAPITOL(tributary)] = old_patrol_reward_overlord + old_reward_raid_overlord

	local old_reward_raid_tributary = DATA.realm_get_quests_raid(tributary)[CAPITOL(overlord)] or 0
	local old_patrol_reward_tributary = DATA.realm_get_quests_patrol(overlord)[CAPITOL(tributary)] or 0
	DATA.realm_get_quests_raid(tributary)[CAPITOL(overlord)] = 0
	DATA.realm_get_quests_patrol(overlord)[CAPITOL(overlord)] = old_patrol_reward_tributary + old_reward_raid_tributary

	for _, item in pairs(DATA.realm_get_known_provinces(overlord)) do
		WORLD.provinces_to_update_on_map[item] = item
	end
	WORLD.realms_changed = true
end

---Removes the tributary relationship and explores provinces for the overlord
---@param overlord Realm
---@param tributary Realm
function effects.unset_tributary(overlord, tributary)
	local to_delete = INVALID_ID

	DATA.for_each_realm_subject_relation_from_subject(tributary, function (item)
		local overlord_of_tributary = DATA.realm_subject_relation_get_overlord(item)

		if overlord_of_tributary == overlord then
			to_delete = item
		end
	end)

	if to_delete ~= INVALID_ID then
		DATA.delete_realm_subject_relation(to_delete)
	end

	for _, item in pairs(DATA.realm_get_known_provinces(overlord)) do
		WORLD.provinces_to_update_on_map[item] = item
	end
	WORLD.realms_changed = true
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
