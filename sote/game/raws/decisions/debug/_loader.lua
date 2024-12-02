local utils = require "game.raws.raws-utils"
local Decision = require "game.raws.decisions"

return function()
	---@type DecisionCharacter
	Decision.Character:new {
		name = 'debug-wealth-character',
		ui_name = "DEBUG: wealth cheat",
		tooltip = utils.constant_string("Get wealth."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			if not OPTIONS.debug_mode then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if not OPTIONS.debug_mode then
				return false
			end
			return true
		end,
		available = function(root, primary_target)
			return true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			---@type Character
			local root = root
			local province = PROVINCE(root)
			if province == INVALID_ID then return end
			DATA.pop_inc_savings(root, 1000)
			if WORLD:does_player_see_realm_news(PROVINCE_REALM(province)) then
				WORLD:emit_notification(NAME(root) .. " conjured money out of thin air.")
			end
		end
	}

		---@type DecisionCharacter
	Decision.Character:new {
		name = 'debug-kill-character',
		ui_name = "DEBUG: kill",
		tooltip = utils.constant_string("Kill."),
		sorting = 1,
		primary_target = "character",
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			if not OPTIONS.debug_mode then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if not OPTIONS.debug_mode then
				return false
			end
			return true
		end,
		available = function(root, primary_target)
			return true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			WORLD:emit_immediate_event('death', primary_target, {})
			WORLD:emit_notification(NAME(root) .. " kills " .. primary_target.name)
		end
	}
end