local tabb = require "engine.table"

local pop = require "game.entities.pop"

local ranks = require "game.raws.ranks.character_ranks"
local PoliticalValues = require "game.raws.values.political"

local TRAIT = require "game.raws.traits.generic"

local PoliticalEffects = {}

---Removes realm from the game
-- Does not handle logic of cleaning up characters and leaders
---@param realm any
function PoliticalEffects.dissolve_realm(realm)
	WORLD.realms[realm.realm_id] = nil
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
		PoliticalEffects.transfer_power(character.province.realm, character)
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
			character.savings = character.savings + 25
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
function PoliticalEffects.transfer_power(realm, target)
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

	realm.leader.rank = ranks.NOBLE
	target.rank = ranks.CHIEF
	PoliticalEffects.remove_overseer(realm)

	realm.leader = target
end

---comment
---@param realm Realm
---@param overseer Character
function PoliticalEffects.set_overseer(realm, overseer)
	realm.overseer = overseer

	PoliticalEffects.medium_popularity_boost(overseer, realm)

	if WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification(overseer.name .. " is a new overseer of " .. realm.name .. ".")
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
function PoliticalEffects.grant_nobility(pop, province)
	province:fire_pop(pop)
	province:unregister_military_pop(pop)
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
---@return Character?
function PoliticalEffects.grant_nobility_to_random_pop(province)
	local pop = tabb.random_select_from_set(province.all_pops)

	if pop then
		PoliticalEffects.grant_nobility(pop, province)
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
		love.math.random(race.adult_age, race.max_age)
	)
	character.rank = ranks.NOBLE

	roll_traits(character)
	character.realm = realm
	province:add_character(character)
	province:set_home(character)

	return character
end

return PoliticalEffects