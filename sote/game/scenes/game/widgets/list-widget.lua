local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

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

---@generic K, V
---@param rect Rect
---@param table table<K, V>
---@param columns TableColumn[]
---@param title string?
---@param compact boolean?
return function(rect, table, columns, title, compact)
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

        init_state(compact)
        local bottom_height = rect.height
        local bottom_y = 0
        if title then
            bottom_height = bottom_height - UI_STYLE.table_header_height
            bottom_y = UI_STYLE.table_header_height
            local top = rect:subrect(0, 0, rect.width, UI_STYLE.table_header_height, "left", "up")
            ui.centered_text(title, top)
        end
        local bottom = rect:subrect(0, bottom_y, rect.width, bottom_height, "left", "up")
        return ut.table(bottom, table, columns, state)
    end
end
