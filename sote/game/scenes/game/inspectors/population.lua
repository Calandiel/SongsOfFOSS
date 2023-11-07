local ui = require "engine.ui";
local ut = require "game.ui-utils"

local inspector = {}

---@return Rect
local function get_main_panel()
	local fs = ui.fullscreen()
	local panel = fs:subrect(ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 40, ut.BASE_HEIGHT * 15, "left", "up")
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

    ui.panel(rect)

    local province = gam.selected.province

    if province == nil then
        return
    end

    local base_unit = ut.BASE_HEIGHT

    local population_data_rect = rect:subrect(0, 0, base_unit * 9, base_unit, "left", "up")

    ut.integer_entry("Total:", province:population(), population_data_rect)
    population_data_rect.x = population_data_rect.x + population_data_rect.width + base_unit
    -- ut.money_entry("Trade wealth:", province.trade_wealth, population_data_rect)
    -- population_data_rect.x = population_data_rect.x + population_data_rect.width + base_unit
    -- ut.money_entry("Local income:", province.local_income, population_data_rect)
    -- population_data_rect.x = population_data_rect.x + population_data_rect.width + base_unit
    -- ut.money_entry("Local building upkeep:", province.local_building_upkeep, population_data_rect)
    -- population_data_rect.y = population_data_rect.y + base_unit

    rect.y = rect.y + base_unit
    rect.height = rect.height - base_unit

    require "game.scenes.game.widgets.pop-list" (rect, base_unit, province)()
end

return inspector