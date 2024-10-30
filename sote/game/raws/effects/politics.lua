local tabb = require "engine.table"

local pop_utils = require "game.entities.pop".POP
local province_utils = require "game.entities.province".Province
local warband_utils = require "game.entities.warband"

local demography_effects = require "game.raws.effects.demography"
local politics_values = require "game.raws.values.politics"
local military_effects = require "game.raws.effects.military"
local messages_effects = require "game.raws.effects.messages"

local PoliticalEffects = {}

---Removes realm from the game
---@param realm Realm
function PoliticalEffects.dissolve_realm(realm)
	local guard = DATA.get_realm_guard_from_realm(realm)
	local warband = DATA.realm_guard_get_guard(guard)
	local capitol = DATA.realm_get_capitol(realm)
	if warband ~= INVALID_ID then
		DATA.delete_warband(warband)
	end
	DATA.delete_realm(realm)
	WORLD:unset_settled_province(capitol)
end

---Returns result of coup: true if success, false if failure
---@param character Character
---@return boolean
function PoliticalEffects.coup(character)
	local realm = LOCAL_REALM(character)
	if realm == INVALID_ID then
		return false
	end

	local leader = LEADER(realm)
	if leader == character then
		return false
	end

	local capitol = DATA.realm_get_capitol(realm)
	if capitol ~= PROVINCE(character) then
		return false
	end

	if politics_values.power_base(character, capitol) > politics_values.power_base(leader, capitol) then
		PoliticalEffects.transfer_power(realm, character, POLITICS_REASON.COUP)
		return true
	else
		if WORLD:does_player_see_realm_news(realm) then
			WORLD:emit_notification(NAME(character) .. " failed to overthrow " .. NAME(leader) .. ".")
		end
	end

	return false
end

---comment
---@param character Character
local function roll_traits(character)
	local fat = DATA.fatten_pop(character)
	if love.math.random() > 0.85 then
		pop_utils.add_trait(character, TRAIT.AMBITIOUS)
	end

	if love.math.random() > 0.7 then
		pop_utils.add_trait(character, TRAIT.GREEDY)
		fat.savings = fat.savings + 250
	end

	if love.math.random() > 0.9 then
		pop_utils.add_trait(character, TRAIT.WARLIKE)
	else
		if love.math.random() > 0.6 then
			pop_utils.add_trait(character, TRAIT.TRADER)
			fat.savings = fat.savings + 500
		end
	end

	if love.math.random() > 0.7 and not HAS_TRAIT(character, TRAIT.AMBITIOUS) then
		pop_utils.add_trait(character, TRAIT.LOYAL)
	end

	if love.math.random() > 0.7 and not HAS_TRAIT(character, TRAIT.AMBITIOUS) then
		pop_utils.add_trait(character, TRAIT.CONTENT)
	end

	local organiser_roll = love.math.random()

	if organiser_roll < 0.05 then
		pop_utils.add_trait(character, TRAIT.BAD_ORGANISER)
	elseif organiser_roll < 0.95 then
		-- do nothing ...
	else
		pop_utils.add_trait(character, TRAIT.GOOD_ORGANISER)
	end

	local laziness_roll = love.math.random()
	if laziness_roll < 0.1 then
		pop_utils.add_trait(character, TRAIT.LAZY)
	elseif laziness_roll < 0.9 then
		-- do nothing ...
	else
		pop_utils.add_trait(character, TRAIT.HARDWORKER)
	end
end


