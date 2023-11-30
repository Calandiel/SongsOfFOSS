local tabb = require "engine.table"
local trade_good = require "game.raws.raws-utils".trade_good

local ui = require "engine.ui"
local ut = require "game.ui-utils"

local ev = require "game.raws.values.economical"
local ef = require "game.raws.effects.economic"
local et = require "game.raws.triggers.economy"

local TRADE_AMOUNT = 1

---@type TableState
local state = nil

local function init_state(base_unit)
    if state == nil then
        state = {
            header_height = base_unit,
            individual_height = base_unit,
            slider_level = 0,
            slider_width = base_unit,
            sorted_field = 1,
            sorting_order = true
        }
    else
        state.header_height = base_unit
        state.individual_height = base_unit
        state.slider_width = base_unit
    end
end


---@class ItemData
---@field name string
---@field icon string
---@field supply number
---@field demand number
---@field balance number
---@field buy_price number
---@field sell_price number
---@field stockpile number
---@field inventory number

---comment
---@param province Province
---@param ui_panel Rect
---@param base_unit number
---@param gam GameScene
---@return function
return function(province, ui_panel, base_unit, gam)
    ---@type TableColumn[]
    local columns = {
        {
            header = ".",
            render_closure = function(rect, k, v)
                ui.image(ASSETS.get_icon(v.icon), rect)
            end,
            width = base_unit * 1,
            value = function(k, v)
                ---@type ItemData
                v = v
                return v.name
            end
        },
        {
            header = "name",
            render_closure = function(rect, k, v)
                ui.left_text(v.name, rect)
            end,
            width = base_unit * 6,
            value = function(k, v)
                ---@type ItemData
                v = v
                return v.name
            end
        },
        {
            header = "supply",
            render_closure = function(rect, k, v)
                ---@type ItemData
                v = v
                ut.data_entry("", ut.to_fixed_point2(v.supply or 0), rect)
            end,
            width = base_unit * 4,
            value = function(k, v)
                ---@type ItemData
                v = v
                return v.supply or 0
            end
        },
        {
            header = "demand",
            render_closure = function(rect, k, v)
                ---@type ItemData
                v = v
                ut.data_entry("", ut.to_fixed_point2(v.demand or 0), rect)
            end,
            width = base_unit * 4,
            value = function(k, v)
                ---@type ItemData
                v = v
                return v.demand or 0
            end
        },
        {
            header = "balance",
            render_closure = function(rect, k, v)
                ---@type ItemData
                v = v
                ut.balance_entry("", v.balance or 0, rect)
            end,
            width = base_unit * 4,
            value = function(k, v)
                ---@type ItemData
                v = v
                return v.balance or 0
            end
        },
        {
            header = "buy price",
            render_closure = function(rect, k, v)
                ---@type ItemData
                v = v
                ut.money_entry("", v.buy_price or 0, rect)
            end,
            width = base_unit * 4,
            value = function(k, v)
                ---@type ItemData
                v = v
                return v.buy_price or 0
            end
        },
        {
            header = "sell price",
            render_closure = function(rect, k, v)
                ---@type ItemData
                v = v
                ut.money_entry("", v.sell_price or 0, rect)
            end,
            width = base_unit * 4,
            value = function(k, v)
                ---@type ItemData
                v = v
                return v.sell_price or 0
            end
        },
        {
            header = "stockpile",
            render_closure = function(rect, k, v)
                ---@type ItemData
                v = v
                ut.data_entry("", ut.to_fixed_point2(v.stockpile), rect)
            end,
            width = base_unit * 4,
            value = function(k, v)
                ---@type ItemData
                v = v
                return v.stockpile
            end
        },
        {
            header = "difference",
            render_closure = function(rect, k, v)
                ---@type ItemData
                v = v
                local tooltip = "Shows the diffence between buy price in your current position and sell price in selected one"
                if WORLD.player_character then
                    local player_province = WORLD.player_character.province
                    if player_province then
                        local price_at_player = ev.get_local_price(player_province, v.name)
                        local data = 1
                        if price_at_player == 0 and (v.sell_price or 0) == 0 then
                            data = 0
                        elseif price_at_player == 0 then
                            data = 99.99
                        elseif (v.sell_price or 0) == 0 then
                            data = 0
                        else
                            data = ((v.sell_price or 0) - price_at_player) / price_at_player
                        end
                        ut.color_coded_percentage(
                            data,
                            rect,
                            true,
                            tooltip
                        )
                    else
                        ut.data_entry("", "???", rect, tooltip)
                    end
                else
                    ut.data_entry("", "???", rect, tooltip)
                end
            end,
            width = base_unit * 4,
            value = function(k, v)
                ---@type ItemData
                v = v

                if WORLD.player_character then
                    local local_province = WORLD.player_character.province
                    if local_province then
                        local price_at_player = ev.get_local_price(local_province, v.name)
                        local data = 1
                        if price_at_player == 0 and (v.sell_price or 0) == 0 then
                            data = 1
                        elseif price_at_player == 0 then
                            data = 99.99
                        elseif (v.sell_price or 0) == 0 then
                            data = 0
                        else
                            data = ((v.sell_price or 0) - price_at_player) / price_at_player
                        end
                        return data
                    else
                        return 0
                    end
                else
                    return 0
                end
            end
        },
        {
            header = "Buy " .. TRADE_AMOUNT,
            render_closure = function (rect, k, v)
                local player_character = WORLD.player_character
                if player_character == nil then
                    return
                end

                ---@type string
                local tooltip = "Buy " .. tostring(TRADE_AMOUNT) .. ". \n"

                local valid_province = player_character.province == province
                if not valid_province then
                    tooltip = tooltip .. "You are too far away \n"
                end

                local can_buy, reasons = et.can_buy(player_character, v.name, TRADE_AMOUNT)
                for _, reason in pairs(reasons) do
                    tooltip = tooltip .. reason .. "\n"
                end

                if ut.text_button("+", rect, tooltip, can_buy and valid_province) then
                    ef.buy(player_character, v.name, TRADE_AMOUNT)
                end
            end,
            width = base_unit * 2,
            value = function(k, v)
                ---@type ItemData
                v = v
                return v.name
            end,
            active = true
        },
        {
            header = "Sell " .. TRADE_AMOUNT,
            render_closure = function (rect, k, v)
                local player_character = WORLD.player_character
                if player_character == nil then
                    return
                end

                ---@type string
                local tooltip = "Sell " .. tostring(TRADE_AMOUNT) .. ". \n"

                local valid_province = player_character.province == province
                if not valid_province then
                    tooltip = tooltip .. "You are too far away \n"
                end

                local can_buy, reasons = et.can_sell(player_character, v.name, TRADE_AMOUNT)
                for _, reason in pairs(reasons) do
                    tooltip = tooltip .. reason .. "\n"
                end

                if ut.text_button("-", rect, tooltip, can_buy and valid_province) then
                    ef.sell(player_character, v.name, TRADE_AMOUNT)
                end
            end,
            width = base_unit * 2,
            value = function(k, v)
                ---@type ItemData
                v = v
                return v.name
            end,
            active = true
        },
        {
            header = "Your",
            render_closure = function(rect, k, v)
                ---@type ItemData
                v = v
                ut.data_entry("", ut.to_fixed_point2(v.inventory), rect)
            end,
            width = base_unit * 4,
            value = function(k, v)
                ---@type ItemData
                v = v
                return v.inventory
            end
        },
        {
            header = "Map",
            render_closure = function (rect, k, v)
                ---@type ItemData
                v = v

                if ut.icon_button(ASSETS.icons['mesh-ball.png'], rect, "Show price on map") then
                    HACKY_MAP_MODE_CONTEXT_TRADE_CATEGORY = v.name
                    gam.update_map_mode("prices")
                end
            end,
            width = base_unit * 2,
            value = function (k, v)
                return v.name
            end
        }
    }


    return function()
        --- local economy data
        local uip = ui_panel:copy()
        init_state(base_unit)

        --- local market
        ---@type table<string, ItemData>
        local data_blob = {}

        local consumption = province.local_consumption
        local production = province.local_production

        local character = WORLD.player_character

        if ui.is_key_held("lshift") or ui.is_key_held("rshift") then
            TRADE_AMOUNT = 5
        elseif ui.is_key_held("lctrl") or ui.is_key_held("rctrl") then
            TRADE_AMOUNT = 50
        else
            TRADE_AMOUNT = 1
        end

        for good_reference, good in pairs(RAWS_MANAGER.trade_goods_by_name) do
            local supply = production[good_reference] or 0
            local demand = consumption[good_reference] or 0
            local inventory = 0
            if character then
                inventory = character.inventory[good_reference] or 0
            end
            data_blob[good_reference] = {
                data = good,
                name = good.name,
                icon = good.icon,
                supply = supply,
                demand = demand,
                balance = supply - demand,
                stockpile = province.local_storage[good_reference] or 0,
                buy_price = ev.get_local_price(province, good_reference),
                sell_price = ev.get_pessimistic_local_price(province, good_reference, TRADE_AMOUNT),
                inventory = inventory
            }
        end

        ut.table(uip, data_blob, columns, state)
    end
end