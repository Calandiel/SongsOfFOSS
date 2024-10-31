local tabb = require "engine.table"

local ui = require "engine.ui";
local ut = require "game.ui-utils"
local ib = require "game.scenes.game.widgets.inspector-redirect-buttons"

local production_method_utils = require "game.raws.production-methods"

local economy_effects = require "game.raws.effects.economy"

local inspector = {}

local BUILDING_SUBSIDY_AMOUNT = 0.125

---@return Rect
local function get_main_panel()
	local fs = ui.fullscreen()
    return fs:subrect(ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 45, fs.height / 2, "left", "up")
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
---@param gamescene GameScene
function inspector.draw(gamescene)
    local rect = get_main_panel()


	--- combining key presses for increments of 1, 5, 10, and 50
	BUILDING_SUBSIDY_AMOUNT = 0.125
	if ui.is_key_held("lshift") or ui.is_key_held("rshift") then
		BUILDING_SUBSIDY_AMOUNT = BUILDING_SUBSIDY_AMOUNT * 2
	end
	if ui.is_key_held("lctrl") or ui.is_key_held("rctrl") then
		BUILDING_SUBSIDY_AMOUNT = BUILDING_SUBSIDY_AMOUNT * 4
	end

    ---@param rect Rect
    ---@param k any
    ---@param v Building
    local function render_province(rect, k, v)
        ib.text_button_to_province(
            gamescene,
            BUILDING_PROVINCE(v),
            rect,
            PROVINCE_NAME(BUILDING_PROVINCE(v)),
            "This building is location in " .. PROVINCE_NAME(BUILDING_PROVINCE(v)) .. "."
        )
    end

    ui.panel(rect)

    local province = gamescene.selected.province

    if province == nil then
        return
    end

    local base_unit = ut.BASE_HEIGHT
    init_state(base_unit)

    ---@type TableColumn[]
    local columns = {
        {
            header = ".",
            ---@param v Building
            render_closure = function(rect, k, v)
                ui.image(ASSETS.get_icon(DATA.building_type_get_icon(DATA.building_get_current_type(v))), rect)
            end,
            width = base_unit * 1,
            ---@param v Building
            value = function(k, v)
                return DATA.building_type_get_description(DATA.building_get_current_type(v))
            end
        },
        {
            header = "name",
            ---@param v Building
            render_closure = function(rect, k, v)
                ib.text_button_to_building(gamescene, v, rect, DATA.building_type_get_description(DATA.building_get_current_type(v)))
            end,
            width = base_unit * 6,
            ---@param v Building
            value = function(k, v)
                return DATA.building_type_get_description(DATA.building_get_current_type(v))
            end
        },
        {
            header = "your share",
            ---@param v Building
            render_closure = function(rect, k, v)
                ut.money_entry(
                    "",
                    DATA.building_get_last_donation_to_owner(v),
                    rect,
                    "Your share is "
                    .. ut.to_fixed_point2(DISPLAY_INCOME_OWNER_RATIO)
                    .. " of last building's income."
                )
            end,
            width = base_unit * 3,
            ---@param v Building
            value = function(k, v)
                return DATA.building_get_last_donation_to_owner(v)
            end
        },
        {
            header = "subsidy",
            ---@param rect Rect
            ---@param v Building
            render_closure = function (rect, k, v)
                local dec_rect = rect:subrect(0, 0, base_unit, base_unit, "left", "up")
                local value_rect = rect:subrect(0, 0, base_unit * 3, base_unit, "center", "up")
                local inc_rect = rect:subrect(0, 0, base_unit, base_unit, "right", "up")

                if ut.icon_button(
                    ASSETS.icons["minus.png"], dec_rect,
                    "Decrease next month's subsidies by ".. ut.to_fixed_point2(-BUILDING_SUBSIDY_AMOUNT).." per worker."
                    .. "\nPress Ctrl and/or Shift to modify amount."
                ) then
                    DATA.building_inc_subsidy(v, -BUILDING_SUBSIDY_AMOUNT)
                end
                if ut.icon_button(ASSETS.icons["plus.png"], inc_rect,
                    "Increase next month's subsidies by " .. ut.to_fixed_point2(BUILDING_SUBSIDY_AMOUNT) .. " per worker."
                    .. "\nPress Ctrl and/or Shift to modify amount."
                ) then
                    DATA.building_inc_subsidy(v, BUILDING_SUBSIDY_AMOUNT)
                end

                ut.money_entry("", DATA.building_get_subsidy(v), value_rect, "Current subsidy per worker. Paid monthly to attract workers.", true)
            end,
            width = base_unit * 5,
            ---@param v Building
            value = function (k, v)
                return DATA.building_get_subsidy(v)
            end,
            active = true
        },
        {
            header = "income",
            ---@param v Building
            render_closure = function(rect, k, v)
                ut.money_entry("", DATA.building_get_last_income(v), rect)
            end,
            width = base_unit * 3,
            ---@param v Building
            value = function(k, v)
                return DATA.building_get_last_income(v)
            end
        },
        {
            header = "inputs",
            ---@param rect Rect
            ---@param k any
            ---@param v Building
            render_closure = function(rect, k, v)
                local input_rect = rect:subrect(0, 0, rect.height * 3, rect.height, "left", "up")
                local total_spent = 0
                for i = 1, MAX_SIZE_ARRAYS_PRODUCTION_METHOD do
                    local input = DATA.building_get_spent_on_inputs_use(v, i)
                    if input == INVALID_ID then
                        break
                    end

                    total_spent = total_spent + DATA.building_get_spent_on_inputs_use(v, i)
                end
                ut.balance_entry(
                    "",
                    total_spent,
                    input_rect
                )
            end,
            width = base_unit * 9,
            ---@param v Building
            value = function(k, v)

                local total_spent = 0
                for i = 1, MAX_SIZE_ARRAYS_PRODUCTION_METHOD do
                    local input = DATA.building_get_spent_on_inputs_use(v, i)
                    if input == INVALID_ID then
                        break
                    end

                    total_spent = total_spent + DATA.building_get_spent_on_inputs_use(v, i)
                end

                return total_spent
            end
        },
        {
            header = "outputs",
            ---@param v Building
            render_closure = function(rect, k, v)
                local input_rect = rect:subrect(0, 0, rect.height * 3, rect.height, "left", "up")
                local total_earn = 0
                for i = 1, MAX_SIZE_ARRAYS_PRODUCTION_METHOD do
                    local output = DATA.building_get_earn_from_outputs_good(v, i)
                    if output == INVALID_ID then
                        break
                    end

                    total_earn = total_earn + DATA.building_get_earn_from_outputs_amount(v, i)
                end
                ut.balance_entry(
                    "",
                    total_earn,
                    input_rect
                )
            end,
            width = base_unit * 9,
            ---@param v Building
            value = function(k, v)

                local total_earn = 0
                for i = 1, MAX_SIZE_ARRAYS_PRODUCTION_METHOD do
                    local output = DATA.building_get_earn_from_outputs_good(v, i)
                    if output == INVALID_ID then
                        break
                    end

                    total_earn = total_earn + DATA.building_get_earn_from_outputs_amount(v, i)
                end

                return total_earn
            end
        },
        {
            header = "province",
            render_closure = render_province,
            width = base_unit * 5,
            value = function(k, v)
                ---@type Building
                v = v
                return PROVINCE_NAME(BUILDING_PROVINCE(v))
            end
        },
        {
            header = "jobs",
            ---@param v Building
            render_closure = function(rect, k, v)

                local employed = #DATA.get_employment_from_building(v)
                local total_needed =  production_method_utils.total_jobs(DATA.building_type_get_production_method(DATA.building_get_current_type(v)))

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
                return #DATA.get_employment_from_building(v)
            end
        },
        {
            header = "X",
            ---@param v Building
            render_closure = function(rect, k, v)
                if ut.icon_button(ASSETS.get_icon("hammer-drop.png"), rect, "Destroy building") then
                    economy_effects.destroy_building(v)
                end
            end,
            width = base_unit * 1,
            value = function(k, v)
                ---@type Building
                v = v
                return DATA.building_type_get_description(DATA.building_get_current_type(v))
            end,
            active = true
        },
    }

    ---@type Building[]
    local buildings_data = {}

    local player = WORLD.player_character

    if player ~= INVALID_ID then
        DATA.for_each_ownership_from_owner(player, function (item)
            table.insert(buildings_data, DATA.ownership_get_building(item))
        end)
    end

    ut.table(rect, buildings_data, columns, state)
end

return inspector