local ut = require "game.ui-utils"

local ev = require "game.raws.values.economical"
local et = require "game.raws.triggers.economy"
local traits = require "game.raws.traits.generic"

local EconomicEffects = {}

---@enum EconomicReason
EconomicEffects.reasons = {
    Raid = "raid",
    Donation = "donation",
    MonthlyChange = "monthly change",
    YearlyChange = "yearly change",
    Infrastructure = "infrastructure",
    Education = "education",
    Court = "court",
    Military = "military",
    Exploration = "exploration",
    Upkeep = "upkeep",
    NewMonth = "new month",
    LoyaltyGift = "loyalty gift",
    Building = "building",
    BuildingIncome = "building income",
    Treasury = "treasury",
    Budget = "budget",
    Waste = "waste",
    Tribute = "tribute",
    Inheritance = "inheritance",
    Trade = "trade",
    Warband = "warband",
    Water = "water",
    Food = "food",
    OtherNeeds = "other needs",
    Forage = "forage",
    Work = "work",
    Other = "other",
    Siphon = "siphon",
    TradeSiphon = "trade siphon",
    Quest = "quest",
    NeighborSiphon = "neigbour siphon",
    Colonisation = "colonisation",
    Tax = "tax",
    Negotiations = "negotiations"
}

---Change realm treasury and display effects to player
---@param realm Realm
---@param x number
---@param reason EconomicReason
function EconomicEffects.change_treasury(realm, x, reason)
    realm.budget.treasury = realm.budget.treasury + x
    if realm.budget.treasury_change_by_category[reason] == nil then
        realm.budget.treasury_change_by_category[reason] = 0
    end
    realm.budget.treasury_change_by_category[reason] = realm.budget.treasury_change_by_category[reason] + x

    if reason == EconomicEffects.reasons.Tax and x > 0 then
        realm.tax_collected_this_year = realm.tax_collected_this_year + x
    end

    EconomicEffects.display_treasury_change(realm, x, reason)
end


---Register budget incomes and display them
---@param realm Realm
---@param x number
---@param reason EconomicReason
function EconomicEffects.register_income(realm, x, reason)
    realm.budget.change = realm.budget.change + x
    if realm.budget.income_by_category[reason] == nil then
        realm.budget.income_by_category[reason] = 0
    end

    if reason == EconomicEffects.reasons.Tax and x > 0 then
        realm.tax_collected_this_year = realm.tax_collected_this_year + x
    end

    realm.budget.income_by_category[reason] = realm.budget.income_by_category[reason] + x
    EconomicEffects.display_treasury_change(realm, x, reason)
end


---Register budget spendings and display them
---@param realm Realm
---@param x number
---@param reason EconomicReason
function EconomicEffects.register_spendings(realm, x, reason)
    if realm.budget.spending_by_category[reason] == nil then
        realm.budget.spending_by_category[reason] = 0
    end
    realm.budget.spending_by_category[reason] = realm.budget.spending_by_category[reason] + x
    EconomicEffects.display_treasury_change(realm, -x, reason)
end


---Change pop savings and display effects to player
---@param pop POP
---@param x number
---@param reason EconomicReason
function EconomicEffects.add_pop_savings(pop, x, reason)
    pop.savings = pop.savings + x

    if pop.savings ~= pop.savings then
        error("BAD POP SAVINGS INCREASE: " .. tostring(x) .. " " .. reason)
    end

    if math.abs(x) > 0 then
        EconomicEffects.display_character_savings_change(pop, x, reason)
    end
end

function EconomicEffects.display_character_savings_change(pop, x, reason)
    if WORLD.player_character == pop then
        WORLD:emit_treasury_change_effect(x, reason, true)
    end
end

function EconomicEffects.display_treasury_change(realm, x, reason)
    if WORLD:does_player_control_realm(realm) then
        WORLD:emit_treasury_change_effect(x, reason)
    end
end

---comment
---@param realm Realm
---@param x number
function EconomicEffects.set_education_budget(realm, x)
    realm.budget.education.ratio = x
end
---@param realm Realm
---@param x number
function EconomicEffects.set_court_budget(realm, x)
    realm.budget.court.ratio = x
end
---@param realm Realm
---@param x number
function EconomicEffects.set_infrastructure_budget(realm, x)
    realm.budget.infrastructure.ratio = x
