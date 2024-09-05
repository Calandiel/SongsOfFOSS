
PoliticalValues = {}

---comment
---@param character Character
---@param province province_id
---@return number
function PoliticalValues.power_base(character, province)
    local total = 0
    for k, character_location in pairs(DATA.get_character_location_from_location(province)) do
        local test_character = DATA.character_location_get_character(character_location)
        local loyal_to = DATA.pop_get_loyalty(test_character)
        if (loyal_to == character) or (test_character == character) then
            local realm = DATA.province_get_realm(province)
            if realm then
                total = total + PoliticalValues.popularity(test_character, realm)
            end
        end
    end

    return total
end

---comment
---@param realm Realm
function PoliticalValues.overseer(realm)
    if realm.overseer then
        return realm.overseer
    end
    if realm.leader then
        return realm.leader
    end
    return nil
end

---comment
---@param realm Realm
function PoliticalValues.guard_leader(realm)
    if realm.capitol_guard == nil then return nil end
    return realm.capitol_guard:active_leader()
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

    for k, character_location in pairs(DATA.get_character_location_from_location(province)) do
        local test_character = DATA.character_location_get_character(character_location)
        local loyal_to = DATA.pop_get_loyalty(test_character)
        local leading_warband = DATA.pop_get_leading_warband(test_character)
        if (loyal_to == character or test_character == character) and leading_warband then
            total_warlords = total_warlords + 1
            total_army = total_army + leading_warband:size()
        end
    end

    return total_warlords, total_army
end

---calculates amount of warlods loyal to character and their total army size
---@param character Character
---@return number, number
function PoliticalValues.military_strength_ready(character)
    local total_warlords = 0
    local total_army = 0

    for k, character_location in pairs(DATA.get_character_location_from_location(province)) do
        local test_character = DATA.character_location_get_character(character_location)
        local loyal_to = DATA.pop_get_loyalty(test_character)
        local leading_warband = DATA.pop_get_leading_warband(test_character)
        if (loyal_to == character or test_character == character) and leading_warband and leading_warband.status == 'idle' then
            total_warlords = total_warlords + 1
            total_army = total_army + leading_warband:size()
        end
    end

    return total_warlords, total_army
end

---Returns popularity of a character in a given realm
---@param character Character?
---@param realm Realm?
---@return number
function PoliticalValues.popularity(character, realm)
    if character == nil then
        return 0
    end
    if realm == nil then
        return 0
    end
    local popularity_link = DATA.get_popularity_from_character(character)
    if popularity_link == INVALID_ID then
        return 0
    end
    return DATA.popularity_link_get_value(popularity_link)
end

return PoliticalValues