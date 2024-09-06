local tabb = require "engine.table"

local pop_utils = require "game.entities.pop".POP
local province_utils = require "game.entities.province".Province

local PoliticalValues = require "game.raws.values.political"


local military_effects = require "game.raws.effects.military"

local PoliticalEffects = {}

---@enum POLITICAL_REASON
PoliticalEffects.reasons = {
	NotEnoughNobles = "political vacuum",
	InitialNoble = "initial noble",
	PopulationGrowth = "population growth",
	ExpeditionLeader = "expedition leader",
	Succession = "succession",
	Coup = "coup",
	InitialRuler = "first ruler",
	Other = "other"
}

---Removes realm from the game
-- Does not handle logic of cleaning up characters and leaders
---@param realm Realm
function PoliticalEffects.dissolve_realm(realm)
	WORLD.realms[realm.realm_id] = nil
	realm.exists = false
	military_effects.dissolve_guard(realm)
	realm:remove_province(realm.capitol)
	WORLD:unset_settled_province(realm.capitol)
end

---Returns result of coup: true if success, false if failure
---@param character Character
---@return boolean
function PoliticalEffects.coup(character)
	if character.province == nil then
		return false
	end
	local realm = character.province.realm
	if realm == nil then
		return false
	end
	if realm.leader == character then
		return false
	end
	if realm.capitol ~= character.province then
		return false
	end

	if PoliticalValues.power_base(character, realm.capitol) > PoliticalValues.power_base(realm.leader, realm.capitol) then
		PoliticalEffects.transfer_power(character.province.realm, character, PoliticalEffects.reasons.Coup)
		return true
	else
		if WORLD:does_player_see_realm_news(realm) then
			WORLD:emit_notification(character.name .. " failed to overthrow " .. realm.leader.name .. ".")
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

	if love.math.random() > 0.7 and not pop_utils.has_trait(character, TRAIT.AMBITIOUS) then
		pop_utils.add_trait(character, TRAIT.LOYAL)
	end

	if love.math.random() > 0.7 and not pop_utils.has_trait(character, TRAIT.AMBITIOUS) then
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
---@param reason POLITICAL_REASON
function PoliticalEffects.transfer_power(realm, target, reason)
	-- LOGS:write("realm: " .. realm.name .. "\n new leader: " .. target.name .. "\n" .. "reason: " .. reason .. "\n")
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
	local new_leader_message = fat_target.name .. " is now the leader of " .. fat_realm.name .. '. Reason: ' .. reason
	if WORLD.player_character == target then
		new_leader_message = "I am now the leader of " .. fat_realm.name .. '. Reason: ' .. reason
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
		local new_leadership = DATA.create_realm_leadership()
		local fat_new_leadership = DATA.fatten_realm_leadership(new_leadership)
		fat_new_leadership.leader = target
		fat_new_leadership.realm = realm
	end

	if fat_target.rank ~= CHARACTER_RANK.CHIEF then
		DATA.pop_set_realm(target, realm)
	end

	fat_target.rank = CHARACTER_RANK.CHIEF
	-- PoliticalEffects.remove_overseer(realm)
end

---comment
---@param realm Realm
---@param overseer Character
function PoliticalEffects.set_overseer(realm, overseer)
	-- LOGS:write("realm: " .. realm.name .. "\n new overseer: " .. overseer.name .. "\n")

	realm.overseer = overseer

	PoliticalEffects.medium_popularity_boost(overseer, realm)

	if WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification(overseer.name .. " is a new overseer of " .. realm.name .. ".")
	end
end

---Sets character as a guard leader of the realm
---@param realm Realm
---@param guard_leader Character
function PoliticalEffects.set_guard_leader(realm, guard_leader)
	military_effects.set_recruiter(realm.capitol_guard, guard_leader)

	if WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification(guard_leader.name .. " now commands guards of " .. realm.name .. ".")
	end
end

---Unsets character as a guard leader of the realm
---@param realm Realm
function PoliticalEffects.remove_guard_leader(realm)
	local guard_leader = realm.capitol_guard.recruiter

	if guard_leader == nil then
		return
	end

	military_effects.unset_recruiter(realm.capitol_guard, guard_leader)
	if guard_leader == realm.capitol_guard.commander then
		realm.capitol_guard:unset_commander()
	end

	if guard_leader and WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification(guard_leader.name .. " no longer commands guards of " .. realm.name .. ".")
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

	DATA.delete_realm_overseer(overseer)

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
	realm.tribute_collectors[character] = character

	PoliticalEffects.small_popularity_boost(character, realm)

	if WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification(character.name .. " had became a tribute collector.")
	end
end

---comment
---@param realm Realm
---@param character Character
function PoliticalEffects.remove_tribute_collector(realm, character)
	realm.tribute_collectors[character] = nil

	PoliticalEffects.small_popularity_decrease(character, realm)

	if WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification(character.name .. " is no longer a tribute collector.")
	end
end

---Banish the character from the realm
---@param character Character
function PoliticalEffects.banish(character)
	if character.province == nil then
		return
	end
	local realm = character.province.realm
	if realm == nil then
		return
	end
	if realm.leader == character then
		return
	end
end

---comment
---@param character Character
---@param realm Realm
---@param x number
function PoliticalEffects.change_popularity(character, realm, x)

	character.popularity[realm] = PoliticalValues.popularity(character, realm) + x
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
---@param pop pop_id
---@param province Province
---@param reason POLITICAL_REASON
function PoliticalEffects.grant_nobility(pop, province, reason)
	-- LOGS:write("realm: " .. province.realm.name .. "\n new noble: " .. pop.name .. "\n" .. "reason: " .. reason .. "\n")

	-- print(pop.name, "becomes noble")

	if province ~= pop.province then
		error(
			"REQUEST TO TURN POP INTO NOBLE FROM INVALID PROVINCE:"
			.. "\n province.name = "
			.. province.name
			.. "\n pop.province.name = "
			.. pop.province.name)
	end

	-- break parent-child link with pops
	if pop.parent then
		pop.parent.children[pop] = nil
		pop.parent = nil
	end
	for _, v in pairs(pop.children) do
		pop.children[v].parent = nil
		pop.children[v] = nil
	end

	province:fire_pop(pop)
	pop:unregister_military()
	province.all_pops[pop] = nil

	province:add_character(pop)
	province:set_home(pop)

	pop.realm = province.realm
	pop.rank = ranks.NOBLE
	pop.popularity[province.realm] = 0.1
	pop.former_pop = true

	roll_traits(pop)

	if province.characters[pop] and pop.province == nil then
		error("SOMETHING IS WRONG!")
	end

	if WORLD:does_player_see_province_news(province) then
		WORLD:emit_notification(pop.name .. " was granted nobility.")
	end
end

---comment
---@param province Province
---@param reason POLITICAL_REASON
---@return Character?
function PoliticalEffects.grant_nobility_to_random_pop(province, reason)
	local pop = tabb.random_select_from_array(DATA.filter_array_home_from_home(province, function (item)
		local pop = DATA.home_get_pop(item)
		if IS_CHARACTER(pop) then
			return false
		end
		if PROVINCE(pop) ~= province then
			return false
		end
		return true
	end))

	if pop ~= INVALID_ID then
		PoliticalEffects.grant_nobility(pop, province, reason)
		return pop
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
	fat.realm = realm
	province_utils.add_character(province, character)
	province_utils.set_home(province, character)

	return character
end

return PoliticalEffects
