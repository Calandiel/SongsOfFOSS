local TRAIT = require "game.raws.traits.generic"
local trade_good = require "game.raws.raws-utils".trade_good

local AiPreferences = {}

---comment
---@param character Character
---@return number
function AiPreferences.percieved_inflation(character)
    local temp = trade_good('food')
    local price = character.province.realm:get_price(temp.name)
    if price == 0 then
        price = temp.base_price
    end
    return price / temp.base_price
end

---comment
---@param character Character
function AiPreferences.money_utility(character) 
    local base = 0.1
    if character.traits[TRAIT.GREEDY] then
        base = 1
    end
    return base / AiPreferences.percieved_inflation(character)
end

function AiPreferences.saving_goal(character)
    return AiPreferences.money_utility(character) * 10
end

function AiPreferences.construction_funds(character)
    return math.max(0, character.savings - AiPreferences.saving_goal(character))
end

---comment
---@param character Character
---@return number
function AiPreferences.loyalty_price(character)
    return AiPreferences.percieved_inflation(character) * (10 + character.popularity) * 2
end

---@class AIDecisionFlags
---@field treason boolean?
---@field ambition boolean?
---@field help boolean?
---@field submission boolean?
---@field work boolean?
---@field aggression boolean?

---generates callback which calculates ai preference on demand
---@param character Character
---@param associated_data Character
---@param income number
---@param flags AIDecisionFlags
---@return fun(): number
function AiPreferences.generic_event_option(character, associated_data, income, flags)
    return function ()
        ---@type Character
        character = character

        if income + character.savings < 0 then
            return -9999
        end
        -- print(character.name)

        local base_value = income * AiPreferences.money_utility(character)

        -- print(base_value)

        if flags.treason then
            base_value = base_value + character.culture.culture_group.view_on_treason
        end

        -- print(base_value)

        if flags.treason and character.traits[TRAIT.LOYAL] then
            base_value = base_value - 100
        end

        -- print(base_value)

        if flags.help and character.traits[TRAIT.LOYAL] and character.loyalty == associated_data then
            base_value = base_value + 10
        end

        -- print(base_value)

        if flags.submission then
            base_value = base_value - 10
        end

        -- print(base_value)

        if flags.submission and character.traits[TRAIT.AMBITIOUS] then
            base_value = base_value - 50
        end

        -- print(base_value)

        if flags.ambition and character.traits[TRAIT.AMBITIOUS] then
            base_value = base_value + 50
        end

        if flags.ambition and character.traits[TRAIT.CONTENT] then
            base_value = base_value - 10
        end

        if flags.work and character.traits[TRAIT.LAZY] then
            base_value = base_value - 20
        end

        if flags.work and character.traits[TRAIT.HARDWORKER] then
            base_value = base_value + 20
        end

        if flags.aggression and character.traits[TRAIT.WARLIKE] then
            base_value = base_value + 20
        end

        if flags.aggression and character.traits[TRAIT.CONTENT] then
            base_value = base_value - 20
        end

        if flags.aggression and character.traits[TRAIT.LAZY] then
            base_value = base_value - 20
        end

        -- print(base_value)

        -- print('______________________________')

        return base_value
    end
end

return AiPreferences