local tabb = require "engine.table"
local utils = require "game.raws.raws-utils"
local Decision = require "game.raws.decisions"

local pop_utils = require "game.entities.pop".POP

local military_effects = require "game.raws.effects.military"
local economic_effects = require "game.raws.effects.economy"
local economic_values = require "game.raws.values.economy"


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
			if BUSY(root) then return false end
			if LOCAL_REALM(root)~= REALM(root)then return false end
			if LEADER_OF_WARBAND(root) ~= INVALID_ID then return false end
			if RECRUITER_OF_WARBAND(root) ~= INVALID_ID then return false end
			if WORLD.player_character ~= root then
				if not HAS_TRAIT(root, TRAIT.WARLIKE) and not HAS_TRAIT(root, TRAIT.TRADER) and not (RANK(root) == CHARACTER_RANK.CHIEF) then
					return false
				end
			end
			return true
		end,
		clickable = function(root, primary_target)
			if LEADER_OF_WARBAND(root) ~= INVALID_ID then return false end
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
			if LEADER_OF_WARBAND(root) == INVALID_ID and HAS_TRAIT(root, TRAIT.WARLIKE) then
				return 1
			end

			if LEADER_OF_WARBAND(root) == INVALID_ID and HAS_TRAIT(root, TRAIT.TRADER) then
				return 1
			end

			if LEADER_OF_WARBAND(root) == INVALID_ID and RANK(root) == CHARACTER_RANK.CHIEF then
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
			if BUSY(root) then return false end
			if LEADER_OF_WARBAND(root) ~= INVALID_ID then return true end
			return false
		end,
		clickable = function(root, primary_target)
			if LEADER_OF_WARBAND(root) ~= INVALID_ID then return true end
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
			if BUSY(root) then return false end
			if SAVINGS(root) < base_gift_size then
				return false
			end
			if LEADER_OF_WARBAND(root) == INVALID_ID then return false end
			return true
		end,
		clickable = function(root, primary_target)
			if LEADER_OF_WARBAND(root) == INVALID_ID then return false end
			if WORLD:is_player(root) then return false end
			return true
		end,
		available = function(root, primary_target)
			if SAVINGS(root) < 5 then
				return false
			end
			return true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if DATA.warband_get_treasury(LEADER_OF_WARBAND(root)) < SAVINGS(root) / 2 then
				return 1
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			economic_effects.gift_to_warband(LEADER_OF_WARBAND(root), root, SAVINGS(root) / 3)
		end
	}
end