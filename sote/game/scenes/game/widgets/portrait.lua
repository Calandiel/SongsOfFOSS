local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

---@param rect Rect
---@param character_id Character
return function(rect, character_id)
    if character_id == INVALID_ID then
        return
    end

    local character = DATA.fatten_pop(character_id)

    if character.race == INVALID_ID then
        return
    end

    local race = DATA.fatten_race(character.race)


    local style = ui.style.panel_outline
    if character.rank == CHARACTER_RANK.NOBLE then
        -- silver color rgba
        ui.style.panel_outline = {r = 165 / 255, g = 169 / 255, b = 180 / 255, a = 1}
    elseif character.rank == CHARACTER_RANK.CHIEF then
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

    local portrait_set = race.male_portrait
    if character.female then
        portrait_set = race.female_portrait
    end

    if portrait_set then
        local portrait = portrait_set.fallback

        if portrait_set.elder then
            portrait = portrait_set.elder
        end

        if character.age < race.elder_age then
            if portrait_set.middle then
                portrait = portrait_set.middle
            end
        end

        if character.age < race.middle_age then
            if portrait_set.adult then
                portrait = portrait_set.adult
            end
        end

        if character.age < race.adult_age then
            if portrait_set.teen then
                portrait = portrait_set.teen
            end
        end

        if character.age < race.teen_age then
            if portrait_set.child then
                portrait = portrait_set.child
            end
        end

        assert(portrait ~= nil, "INVALID PORTRAIT: RACE " .. race.name)

        ---@type number[]
        local dna_per_layer = {}
        ---@type table<string, number>
        local layer_to_index = {}
        for i, layer in ipairs(portrait.layers) do
            table.insert(dna_per_layer, DATA.pop_get_dna(character_id, i))
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
        assert(race.icon ~= nil, "race " .. character.race .. " icon is nil")
        assert(ASSETS.icons[race.icon] ~= nil, "race " .. race.name .. " icon " .. race.icon .. " is missing ")
        ui.image(ASSETS.icons[race.icon], subrect)
    end

    -- relation to player character
    if WORLD.player_character ~= INVALID_ID then
        local player_realtion_icon_size = math.min(20, (subrect.width - 2) / 3)
        local player_relation_icon_rect = subrect:subrect(2, -2, player_realtion_icon_size, player_realtion_icon_size, "left", "down")

        local parent_rel = DATA.get_parent_child_relation_from_child(WORLD.player_character)
        local parent = DATA.parent_child_relation_get_parent(parent_rel)
        local is_parent = false
        if parent == character then
            is_parent = true
        end

        local is_child = false
        DATA.for_each_parent_child_relation_from_parent(WORLD.player_character, function (item)
            local child = DATA.parent_child_relation_get_child(item)
            if child == character then
                is_child = true
            end
        end)

        if WORLD.player_character == character then
            ut.render_icon(player_relation_icon_rect, "self-love.png", 1, 1, 1, 1)
            player_relation_icon_rect:shrink(-1)
            ut.render_icon(player_relation_icon_rect, "self-love.png", 0.72, 0.13, 0.27, 1.0)
        elseif is_parent or is_child then
            ut.render_icon(player_relation_icon_rect, "ages.png", 1, 1, 1, 1)
            player_relation_icon_rect:shrink(-1)
            ut.render_icon(player_relation_icon_rect, "ages.png", 0.72, 0.13, 0.27, 1.0)
        end
    end
    ui.panel(subrect, 2, true, false)
    love.graphics.setLineWidth( 1 )
    ui.style.panel_outline = style
end