local tabb = require "engine.table"

local ui = require "engine.ui";
local ut = require "game.ui-utils"


local inspector = {}

local buildings_scroll = 0

---@return Rect
local function get_main_panel()
	local fs = ui.fullscreen()
	local panel = fs:subrect(ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 15 , fs.height - ut.BASE_HEIGHT * 2, "left", 'up')
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

function inspector.draw(gam)
    local rect = get_main_panel()
    local base_unit = ut.BASE_HEIGHT + 5

    ui.panel(rect)

    local rr = rect.height
    rect.height = base_unit

    local top_rect = rect:subrect(0, 0, rect.width - base_unit, base_unit, "left", 'up')

    local label_rect = top_rect:subrect(2, 0, top_rect.width / 2, base_unit, "left", 'up')
    ui.centered_text("Construction", label_rect)
    local public_flag_rect = top_rect:subrect(0, 0, top_rect.width / 2, base_unit, "right", 'up')

    local public_mode = ui.named_checkbox(
		"Use realm treasury: ",
		public_flag_rect,
        gam.macrobuilder_public_mode,
		5
	)

    if WORLD.player_character then
        if WORLD.player_character.realm.leader == WORLD.player_character then
            gam.macrobuilder_public_mode = public_mode
        end
    end

    rect.height = rr - base_unit
    rect.y = rect.y + base_unit
    buildings_scroll = ui.scrollview(
        rect, 
        function(number, rect)
            ---@type Rect
            rect = rect
            rect.height = rect.height - 1
            if number > 0 then
                local name, building_type = tabb.nth(RAWS_MANAGER.building_types_by_name, number)
                if building_type == nil then
                    return
                end

                ---@type BuildingType
                building_type = building_type

                -- drawing icons
                local icon = building_type.icon
                local image_padding = 3
                local icon_rect = rect:subrect(image_padding, image_padding, base_unit - image_padding * 2, base_unit - image_padding * 2, "left", 'up')
                ui.image(ASSETS.get_icon(icon), icon_rect)

                rect.x = rect.x + base_unit
                rect.width = rect.width - base_unit

                -- drawing the button
                local result, rect_data = ut.button(rect, true)
                if result then
                    gam.selected_macrobuilder_building_type = building_type
                end
                ut.generic_string_field("", building_type.description, rect_data, nil, ut.NAME_MODE.NAME, false)
            end
        end,
        base_unit,
        tabb.size(RAWS_MANAGER.building_types_by_name),
        base_unit,
        buildings_scroll
    )

end


return inspector