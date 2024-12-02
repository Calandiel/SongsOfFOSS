local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

---@type TableState
local state = nil

local function init_state(base_unit)
    if state == nil then
        state = {
            header_height = UI_STYLE.table_header_height,
            individual_height = UI_STYLE.scrollable_list_item_height,
            slider_level = 0,
            slider_width = UI_STYLE.slider_width,
            sorted_field = 1,
            sorting_order = true
        }
    else
        state.header_height = UI_STYLE.table_header_height
        state.individual_height = UI_STYLE.scrollable_list_item_height
        state.slider_width = UI_STYLE.slider_width
    end
end

local function render_name(rect, k, v)
    local fat = DATA.fatten_pop(v)
    local name = fat.name
    local children = 0
    DATA.for_each_parent_child_relation_from_parent(v, function (item)
        children = children + 1
    end)

    local has_parent = DATA.get_parent_child_relation_from_child(v)
    local parent = DATA.parent_child_relation_get_parent(has_parent)
    if parent ~= INVALID_ID then
        name = name .. " [" .. DATA.pop_get_name(parent) .. "]"
    end
    if children > 0 then
        name = name .. " (" .. children .. ")"
    end
    ui.left_text(name, rect)
end

---comment
---@param pop POP
---@return string
local function pop_display_occupation(pop)
    local occupation = DATA.get_employment_from_worker(pop)
    local job = DATA.employment_get_job(occupation)
    local employer = DATA.employment_get_building(occupation)
    if employer == INVALID_ID then
        local age = DATA.pop_get_age(pop)
        local race = DATA.pop_get_race(pop)
        local teen_age = DATA.race_get_teen_age(race)
        if age < teen_age then
            return "child"
        end
        local unit_of = UNIT_OF(pop)
        if unit_of == INVALID_ID then
            return "unemployed"
        end
        return "warrior"
    end
    return DATA.job_get_name(job)
end

local function pop_sex(pop)
    local f = "m"
    if DATA.pop_get_female(pop) then f = "f" end
    return f
end

---@param rect Rect
---@param base_unit number
---@param province Province
return function(rect, base_unit, province)
    return function()
        ---@type TableColumn[]
        local columns = {
            {
                header = ".",
                render_closure = function(rect, k, v)
                    --ui.image(ASSETS.get_icon(v.race.icon)
                    require "game.scenes.game.widgets.portrait"(rect, v)
                end,
                width = 1,
                value = function (k, v)
                    return DATA.pop_get_name(v)
                end
            },
            {
                header = "name",
                render_closure = render_name,
                width = 6,
                value = function (k, v)
                    return DATA.pop_get_name(v)
                end
            },
            {
                header = "race",
                render_closure = function (rect, k, v)
                    ui.centered_text(DATA.race_get_name(DATA.pop_get_race(v)), rect)
                end,
                width = 4,
                value = function(k, v)
                    ---@type POP
                    v = v
                    return DATA.race_get_name(DATA.pop_get_race(v))
                end
            },
            {
                header = "culture",
                render_closure = function (rect, k, v)
                    ui.centered_text(DATA.culture_get_name(DATA.pop_get_culture(v)), rect)
                    ui.tooltip("This character follows the customs of " .. DATA.culture_get_name(DATA.pop_get_culture(v)) .. "."
                        .. require "game.economy.diet-breadth-model".culture_target_tooltip(DATA.pop_get_culture(v)), rect)
                end,
                width = 4,
                value = function(k, v)
                    ---@type POP
                    v = v
                    return DATA.culture_get_name(DATA.pop_get_culture(v))
                end
            },
            {
                header = "faith",
                render_closure = function (rect, k, v)
                    ui.centered_text(DATA.faith_get_name(DATA.pop_get_faith(v)), rect)
                end,
                width = 4,
                value = function(k, v)
                    ---@type POP
                    v = v
                    return DATA.faith_get_name(DATA.pop_get_faith(v))
                end
            },
            {
                header = "job",
                render_closure = function (rect, k, v)
                    ui.centered_text(pop_display_occupation(v), rect)
                end,
                width = 4,
                value = function(k, v)
                    return pop_display_occupation(v)
                end
            },
            {
                header = "age",
                render_closure = function (rect, k, v)
                    ui.right_text(tostring(DATA.pop_get_age(v)), rect)
                end,
                width = 2,
                value = function(k, v)
                    return DATA.pop_get_age(v)
                end
            },
            {
                header = "sex",
                render_closure = function (rect, k, v)
                    ui.centered_text(pop_sex(v), rect)
                end,
                width = 1,
                value = function(k, v)
                    return pop_sex(v)
                end
            },
            {
                header = "savings",
                render_closure = function (rect, k, v)
                    ---@type POP
                    v = v

                    local inventory_tooltip = "\n Character's inventory: \t"
                    DATA.for_each_trade_good(function (item)
                        inventory_tooltip =
                            inventory_tooltip
                            .. DATA.trade_good_get_name(item)
                            .. " " .. DATA.pop_get_inventory(v, item) .. "\t"
                    end)

                    ut.money_entry(
                        "",
                        DATA.pop_get_savings(v),
                        rect,
                        "Savings of this character. "
                        .. "Characters spend them on buying food and other commodities."
                        .. inventory_tooltip
                    )
                end,
                width = 3,
                value = function (k, v)
                    return DATA.pop_get_savings(v)
                end
            },
            {
                header = "satisfac.",
                render_closure = function (rect, k, v)
                    ut.render_pop_satsifaction(rect, v)
                end,
                width = 2,
                value = function (k, v)
                    return DATA.pop_get_basic_needs_satisfaction(v)
                end
            },
            {
                header = "life needs",
                render_closure = function (rect, k, v)
                    ---@type POP
                    v = v

                    local needs_tooltip = ""

                    for index = 1, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
                        local use_case = DATA.pop_get_need_satisfaction_use_case(v, index)
                        if use_case == 0 then
                            break
                        end
                        local need = DATA.pop_get_need_satisfaction_need(v, index)

                        if DATA.need_get_life_need(need) then
                            local demanded = DATA.pop_get_need_satisfaction_demanded(v, index)
                            local consumed = DATA.pop_get_need_satisfaction_consumed(v, index)

                            ---@type string
                            needs_tooltip = needs_tooltip
                                .. "\n  "
                                .. DATA.use_case_get_name(use_case)
                                .. "(" .. DATA.need_get_name(need) .. ")"
                                .. ": "
                                .. ut.to_fixed_point2(consumed)
                                .. " / "
                                .. ut.to_fixed_point2(demanded)
                                .. " (" .. ut.to_fixed_point2(consumed / demanded * 100) .. "%)"
                        end
                    end

                    ut.data_entry_percentage(
                        "",
                        DATA.pop_get_life_needs_satisfaction(v),
                        rect,
                        "Satisfaction of life needs of this character. " .. needs_tooltip
                    )
                end,
                width = 2,
                value = function (k, v)
                    return DATA.pop_get_life_needs_satisfaction(v)
                end
            }
        }
        init_state(base_unit)
        local top = rect:subrect(0, 0, rect.width, base_unit, "left", "up")
        local bottom = rect:subrect(0, base_unit, rect.width, rect.height - base_unit, "left", "up")
        ui.centered_text("Population", top)
        local locations = DATA.filter_array_pop_location_from_location(province, function (item)
            return true
        end)

        ut.table(bottom, tabb.map_array(locations, DATA.pop_location_get_pop), columns, state)
    end
end