local tabb = require "engine.table"

local ui = require "engine.ui";
local ut = require "game.ui-utils"

local trade_good = require "game.raws.raws-utils".trade_good

local economy_values = require "game.raws.values.economical"

local inspector = {}

---@return Rect
local function get_main_panel()
	local fs = ui.fullscreen()
	local panel = fs:subrect(ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 45, ut.BASE_HEIGHT * 15, "left", "up")
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
                ---@type Building
                v = v
                ui.image(ASSETS.get_icon(v.type.icon), rect)
            end,
            width = base_unit * 1,
            value = function(k, v)
                ---@type Building
                v = v
                return v.type.description
            end
        },
        {
            header = "name",
            render_closure = function(rect, k, v)
                ---@type Building
                v = v
                ui.left_text(v.type.description, rect)
            end,
            width = base_unit * 6,
            value = function(k, v)
                ---@type Building
                v = v
                return v.type.description
            end
        },
        {
            header = "your share",
            render_closure = function(rect, k, v)
                ---@type Building
                v = v
                ut.money_entry(
                    "",
                    v.last_donation_to_owner,
                    rect,
                    "Your share is "
                    .. ut.to_fixed_point2(DISPLAY_INCOME_OWNER_RATIO)
                    .. " of last building's income."
                )
            end,
            width = base_unit * 3,
            value = function(k, v)
                ---@type Building
                v = v
                return v.last_donation_to_owner
            end
        },
        {
            header = "subsidy",
            render_closure = function (rect, k, v)
                ---@type Building
                v = v
                local dec_rect = rect:subrect(0, 0, base_unit, base_unit, "left", "up")
                local value_rect = rect:subrect(0, 0, base_unit * 3, base_unit, "center", "up")
                local inc_rect = rect:subrect(0, 0, base_unit, base_unit, "right", "up")

                if ut.text_button("-", dec_rect, "Decrease subsidy", v.subsidy >= 0.125) then
                    v.subsidy = v.subsidy - 0.125
                end

                if ut.text_button("+", inc_rect, "Increase subsidy") then
                    v.subsidy = v.subsidy + 0.125
                end

                ut.money_entry("", v.subsidy, value_rect, "Current subsidy per worker", true)
            end,
            width = base_unit * 5,
            value = function (k, v)
                ---@type Building
                v = v
                return v.subsidy
            end,
            active = true
        },
        {
            header = "income",
            render_closure = function(rect, k, v)
                ---@type Building
                v = v
                ut.money_entry("", v.last_income, rect)
            end,
            width = base_unit * 3,
            value = function(k, v)
                ---@type Building
                v = v
                return v.last_income
            end
        },
        {
            header = "inputs",
            render_closure = function(rect, k, v)
                ---@type Building
                v = v
                local input_rect = rect:subrect(0, 0, rect.height * 3, rect.height, "left", "up")

                local total_estimated_cost = 0

                for key, value in pairs(v.spent_on_inputs) do
                    local good = trade_good(key)
                    ut.generic_number_field(
                        good.icon,
                        -value,
                        input_rect,
                        nil,
                        ut.NUMBER_MODE.MONEY,
                        ut.NAME_MODE.ICON,
                        nil,
                        false
                    )

                    total_estimated_cost = total_estimated_cost + value

                    input_rect.x = input_rect.x + input_rect.width
                end

                ui.tooltip("Total estimated cost: " .. ut.to_fixed_point2(total_estimated_cost), rect)
            end,
            width = base_unit * 9,
            value = function(k, v)
                ---@type Building
                v = v

                local total_estimated_cost = 0

                for key, value in pairs(v.spent_on_inputs) do
                    total_estimated_cost = total_estimated_cost + value
                end

                return total_estimated_cost
            end
        },
        {
            header = "outputs",
            render_closure = function(rect, k, v)
                ---@type Building
                v = v
                local output_rect = rect:subrect(0, 0, rect.height * 3, rect.height, "left", "up")

                local total_estimated_cost = 0

                for key, value in pairs(v.earn_from_outputs) do
                    local good = trade_good(key)
                    ut.generic_number_field(
                        good.icon,
                        value,
                        output_rect,
                        nil,
                        ut.NUMBER_MODE.MONEY,
                        ut.NAME_MODE.ICON,
                        nil,
                        false
                    )

                    total_estimated_cost = total_estimated_cost + value

                    output_rect.x = output_rect.x + output_rect.width
                end

                ui.tooltip("Total estimated cost: " .. ut.to_fixed_point2(total_estimated_cost), rect)
            end,
            width = base_unit * 9,
            value = function(k, v)
                ---@type Building
                v = v

                local total_estimated_cost = 0

                for key, value in pairs(v.earn_from_outputs) do
                    total_estimated_cost = total_estimated_cost + value
                end

                return total_estimated_cost
            end
        },
        {
            header = "province",
            render_closure = function(rect, k, v)
                ---@type Building
                v = v
                ut.data_entry(v.province.name, "", rect)
            end,
            width = base_unit * 5,
            value = function(k, v)
                ---@type Building
                v = v
                return v.province.name
            end
        },
        {
            header = "jobs",
            render_closure = function(rect, k, v)
                ---@type Building
                v = v

                local employed = tabb.size(v.workers)
                local total_needed = v.type.production_method:total_jobs()

                ut.data_entry(
                    "",
                    tostring(employed) .. "/" .. tostring(total_needed),
                    rect
                )
            end,
            width = base_unit * 2,
            value = function(k, v)
            ---@type Building
                v = v
                return tabb.size(v.workers)
            end
        }
    }

    ---@type Building[]
    local buildings_data = {}

    local player = WORLD.player_character

    if player then
        for key, value in pairs(player.owned_buildings) do
            table.insert(buildings_data, value)
        end
    end

    ut.table(rect, buildings_data, columns, state)
end

return inspector