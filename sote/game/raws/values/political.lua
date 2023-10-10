
PoliticalValues = {}

---comment
---@param character Character
---@param province Province
---@return number
function PoliticalValues.power_base(character, province)
    local total = 0
    for k, v in pairs(province.characters) do
        if (v.loyalty == character) or (v == character) then
            total = total + v.popularity
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

---calculates amount of warlods loyal to character and their total army size
---@param character Character
---@return number, number
function PoliticalValues.military_strength(character)
    if character == nil then
        return 0, 0
    end
    
    local total_warlords = 0
    local total_army = 0

    for k, v in pairs(character.province.characters) do
        if (v.loyalty == character or v == character) and v.leading_warband then
            total_warlords = total_warlords + 1
            total_army = total_army + v.leading_warband:size()
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

    for k, v in pairs(character.province.characters) do
        if (v.loyalty == character or v == character) and v.leading_warband and v.leading_warband.status == 'idle' then
            total_warlords = total_warlords + 1
            total_army = total_army + v.leading_warband:size()
        end
    end

    return total_warlords, total_army
end

return PoliticalValues