---Transfers control over realm to target
---@param realm Realm
---@param target Character
---@param reason POLITICS_REASON
function PoliticalEffects.transfer_power(realm, target, reason)
	-- ---#logging LOGS:write("realm: " .. REALM_NAME(realm) .. "\n new leader: " .. target.name .. "\n" .. "reason: " .. reason .. "\n")
	local fat_realm = DATA.fatten_realm(realm)
	local fat_target = DATA.fatten_pop(target)
	local leadership = DATA.get_realm_leadership_from_realm(realm)
	local depose_message = ""
	if leadership ~= INVALID_ID then
		local current_leader = DATA.realm_leadership_get_leader(leadership)
		local fat_current_leader = DATA.fatten_pop(current_leader)
		if WORLD.player_character == current_leader then
			depose_message = "I am no longer the leader of " .. fat_realm.name .. '.'
		elseif WORLD:does_player_see_realm_news(realm) then
			depose_message = fat_current_leader.name .. " is no longer the leader of " .. fat_realm.name .. '.'
		end
	end
	local new_leader_message = fat_target.name .. " is now the leader of " .. fat_realm.name .. '. Reason: ' .. DATA.politics_reason_get_description(reason)
	if WORLD.player_character == target then
		new_leader_message = "I am now the leader of " .. fat_realm.name .. '. Reason: ' .. DATA.politics_reason_get_description(reason)
	end
	if WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification(depose_message .. " " .. new_leader_message)
	end

	if leadership ~= INVALID_ID then
		local current_leader = DATA.realm_leadership_get_leader(leadership)
		local fat_current_leader = DATA.fatten_pop(current_leader)
		fat_current_leader.rank = CHARACTER_RANK.NOBLE
		DATA.realm_leadership_set_leader(leadership, target)
	else
		DATA.force_create_realm_leadership(target, realm)
	end

	if fat_target.rank ~= CHARACTER_RANK.CHIEF then
		SET_REALM(target, realm)
	end

	fat_target.rank = CHARACTER_RANK.CHIEF
	-- PoliticalEffects.remove_overseer(realm)
end

---comment
---@param realm Realm
---@param overseer Character
function PoliticalEffects.set_overseer(realm, overseer)
	-- ---#logging LOGS:write("realm: " .. REALM_NAME(realm) .. "\n new overseer: " .. overseer.name .. "\n")
	local overseership = DATA.get_realm_overseer_from_realm(realm)

	if overseership == INVALID_ID then
		DATA.force_create_realm_overseer(overseer, realm)
		messages_effects.on_overseer_set(realm, overseer)
	else
		local old_overseer = DATA.realm_overseer_get_overseer(overseership)
		PoliticalEffects.medium_popularity_decrease(old_overseer, realm)
		DATA.realm_overseer_set_overseer(overseership, overseer)
		messages_effects.on_overseer_change(realm, old_overseer, overseer)
	end

	PoliticalEffects.medium_popularity_boost(overseer, realm)
end

---Sets character as a guard leader of the realm
---Assumes that guard exists
---@param realm Realm
---@param guard_leader Character
function PoliticalEffects.set_guard_leader(realm, guard_leader)
	local realm_guard = DATA.get_realm_guard_from_realm(realm)
	local guard = DATA.realm_guard_get_guard(realm_guard)
	military_effects.set_recruiter(guard, guard_leader)

	if WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification(NAME(guard_leader) .. " now commands guards of " .. DATA.realm_get_name(realm) .. ".")
	end
end

---Unsets character as a guard leader of the realm
---Assumes that guard exists
---@param realm Realm
function PoliticalEffects.remove_guard_leader(realm)
	local realm_guard = DATA.get_realm_guard_from_realm(realm)
	local guard = DATA.realm_guard_get_guard(realm_guard)

	local guard_leadership = DATA.get_warband_recruiter_from_warband(guard)
	local guard_leader = DATA.warband_recruiter_get_recruiter(guard_leadership)

	if guard_leader == INVALID_ID then
		return
	end

	military_effects.unset_recruiter(guard, guard_leader)

	local command = DATA.get_warband_commander_from_warband(guard)
	if command ~= INVALID_ID then
		local commander = DATA.warband_commander_get_commander(command)

		if guard_leader == commander then
			warband_utils.unset_commander(guard)
		end
	end

	if guard_leader and WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification(NAME(guard_leader) .. " is no longer a guard commander of " .. DATA.realm_get_name(realm) .. ".")
	end
