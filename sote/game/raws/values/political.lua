
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

return PoliticalValues