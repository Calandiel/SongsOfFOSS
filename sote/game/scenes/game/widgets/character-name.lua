local ui = require "engine.ui"
local ranks_localisation = require "game.raws.ranks.localisation"

---comment
---@param rect Rect
---@param character Character
local function name(rect, character)
    local title = ""
    if character.realm.overseer == character then
        title = title .. " Overseer"
    end
    if character.realm.tribute_collectors[character] then
        title = title .. " Tribute Collector"
    end
    ui.centered_text(character.name .. ", " .. ranks_localisation[character.rank] .. title .. " of " .. character.realm.name, rect)
end

return name