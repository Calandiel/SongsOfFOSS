local ui = require "engine.ui"
local ranks_localisation = require "game.raws.ranks.localisation"

---comment
---@param rect Rect
---@param character Character
local function name(rect, character)
    ui.centered_text(character.name .. ", " .. ranks_localisation[character.rank] .. " of " .. character.realm.name, rect)
end

return name