local province_utils = require "game.entities.province"
local warband_utils = require "game.entities.warband"

local PoliticalValues = {}

---commenting
---@param province province_id
---@return pop_id
function PoliticalValues.province_leader(province)
    local realm_ownership = DATA.get_realm_provinces_from_province(province)
    if realm_ownership == INVALID_ID then
        return INVALID_ID
    end
    local realm = DATA.realm_provinces_get_realm(realm_ownership)
    return PoliticalValues.leader(realm)
end

---@param realm realm_id
---@return pop_id
function PoliticalValues.leader(realm)
    local leadership = DATA.get_realm_leadership_from_realm(realm)
    if leadership == INVALID_ID then
        return INVALID_ID
    end
    return DATA.realm_leadership_get_leader(leadership)
end

---comment
---@param character Character
---@param province province_id
---@return number
function PoliticalValues.power_base(character, province)
    local total = 0
    for k, character_location in pairs(DATA.get_character_location_from_location(province)) do
        local test_character = DATA.character_location_get_character(character_location)
        local loyal_to = LOYAL_TO(test_character)
        if (loyal_to == character) or (test_character == character) then
            local realm = PROVINCE_REALM(province)
            if realm then
                total = total + PoliticalValues.popularity(test_character, realm)
            end
        end
    end

    return total
end

---comment
---@param realm Realm
---@return Character
function PoliticalValues.overseer(realm)
    local overseer = DATA.get_realm_overseer_from_realm(realm)
    local leader = DATA.get_realm_leadership_from_realm(realm)
    if overseer ~= INVALID_ID then
        return DATA.realm_overseer_get_overseer(overseer)
    end
    if leader ~= INVALID_ID then
        return DATA.realm_leadership_get_leader(leader)
    end
    error("NO OVERSEER")
end

---comment
---@param realm Realm
function PoliticalValues.guard_leader(realm)
    local capitol_guard = DATA.get_realm_guard_from_realm(realm)
    if capitol_guard == INVALID_ID then
        return INVALID_ID
    end

    return warband_utils.active_leader(DATA.realm_guard_get_guard(capitol_guard))
end

---calculates amount of warlods loyal to character and their total army size
---@param character Character
---@return number, number
function PoliticalValues.military_strength(character)
    if character == nil then
        return 0, 0
    end
    if DATA.pop_get_dead(character) then
        return 0, 0
    end

    local total_warlords = 0
    local total_army = 0

    DATA.for_each_character_location_from_location(PROVINCE(character), function (item)
        local test_character = DATA.character_location_get_character(item)
        local loyal_to = LOYAL_TO(test_character)
        local leading_warband = LEADER_OF_WARBAND(test_character)

        if leading_warband == INVALID_ID then
            return
        end

        if (loyal_to == character or test_character == character) then
            total_warlords = total_warlords + 1
            total_army = total_army + warband_utils.size(leading_warband)
        end
    end)

    return total_warlords, total_army
end

---calculates amount of warlods loyal to character and their total army size
---@param character Character
---@return number, number
function PoliticalValues.military_strength_ready(character)
    local total_warlords = 0
    local total_army = 0

    DATA.for_each_character_location_from_location(PROVINCE(character), function (item)
        local test_character = DATA.character_location_get_character(item)
        local loyal_to = LOYAL_TO(test_character)
        local leading_warband = LEADER_OF_WARBAND(test_character)

        if leading_warband == INVALID_ID then
            return
        end

        if (loyal_to == character or test_character == character) and DATA.warband_get_status(leading_warband) == WARBAND_STATUS.IDLE then
            total_warlords = total_warlords + 1
            total_army = total_army + warband_utils.size(leading_warband)
        end
    end)

    return total_warlords, total_army
end

---Returns popularity of a character in a given realm
---@param character Character
---@param realm Realm
---@return number
function PoliticalValues.popularity(character, realm)
    if character == INVALID_ID then
        return 0
    end
    if realm == INVALID_ID then
        return 0
    end

    local value = 0

    DATA.for_each_popularity_from_who(character, function (item)
        local item_realm = DATA.popularity_get_where(item)
        if item_realm == realm then
            value = DATA.popularity_get_value(item)
            return
        end
    end)

    return value
end

return PoliticalValues