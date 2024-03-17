local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"
local ranks = require "game.raws.ranks.character_ranks"

---@param rect Rect
---@param character Character
return function(rect, character)
    local style = ui.style.panel_outline
    if character.rank == ranks.NOBLE then
        -- silver color rgba
        ui.style.panel_outline = {r = 165 / 255, g = 169 / 255, b = 180 / 255, a = 1}
    elseif character.rank == ranks.CHIEF then
        -- gold color rgba
        ui.style.panel_outline = {r = 255 / 255, g = 215 / 255, b = 0 / 255, a = 1}
    end

    local subrect
    if rect.width > rect.height then
        subrect = rect:new(rect.x + (rect.width - rect.height) / 2, rect.y, rect.height, rect.height)
    elseif rect.height > rect.width then
        subrect = rect:new(rect.x, rect.y + (rect.height - rect.width) / 2, rect.width, rect.width)
    else
        subrect = rect
    end

    love.graphics.setLineWidth( 4 )
    ui.panel(subrect)
    love.graphics.setLineWidth( 1 )

    ui.style.panel_outline = style

    ui.image(ASSETS.get_icon(character.race.icon), subrect)
end