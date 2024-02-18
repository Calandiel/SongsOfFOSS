local tabb = require "engine.table"

local pop = require "game.entities.pop"

local ranks = require "game.raws.ranks.character_ranks"
local PoliticalValues = require "game.raws.values.political"

local TRAIT = require "game.raws.traits.generic"

local military_effects = require "game.raws.effects.military"

local PoliticalEffects = {}

---@enum POLITICAL_REASON
PoliticalEffects.reasons = {
	NOT_ENOUGH_NOBLES = "political vacuum",
	INITIAL_NOBLE = "initial noble",
	POPULATION_GROWTH = "population growth",
	EXPEDITION_LEADER = "expedition leader",
	SUCCESSION = "succession",
	COUP = "coup",
	INITIAL_RULER = "first ruler",
	OTHER = "other"
}

---Removes realm from the game
-- Does not handle logic of cleaning up characters and leaders
---@param realm Realm
function PoliticalEffects.dissolve_realm(realm)
	WORLD.realms[realm.realm_id] = nil
	military_effects.dissolve_guard(realm)
	realm:remove_province(realm.capitol)
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
		PoliticalEffects.transfer_power(character.province.realm, character, PoliticalEffects.reasons.COUP)
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
	if love.math.random() > 0.85 then
		character.traits[TRAIT.AMBITIOUS] = TRAIT.AMBITIOUS
	end

	if love.math.random() > 0.7 then
		character.traits[TRAIT.GREEDY] = TRAIT.GREEDY
	end

	if love.math.random() > 0.9 then
		character.traits[TRAIT.WARLIKE] = TRAIT.WARLIKE
	else
		if love.math.random() > 0.6 then
			character.traits[TRAIT.TRADER] = TRAIT.TRADER
			character.savings = character.savings + 500
		end
	end

	if love.math.random() > 0.7 and not character.traits[TRAIT.AMBITIOUS] then
		character.traits[TRAIT.LOYAL] = TRAIT.LOYAL
	end

	if love.math.random() > 0.7 and not character.traits[TRAIT.AMBITIOUS] then
		character.traits[TRAIT.CONTENT] = TRAIT.CONTENT
	end

	local organiser_roll = love.math.random()

	if organiser_roll < 0.1 then
		character.traits[TRAIT.BAD_ORGANISER] = TRAIT.BAD_ORGANISER
	elseif organiser_roll < 0.9 then
		-- do nothing ...
	else
		character.traits[TRAIT.GOOD_ORGANISER] = TRAIT.GOOD_ORGANISER
	end

	local laziness_roll = love.math.random()
	if laziness_roll < 0.1 then
		character.traits[TRAIT.LAZY] = TRAIT.LAZY
	elseif laziness_roll < 0.9 then
		-- do nothing ...
	else
		character.traits[TRAIT.HARDWORKER] = TRAIT.HARDWORKER
	end
end


---Transfers control over realm to target
---@param realm Realm
---@param target Character
---@param reason POLITICAL_REASON
function PoliticalEffects.transfer_power(realm, target, reason)
	-- LOGS:write("realm: " .. realm.name .. "\n new leader: " .. target.name .. "\n" .. "reason: " .. reason .. "\n")

	local depose_message = ""
	if realm.leader ~= nil then
		if WORLD.player_character == realm.leader then
			depose_message = "I am no longer the leader of " .. realm.name .. '.'
		elseif WORLD:does_player_see_realm_news(realm) then
			depose_message = realm.leader.name .. " is no longer the leader of " .. realm.name .. '.'
		end
	end
	local new_leader_message = target.name .. " is now the leader of " .. realm.name .. '.'
	if WORLD.player_character == target then
		new_leader_message = "I am now the leader of " .. realm.name .. '.'
	end
	if WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification(depose_message .. " " .. new_leader_message)
	end

	if realm.leader then
		realm.leader.rank = ranks.NOBLE
		realm.leader.leader_of[realm] = nil
	end

	if target.rank ~= ranks.CHIEF then
		target.realm = realm
	end

	target.rank = ranks.CHIEF
	PoliticalEffects.remove_overseer(realm)

	target.leader_of[realm] = realm

	realm.leader = target
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
	realm.capitol_guard.commander = guard_leader

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
	realm.capitol_guard.commander = nil

	if guard_leader and WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification(guard_leader.name .. " no longer commands guards of " .. realm.name .. ".")
	end
end

---comment
---@param realm Realm
function PoliticalEffects.remove_overseer(realm)
	local overseer = realm.overseer
	realm.overseer = nil

	if overseer then
		PoliticalEffects.medium_popularity_decrease(overseer, realm)
	end

	if overseer and WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification(overseer.name .. " is no longer an overseer of " .. realm.name .. ".")
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
---@param pop POP
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
	for _,v in pairs(pop.children) do
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
	local pop = tabb.random_select_from_set(tabb.filter(province.home_to,function(a)return not a:is_character() end))

	if pop then
		PoliticalEffects.grant_nobility(pop, province, reason)
	end

	return pop
end

---comment
---@param realm Realm
---@param province Province
---@param race Race
---@param faith Faith
---@param culture Culture
---@return Character
function PoliticalEffects.generate_new_noble(realm, province, race, faith, culture)
	local character = pop.POP:new(
		race,
		faith,
		culture,
		love.math.random() > race.males_per_hundred_females / (100 + race.males_per_hundred_females),
		love.math.random(race.adult_age, race.max_age),
		province, province, true
	)
	character.rank = ranks.NOBLE

	character.savings = character.savings + math.sqrt(character.age) * 10

	roll_traits(character)
	character.realm = realm
	province:add_character(character)
	province:set_home(character)

	return character
end

return PoliticalEffects