end
---@param realm Realm
---@param x number
function EconomicEffects.set_military_budget(realm, x)
    realm.budget.military.ratio = x
end

---comment
---@param budget BudgetCategory
---@param x number
function EconomicEffects.set_budget(budget, x)
    budget.ratio = math.max(0, x)
end

---Directly inject money from treasury to budget category
---@param realm Realm
---@param budget_category BudgetCategory
---@param x number
---@param reason EconomicReason
function EconomicEffects.direct_investment(realm, budget_category, x, reason)
    EconomicEffects.change_treasury(realm, -x, reason)
    budget_category.budget = budget_category.budget + x
end

--- Directly injects money to province infrastructure
---@param realm Realm
---@param province Province
---@param x number
function EconomicEffects.direct_investment_infrastructure(realm, province, x)
    EconomicEffects.change_treasury(realm, -x, EconomicEffects.reasons.Infrastructure)
    province.infrastructure_investment = province.infrastructure_investment + x
end

---commenting
---@param province Province
---@param x number
---@param reason EconomicReason
function EconomicEffects.change_local_wealth(province, x, reason)
    province.local_wealth = province.local_wealth + x

    -- if WORLD.player_character then
    --     if WORLD.player_character.province == province then
    --         print("province local wealth change")
    --         print(x)
    --         print(reason)
    --         print("current_wealth: ")
    --         print(province.local_wealth)
    --     end
    -- end
end

---comment
---@param building Building
---@param pop POP?
function EconomicEffects.set_ownership(building, pop)
    building.owner = pop

    if pop then
        pop.owned_buildings[building] = building
    end

    if pop and WORLD:does_player_see_province_news(building.province) then
        if WORLD.player_character == pop then
            WORLD:emit_notification(building.type.name .. " is now owned by me, " .. pop.name .. ".")
        else
            WORLD:emit_notification(building.type.name .. " is now owned by " .. pop.name .. ".")
        end
    end
end

---@param building Building
function EconomicEffects.unset_ownership(building)
    local owner = building.owner

    if owner == nil then
        return
    end

    owner.owned_buildings[building] = nil

    if WORLD:does_player_see_province_news(owner.province) then
        if WORLD.player_character == owner then
            WORLD:emit_notification(building.type.name .. " is no longer owned by me, " .. owner.name .. ".")
        else
            WORLD:emit_notification(building.type.name .. " is no longer owned by " .. owner.name .. ".")
        end
    end
end

---comment
---@param building_type BuildingType
---@param province Province
---@param tile Tile?
---@param owner POP?
---@return Building
function EconomicEffects.construct_building(building_type, province, tile, owner)
    local Building = require "game.entities.building".Building
    local result_building = Building:new(province, building_type, tile)
    EconomicEffects.set_ownership(result_building, owner)

    if WORLD:does_player_see_province_news(province) then
        WORLD:emit_notification(building_type.name .. " was constructed in " .. province.name .. ".")
    end
    return result_building
end

---comment
---@param building Building
function EconomicEffects.destroy_building(building)
    EconomicEffects.unset_ownership(building)
    building:remove_from_province()
end

---comment
---@param building_type BuildingType
---@param province Province
---@param tile Tile?
---@param owner POP?
---@param overseer POP?
---@param public boolean
---@return Building
function EconomicEffects.construct_building_with_payment(building_type, province, tile, owner, overseer, public)
    local construction_cost = ev.building_cost(building_type, overseer, public)
    local building = EconomicEffects.construct_building(building_type, province, tile, owner)

    if public or (owner == nil) then
        EconomicEffects.change_treasury(province.realm, -construction_cost, EconomicEffects.reasons.Building)
    else
        EconomicEffects.add_pop_savings(owner, -construction_cost, EconomicEffects.reasons.Building)
    end

    return building
end


---character collects tribute into his pocket and returns collected value
---@param collector Character
---@param realm Realm
---@return number
function EconomicEffects.collect_tribute(collector, realm)
    local tribute_amount = math.min(10, math.floor(realm.budget.tribute.budget))

    if WORLD:does_player_see_realm_news(realm) then
        WORLD:emit_notification("Tribute collector had arrived. Another day of humiliation. " .. tribute_amount .. MONEY_SYMBOL .. " were collected.")
    end

    EconomicEffects.register_spendings(realm, tribute_amount, EconomicEffects.reasons.Tribute)
    realm.budget.tribute.budget = realm.budget.tribute.budget - tribute_amount

    EconomicEffects.add_pop_savings(collector, tribute_amount, EconomicEffects.reasons.Tribute)

    return tribute_amount
