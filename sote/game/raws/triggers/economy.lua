local ev = require "game.raws.values.economy"

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
    if realm == INVALID_ID then
        return true
    end

    local fat = DATA.fatten_realm(realm)

    if fat.law_trade == LAW_TRADE.NO_REGULATION then
        return true
    end

    if fat.law_trade == LAW_TRADE.LOCALS_ONLY then
        if REALM(character) == realm then
            return true
        end
    end

    local result = false

    DATA.for_each_personal_rights_from_person(character, function (item)
        local checked_realm = DATA.personal_rights_get_realm(item)
        if checked_realm == realm then
            ---@type boolean
            result = result or DATA.personal_rights_get_can_trade(item)
        end
    end)

    return result
end

---commenting
---@param character Character
---@param realm Realm
---@return boolean
function triggers.allowed_to_build(character, realm)
    if realm == INVALID_ID then
        return true
    end
    if character == INVALID_ID then
        return true --- when population tries to build stuff with local wealth
    end

    local fat = DATA.fatten_realm(realm)

    if fat.law_building == LAW_BUILDING.NO_REGULATION then
        return true
    end

    if fat.law_building == LAW_BUILDING.LOCALS_ONLY then
        if REALM(character) == realm then
            return true
        end
    end

    local result = false

    DATA.for_each_personal_rights_from_person(character, function (item)
        local checked_realm = DATA.personal_rights_get_realm(item)
        if checked_realm == realm then
            ---@type boolean
            result = result or DATA.personal_rights_get_can_build(item)
        end
    end)

    return result
end

---performs a check if character can buy amount of goods locally
---@param character Character
---@param good trade_good_id
---@param amount number
---@return boolean, TRADE_FAILURE_REASONS[]
function triggers.can_buy(character, good, amount)
    local response = true;
    local reasons = {}

    if amount <= 0 then
        response = false
        table.insert(reasons, triggers.TRADE_FAILURE_REASONS.INVALID_AMOUNT)
    end

    local province = PROVINCE(character)

    if province == INVALID_ID then
        response = false
        table.insert(reasons, triggers.TRADE_FAILURE_REASONS.INVALID_PROVINCE)
    end

    if PROVINCE ~= INVALID_ID then
        if DATA.province_get_local_storage(province, good) < amount then
            response = false
            table.insert(reasons, triggers.TRADE_FAILURE_REASONS.LOCAL_GOODS_IS_TOO_LOW)
        end

        local price = ev.get_local_price(province, good)
        local cost = price * amount

        if DATA.pop_get_savings(character) < cost then
            response = false
            table.insert(reasons, triggers.TRADE_FAILURE_REASONS.CHARACTER_WEALTH_IS_TO_LOW)
        end

        if not triggers.allowed_to_trade(character, LOCAL_REALM(character)) then
            response = false
            table.insert(reasons, triggers.TRADE_FAILURE_REASONS.NO_PERMISSION)
        end
    end

    return response, reasons
end

---performs a check if character can buy amount of goods locally
---@param province Province
---@param savings number
---@param use use_case_id
---@param amount number
---@return boolean, TRADE_FAILURE_REASONS[]
function triggers.can_buy_use(province, savings, use, amount)
    local response = true;
    local reasons = {}

    if amount <= 0 then
        response = false
        table.insert(reasons, triggers.TRADE_FAILURE_REASONS.INVALID_AMOUNT)
    end

    if province == INVALID_ID then
        response = false
        table.insert(reasons, triggers.TRADE_FAILURE_REASONS.INVALID_PROVINCE)
    end

    if province ~= INVALID_ID then
        if ev.get_local_amount_of_use(province, use) < amount then
            response = false
            table.insert(reasons, triggers.TRADE_FAILURE_REASONS.LOCAL_GOODS_IS_TOO_LOW)
        end

        local price = ev.get_local_price_of_use(province, use)
        local cost = price * amount

        if savings < cost then
            response = false
            table.insert(reasons, triggers.TRADE_FAILURE_REASONS.CHARACTER_WEALTH_IS_TO_LOW)
        end
    end

    return response, reasons
end

---performs a check if character can sell amount of goods locally
---@param character Character
---@param good trade_good_id
---@param amount number
---@return boolean, TRADE_FAILURE_REASONS[]
function triggers.can_sell(character, good, amount)
    local response = true;
    local reasons = {}

    if DATA.pop_get_inventory(character, good) < amount then
        response = false
        table.insert(reasons, triggers.TRADE_FAILURE_REASONS.CHARACTER_GOODS_IS_TOO_LOW)
    end

    if amount <= 0 then
        response = false
        table.insert(reasons, triggers.TRADE_FAILURE_REASONS.INVALID_AMOUNT)
    end

    local province = PROVINCE(character)
    if province == INVALID_ID then
        response = false
        table.insert(reasons, triggers.TRADE_FAILURE_REASONS.INVALID_PROVINCE)
    end

    if province ~= INVALID_ID then
        local price = ev.get_pessimistic_local_price(province, good, amount, true)
        local cost = price * amount

        if DATA.province_get_trade_wealth(province) < cost then
            response = false
            table.insert(reasons, triggers.TRADE_FAILURE_REASONS.LOCAL_WEALTH_IS_TOO_LOW)
        end

        if not triggers.allowed_to_trade(character, LOCAL_REALM(character)) then
            response = false
            table.insert(reasons, triggers.TRADE_FAILURE_REASONS.NO_PERMISSION)
        end
    end

    return response, reasons
end

return triggers