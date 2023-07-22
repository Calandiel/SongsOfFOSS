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
    RewardFlag = "reward flag"
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

return EconomicEffects