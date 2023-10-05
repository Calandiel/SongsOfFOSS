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
}

---Change realm treasury and display effects to player
---@param realm Realm
---@param x number
---@param reason EconomicReason
function EconomicEffects.add_treasury(realm, x, reason)
    realm.treasury = realm.treasury + x
    EconomicEffects.display_treasury_change(realm, x, reason)
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
function EconomicEffects.increase_education_budget(realm, x)
    realm.education_budget = math.max(0, realm.education_budget + x)
    -- realm.monthly_education_investment = realm.tr
end
---@param realm Realm
---@param x number
function EconomicEffects.increase_court_budget(realm, x)
    realm.court_budget = math.max(0, realm.court_budget + x)
end
---@param realm Realm
---@param x number
function EconomicEffects.increase_infrastructure_budget(realm, x)
    realm.infrastructure_budget = math.max(0, realm.infrastructure_budget + x)
end


---comment
---@param building Building
---@param pop POP?
function EconomicEffects.set_ownership(building, pop)
    building.owner = pop

    if pop and WORLD:does_player_see_province_news(building.tile.province) then
        if WORLD.player_character == pop then
            WORLD:emit_notification(building.type.name .. " is now owned by me, " .. pop.name .. ".")
        else
            WORLD:emit_notification(building.type.name .. " is now owned by " .. pop.name .. ".")
        end
    end
end

return EconomicEffects