local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

local portrait = require "game.scenes.game.widgets.portrait"

---@type TableState
local state = nil

---comment
---@param compact boolean
local function init_state(compact)
    local entry_height = UI_STYLE.scrollable_list_item_height
    if compact then
        entry_height = UI_STYLE.scrollable_list_small_item_height
    end

    if state == nil then
        state = {
            header_height = UI_STYLE.table_header_height,
            individual_height = entry_height,
            slider_level = 0,
            slider_width = UI_STYLE.slider_width,
            sorted_field = 1,
            sorting_order = true
        }
    else
        state.header_height = UI_STYLE.table_header_height
        state.individual_height = entry_height
        state.slider_width = UI_STYLE.slider_width
    end
end

local function render_name(rect, k, v)
    if ut.text_button(v.name, rect) then
        return v
    end
end

local function render_race(rect, k, v)
    ui.centered_text(v.race.name, rect)
end

local function pop_sex(pop)
    local f = "m"
    if pop.female then f = "f" end
    return f
end

---@param rect Rect
---@param province Province
---@param compact boolean?
return function(rect, province, compact)
    if compact == nil then
        compact = false
    end

    local portrait_width = UI_STYLE.scrollable_list_item_height
    if compact then
        portrait_width = UI_STYLE.scrollable_list_small_item_height
    end

    local rest_width = rect.width - portrait_width
    local width_unit = rest_width / 12
    return function()
        ---@type TableColumn[]
        local columns = {
            {
                header = ".",
                render_closure = function(rect, k, v)
                    portrait(rect, v)
                end,
                width = portrait_width,
                value = function(k, v)
                    ---@type POP
                    v = v
                    return v.name
                end
            },
            {
                header = "name",
                render_closure = render_name,
                width = width_unit * 7,
                value = function(k, v)
                    ---@type POP
                    v = v
                    return v.name
                end,
                active = true
            },
            {
                header = "age",
                render_closure = function (rect, k, v)
                    ui.right_text(tostring(v.age), rect)
                end,
                width = width_unit * 3,
                value = function(k, v)
                    return v.age
                end
            },
            {
                header = "sex",
                render_closure = function (rect, k, v)
                    ui.centered_text(pop_sex(v), rect)
                end,
                width = width_unit * 1,
                value = function(k, v)
                    return pop_sex(v)
                end
            }
        }
        init_state(compact)

        local top = rect:subrect(0, 0, rect.width, UI_STYLE.table_header_height, "left", "up")
        local bottom = rect:subrect(0, UI_STYLE.table_header_height, rect.width, rect.height - UI_STYLE.table_header_height, "left", "up")
        ui.centered_text("Local characters", top)
        return ut.table(bottom, province.characters, columns, state)
    end
end