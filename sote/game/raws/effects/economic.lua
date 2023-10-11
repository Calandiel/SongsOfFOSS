local eco_values = require "game.raws.values.economical"
local traits = require "game.raws.traits.generic"

EconomicEffects = {}

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
    RewardFlag = "reward flag",
    LoyaltyGift = "loyalty gift",
    Building = "building",
    BuildingIncome = "building income",
    Treasury = "treasury",
    Budget = "budget",
    Waste = "waste",
    Tribute = "tribute",
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
    EconomicEffects.display_character_savings_change(pop, x, reason)
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

---comment
---@param building Building
---@param pop POP?
function EconomicEffects.set_ownership(building, pop)
    building.owner = pop

    if pop and WORLD:does_player_see_province_news(pop.province) then
        if WORLD.player_character == pop then
            WORLD:emit_notification(building.type.name .. " is now owned by me, " .. pop.name .. ".")
        else
            WORLD:emit_notification(building.type.name .. " is now owned by " .. pop.name .. ".")
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
---@param building_type BuildingType
---@param province Province
---@param tile Tile?
---@param owner POP?
---@param overseer POP?
---@param public boolean
---@return Building
function EconomicEffects.construct_building_with_payment(building_type, province, tile, owner, overseer, public)
    local construction_cost = eco_values.building_cost(building_type, overseer, public)
    local building = EconomicEffects.construct_building(building_type, province, tile, owner)

    if public or (owner == nil) then
        EconomicEffects.change_treasury(province.realm, -construction_cost, EconomicEffects.reasons.Building)
    else
        EconomicEffects.add_pop_savings(owner, -construction_cost, EconomicEffects.reasons.Building)
    end

    return building
end


---comment
---@param realm Realm
---@param reward_flag RewardFlag
function EconomicEffects.cancel_reward_flag(realm, reward_flag)
    if realm.reward_flags[reward_flag] == nil then
        return
    end
    EconomicEffects.add_pop_savings(reward_flag.owner, reward_flag.reward, EconomicEffects.reasons.RewardFlag)
    realm:remove_reward_flag(reward_flag)
end

---comment
---@param origin Realm
---@param target Realm
function EconomicEffects.remove_raiding_flags(origin, target)
    ---@type RewardFlag[]
    local flags_to_remove = {}

    for reward_flag, _ in pairs(origin.reward_flags) do
        if reward_flag.target.realm == target then
            table.insert(flags_to_remove, reward_flag)
        end
    end

    for _, flag in pairs(flags_to_remove) do
        EconomicEffects.cancel_reward_flag(origin, flag)
    end
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

return EconomicEffects