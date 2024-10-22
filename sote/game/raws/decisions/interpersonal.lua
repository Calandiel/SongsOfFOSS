local tabb = require "engine.table"

local Decision = require "game.raws.decisions"
local utils = require "game.raws.raws-utils"

local ie = require "game.raws.effects.interpersonal"

local ai_values = require "game.raws.values.ai"
local demography_values = require "game.raws.values.demography"



local function load()
    Decision.Character:new {
		name = 'suggest-to-be-loyal',
		ui_name = "Request loyalty",
		tooltip = utils.constant_string("Suggest character to swear loyalty to you."),
		sorting = 1,
		primary_target = 'character',
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			if BUSY(root) then return false end
			return true
		end,
		clickable = function(root, primary_target)
			if primary_target == root then
				return false
			end
			return true
		end,
		available = function(root, primary_target)
			if primary_target == root then
				return false
			end
			if primary_target.province ~= PROVINCE(root) then
				return false
			end
			return true
		end,
		ai_target = function(root)

			local p = PROVINCE(root)
			if p == INVALID_ID then
				return nil, false
			end

			-- Once you target a province, try selecting a random courtier
			local character = demography_values.sample_character_from_province(p)

			if character == nil then
				return nil, false
			end

			if
				LOYAL_TO(character) == INVALID_ID
				and character ~= root
				and LOYAL_TO(character) ~= root
				and REALM(character) == REALM(root)
			then
				return character, true
			end

			return nil, false
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			---@type Character
			root = root
			if primary_target.traits[TRAIT.AMBITIOUS] then
				return 0
			end
			if HAS_TRAIT(root, TRAIT.CONTENT) then
				return 0
			end
			if HAS_TRAIT(root, TRAIT.AMBITIOUS) then
				return 1/12
			end
			if LEADER(LOCAL_REALM(root)) == root then
				return 1/24
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			if WORLD.player_character == root then
				WORLD:emit_notification("I requested loyalty from ".. primary_target.name)
			end
			WORLD:emit_immediate_event('request-loyalty', primary_target, root)
		end
	}

    Decision.Character:new {
		name = 'designate-successor',
		ui_name = "Designate successor",
		tooltip = utils.constant_string("Designate character as your successor."),
		sorting = 1,
		primary_target = 'character',
		secondary_target = 'none',
		base_probability = 1 / 24 , -- Once every two year on average
		pretrigger = function(root)
			if BUSY(root) then return false end
            if WORLD.player_character == root then
                return true
            end
			local race = F_RACE(root)
            return AGE(root) > race.elder_age * 0.5 + race.middle_age * 0.5
		end,
		clickable = function(root, primary_target)
			if primary_target == root then
				return false
			end
			return true
		end,
		available = function(root, primary_target)
			if primary_target == root then
				return false
			end
			return true
		end,
		ai_target = function(root)
            local successor = ai_values.best_successor(root)
            if successor then
                return successor, true
            end
            return nil, false
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			---@type Character
			root = root
			if primary_target.realm ~= REALM(root)then
				return 0
			end
			if primary_target.traits[TRAIT.LAZY] then
				return 1/48
			end
			return 1/12
		end,
		effect = function(root, primary_target, secondary_target)
			ie.set_successor(root, primary_target)
            WORLD:emit_immediate_event('succession-set', primary_target, root)
		end
	}
end

return load