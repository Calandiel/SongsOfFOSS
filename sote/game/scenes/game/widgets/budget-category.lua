local ui = require "engine.ui";
local uit = require "game.ui-utils"

local ef = require "game.raws.effects.economic"

---comment
---@param rect Rect
---@param name string
---@param realm Realm
---@param budget_category BudgetCategory
return function (rect, name, realm, budget_category, disable_control)
    rect.width = rect.width / 9.2

    -- first part - label for category!
    uit.data_entry(name, "", rect, "Budget breakdown")
    rect.x = rect.x + rect.width    

    -- second part - current spendings
    uit.money_entry("", budget_category.to_be_invested, rect, "To be invested")
    rect.x = rect.x + rect.width


    -- third part - current incomes
    uit.money_entry("", budget_category.budget, rect, "Current investments")
    rect.x = rect.x + rect.width

    -- fourth part - target spendings
    uit.money_entry("", budget_category.target, rect, "Target investments")
    rect.x = rect.x + rect.width

    

    local satisfactio_ratio = 1
    if budget_category.target ~= 0 then
        satisfactio_ratio = budget_category.budget / budget_category.target
    end
    local satisfaction_explanation = ""
    if name == 'Education' then
        satisfaction_explanation = "Being above 100% means that your tribe researches new technologies faster."
    end
    if name == 'Military' then
        satisfaction_explanation = "Being above 100% means that your tribe can support current army at least for a year."
    end
    if name == 'Infrastructure' then
        satisfaction_explanation = "Being above 100% means that your infrastructure spendings are fully satisfied."
    end
    if name == 'Court' then
        satisfaction_explanation = "This value tells how much wealth your court receives from tribal treasury compared to their expectations. This value influences decisions of some of your nobles."
    end

    uit.data_entry_percentage("", satisfactio_ratio, rect, "Satisfaction ratio. ".. satisfaction_explanation)
    rect.x = rect.x + rect.width

    -- fifth part - current ratio of income spent on it
    uit.data_entry_percentage("", budget_category.ratio, rect, "Income ratio spent on " .. name, false)
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
        if ui.text_button(
            tostring(percentage) .. "%",
            pr,
            "Change monthly investment by " .. tostring(percentage) .. "%"
        ) then
            local current = budget_category.ratio
            ef.set_budget(budget_category, budget_category.ratio + percentage / 100)
        end
        pr.x = pr.x + uit.BASE_HEIGHT * 2
    end

    -- change(-10)
    change(-5)
    -- change(-1)
    -- change(1)
    change(5)
    -- change(10)
end