local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"


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
    }


    return function()
        --- local economy data
        local uip = ui_panel:copy()
        uip.height = base_unit
        uip.width = base_unit * 8
        ut.money_entry("Local wealth:", tile.province.local_wealth, uip)
        uip.x = uip.x + uip.width + base_unit
        ut.money_entry("Local income:", tile.province.local_income, uip)
        uip.x = uip.x + uip.width + base_unit
        ut.money_entry("Local building upkeep:", tile.province.local_building_upkeep, uip)
        uip.y = uip.y + base_unit
        init_state(base_unit)

        --- local market
        local data_blob = {}

        local consumption = tile.province.local_consumption
        local production = tile.province.local_production

        uip.x = ui_panel.x
        uip.width = ui_panel.width
        uip.height = uip.height * 8
        for good, amount in pairs(production) do
            if data_blob[good] == nil then
                data_blob[good] = {}
                data_blob[good].name = good.name
                data_blob[good].icon = good.icon
            end
            data_blob[good].supply = amount
            data_blob[good].balance = amount
            data_blob[good].price = tile.province.realm:get_price(good)
        end
        for good, amount in pairs(consumption) do
            if data_blob[good] == nil then
                data_blob[good] = {}
                data_blob[good].name = good.name
                data_blob[good].icon = good.icon
            end
            local old = data_blob[good].supply or 0
            data_blob[good].balance = old - amount
            data_blob[good].demand = amount
            data_blob[good].price = tile.province.realm:get_price(good)
        end

        ui.table(uip, data_blob, columns, state)
    end
end