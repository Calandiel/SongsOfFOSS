local ui = require "engine.ui";
local uit = require "game.ui-utils"

local bc = require "game.scenes.game.widgets.budget-category"

---@param ui_panel Rect
---@param realm Realm
return function(ui_panel, realm)
    return function()
        local column_width = uit.BASE_HEIGHT * 8

        -- current treasury
        local panel_rect = ui_panel:subrect(0, 0, column_width, uit.BASE_HEIGHT, "left", 'up')
        uit.money_entry("Realm treasury", realm.budget.treasury, panel_rect, "Treasury")
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        -- current spending
        local spendings_rect = panel_rect:subrect(0, 0, column_width - uit.BASE_HEIGHT, uit.BASE_HEIGHT, "left", 'up')
        for category, spendings in pairs(realm.budget.spending_by_category) do
            uit.money_entry(category, spendings, spendings_rect, "Spending", true)
            spendings_rect.y = spendings_rect.y + uit.BASE_HEIGHT
        end

        -- current incomes
        local incomes_rect = panel_rect:subrect(column_width, 0, column_width - uit.BASE_HEIGHT, uit.BASE_HEIGHT, "left", 'up')
        for category, incomes in pairs(realm.budget.income_by_category) do
            uit.money_entry(category, incomes, incomes_rect, "Income")
            incomes_rect.y = incomes_rect.y + uit.BASE_HEIGHT
        end

        -- treasury changes
        local treasury_changes = panel_rect:subrect(2 * column_width, 0, column_width, uit.BASE_HEIGHT, "left", 'up')
        for category, spendings in pairs(realm.budget.spending_by_category) do
            uit.money_entry(category, spendings, treasury_changes, "Treasury changes", true)
            treasury_changes.y = treasury_changes.y + uit.BASE_HEIGHT
        end

        -- current budget
        panel_rect = ui_panel:subrect(0, ui_panel.height / 2, ui_panel.width, ui_panel.height / 2, "left", 'up')

        -- budget breakdown


        bc(panel_rect:subrect(0, 0, panel_rect.width, uit.BASE_HEIGHT, "left", 'up'),
            'Education', realm, realm.budget.education, false, true)
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        bc(panel_rect:subrect(0, 0, panel_rect.width, uit.BASE_HEIGHT, "left", 'up'), 
            'Military', realm, realm.budget.military, false, false)
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        bc(panel_rect:subrect(0, 0, panel_rect.width, uit.BASE_HEIGHT, "left", 'up'), 
            'Court', realm, realm.budget.court, false, true)
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        bc(panel_rect:subrect(0, 0, panel_rect.width, uit.BASE_HEIGHT, "left", 'up'), 
            'Infrastructure', realm, realm.budget.infrastructure, false, false)
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        bc(panel_rect:subrect(0, 0, panel_rect.width, uit.BASE_HEIGHT, "left", 'up'), 
            'Tribute', realm, realm.budget.tribute, true, true)
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        -- treasury target
        uit.money_entry("Target budget", realm.budget.treasury_target, panel_rect:subrect(0, 0, panel_rect.width, uit.BASE_HEIGHT, "left", 'up'), "We try to save up at least this amount of wealth in treasury")
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        -- control over treasury target
        if WORLD:does_player_control_realm(realm) then
            local button_rect = panel_rect:subrect(0, 0, uit.BASE_HEIGHT * 3, uit.BASE_HEIGHT, "left", 'up')

            local function change_treasury_target(x)
                if uit.text_button(
                    uit.to_fixed_point2(x) .. MONEY_SYMBOL,
                    button_rect,
                    "Change monthly investment by " .. uit.to_fixed_point2(x) .. MONEY_SYMBOL
                ) then
                    realm.budget.treasury_target = realm.budget.treasury_target + x
                end
                button_rect.x = button_rect.x + uit.BASE_HEIGHT * 3
            end
            
            change_treasury_target(-100)
            change_treasury_target(-10)
            change_treasury_target(-1)
            change_treasury_target(1)
            change_treasury_target(10)
            change_treasury_target(100)
        end

        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        -- current change
        uit.money_entry(
            "Previous total income",
            realm.budget.saved_change,
            panel_rect:subrect(0, 0, panel_rect.width, uit.BASE_HEIGHT, "left", 'up'),
            "Previous total income"
        )
    end
end