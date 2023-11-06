local ui = require "engine.ui";
local uit = require "game.ui-utils"

local bc = require "game.scenes.game.widgets.budget-category"

local economic_effects = require "game.raws.effects.economic"

local TREASURY_TARGET_CHANGE = 1

---@param ui_panel Rect
---@param realm Realm
return function(ui_panel, realm)
    return function()

        if ui.is_key_held("lshift") or ui.is_key_held("rshift") then
            TREASURY_TARGET_CHANGE = 5
        elseif ui.is_key_held("lctrl") or ui.is_key_held("rctrl") then
            TREASURY_TARGET_CHANGE = 50
        else
            TREASURY_TARGET_CHANGE = 1
        end

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
            local button_rect = panel_rect:subrect(0, 0, uit.BASE_HEIGHT * 6, uit.BASE_HEIGHT, "left", 'up')

            ---@param mult number
            local function change_treasury_target(mult)
                local amount = mult * TREASURY_TARGET_CHANGE
                if uit.money_button(
                    "Change by ",
                    amount,
                    button_rect,
                    "Change treasury target by "
                    .. uit.to_fixed_point2(amount) .. MONEY_SYMBOL
                    .. ". You will try to save up specified amount of wealth in treasury. "
                    .. "If this amount is reached, excess money are reinvested across budget categories. "
                    .. "Press Ctrl or Shift to modify invested amount."
                ) then
                    realm.budget.treasury_target = math.max(0, realm.budget.treasury_target + amount)
                end
                button_rect.x = button_rect.x + uit.BASE_HEIGHT * 6
            end

            change_treasury_target(-1)
            change_treasury_target(1)
        end

        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        -- current change
        uit.money_entry(
            "Previous total income",
            realm.budget.saved_change,
            panel_rect:subrect(0, 0, panel_rect.width, uit.BASE_HEIGHT, "left", 'up'),
            "Previous total income"
        )

        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        local label_panel =  panel_rect:subrect(0, 0, panel_rect.width, uit.BASE_HEIGHT, "left", 'up')

        ui.text_panel("Gift wealth to your tribe: ", label_panel)

        local button_rect = panel_rect:subrect(0, uit.BASE_HEIGHT * 1, uit.BASE_HEIGHT * 10, uit.BASE_HEIGHT, "left", 'up')

        if uit.money_button(
            "Gift to tribal treasury",
            TREASURY_TARGET_CHANGE,
            button_rect,
            "Invest "
            .. uit.to_fixed_point2(TREASURY_TARGET_CHANGE)
            .. MONEY_SYMBOL
            .. " of personal wealth into treasury. Press Ctrl or Shift to modify invested amount."
        ) then
            economic_effects.gift_to_tribe(WORLD.player_character, realm, TREASURY_TARGET_CHANGE)
        end
    end
end