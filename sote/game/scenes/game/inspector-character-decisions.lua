local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

local window = {}

local selected_decision = nil
local decision_target_primary = nil
local decision_target_secondary = nil

---@return Rect
function window.rect() 
    return ui.fullscreen():subrect(0, 0, 300, 400, "center", "center")
end

function window.mask()
    if ui.trigger(window.rect()) then
		return false
	else
		return true
	end
end

---Draw decisions window
---@param game table
function window.draw(game)
    local ui_panel = window.rect()
    -- draw a panel
    ui.panel(ui_panel)

    local base_unit = ut.BASE_HEIGHT

    ui.text("Character decisions", ui_panel, "left", 'up')

    if ui.icon_button(ASSETS.icons["cancel.png"], ui_panel:subrect(0, 0, base_unit, base_unit, "right", 'up')) then
        game.inspector = nil
    end

    ui_panel.y = ui_panel.y + base_unit
    ui_panel.height = ui_panel.height - base_unit * 2

    ut.rows({
		function(rect)
			-- First, we need to check if the player is controlling a realm
			if WORLD.player_character then
				selected_decision, decision_target_primary, decision_target_secondary = require "sote.game.scenes.game.widgets.decision-selection-character"(
					rect,
					'none',
					nil,
                    selected_decision
				)
			else
				-- No player realm: no decisions to draw
			end
		end,
		function(rect)
			local res = require "sote.game.scenes.game.widgets.decision-desc"(
				rect,
				WORLD.player_character,
				selected_decision,
				decision_target_primary,
				decision_target_secondary
			)

			if res ~= 'nothing' then
				selected_decision = nil
				decision_target_primary = nil
				decision_target_secondary = nil
			end
		end
	}, ui_panel, ui_panel.height / 2)
end

return window