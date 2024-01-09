local ui = require "engine.ui"
local ut = require "game.ui-utils"

local office_triggers = require "game.raws.triggers.offices"

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
        "army",
        "character-decisions",
        "warband",
        "property",
        "market",
        "preferences",
        "quests"
    }

    local inspector_icons = {
        ["macrobuilder"] = ASSETS.icons["hammer-drop.png"],
        ["macrodecision"] = ASSETS.icons["horizon-road.png"],
        ["army"] = ASSETS.icons["guards.png"],
        ["character-decisions"] = ASSETS.icons["envelope.png"],
        ["warband"] = ASSETS.icons["barbute.png"],
        ["property"] = ASSETS.icons["bank.png"],
        ["market"] = ASSETS.icons["scales.png"],
        ["preferences"] = ASSETS.icons["shrug.png"],
        ["quests"] =ASSETS.icons["coins.png"]
    }

    local inspector_tooltips = {
        ["macrobuilder"] = "Plan development of your estates",
        ["macrodecision"] = "Target province",
        ["army"] = "View local warriors",
        ["character-decisions"] = "Actions",
        ["warband"] = "View your warband",
        ["property"] = "Assess your property",
        ["market"] = "View local market",
        ["preferences"] = "Decide your preferences",
        ["quests"] = "View available quests"
    }

    local inspector_visible = {
        ["macrobuilder"] = function ()
            if WORLD.player_character == nil then return false end
            return true
        end,
        ["macrodecision"] = function ()
            if WORLD.player_character == nil then return false end
            return true
        end,
        ["army"] = function ()
            if WORLD.player_character == nil then return false end
            return true
        end,
        ["character-decisions"] = function ()
            if WORLD.player_character == nil then return false end
            return true
        end,
        ["warband"] = function ()
            if WORLD.player_character == nil then return false end
            if WORLD.player_character.leading_warband then return true end
            if office_triggers.guard_leader(WORLD.player_character, WORLD.player_character.realm) then return true end
            return false
        end,
        ["property"] = function ()
            if WORLD.player_character == nil then return false end
            return true
        end,
        ["market"] = function ()
            if WORLD.player_character == nil then return false end
            return true
        end,
        ["preferences"] = function ()
            return true
        end,
        ["quests"] = function ()
            if WORLD.player_character == nil then return false end
            return true
        end
    }

    for _, inspector in pairs(inspectors) do
        local active = gam.inspector == inspector
        local icon = inspector_icons[inspector]
        local tooltip = inspector_tooltips[inspector]

        local check = inspector_visible[inspector]

        if check() then
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


    local fs = ui.fullscreen()
    local rect_for_menu = fs:subrect(0, 0, base_unit, base_unit, "left", "down")
	if ut.icon_button(
			ASSETS.icons["gear.png"],
			rect_for_menu,
			"Open menu."
	) then
		gam.inspector = "confirm-exit"
	end
end


return inspector