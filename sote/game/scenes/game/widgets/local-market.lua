local tabb = require "engine.table"
local trade_good = require "game.raws.raws-utils".trade_good

local ui = require "engine.ui"
local ut = require "game.ui-utils"

local ev = require "game.raws.values.economical"

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
---@field price number
---@field stockpile number

---comment
---@param tile Tile
---@param ui_panel Rect
---@param base_unit number
---@return function
return function(tile, ui_panel, base_unit)
    ---@type TableColumn[]
    local columns = {
        {
            header = '.',
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
            header = 'name',
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
            header = 'supply',
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
            header = 'demand',
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
            header = 'balance',
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
            header = 'price',
            render_closure = function(rect, k, v)
                ---@type ItemData
                v = v
                ut.money_entry("", v.price or 0, rect)
            end,
            width = base_unit * 6,
            value = function(k, v)
                ---@type ItemData
                v = v
                return v.price or 0
            end
        },
        {
            header = 'stockpile',
            render_closure = function(rect, k, v)
                ---@type ItemData
                v = v
                ut.money_entry("", v.stockpile, rect)
            end,
            width = base_unit * 6,
            value = function(k, v)
                ---@type ItemData
                v = v
                return v.stockpile
            end
        },
        {
            header = 'difference',
            render_closure = function(rect, k, v)
                ---@type ItemData
                v = v
                if WORLD.player_character then
                    local province = WORLD.player_character.province
                    if province then
                        local price_at_player = ev.get_local_price(province, v.name)
                        ut.money_entry("", 
                                        (v.price or 0) - price_at_player, 
                                        rect, 
                                        "Shows diffence between price in your current position and selected one"
                        )
                    else
                        ut.data_entry("", "Undefined", rect)
                    end
                else
                    ut.data_entry("", "Undefined", rect)
                end
            end,
            width = base_unit * 6,
            value = function(k, v)
                ---@type ItemData
                v = v

                if WORLD.player_character then
                    local province = WORLD.player_character.province
                    if province then
                        local price_at_player = ev.get_local_price(province, v.name)
                        return (v.price or 0) - price_at_player
                    else 
                        return 0
                    end
                else
                    return 0
                end
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

        local consumption = tile.province.local_consumption
        local production = tile.province.local_production

        for good_reference, good in pairs(RAWS_MANAGER.trade_goods_by_name) do
            local supply = production[good_reference] or 0
            local demand = consumption[good_reference] or 0
            data_blob[good_reference] = {
                data = good,
                name = good.name,
                icon = good.icon,
                supply = supply,
                demand = demand,
                balance = supply - demand,
                stockpile = tile.province.local_storage[good_reference] or 0,
                price = ev.get_local_price(tile.province, good_reference)
            }
        end

        ui.table(uip, data_blob, columns, state)
    end
end