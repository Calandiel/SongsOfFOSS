local ui = require "engine.ui"
local ranks_localisation = require "game.raws.ranks.localisation"

---comment
---@param rect Rect
---@param character Character
local function name(rect, character)
    -- rect = rect:shrink(5)

    local realm = character.realm

    local title = character.name .. "\n"
    if realm then
        if realm.overseer == character then
            title = title .. " Overseer,"
        end
        if realm.tribute_collectors[character] then
            title = title .. " Tribute Collector,"
        end
        if realm.capitol_guard and realm.capitol_guard.recruiter == character then
            title = title .. " Protector,"
        end

    end

    title = title .. " \n" .. ranks_localisation[character.rank]
    ui.text(title .. " of " .. character.realm.name, rect, "left", "up")
end

return name