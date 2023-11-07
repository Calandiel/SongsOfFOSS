local tabb = require "engine.table"

local ui = require "engine.ui";
local ut = require "game.ui-utils"

local pv = require "game.raws.values.political"
local ev = require "game.raws.values.economical"

local inspector = {}

local buildings_scroll = 0

---@return Rect
local function get_main_panel()
	local fs = ui.fullscreen()
	local panel = fs:subrect(ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 15 , fs.height - ut.BASE_HEIGHT * 2, "left", "up")
	return panel
end

---Returns whether or not clicks on the planet can be registered.
---@return boolean
function inspector.mask()
	if ui.trigger(get_main_panel()) then
		return false
	else
		return true
	end
end

---comment
---@param gam GameScene
function inspector.draw(gam)
    local rect = get_main_panel()
    local base_unit = UI_STYLE.scrollable_list_item_height

    ui.panel(rect)

    local rr = rect.height
    rect.height = base_unit

    local top_rect = rect:subrect(0, 0, rect.width - base_unit, base_unit, "left", "up")

    local label_rect = top_rect:subrect(0, 0, top_rect.width / 2, base_unit, "left", "up")
    ui.centered_text("Construction", label_rect)
    local public_flag_rect = top_rect:subrect(0, 0, top_rect.width / 2, base_unit, "right", "up")

    local public_mode = false

    local character = WORLD.player_character

    if character then
        if character.realm.leader == character then
            public_mode = ui.named_checkbox(
                "Use realm treasury: ",
                public_flag_rect,
                gam.macrobuilder_public_mode,
                5
            )
            gam.macrobuilder_public_mode = public_mode
        end
    end


    local available_buildings = {}
    local seen = {}
    local buildable = {}

    local public_flag = false
    local overseer = character
    local funds = 0
    local owner = character

    if character then
        funds = character.savings
        if gam.macrobuilder_public_mode then
            overseer = pv.overseer(character.realm)
            public_flag = true
            funds = character.realm.budget.treasury
            owner = nil
        end

        for _, province in pairs(character.realm.provinces) do
            for _, building in pairs(province.buildable_buildings) do
                if not seen[building] then
                    table.insert(available_buildings, building)
                    buildable[building] = false
                else
                    seen[building] = true
                end

                if province:can_build(funds, building, province.center, overseer, public_flag) then
                    buildable[building] = true
                end
            end
        end
    end

    rect.height = rr - base_unit
    rect.y = rect.y + base_unit
    buildings_scroll = ut.scrollview(
        rect,
        function(number, rect)
            ---@type Rect
            rect = rect
            rect.height = rect.height - 1
            if number > 0 then
                local name, building_type = tabb.nth(available_buildings, number)
                if building_type == nil then
                    return
                end

                ---@type BuildingType
                building_type = building_type

                -- drawing icons
                local icon = building_type.icon
                local image_padding = 3
                local icon_rect = rect:subrect(image_padding, image_padding, base_unit - image_padding * 2, base_unit - image_padding * 2, "left", "up")
                ui.image(ASSETS.get_icon(icon), icon_rect)

                rect.x = rect.x + base_unit
                rect.width = rect.width - base_unit

                -- drawing the button
                local result, rect_data = ut.button(rect, buildable[building_type], gam.selected.macrobuilder_building_type == building_type)
                if result then
                    gam.selected.macrobuilder_building_type = building_type
                end

                local construction_cost = ev.building_cost(
                    building_type,
                    overseer,
                    public_flag
                )

                local negative_flag = construction_cost > funds

                ut.money_entry(building_type.description, construction_cost, rect_data, nil, negative_flag, false)
            end
        end,
        UI_STYLE.scrollable_list_item_height,
        tabb.size(available_buildings),
        UI_STYLE.slider_width,
        buildings_scroll
    )

end


return inspector