end

---@param collector Character
---@param realm Realm
---@param tribute number
function EconomicEffects.return_tribute_home(collector, realm, tribute)
    local payment_multiplier = 0.1
    if collector.traits[traits.GREEDY] then
        payment_multiplier = 0.5
    end

    local payment = tribute * payment_multiplier
    local to_treasury = tribute - payment

    if WORLD:does_player_see_realm_news(realm) then
        WORLD:emit_notification("Tribute collector had arrived back. He brought back " .. to_treasury .. MONEY_SYMBOL .. " wealth.")
    end

    EconomicEffects.register_income(realm,      to_treasury, EconomicEffects.reasons.Tribute)
    EconomicEffects.add_pop_savings(collector,  -to_treasury, EconomicEffects.reasons.Tribute)
end


---comment
---@param province Province
---@param good TradeGoodReference
---@param x number
function EconomicEffects.change_local_price(province, good, x)
    province.local_prices[good] = math.max(0.001, (province.local_prices[good] or 0) + x)

    if province.local_prices[good] ~= province.local_prices[good] or province.local_prices[good] == math.huge then
        error(
            "INVALID PRICE CHANGE"
            .. "\n change = "
            .. tostring(x)
        )
    end
end

---comment
---@param province Province
---@param good TradeGoodReference
---@param x number
function EconomicEffects.change_local_stockpile(province, good, x)
    province.local_storage[good] = math.max(0, (province.local_storage[good] or 0) + x)

    if province.local_storage[good] ~= province.local_storage[good] then
        error(
            "INVALID LOCAL STOCKPILE CHANGE"
            .. "\n change = "
            .. tostring(x)
        )
    end
end

---comment
---@param province Province
---@param good TradeGoodReference
function EconomicEffects.decay_local_stockpile(province, good)
    province.local_storage[good] = (province.local_storage[good] or 0) * 0.9
end

---comment
---@param character Character
---@param good TradeGoodReference
---@param amount number
function EconomicEffects.buy(character, good, amount)
    local can_buy, _ = et.can_buy(character, good, amount)
    if not can_buy then
        return false
    end

    -- can_buy validates province
    ---@type Province
    local province = character.province
    local price = ev.get_local_price(province, good)

    if character.price_memory[good] == nil then
        character.price_memory[good] = price
    else
        character.price_memory[good] = character.price_memory[good] * (3 / 4) + price * (1 / 4)
    end

    local cost = price * amount

    if cost ~= cost then
        error(
            "WRONG BUY OPERATION "
            .. "\n price = "
            .. tostring(price)
            .. "\n amount = "
            .. tostring(amount)
        )
    end

    EconomicEffects.add_pop_savings(character, -cost, EconomicEffects.reasons.Trade)
    province.trade_wealth = province.trade_wealth + cost
    character.inventory[good] = (character.inventory[good] or 0) + amount

    EconomicEffects.change_local_stockpile(province, good, -amount)

    local trade_volume = (province.local_consumption[good] or 0) + (province.local_production[good] or 0) + amount
    local price_change = amount / trade_volume * PRICE_SIGNAL_PER_STOCKPILED_UNIT * price

    EconomicEffects.change_local_price(province, good, price_change)

    -- print('!!! BUY')

    if WORLD:does_player_see_province_news(province) then
        WORLD:emit_notification("Trader " .. character.name .. " bought " .. amount .. " " .. good .. " for " .. ut.to_fixed_point2(cost) .. MONEY_SYMBOL)
    end

    return true
end

