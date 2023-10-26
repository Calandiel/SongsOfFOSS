local ui = require "engine.ui"
local ut = require "game.ui-utils"

local callback = require "game.scenes.callbacks"

---@param tile Tile
---@param rect Rect rectangle of the according tile
---@param x number
---@param y number
---@param size number
return function(gam, tile, rect, x, y, size)
    -- draw an icon on map
    ui.image(ASSETS.get_icon('village.png'), rect)

    -- unit sizes
    local width_unit = size * 4
    local height_unit = size / 2

    local length_of_line = 50 - height_unit

    local name_rect = ui.rect(
        x - size / 5, 
        y - height_unit - 50, 
        width_unit, 
        height_unit
    )

    local realm_rect = name_rect:copy()
    realm_rect.y = realm_rect.y - height_unit

    local population_rect = ui.rect(
        x - size / 5, 
        y - length_of_line - height_unit, 
        width_unit,
        height_unit
    )

    local button_rect = ui.rect(
        x - size / 5 + width_unit, 
        y - 50 - height_unit * 2, 
        size, 
        size
    )

    local line_rect = ui.rect(x - 1, y - length_of_line, 2, 50 - height_unit)

    ui.rectangle(line_rect)

    if require "game.scenes.game.widgets.realm-name"(gam, tile.province.realm, height_unit, realm_rect) then
        return true
    end
    
    ut.data_entry("", tile.province.name, name_rect)
    local population = tile.province:population()
    ut.data_entry("", tostring(population), population_rect)

    if WORLD.player_character then
        if ui.icon_button(ASSETS.get_icon("barbute.png"), button_rect) then
            callback.toggle_raiding_target(gam, tile.province)()
            return true
        end
    end
end

