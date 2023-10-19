local ui = require "engine.ui";
local uit = require "game.ui-utils"

local EconomicEffects = require "game.raws.effects.economic"
local EconomicValues = require "game.raws.values.economical"
local pv = require "game.raws.values.political"

---comment
---@param rect Rect
---@param reason BuildingAttemptFailureReason?
---@param funds number
---@param cost number
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
            " / " .. uit.to_fixed_point2(cost) .. MONEY_SYMBOL, rect)
    elseif reason == 'missing_local_resources' then
        ui.image(ASSETS.icons['triangle-target.png'], rect)
        ui.tooltip('Missing local resources!', rect)
    end
end

---comment
---@param gam table
---@param rect Rect
---@param building_type BuildingType
---@param tile Tile
---@param owner POP?
---@param overseer POP?
---@param public_flag boolean
---@param tile_improvement_flag boolean
local function construction_button(gam, rect, building_type, tile, owner, overseer, public_flag, tile_improvement_flag)
    local character = WORLD.player_character
    if character == nil then
        return
    end
    local realm = character.realm
    if realm == nil then
        return
    end

    local funds = 0
    if public_flag or owner == nil then
        funds = realm.budget.treasury
    else
        funds = owner.savings
    end

    local success, reason = tile.province:can_build(
        funds,
        building_type,
        tile,
        overseer,
        public_flag
    )

    local construction_cost = EconomicValues.building_cost(
        building_type,
        overseer,
        public_flag
    )

    if not success then
        validate_building_tooltip(rect, reason, funds, construction_cost)
    else
        if tile.tile_improvement and building_type.tile_improvement then
            ui.image(ASSETS.icons['triangle-target.png'], rect)
            ui.tooltip('There already is a tile improvement on here!', rect)
        else
            local tooltip = "(private)"
            if public_flag then
                tooltip = "(public)"
            end
            if ui.icon_button(ASSETS.icons['hammer-drop.png'], rect,
                "Build " .. tooltip .." (" .. tostring(construction_cost) .. MONEY_SYMBOL .. ")") then

                EconomicEffects.construct_building_with_payment(
                    building_type,
                    tile.province,
                    tile,
                    owner,
                    overseer,
                    public_flag
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

---comment
---@param gam table
---@param rect Rect
---@param base_unit number
---@param building_type BuildingType
---@param tile_improvement_flag boolean
---@param tile Tile
return function (gam, rect, base_unit, building_type, tile, tile_improvement_flag)
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
        construction_button(gam, r, building_type, tile, WORLD.player_character, WORLD.player_character, false, tile_improvement_flag)
    end

    r.x = r.x + base_unit
    r.width = base_unit
    if WORLD:does_player_control_realm(tile.province.realm) then
        construction_button(gam, r, building_type, tile, nil, pv.overseer(tile.province.realm), true, tile_improvement_flag)
    end
end