---comment
---@param character Character
---@param good TradeGoodReference
---@param amount number
function EconomicEffects.sell(character, good, amount)
    local can_sell, _ = et.can_sell(character, good, amount)
    if not can_sell then
        return false
    end

    -- can_sell validates province
    ---@type Province
    local province = character.province
    local price = ev.get_pessimistic_local_price(province, good, amount, true)

    if character.price_memory[good] == nil then
        character.price_memory[good] = price
    else
        character.price_memory[good] = character.price_memory[good] * (3 / 4) + price * (1 / 4)
    end

    local cost = price * amount

    if cost ~= cost then
        error(
            "WRONG SELL OPERATION "
            .. "\n price = "
            .. tostring(price)
            .. "\n amount = "
            .. tostring(amount)
        )
    end

    EconomicEffects.add_pop_savings(character, cost, EconomicEffects.reasons.Trade)
    province.trade_wealth = province.trade_wealth - cost
    character.inventory[good] = (character.inventory[good] or 0) - amount
    EconomicEffects.change_local_stockpile(province, good, amount)

    local trade_volume = (province.local_consumption[good] or 0) + (province.local_production[good] or 0) + amount
    local price_change = amount / trade_volume * PRICE_SIGNAL_PER_STOCKPILED_UNIT * price
    EconomicEffects.change_local_price(province, good, -price_change)

    -- print('!!! SELL')

    if WORLD:does_player_see_province_news(province) then
        WORLD:emit_notification("Trader " .. character.name .. " sold " .. amount .. " " .. good .. " for " .. ut.to_fixed_point2(cost) .. MONEY_SYMBOL)
    end
    return true
end

---comment
---@param character Character
---@param realm Realm
---@param amount number
function EconomicEffects.gift_to_tribe(character, realm, amount)
    if character.savings < amount then
        return
    end

    EconomicEffects.add_pop_savings(character, -amount, EconomicEffects.reasons.Donation)
    EconomicEffects.change_treasury(realm, amount, EconomicEffects.reasons.Donation)

    realm.capitol.mood = realm.capitol.mood + amount / realm.capitol:population() / 100
    character.popularity[realm] = (character.popularity[realm] or 0) + amount / (realm.capitol:population() + 1) / 100
end

---comment
---@param character Character
---@param amount number
function EconomicEffects.gift_to_warband(character, amount)
    local warband = character.leading_warband

    if warband == nil then
        return
    end

    if amount > 0 then
        if character.savings < amount then
            amount = character.savings
        end
    else
        if warband.treasury < -amount then
            amount = warband.treasury
        end
    end

    EconomicEffects.add_pop_savings(character, -amount, EconomicEffects.reasons.Warband)
    warband.treasury = warband.treasury + amount
end

---commenting
---@param character Character
---@return number
function EconomicEffects.collect_tax(character)
    local total_tax = 0
    local tax_collection_ability = 0.05
    if character.traits[traits.HARDWORKER] then
        tax_collection_ability = tax_collection_ability + 0.01
    end
    if character.traits[traits.GREEDY] then
        tax_collection_ability = tax_collection_ability + 0.03
    end
    if character.traits[traits.LAZY] then
        tax_collection_ability = tax_collection_ability - 0.01
    end
    for _, pop in pairs(character.province.all_pops) do
        if pop.savings > 0 then
            total_tax = total_tax + pop.savings * tax_collection_ability
            EconomicEffects.add_pop_savings(pop, -pop.savings * tax_collection_ability, EconomicEffects.reasons.Tax)
        end
    end
    return total_tax
end

---Grants trading rights to character
---@param character Character
---@param realm Realm
function EconomicEffects.grant_trade_rights(character, realm)
    character.has_trade_permits_in[realm] = realm
    realm.trading_right_given_to[character] = character
end

---Clears all trading rights of character
---@param character Character
function EconomicEffects.abandon_trade_rights(character)
    ---@type Realm[]
    local realms = {}

    for _, realm in pairs(character.has_trade_permits_in) do
        table.insert(realms, realm)
    end

    for _, realm in ipairs(realms) do
        character.has_trade_permits_in[realm] = nil
        realm.trading_right_given_to[character] = nil
    end
end

---Grants trading rights to character
---@param character Character
---@param realm Realm
function EconomicEffects.grant_building_rights(character, realm)
    character.has_building_permits_in[realm] = realm
    realm.building_right_given_to[character] = character
end

---Clears all trading rights of character
---@param character Character
function EconomicEffects.abandon_building_rights(character)
    ---@type Realm[]
    local realms = {}

    for _, realm in pairs(character.has_building_permits_in) do
        table.insert(realms, realm)
    end

    for _, realm in ipairs(realms) do
        character.has_building_permits_in[realm] = nil
        realm.building_right_given_to[character] = nil
    end
end

return EconomicEffects