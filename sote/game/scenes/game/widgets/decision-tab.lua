local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

---Renders the decision tab
---@param ui_panel Rect
---@param primary_target any
---@param decision_type DecisionTarget
---@param gam GameScene
return function (ui_panel, primary_target, decision_type, gam)
	ut.columns({
		function(rect)
			local decis, tg_primar, tg_second = require "game.scenes.game.widgets.decision-selection-character"(
				rect,
				decision_type,
				primary_target,
				gam.selected.decision
			)
			gam.selected.decision = decis
			gam.decision_target_primary = tg_primar
			gam.decision_target_secondary = tg_second
		end,
		function(rect)
			local res = require "game.scenes.game.widgets.decision-desc"(
				rect,
				WORLD.player_character,
				gam.selected.decision,
				gam.decision_target_primary,
				gam.decision_target_secondary
			)

			if res ~= 'nothing' then
				gam.selected.decision = nil
				gam.decision_target_primary = nil
				gam.decision_target_secondary = nil
			end
		end
	}, ui_panel, ui_panel.width / 2)
end