local ui = require "engine.ui"
local ut = require "game.ui-utils"

local inspector = {}

local function get_main_panel()
    local fs = ui.fullscreen()
	local panel = fs:subrect(0, ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 2, fs.height, "left", "up")
	return panel
end

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
    local base_unit = ut.BASE_HEIGHT * 2
    ui.panel(rect)

    local layout = ui.layout_builder()
        :vertical()
        :position(rect.x, rect.y)
        :spacing(0)
        :build()

    local inspectors = {
        "macrobuilder",
        "macrodecision",
        "market",
        "army",
        "character-decisions",
        "warband",
        "property"
    }

    local inspector_icons = {
        ["macrobuilder"] = ASSETS.icons["hammer-drop.png"],
        ["macrodecision"] = ASSETS.icons["horizon-road.png"],
        ["market"] = ASSETS.icons["scales.png"],
        ["army"] = ASSETS.icons["guards.png"],
        ["character-decisions"] = ASSETS.icons["envelope.png"],
        ["warband"] = ASSETS.icons["barbute.png"],
        ["property"] = ASSETS.icons["bank.png"],
    }

    local inspector_tooltips = {
        ["macrobuilder"] = "Plan development of your estates",
        ["macrodecision"] = "Target province",
        ["market"] = "Visit local market",
        ["army"] = "View local warriors",
        ["character-decisions"] = "Actions",
        ["warband"] = "View your warband",
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

                local character = WORLD.player_character
                if character and gam.inspector == "market" then
                    gam.selected.province = character.province
                end
            end
        end
    end
end


return inspector