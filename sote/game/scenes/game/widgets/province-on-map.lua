local ui = require "engine.ui"
local ut = require "game.ui-utils"

local callback = require "game.scenes.callbacks"

local ev = require "game.raws.values.economical"
local ee = require "game.raws.effects.economic"
local pv = require "game.raws.values.political"

---comment
---@param gam GameScene
---@param tile Tile
---@param rect Rect
---@param x number
---@param y number
---@param size number
local function macrodecision(gam, tile, rect, x, y, size)
    local decision = gam.selected.macrodecision
    if decision  == nil then
        return
    end

    local player = WORLD.player_character
    if player == nil then
        return
    end

    if not decision.pretrigger(player) then
        return
    end

    if not decision.clickable(player, tile.province) then
        return
    end

    local tooltip = decision.tooltip(player, tile.province)
    local available = decision.available(player, tile.province)

    if ut.icon_button(ASSETS.icons["circle.png"], rect, tooltip, available) then
        return function ()
            decision.effect(player, tile.province)
        end
    end
end

---comment
---@param gam GameScene
---@param tile Tile
---@param rect Rect
---@param x number
---@param y number
---@param size number
---@return function|nil
local function macrobuilder(gam, tile, rect, x, y, size)
    local player_character = WORLD.player_character
    if player_character == nil then
        return
    end
    if player_character.province ~= tile.province then
        return
    end
    ---@type BuildingType
    local building_type = gam.selected.macrobuilder_building_type

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

        local icon_rect = rect:subrect(0, 0, unit, unit, "left", "up")
        local count_rect = rect:subrect(0, unit, unit, unit / 2, "left", "up")

        if funds < construction_cost then
            ut.icon_button(ASSETS.icons["cancel.png"], icon_rect, "Not possible to build", false)
        elseif ut.icon_button(ASSETS.get_icon(icon), icon_rect, "Build " .. name .. " for " .. ut.to_fixed_point2(construction_cost) .. MONEY_SYMBOL ) then
            return function()
                ee.construct_building_with_payment(
                    building_type,
                    tile.province,
                    best_location,
                    owner,
                    overseer,
                    public_flag
                )
            end
        end

        ut.integer_entry("", amount, count_rect, "Current amount of buildings")
    end
end


---@param gam GameScene
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

    if gam.inspector == "macrodecision" then
        return macrodecision(gam, tile, rect, x, y, size)
    end

    if gam.inspector == "macrobuilder" then
        return macrobuilder(gam, tile, rect, x, y, size)
    end

    rect.x = x - size / 5
    rect.y = y - length_of_line - height_unit * 2
    rect.width = width_unit
    rect.height = height_unit
    ut.data_entry("", tile.province.name, rect)


    rect.y = rect.y - height_unit
    local callback_coa = require "game.scenes.game.widgets.realm-name"(gam, tile.province.realm, rect, "callback")


    rect.y = y - length_of_line - height_unit
    local population = tile.province:population()
    ut.data_entry("", tostring(population), rect)

    local line_rect = ui.rect(x - 1, y - length_of_line, 2, 50 - height_unit)
    ui.rectangle(line_rect)

    if callback_coa then
        return callback_coa
    end

    if WORLD.player_character then
        local button_rect = ui.rect(
            x - size / 5 + width_unit,
            y - 50 - height_unit * 2,
            size,
            size
        )
        if ut.icon_button(ASSETS.get_icon("barbute.png"), button_rect) then
            return callback.toggle_raiding_target(gam, tile.province)
        end
    end
end

