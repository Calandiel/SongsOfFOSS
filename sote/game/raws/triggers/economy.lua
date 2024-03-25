local ev = require "game.raws.values.economical"
local TRADE_LAW = require "game.raws.laws.trade"

local triggers = {}

---@enum TRADE_FAILURE_REASONS
triggers.TRADE_FAILURE_REASONS = {
    INVALID_AMOUNT = "Invalid amount. ",
    INVALID_PROVINCE = "Invalid province. ",
    LOCAL_WEALTH_IS_TOO_LOW = "Not enough local wealth. ",
    CHARACTER_WEALTH_IS_TO_LOW = "Not enough savings. ",
    LOCAL_GOODS_IS_TOO_LOW = "Not enough goods in local stockpile. ",
    CHARACTER_GOODS_IS_TOO_LOW = "Character doesn't have enough goods. ",
    NO_PERMISSION = "Character doesn't have permission to trade here. "
}

---Checks if character is allowed to trade in a given realm
---@param character Character
---@param realm Realm
---@return boolean
function triggers.allowed_to_trade(character, realm)
    if realm == nil then
        return true
    end

    if realm.trading_right_law == TRADE_LAW.TRADE_RIGHT.GUESTS then
        return true
    end

    if realm.trading_right_law == TRADE_LAW.TRADE_RIGHT.NOBLES then
        if character.realm == realm or realm.trading_right_given_to[character] then
            return true
        end
    end

    if realm.trading_right_law == TRADE_LAW.TRADE_RIGHT.PERMISSION_ONLY then
        if realm.trading_right_given_to[character] then
            return true
        end
    end

    return false
end

---performs a check if character can buy amount of goods locally
---@param character Character
---@param good TradeGoodReference
---@param amount number
---@return boolean, TRADE_FAILURE_REASONS[]
function triggers.can_buy(character, good, amount)
    local response = true;
    local reasons = {}

    if amount <= 0 then
        response = false
        table.insert(reasons, triggers.TRADE_FAILURE_REASONS.INVALID_AMOUNT)
    end

    local province = character.province
    if province == nil then
        response = false
        table.insert(reasons, triggers.TRADE_FAILURE_REASONS.INVALID_PROVINCE)
    end

    if province then
        if (province.local_storage[good] or 0) < amount then
            response = false
            table.insert(reasons, triggers.TRADE_FAILURE_REASONS.LOCAL_GOODS_IS_TOO_LOW)
        end

        local price = ev.get_local_price(province, good)
        local cost = price * amount

        if character.savings < cost then
            response = false
            table.insert(reasons, triggers.TRADE_FAILURE_REASONS.CHARACTER_WEALTH_IS_TO_LOW)
        end

        if not triggers.allowed_to_trade(character, province.realm) then
            response = false
            table.insert(reasons, triggers.TRADE_FAILURE_REASONS.NO_PERMISSION)
        end
    end

    return response, reasons
end

---performs a check if character can sell amount of goods locally
---@param character Character
---@param good TradeGoodReference
---@param amount number
---@return boolean, TRADE_FAILURE_REASONS[]
function triggers.can_sell(character, good, amount)
    local response = true;
    local reasons = {}

    if (character.inventory[good] or 0) < amount then
        response = false
        table.insert(reasons, triggers.TRADE_FAILURE_REASONS.CHARACTER_GOODS_IS_TOO_LOW)
    end

    if amount <= 0 then
        response = false
        table.insert(reasons, triggers.TRADE_FAILURE_REASONS.INVALID_AMOUNT)
    end

    local province = character.province
    if province == nil then
        response = false
        table.insert(reasons, triggers.TRADE_FAILURE_REASONS.INVALID_PROVINCE)
    end

    if province then
        local price = ev.get_pessimistic_local_price(province, good, amount, true)
        local cost = price * amount

        if province.trade_wealth < cost then
            response = false
            table.insert(reasons, triggers.TRADE_FAILURE_REASONS.LOCAL_WEALTH_IS_TOO_LOW)
        end

        if not triggers.allowed_to_trade(character, province.realm) then
            response = false
            table.insert(reasons, triggers.TRADE_FAILURE_REASONS.NO_PERMISSION)
        end
    end

    return response, reasons
end

return triggers