local ui = require "engine.ui"
local uit = require "game.ui-utils"

local inspector = {}

local function get_main_panel()
    local fs = ui.fullscreen()
	local panel = fs:subrect(0, uit.BASE_HEIGHT * 2, uit.BASE_HEIGHT * 2, fs.height, "left", 'up')
	return panel
end

function inspector.mask()
    if ui.trigger(get_main_panel()) then
		return false
	else
		return true
	end
end

function inspector.draw(gam)
    local rect = get_main_panel()
    local base_unit = uit.BASE_HEIGHT * 2
    ui.panel(rect)

    local layout = ui.layout_builder()
        :vertical()
        :position(rect.x, rect.y)
        :spacing(0)
        :build()
    
    if ui.icon_button(ASSETS.icons['scales.png'], layout:next(base_unit, base_unit), "Visit local market") then
        if gam.inspector == 'market' then
            gam.inspector = nil
        else
            gam.inspector = 'market'
        end
    end

    if ui.icon_button(ASSETS.icons['guards.png'], layout:next(base_unit, base_unit), "Visit local warriors") then
        if gam.inspector == 'army' then
            gam.inspector = nil
        else
            gam.inspector = "army"
        end
    end

    if ui.icon_button(ASSETS.icons['envelope.png'], layout:next(base_unit, base_unit), "Do something") then
        if gam.inspector == 'character-decisions' then
            gam.inspector = nil
        else
            gam.inspector = "character-decisions"
        end
    end
end


return inspector