local TRAIT = require "game.raws.traits.generic"

local AiPreferences = {}

---comment
---@param character Character
---@return number
function AiPreferences.percieved_inflation(character)
    local temp = RAWS_MANAGER.trade_goods_by_name['food']
    return character.province.realm:get_price(temp) / temp.base_price
end

---comment
---@param character Character
function AiPreferences.money_utility(character) 
    local base = 0.01
    if character.traits[TRAIT.GREEDY] then
        base = 1
    end
    return base / AiPreferences.percieved_inflation(character)
end

---comment
---@param character Character
---@return number
function AiPreferences.loyalty_price(character)
    return AiPreferences.percieved_inflation(character) * (10 + character.popularity)
end

function AiPreferences.generic_event_option(character, associated_data, income, flag_treason, flag_ambition, flag_help, flag_submission)
    return function ()
        ---@type Character
        character = character

        if income + character.savings < 0 then
            return -9999
        end

        local base_value = income * AiPreferences.money_utility(character)

        if flag_treason then
            base_value = base_value + character.culture.culture_group.view_on_treason
        end

        if flag_treason and character.traits[TRAIT.LOYAL] then
            base_value = base_value - 100
        end

        if flag_help and character.traits[TRAIT.LOYAL] and character.loyalty == associated_data then
            base_value = base_value + 10
        end

        if flag_submission then
            base_value = base_value - 10
        end

        if flag_submission and character.traits[TRAIT.AMBITIOUS] then
            base_value = base_value - 100
        end

        if flag_ambition and character.traits[TRAIT.AMBITIOUS] then
            base_value = base_value + 100
        end

        return base_value
    end
end

return AiPreferences