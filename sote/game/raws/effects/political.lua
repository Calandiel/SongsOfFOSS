local tabb = require "engine.table"

local ranks = require "game.raws.ranks.character_ranks"
local PoliticalValues = require "game.raws.values.political"

PoliticalEffects = {}

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
    province.all_pops[pop] = nil
    province.characters[pop] = pop

    pop.province = province
    pop.realm = province.realm
    pop.popularity[province.realm] = 0.1

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

return PoliticalEffects