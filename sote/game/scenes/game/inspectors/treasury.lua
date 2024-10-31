local ui = require "engine.ui";
local uit = require "game.ui-utils"

local bc = require "game.scenes.game.widgets.budget-category"

local economic_effects = require "game.raws.effects.economy"

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
        local panel_rect = ui_panel:subrect(0, 0, column_width, uit.BASE_HEIGHT, "left", "up")
        uit.money_entry("Realm treasury", DATA.realm_get_budget_treasury(realm), panel_rect, "Treasury")
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        -- current spending
        local spendings_rect = panel_rect:subrect(0, 0, column_width - uit.BASE_HEIGHT, uit.BASE_HEIGHT, "left", "up")
        DATA.for_each_economy_reason(function (item)
            local name = DATA.economy_reason_get_description(item)
            local spendings = DATA.realm_get_budget_spending_by_category(realm, item)
            if spendings > 0 then
                uit.money_entry(name, spendings, spendings_rect, "Spending", true)
                spendings_rect.y = spendings_rect.y + uit.BASE_HEIGHT
            end
        end)

        -- current incomes
        local incomes_rect = panel_rect:subrect(column_width, 0, column_width - uit.BASE_HEIGHT, uit.BASE_HEIGHT, "left", "up")
        DATA.for_each_economy_reason(function (item)
            local name = DATA.economy_reason_get_description(item)
            local income = DATA.realm_get_budget_income_by_category(realm, item)
            if income >= 0 then
                uit.money_entry(name, income, incomes_rect, "Income", true)
                incomes_rect.y = incomes_rect.y + uit.BASE_HEIGHT
            end
        end)

        -- treasury changes
        -- local treasury_changes = panel_rect:subrect(2 * column_width, 0, column_width, uit.BASE_HEIGHT, "left", "up")
        -- for category, spendings in pairs(realm.budget.spending_by_category) do
        --     uit.money_entry(category, spendings, treasury_changes, "Treasury changes", true)
        --     treasury_changes.y = treasury_changes.y + uit.BASE_HEIGHT
        -- end

        -- current budget
        panel_rect = ui_panel:subrect(0, ui_panel.height / 2, ui_panel.width, ui_panel.height / 2, "left", "up")

        -- budget breakdown


        bc(panel_rect:subrect(0, 0, panel_rect.width, uit.BASE_HEIGHT, "left", "up"),
            "Education", realm, BUDGET_CATEGORY.EDUCATION, false, true)
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        bc(panel_rect:subrect(0, 0, panel_rect.width, uit.BASE_HEIGHT, "left", "up"),
            "Military", realm, BUDGET_CATEGORY.MILITARY, false, false)
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        bc(panel_rect:subrect(0, 0, panel_rect.width, uit.BASE_HEIGHT, "left", "up"),
            "Court", realm, BUDGET_CATEGORY.COURT, false, true)
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        bc(panel_rect:subrect(0, 0, panel_rect.width, uit.BASE_HEIGHT, "left", "up"),
            "Infrastructure", realm, BUDGET_CATEGORY.INFRASTRUCTURE, false, false)
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        bc(panel_rect:subrect(0, 0, panel_rect.width, uit.BASE_HEIGHT, "left", "up"),
            "Tribute", realm, BUDGET_CATEGORY.TRIBUTE, true, true)
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        -- treasury target
        uit.money_entry("Target budget", realm.budget.treasury_target,
            panel_rect:subrect(0, 0, uit.BASE_HEIGHT * 8, uit.BASE_HEIGHT, "left", "up"),
            "We try to save up at least this amount of wealth in treasury"
        )
        -- panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        -- control over treasury target
        local treasury_button_rect = panel_rect:subrect(uit.BASE_HEIGHT * 8, 0, uit.BASE_HEIGHT * 6, uit.BASE_HEIGHT, "left", "up")
        if WORLD:does_player_control_realm(realm) then
            ---@param mult number
            local function change_treasury_target(mult)
                local amount = mult * TREASURY_TARGET_CHANGE
                if uit.money_button(
                    "Change by ",
                    amount,
                    treasury_button_rect,
                    "Change treasury target by "
                    .. uit.to_fixed_point2(amount) .. MONEY_SYMBOL
                    .. ". You will try to save up specified amount of wealth in treasury. "
                    .. "If this amount is reached, excess money are reinvested across budget categories. "
                    .. "Press Ctrl or Shift to modify invested amount."
                ) then

                    realm.budget.treasury_target = math.max(0, realm.budget.treasury_target + amount)
                end
                treasury_button_rect.x = treasury_button_rect.x + uit.BASE_HEIGHT * 6
            end

            change_treasury_target(-1)
            change_treasury_target(1)
        end

        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        uit.money_entry("Target yearly tax", realm.tax_target,
            panel_rect:subrect(0, 0, uit.BASE_HEIGHT * 8, uit.BASE_HEIGHT, "left", "up"),
            "We try to collect this amount of wealth per year from our population"
        )

        -- control over treasury target
        local tax_button_rect = panel_rect:subrect(uit.BASE_HEIGHT * 8, 0, uit.BASE_HEIGHT * 6, uit.BASE_HEIGHT, "left", "up")
        if WORLD:does_player_control_realm(realm) then
        ---@param mult number
            local function change_tax_target(mult)
                local amount = mult * TREASURY_TARGET_CHANGE
                if uit.money_button(
                    "Change by ",
                    amount,
                    tax_button_rect,
                    "Change tax target by "
                    .. uit.to_fixed_point2(amount) .. MONEY_SYMBOL
                    .. "Press Ctrl or Shift to modify invested amount."
                ) then
                    realm.tax_target = math.max(0, realm.tax_target + amount)
                end
                tax_button_rect.x = tax_button_rect.x + uit.BASE_HEIGHT * 6
            end

            change_tax_target(-1)
            change_tax_target(1)
        end

        uit.money_entry("Collected tax", realm.tax_collected_this_year,
        panel_rect:subrect(tax_button_rect.x, 0, uit.BASE_HEIGHT * 8, uit.BASE_HEIGHT, "left", "up"),
        "We try to collect this amount of wealth per year from our population")

        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        -- current change
        uit.money_entry(
            "Previous total income",
            realm.budget.saved_change,
            panel_rect:subrect(0, 0, panel_rect.width, uit.BASE_HEIGHT, "left", "up"),
            "Previous total income"
        )

        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        local label_panel =  panel_rect:subrect(0, 0, panel_rect.width, uit.BASE_HEIGHT, "left", "up")

        ui.text_panel("Gift wealth to your tribe: ", label_panel)

        local button_rect = panel_rect:subrect(0, uit.BASE_HEIGHT * 1, uit.BASE_HEIGHT * 10, uit.BASE_HEIGHT, "left", "up")

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