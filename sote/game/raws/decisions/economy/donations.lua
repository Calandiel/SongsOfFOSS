local utils = require "game.raws.raws-utils"
local Decision = require "game.raws.decisions"
local economic_effects = require "game.raws.effects.economy"

local base_gift_size = 20

return function ()
	---@type DecisionCharacter
	Decision.Character:new {
		name = 'donate-wealth-local-wealth',
		ui_name = "Donate wealth to locals.",
		tooltip = utils.constant_string("I will donate (" .. tostring(base_gift_size) .. MONEY_SYMBOL .. ") to local wealth pool in exchange for popularity."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			local fat = DATA.fatten_pop(root)
			if fat.busy then return false end
			if fat.savings < base_gift_size then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			return true
		end,
		available = function(root, primary_target)
			return true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			local fat = DATA.fatten_pop(root)
			if fat.savings > base_gift_size * 20 then
				return 0.1
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			local province = PROVINCE(root)
			if province == INVALID_ID then return end
			economic_effects.gift_to_province(root, province, base_gift_size)
		end
	}

	---@type DecisionCharacter
	Decision.Character:new {
		name = 'donate-wealth-realm',
		ui_name = "Donate wealth to your realm.",
		tooltip = utils.constant_string("Donate wealth (" .. tostring(base_gift_size) .. ") to your realm treasury."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			local fat = DATA.fatten_pop(root)
			if fat.busy then return false end
			if fat.savings < base_gift_size then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			return true
		end,
		available = function(root, primary_target)
			local realm = LOCAL_REALM(root)
			if realm == INVALID_ID then
				return false
			end

			if DATA.pop_get_savings(root) < base_gift_size then
				return false
			end
			return true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			---@type Character
			local root = root

			--- rich characters want to donate money to the state more
			if DATA.pop_get_savings(root) > base_gift_size then
				return ((DATA.pop_get_savings(root)  / base_gift_size) - 1) * 0.001
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			economic_effects.gift_to_tribe(root, LOCAL_REALM(root), base_gift_size)
		end
	}
end