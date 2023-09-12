local PoliticalValues = require "game.raws.values.political"

PoliticalEffects = {}

---comment
---@param character Character
function PoliticalEffects.coup(character)
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
    if realm.capitol ~= character.province then
        return
    end

    if PoliticalValues.power_base(character, realm.capitol) > PoliticalValues.power_base(realm.leader, realm.capitol) then
        PoliticalEffects.transfer_power(character.province.realm, character)
    else
        if WORLD:does_player_see_realm_news(realm) then
            WORLD:emit_notification(character.name .. " failed to overthrow " .. realm.leader.name .. ".")
        end
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

    realm.leader = target
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

return PoliticalEffects