end

---comment
---@param realm Realm
function PoliticalEffects.remove_overseer(realm)
	local fat_realm = DATA.fatten_realm(realm)
	local overseership = DATA.get_realm_overseer_from_realm(realm)
	if overseership == INVALID_ID then
		return
	end

	local overseer = DATA.realm_overseer_get_overseer(overseership)
	local fat_overseer = DATA.fatten_pop(overseer)

	DATA.delete_realm_overseer(overseership)

	if overseer ~= INVALID_ID then
		PoliticalEffects.medium_popularity_decrease(overseer, realm)
		if WORLD:does_player_see_realm_news(realm) then
			WORLD:emit_notification(fat_overseer.name .. " is no longer an overseer of " .. fat_realm.name .. ".")
		end
	end
end

---comment
---@param realm Realm
---@param character Character
function PoliticalEffects.set_tribute_collector(realm, character)
	DATA.force_create_tax_collector(character, realm)
	PoliticalEffects.small_popularity_boost(character, realm)

	if WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification(NAME(character) .. " had became a tribute collector.")
	end
end

---comment
---@param character Character
---@param realm Realm
---@param x number
function PoliticalEffects.change_popularity(character, realm, x)
	DATA.for_each_popularity_from_who(character, function (item)
		local candidate_realm = DATA.popularity_get_where(item)
		if candidate_realm == realm then
			DATA.popularity_inc_value(item, x)
		end
	end)
end

---comment
---@param character Character
---@param realm Realm
function PoliticalEffects.small_popularity_boost(character, realm)
	PoliticalEffects.change_popularity(character, realm, 0.1)
end

---comment
---@param character Character
---@param realm Realm
function PoliticalEffects.medium_popularity_boost(character, realm)
	PoliticalEffects.change_popularity(character, realm, 0.5)
end

---comment
---@param character Character
---@param realm Realm
function PoliticalEffects.huge_popularity_boost(character, realm)
	PoliticalEffects.change_popularity(character, realm, 1)
end

---comment
---@param character Character
---@param realm Realm
function PoliticalEffects.small_popularity_decrease(character, realm)
	PoliticalEffects.change_popularity(character, realm, -0.1)
end

---comment
---@param character Character
---@param realm Realm
function PoliticalEffects.medium_popularity_decrease(character, realm)
	PoliticalEffects.change_popularity(character, realm, -0.5)
end

---comment
---@param character Character
---@param realm Realm
function PoliticalEffects.huge_popularity_decrease(character, realm)
	PoliticalEffects.change_popularity(character, realm, -1)
end

---comment
---@param character Character
---@param realm Realm
---@param wealth number
function PoliticalEffects.popularity_shift_scaled_with_wealth(character, realm, wealth)
	local population = province_utils.local_population(CAPITOL(realm))
	PoliticalEffects.change_popularity(character, realm, wealth / (population + 1))
end

