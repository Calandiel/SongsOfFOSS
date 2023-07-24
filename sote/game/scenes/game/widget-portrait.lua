local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

return function(rect, character)
    ui.panel(rect)
    ui.image(ASSETS.get_icon(character.race.icon), rect)
end