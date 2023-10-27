local ui = require "engine.ui"
local ut = require "game.ui-utils"

local callback = require "game.scenes.callbacks"

local ev = require "game.raws.values.economical"
local ee = require "game.raws.effects.economic"
local pv = require "game.raws.values.political"

---@param tile Tile
---@param rect Rect rectangle of the according tile
---@param x number
---@param y number
---@param size number
return function(gam, tile, rect, x, y, size)
    -- unit sizes
    local width_unit = size * 4
    local height_unit = size / 2

    local length_of_line = 50 - height_unit


    if gam.inspector == "macrobuilder" then
        local player_character = WORLD.player_character

        if player_character == nil then
            return false
        end

        if player_character.realm ~= tile.province.realm then
            return false
        end

        ---@type BuildingType
        local building_type = gam.selected_macrobuilder_building_type

        if building_type then

            local best_location = nil

            if building_type.tile_improvement then
                local best_eff = 0
                local province = tile.province
                if province and building_type then
                    for _, p_tile in pairs(province.tiles) do
                        if not p_tile.tile_improvement then
                            best_eff = math.max(best_eff, building_type.production_method:get_efficiency(p_tile))
                            best_location = p_tile
                        end
                    end
                end
            end

            local public_flag = false
            local overseer = player_character
            local funds = player_character.savings
            local owner = player_character

            if gam.macrobuilder_public_mode then
                overseer = pv.overseer(tile.province.realm)
                public_flag = true
                funds = player_character.realm.budget.treasury
                owner = nil
            end

            if not tile.province:can_build(9999, building_type, best_location, overseer, public_flag) then
                return
            end

            local icon = building_type.icon
            local name = building_type.name

            local amount = 0
            
            for _, building in pairs(tile.province.buildings) do
                if building.type == building_type then
                    amount = amount + 1
                end
            end

            local unit = size * 1.5

            local rect = ui.rect(
                x - unit / 2 ,
                y - unit / 2,
                unit,
                unit
            )

            local construction_cost = ev.building_cost(
                building_type,
                overseer,
                public_flag
            )

            local icon_rect = rect:subrect(0, 0, unit, unit, "left", 'up')
            local count_rect = rect:subrect(0, unit, unit, unit / 2, "left", 'up')

            if funds < construction_cost then
                ui.image(ASSETS.icons['uncertainty.png'], icon_rect)
            elseif ui.icon_button(ASSETS.get_icon(icon), icon_rect, "Build " .. name .. " for " .. ut.to_fixed_point2(construction_cost) .. MONEY_SYMBOL ) then
                ee.construct_building_with_payment(
                    building_type,
                    tile.province,
                    best_location,
                    owner,
                    overseer,
                    public_flag
                )
                
                return true
            end

            ut.integer_entry("", amount, count_rect, "Current amount of buildings")
        end

        return
    end
    -- draw an icon on map
    ui.image(ASSETS.get_icon('village.png'), rect)    

    local name_rect = ui.rect(
        x - size / 5, 
        y - height_unit - 50, 
        width_unit, 
        height_unit
    )

    local realm_rect = name_rect:copy()
    realm_rect.y = realm_rect.y - height_unit

    local population_rect = ui.rect(
        x - size / 5, 
        y - length_of_line - height_unit, 
        width_unit,
        height_unit
    )

    local button_rect = ui.rect(
        x - size / 5 + width_unit, 
        y - 50 - height_unit * 2, 
        size, 
        size
    )

    local line_rect = ui.rect(x - 1, y - length_of_line, 2, 50 - height_unit)

    ui.rectangle(line_rect)

    if require "game.scenes.game.widgets.realm-name"(gam, tile.province.realm, height_unit, realm_rect) then
        return true
    end

    ut.data_entry("", tile.province.name, name_rect)
    local population = tile.province:population()
    ut.data_entry("", tostring(population), population_rect)

    if WORLD.player_character then
        if ui.icon_button(ASSETS.get_icon("barbute.png"), button_rect) then
            callback.toggle_raiding_target(gam, tile.province)()
            return true
        end
    end
end

