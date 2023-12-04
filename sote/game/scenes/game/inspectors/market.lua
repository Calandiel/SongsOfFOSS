local ui = require "engine.ui";
local ut = require "game.ui-utils"

local inspector = {}

---@return Rect
local function get_main_panel()
	local fs = ui.fullscreen()
	local panel = fs:subrect(ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 50, ut.BASE_HEIGHT * 15, "left", "up")
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

    local wealth_data_rect = rect:subrect(0, 0, base_unit * 9, base_unit, "left", "up")

    ut.money_entry("Local wealth:", province.local_wealth, wealth_data_rect)
    wealth_data_rect.x = wealth_data_rect.x + wealth_data_rect.width + base_unit
    ut.money_entry("Trade wealth:", province.trade_wealth, wealth_data_rect)
    wealth_data_rect.x = wealth_data_rect.x + wealth_data_rect.width + base_unit
    ut.money_entry("Local income:", province.local_income, wealth_data_rect)
    wealth_data_rect.x = wealth_data_rect.x + wealth_data_rect.width + base_unit
    ut.money_entry("Local building upkeep:", province.local_building_upkeep, wealth_data_rect)
    wealth_data_rect.y = wealth_data_rect.y + base_unit

    rect.y = rect.y + base_unit
    rect.height = rect.height - base_unit

    require "game.scenes.game.widgets.local-market" (province, rect, base_unit, gam)()
end

return inspector