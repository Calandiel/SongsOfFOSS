local tabb = require "engine.table"
local utils = require "game.raws.raws-utils"
local Decision = require "game.raws.decisions"

local military_effects = require "game.raws.effects.military"
local economic_effects = require "game.raws.effects.economic"
local economic_values = require "game.raws.values.economical"

local TRAIT = require "game.raws.traits.generic"
local RANK = require "game.raws.ranks.character_ranks"

return function ()
	local base_gift_size = 20

	---@type DecisionCharacter
	Decision.Character:new {
		name = 'gather-warband',
		ui_name = "Gather my own party!",
		tooltip = utils.constant_string("I have decided to gather my own party."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			if root.busy then return false end
			if root.province.realm ~= root.realm then return false end
			if root.leading_warband then return false end
			if root.recruiter_for_warband then return false end
			if WORLD.player_character ~= root then
				if not root.traits[TRAIT.WARLIKE] and not root.traits[TRAIT.TRADER] and not (root.rank == RANK.CHIEF) then
					return false
				end
			end
			return true
		end,
		clickable = function(root, primary_target)
			if root.leading_warband then return false end
			return true
		end,
		available = function(root, primary_target)
			return true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			---@type Character
			root = root
			if root.leading_warband == nil and root.traits[TRAIT.WARLIKE] then
				return 1
			end

			if root.leading_warband == nil and root.traits[TRAIT.TRADER] then
				return 1
			end

			if root.leading_warband == nil and root.rank == RANK.CHIEF then
				return 1
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			military_effects.gather_warband(root)
		end
	}

	---@type DecisionCharacter
	Decision.Character:new {
		name = 'disband-warband',
		ui_name = "Disband my party",
		tooltip = utils.constant_string("I have decided to disband my party."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 0 , -- AI never disbands
		pretrigger = function(root)
			if root.busy then return false end
			if root.leading_warband then return true end
			return false
		end,
		clickable = function(root, primary_target)
			if root.leading_warband then return true end
			return false
		end,
		available = function(root, primary_target)
			return true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			return 0 -- AI never disbands
		end,
		effect = function(root, primary_target, secondary_target)
			military_effects.dissolve_warband(root)
		end
	}


		---@type DecisionCharacter
	Decision.Character:new {
		name = 'donate-wealth-warband',
		ui_name = "Donate wealth to your warband.",
		tooltip = utils.constant_string("Donate wealth (" .. tostring(base_gift_size) .. ") to your warband treasury."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 1 / 3 , -- Once every 3 months on average
		pretrigger = function(root)
			if root.busy then return false end
			if root.savings < base_gift_size then
				return false
			end
			if root.leading_warband == nil then return false end
			return true
		end,
		clickable = function(root, primary_target)
			if root.leading_warband == nil then return false end
			if WORLD:is_player(root) then return false end
			return true
		end,
		available = function(root, primary_target)
			if root.savings < 5 then
				return false
			end
			return true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if root.leading_warband.treasury < root.savings / 2 then
				return 1
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			economic_effects.gift_to_warband(root, root.savings / 3)
		end
	}
end