local ev = require "game.raws.values.economical"

local triggers = {}

---performs a check if character can buy amount of goods locally
---@param character Character
---@param good TradeGoodReference
---@param amount number
---@return boolean
function triggers.can_buy(character, good, amount)
    if amount <= 0 then
        return false
    end
    local province = character.province
    if province == nil then
        return false
    end
    if province.local_storage[good] < amount then
        return false
    end

    local price = ev.get_local_price(province, good)
    local cost = price * amount

    if character.savings < cost then
        return false
    end

    return true
end

---performs a check if character can sell amount of goods locally
---@param character Character
---@param good TradeGoodReference
---@param amount number
---@return boolean
function triggers.can_sell(character, good, amount)
    if amount <= 0 then
        return false
    end
    local province = character.province
    if province == nil then
        return false
    end
    if character.inventory[good] < amount then
        return false
    end

    local price = ev.get_local_price(province, good)
    local cost = price * amount

    if province.local_wealth < cost then
        return false
    end

    return true
end

return triggers