---current pop province must be equal to the province where he is promoted
---@param pop pop_id
---@param reason POLITICS_REASON
function PoliticalEffects.grant_nobility(pop, reason)
	-- ---#logging LOGS:write("realm: " .. REALM_NAME(PROVINCE_REALM(province)) .. "\n new noble: " .. pop.name .. "\n" .. "reason: " .. reason .. "\n")

	-- print(pop.name, "becomes noble")

	local province = PROVINCE(pop)
	local realm = LOCAL_REALM(pop)

	-- break parent-child link with pops
	---@type parent_child_relation_id[]
	local links_to_break = {}

	DATA.for_each_parent_child_relation_from_parent(pop, function (item)
		table.insert(links_to_break, item)
	end)
	local parent = DATA.parent_child_relation_get_parent(DATA.get_parent_child_relation_from_child(pop))
	if parent ~= INVALID_ID then
		table.insert(links_to_break, DATA.get_parent_child_relation_from_child(pop))
	end
	for _, item in pairs(links_to_break) do
		DATA.delete_parent_child_relation(item)
	end

	demography_effects.fire_pop(pop)
	warband_utils.unregister_military(pop)

	-- local pop_location = DATA.get_pop_location_from_pop(pop)
	-- DATA.delete_pop_location(pop_location)

	province_utils.add_character(province, pop)
	province_utils.set_home(province, pop)

	DATA.pop_set_rank(pop, CHARACTER_RANK.NOBLE)
	SET_REALM(pop, realm)
	DATA.pop_set_former_pop(pop, true)
	PoliticalEffects.change_popularity(pop, realm, 0.1)
	roll_traits(pop)

	if WORLD:does_player_see_province_news(province) then
		WORLD:emit_notification(
			NAME(pop) .. " was granted nobility due to reason: " .. DATA.politics_reason_get_description(reason)
		)
	end
end

---commenting
---@param province Province
---@param x number
function PoliticalEffects.mood_shift(province, x)
	local mood = DATA.province_get_mood(province)
	DATA.province_set_mood(province, math.max(0, mood + x))
end

---commenting
---@param province Province
function PoliticalEffects.mood_minor_increase(province)
	PoliticalEffects.mood_shift(province, 0.025)
end

---commenting
---@param province Province
function PoliticalEffects.mood_medium_increase(province)
	PoliticalEffects.mood_shift(province, 0.5)
end

---commenting
---@param province Province
function PoliticalEffects.mood_major_increase(province)
	PoliticalEffects.mood_shift(province, 0.1)
end

---commenting
---@param province Province
function PoliticalEffects.mood_minor_decrease(province)
	PoliticalEffects.mood_shift(province, -0.025)
end

---commenting
---@param province Province
function PoliticalEffects.mood_medium_decrease(province)
	PoliticalEffects.mood_shift(province, -0.5)
end

---commenting
---@param province Province
function PoliticalEffects.mood_major_decrease(province)
	PoliticalEffects.mood_shift(province, -0.1)
end

---comment
---@param province Province
---@param wealth number
function PoliticalEffects.mood_shift_from_wealth_shift(province, wealth)
	local per_pop_wealth = wealth / (province_utils.local_population(province) + 1)
	PoliticalEffects.mood_shift(province, per_pop_wealth)
end

---comment
---@param province Province
---@param reason POLITICS_REASON
---@return Character?
function PoliticalEffects.grant_nobility_to_random_pop(province, reason)
	local item = tabb.random_select_from_array(DATA.filter_array_home_from_home(province, function (item)
		local pop = DATA.home_get_pop(item)
		if IS_CHARACTER(pop) then
			return false
		end
		if PROVINCE(pop) ~= province then
			return false
		end
		return true
	end))

	if item ~= nil then
		PoliticalEffects.grant_nobility(DATA.home_get_pop(item), reason)
		return DATA.home_get_pop(item)
	end

	return nil
end

---comment
---@param realm Realm
---@param province Province
---@param race Race
---@param faith Faith
---@param culture Culture
---@return Character
function PoliticalEffects.generate_new_noble(realm, province, race, faith, culture)
	local fat_race = DATA.fatten_race(race)

	local character = pop_utils.new(
		race,
		faith,
		culture,
		love.math.random() > fat_race.males_per_hundred_females / (100 + fat_race.males_per_hundred_females),
		love.math.random(fat_race.adult_age, fat_race.max_age)
	)

	local fat = DATA.fatten_pop(character)
	fat.rank = CHARACTER_RANK.NOBLE

	fat.savings = fat.savings + math.sqrt(fat.age) * 10

	roll_traits(character)
	SET_REALM(character, realm)
	province_utils.add_character(province, character)
	province_utils.add_pop(province, character)
	province_utils.set_home(province, character)

	return character
end

return PoliticalEffects
