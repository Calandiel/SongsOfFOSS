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

    -- TODO: maybe we should draw background images related to current position
    local old_inside = ui.style["panel_inside"]
    ui.style["panel_inside"] = {r = 0 / 255, g = 20 / 255, b = 10 / 255, a = 0.3}
    ui.panel(rect, 2, false)
    ui.style["panel_inside"] = old_inside

    love.graphics.setLineWidth( 4 )

    if character.race.portrait_description then
        ---@type number[]
        local dna_per_layer = {}
        ---@type table<string, number>
        local layer_to_index = {}
        for i, layer in ipairs(character.race.portrait_description.layers) do
            table.insert(dna_per_layer, character.dna[i])
            layer_to_index[layer] = i
        end

        for i, layers_group in pairs(character.race.portrait_description.layers_groups) do
            for j, layer in ipairs(layers_group) do
                dna_per_layer[layer_to_index[layer]] = dna_per_layer[layer_to_index[layers_group[1]]]
            end
        end

        assert(ASSETS.portraits[character.race.portrait_description.folder] ~= nil, character.race.portrait_description.folder .. " WAS NOT LOADED")

        for i, layer in ipairs(character.race.portrait_description.layers) do
            assert(ASSETS.portraits[character.race.portrait_description.folder][layer] ~= nil, layer .. " WAS NOT LOADED")
            assert(dna_per_layer[i] ~= nil, i)
            ui.image_ith(ASSETS.portraits[character.race.portrait_description.folder][layer], dna_per_layer[i], rect)
        end
    else
        ui.image(ASSETS.icons[character.race.icon], rect)
    end

    ui.panel(rect, 2, true, false)
    love.graphics.setLineWidth( 1 )
    ui.style.panel_outline = style
end