local ui = require "engine.ui";
local uit = require "game.ui-utils"

local EconomicEffects = require "game.raws.effects.economic"

local function validate_building_tooltip(rect, reason, funds, cost)
    if reason == 'unique_duplicate' then
        ui.image(ASSETS.icons['triangle-target.png'], rect)
        ui.tooltip('There can be at most a single building of this type per province!', rect)
    elseif reason == 'tile_improvement' then
        ui.image(ASSETS.icons['triangle-target.png'], rect)
        ui.tooltip('Tile improvements have to be built from the local infrastructure UI!', rect)
    elseif reason == 'not_enough_funds' then
        ui.image(ASSETS.icons['uncertainty.png'], rect)
        ui.tooltip('Not enough funds: ' ..
            uit.to_fixed_point2(funds) ..
            " / " .. tostring(cost) .. MONEY_SYMBOL, rect)
    elseif reason == 'missing_local_resources' then
        ui.image(ASSETS.icons['triangle-target.png'], rect)
        ui.tooltip('Missing local resources!', rect)
    end
end

---@param gam table
---@param rect Rect
return function (gam, rect, base_unit, building_type, tile)
    ui.tooltip(building_type:get_tooltip(), rect)
    ---@type Rect
    local r = rect
    local im = r:subrect(0, 0, base_unit, base_unit, "left", 'up')
    ui.image(ASSETS.get_icon(building_type.icon), im)
    r.x = r.x + base_unit
    r.width = r.width - base_unit * 4

    if building_type.tile_improvement then
        ui.left_text(building_type.name, r)
        uit.color_coded_percentage(building_type.production_method:get_efficiency(tile), r)
    else
        ui.left_text(building_type.name, r)
    end

    r.x = r.x + r.width
    r.width = base_unit
    if ui.icon_button(ASSETS.icons['mesh-ball.png'], r,
        "Show local efficiency on map") then
        gam.selected_building_type = building_type
        gam.refresh_map_mode(true)
    end

    r.x = r.x + base_unit
    r.width = base_unit
    if (WORLD.player_character) and WORLD.player_character.province == tile.province then
        local success, reason = tile.province:can_build(WORLD.player_character.savings, building_type, tile)
        if not success then
            validate_building_tooltip(r, reason, WORLD.player_character.savings, building_type.construction_cost)
        else
            if tile.tile_improvement then
                ui.image(ASSETS.icons['triangle-target.png'], r)
                ui.tooltip('There already is a tile improvement on here!', r)
            else
                if ui.icon_button(ASSETS.icons['hammer-drop.png'], r,
                    "Build (" .. tostring(building_type.construction_cost) .. MONEY_SYMBOL .. ")") then

                    local Building = require "game.entities.building".Building
                    local building = Building:new(tile.province, building_type, tile)
                    EconomicEffects.set_ownership(building, WORLD.player_character)
                    EconomicEffects.add_pop_savings(
                        WORLD.player_character,
                        -building_type.construction_cost,
                        EconomicEffects.reasons.Building
                    )
                    WORLD:emit_notification("Tile improvement complete (" .. building_type.name .. ")")

                    if gam.selected_building_type == building_type then
                        gam.selected_building_type = building_type
                        gam.refresh_map_mode(true)
                    end
                end
            end
        end
    end

    r.x = r.x + base_unit
    r.width = base_unit
    if WORLD:does_player_control_realm(tile.province.realm) then
        local success, reason = tile.province:can_build(WORLD.player_realm.treasury, building_type, tile)
        if not success then
            validate_building_tooltip(r, reason, WORLD.player_realm.treasury, building_type.construction_cost)
        else
            if tile.tile_improvement then
                ui.image(ASSETS.icons['triangle-target.png'], r)
                ui.tooltip('There already is a tile improvement on here!', r)
            else
                if ui.icon_button(ASSETS.icons['hammer-drop.png'], r,
                    "Build (" .. tostring(building_type.construction_cost) .. MONEY_SYMBOL .. ")") then
                    local Building = require "game.entities.building".Building
                    Building:new(tile.province, building_type, tile)
                    WORLD.player_realm.treasury = WORLD.player_realm.treasury - building_type.construction_cost
                    WORLD:emit_notification("Tile improvement complete (" .. building_type.name .. ")")

                    if gam.selected_building_type == building_type then
                        gam.selected_building_type = building_type
                        gam.refresh_map_mode(true)
                    end
                end
            end
        end
    end


end