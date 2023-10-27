local ui = require "engine.ui"
local ut = require "game.ui-utils"

local inspector = {}

local function get_main_panel()
    local fs = ui.fullscreen()
	local panel = fs:subrect(0, ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 2, fs.height, "left", 'up')
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
    local base_unit = ut.BASE_HEIGHT * 2
    ui.panel(rect)

    local layout = ui.layout_builder()
        :vertical()
        :position(rect.x, rect.y)
        :spacing(0)
        :build()

    local inspectors = {
        "macrobuilder",
        "market",
        "army",
        "character-decisions",
    }

    local inspector_icons = {
        ['macrobuilder'] = ASSETS.icons['hammer-drop.png'],
        ['market'] = ASSETS.icons['scales.png'],
        ['army'] = ASSETS.icons['guards.png'],
        ['character-decisions'] = ASSETS.icons['envelope.png'],
    }

    local inspector_tooltips = {
        ['macrobuilder'] = "Plan development of your estates",
        ['market'] = "Visit local market",
        ['army'] = "Visit local warriors",
        ['character-decisions'] = "Do something",
    }

    for _, inspector in pairs(inspectors) do
        local active = gam.inspector == inspector
        local icon = inspector_icons[inspector]
        local tooltip = inspector_tooltips[inspector]

        if ut.icon_button(icon, layout:next(base_unit, base_unit), tooltip, true, active) then
            if active then
                gam.inspector = nil
            else
                gam.inspector = inspector
            end
        end
    end

    -- if ut.icon_button(ASSETS.icons['hammer-drop.png'], layout:next(base_unit, base_unit), "Plan development of your estates", true) then
    --     if gam.inspector == 'macrobuilder' then
    --         gam.inspector = nil
    --     else
    --         gam.inspector = 'macrobuilder'
    --     end
    -- end

    
    -- if ut.icon_button(ASSETS.icons['scales.png'], layout:next(base_unit, base_unit), "Visit local market", true) then
    --     if gam.inspector == 'market' then
    --         gam.inspector = nil
    --     else
    --         gam.inspector = 'market'
    --     end
    -- end

    -- if ut.icon_button(ASSETS.icons['guards.png'], layout:next(base_unit, base_unit), "Visit local warriors", true) then
    --     if gam.inspector == 'army' then
    --         gam.inspector = nil
    --     else
    --         gam.inspector = "army"
    --     end
    -- end

    -- if ut.icon_button(ASSETS.icons['envelope.png'], layout:next(base_unit, base_unit), "Do something") then
    --     if gam.inspector == 'character-decisions' then
    --         gam.inspector = nil
    --     else
    --         gam.inspector = "character-decisions"
    --     end
    -- end
end


return inspector