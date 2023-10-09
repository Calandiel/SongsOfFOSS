
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

return PoliticalValues