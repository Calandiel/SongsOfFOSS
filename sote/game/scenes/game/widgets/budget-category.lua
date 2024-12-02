local ui = require "engine.ui";
local uit = require "game.ui-utils"

local ef = require "game.raws.effects.economy"

---comment
---@param rect Rect
---@param name string
---@param realm Realm
---@param budget_category BUDGET_CATEGORY
---@param disable_control boolean
---@param bg boolean
return function (rect, name, realm, budget_category, disable_control, bg)

    if bg then
        local old_style = ui.style.panel_inside
        ui.style.panel_inside = {r=1, g=1, b=1, a=0.05}
        ui.panel(rect)
        ui.style.panel_inside = old_style
    end

    rect.width = rect.width / 6

    -- first part - label for category!
    uit.data_entry(name, "", rect, "Budget breakdown")
    rect.x = rect.x + rect.width

    rect.width = uit.BASE_HEIGHT * 4

    -- second part - current spendings
    uit.money_entry("", DATA.realm_get_budget_to_be_invested(realm, budget_category), rect, "To be invested")
    rect.x = rect.x + rect.width


    -- third part - current incomes
    uit.money_entry("", DATA.realm_get_budget_budget(realm, budget_category), rect, "Current investments")
    rect.x = rect.x + rect.width

    -- fourth part - target spendings
    uit.money_entry("", DATA.realm_get_budget_target(realm, budget_category), rect, "Target investments")
    rect.x = rect.x + rect.width



    local satisfactio_ratio = 1
    if DATA.realm_get_budget_target(realm, budget_category) > 0 then
        satisfactio_ratio = DATA.realm_get_budget_budget(realm, budget_category) / DATA.realm_get_budget_target(realm, budget_category)
    end
    local satisfaction_explanation = ""
    if name == "Education" then
        satisfaction_explanation = "Being above 100% means that your tribe researches new technologies faster."
    end
    if name == "Military" then
        satisfaction_explanation = "Being above 100% means that your tribe can support current army at least for a year."
    end
    if name == "Infrastructure" then
        satisfaction_explanation = "Being above 100% means that your infrastructure spendings are fully satisfied."
    end
    if name == "Court" then
        satisfaction_explanation = "This value tells how much wealth your court receives from tribal treasury compared to their expectations. This value influences decisions of some of your nobles."
    end

    uit.data_entry_percentage("", satisfactio_ratio, rect, "Satisfaction ratio. ".. satisfaction_explanation)
    rect.x = rect.x + rect.width

    -- fifth part - current ratio of income spent on it
    uit.data_entry_percentage("", DATA.realm_get_budget_ratio(realm, budget_category), rect, "Income ratio spent on " .. name, false)
    rect.x = rect.x + rect.width

    if disable_control then
        return
    end

    -- sixth part - control over ratio
    if not WORLD:does_player_control_realm(realm) then
        return
    end

    local pr = rect:copy()
    pr.width = uit.BASE_HEIGHT * 2

    local function change(percentage)
        if uit.text_button(
            tostring(percentage) .. "%",
            pr,
            "Change monthly investment by " .. tostring(percentage) .. "%"
        ) then
            local current = DATA.realm_get_budget_ratio(realm, budget_category)
            ef.set_budget(realm, budget_category, current + percentage / 100)
        end
        pr.x = pr.x + uit.BASE_HEIGHT * 2
    end

    pr.x = pr.x + uit.BASE_HEIGHT

    -- change(-10)
    change(-5)
    -- change(-1)
    -- change(1)
    change(5)
    -- change(10)
end