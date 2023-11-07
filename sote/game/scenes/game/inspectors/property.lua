local ui = require "engine.ui";
local ut = require "game.ui-utils"

local trade_good = require "game.raws.raws-utils".trade_good

local economy_values = require "game.raws.values.economical"

local inspector = {}

---@return Rect
local function get_main_panel()
	local fs = ui.fullscreen()
	local panel = fs:subrect(ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 30, ut.BASE_HEIGHT * 15, "left", "up")
	return panel
end

---Returns whether or not clicks on the planet can be registered.
---@return boolean
function inspector.mask()
	if ui.trigger(get_main_panel()) then
		return false
	else
		return true
	end
end

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

---@class (strict) PropertyData
---@field icon string
---@field income number
---@field building_type BuildingType
---@field province Province

---comment
---@param gam GameScene
function inspector.draw(gam)
    local rect = get_main_panel()

    ui.panel(rect)

    local province = gam.selected.province

    if province == nil then
        return
    end

    local base_unit = ut.BASE_HEIGHT
    init_state(base_unit)

    ---@type TableColumn[]
    local columns = {
        {
            header = ".",
            render_closure = function(rect, k, v)
                ---@type PropertyData
                v = v
                ui.image(ASSETS.get_icon(v.icon), rect)
            end,
            width = base_unit * 1,
            value = function(k, v)
                ---@type PropertyData
                v = v
                return v.building_type.description
            end
        },
        {
            header = "name",
            render_closure = function(rect, k, v)
                ---@type PropertyData
                v = v
                ui.left_text(v.building_type.description, rect)
            end,
            width = base_unit * 6,
            value = function(k, v)
                ---@type PropertyData
                v = v
                return v.building_type.description
            end
        },
        {
            header = "income",
            render_closure = function(rect, k, v)
                ---@type PropertyData
                v = v
                ut.money_entry("", v.income, rect)
            end,
            width = base_unit * 3,
            value = function(k, v)
                ---@type PropertyData
                v = v
                return v.income
            end
        },
        {
            header = "inputs",
            render_closure = function(rect, k, v)
                ---@type PropertyData
                v = v
                local input_rect = rect:subrect(0, 0, rect.height * 2.1, rect.height, "left", "up")

                local total_estimated_cost = 0

                for key, value in pairs(v.building_type.production_method.inputs) do
                    local good = trade_good(key)
                    ut.generic_number_field(
                        good.icon,
                        -value,
                        input_rect,
                        nil,
                        ut.NUMBER_MODE.NUMBER,
                        ut.NAME_MODE.ICON,
                        nil,
                        false
                    )

                    total_estimated_cost = total_estimated_cost
                        + value * economy_values.get_local_price(v.province, key)

                    input_rect.x = input_rect.x + input_rect.width
                end

                ui.tooltip("Total estimated cost: " .. ut.to_fixed_point2(total_estimated_cost), rect)
            end,
            width = base_unit * 8.4,
            value = function(k, v)
                ---@type PropertyData
                v = v

                local total_estimated_cost = 0

                for key, value in pairs(v.building_type.production_method.inputs) do
                    total_estimated_cost = total_estimated_cost
                        + value * economy_values.get_local_price(v.province, key)
                end

                return total_estimated_cost
            end
        },
        {
            header = "outputs",
            render_closure = function(rect, k, v)
                ---@type PropertyData
                v = v
                local output_rect = rect:subrect(0, 0, rect.height * 2.1, rect.height, "left", "up")

                local total_estimated_cost = 0

                for key, value in pairs(v.building_type.production_method.outputs) do
                    local good = trade_good(key)
                    ut.generic_number_field(
                        good.icon,
                        value,
                        output_rect,
                        nil,
                        ut.NUMBER_MODE.NUMBER,
                        ut.NAME_MODE.ICON,
                        nil,
                        false
                    )

                    total_estimated_cost = total_estimated_cost
                        + value * economy_values.get_local_price(v.province, key)

                    output_rect.x = output_rect.x + output_rect.width
                end

                ui.tooltip("Total estimated cost: " .. ut.to_fixed_point2(total_estimated_cost), rect)
            end,
            width = base_unit * 8.4,
            value = function(k, v)
                ---@type PropertyData
                v = v

                local total_estimated_cost = 0

                for key, value in pairs(v.building_type.production_method.outputs) do
                    total_estimated_cost = total_estimated_cost
                        + value * economy_values.get_pessimistic_local_price(v.province, key, value)
                end

                return total_estimated_cost
            end
        },
    }

    ---@type PropertyData[]
    local buildings_data = {}

    local player = WORLD.player_character

    if player then
        for k, v in pairs(player.owned_buildings) do
            ---@type PropertyData
            local entry = {
                building_type = v.type,
                income = v.income_mean,
                province = v.province,
                icon = v.type.icon
            }

            table.insert(buildings_data, entry)
        end
    end

    ut.table(rect, buildings_data, columns, state)
end

return inspector