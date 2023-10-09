local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

local portrait = require "sote.game.scenes.game.widgets.portrait"

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

local function render_name(rect, k, v)
    if ui.text_button(v.name, rect) then
        return v
    end
end

local function render_race(rect, k, v)
    ui.centered_text(v.race.name, rect)
end

local function pop_sex(pop)
    local f = 'm'
    if pop.female then f = 'f' end
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
                header = '.',
                render_closure = function(rect, k, v)
                    portrait(rect, v)
                end,
                width = base_unit * 1,
                value = function(k, v)
                    ---@type POP
                    v = v
                    return v.name
                end
            },
            {
                header = 'name',
                render_closure = render_name,
                width = base_unit * 8,
                value = function(k, v)
                    ---@type POP
                    v = v
                    return v.name
                end,
                active = true
            },
            {
                header = 'age',
                render_closure = function (rect, k, v)
                    ui.right_text(tostring(v.age), rect)
                end,
                width = base_unit * 3,
                value = function(k, v)
                    return v.age
                end
            },
            {
                header = 'sex',
                render_closure = function (rect, k, v)
                    ui.centered_text(pop_sex(v), rect)
                end,
                width = base_unit * 1,
                value = function(k, v)
                    return pop_sex(v)
                end
            }
        }
        init_state(base_unit)
        local top = rect:subrect(0, 0, rect.width, base_unit, "left", 'up')
        local bottom = rect:subrect(0, base_unit, rect.width, rect.height - base_unit, "left", 'up')
        ui.centered_text("Local characters", top)
        return ui.table(bottom, province.characters, columns, state)
    end
end