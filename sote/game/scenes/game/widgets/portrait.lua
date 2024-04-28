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
    -- square portrait image
    local subrect = rect:centered_square()
    -- TODO: maybe we should draw background images related to current position
    local old_inside = ui.style["panel_inside"]
    ui.style["panel_inside"] = {r = 0 / 255, g = 20 / 255, b = 10 / 255, a = 0.3}
    ui.panel(subrect, 2, false)
    ui.style["panel_inside"] = old_inside

    love.graphics.setLineWidth( 4 )

    local portrait_set = character.race.male_portrait
    if character.female then
        portrait_set = character.race.female_portrait
    end

    if portrait_set then
        local portrait = portrait_set.fallback

        if portrait_set.elder then
            portrait = portrait_set.elder
        end

        if character.age < character.race.elder_age then
            if portrait_set.middle then
                portrait = portrait_set.middle
            end
        end

        if character.age < character.race.middle_age then
            if portrait_set.adult then
                portrait = portrait_set.adult
            end
        end

        if character.age < character.race.adult_age then
            if portrait_set.teen then
                portrait = portrait_set.teen
            end
        end

        if character.age < character.race.teen_age then
            if portrait_set.child then
                portrait = portrait_set.child
            end
        end

        assert(portrait ~= nil, "INVALID PORTRAIT: RACE " .. character.race.name)

        ---@type number[]
        local dna_per_layer = {}
        ---@type table<string, number>
        local layer_to_index = {}
        for i, layer in ipairs(portrait.layers) do
            table.insert(dna_per_layer, character.dna[i])
            layer_to_index[layer] = i
        end

        for i, layers_group in pairs(portrait.layers_groups) do
            for j, layer in ipairs(layers_group) do
                dna_per_layer[layer_to_index[layer]] = dna_per_layer[layer_to_index[layers_group[1]]]
            end
        end

        assert(ASSETS.portraits[portrait.folder] ~= nil, portrait.folder .. " WAS NOT LOADED")

        for i, layer in ipairs(portrait.layers) do
            assert(ASSETS.portraits[portrait.folder][layer] ~= nil, layer .. " WAS NOT LOADED")
            assert(dna_per_layer[i] ~= nil, i)
            ui.image_ith(ASSETS.portraits[portrait.folder][layer], dna_per_layer[i], subrect)
        end
    else
        ui.image(ASSETS.icons[character.race.icon], subrect)
    end

    -- relation to player character
    if WORLD.player_character then
        local player_realtion_icon_size = math.min(20, (subrect.width - 2) / 3)
        local player_relation_icon_rect = subrect:subrect(2, -2, player_realtion_icon_size, player_realtion_icon_size, "left", "down")
        if WORLD.player_character == character then
            ut.render_icon(player_relation_icon_rect, "self-love.png", 1, 1, 1, 1)
            player_relation_icon_rect:shrink(-1)
            ut.render_icon(player_relation_icon_rect, "self-love.png", 0.72, 0.13, 0.27, 1.0)
        elseif WORLD.player_character.parent == character or WORLD.player_character.children[character] then
            ut.render_icon(player_relation_icon_rect, "ages.png", 1, 1, 1, 1)
            player_relation_icon_rect:shrink(-1)
            ut.render_icon(player_relation_icon_rect, "ages.png", 0.72, 0.13, 0.27, 1.0)
        end
    end
    ui.panel(subrect, 2, true, false)
    love.graphics.setLineWidth( 1 )
    ui.style.panel_outline = style
end