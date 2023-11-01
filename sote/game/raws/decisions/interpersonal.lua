local tabb = require "engine.table"

local Decision = require "game.raws.decisions"
local TRAIT = require "game.raws.traits.generic"
local utils = require "game.raws.raws-utils"

local ie = require "game.raws.effects.interpersonal"

local av = require "game.raws.values.ai_preferences"



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
			if primary_target.province ~= root.province then
				return false
			end
			return true
		end,
		ai_target = function(root)
			--print("ait")
			---@type Character
			local root = root
			---@type Province
			local p = root.province
			if p then
				-- Once you target a province, try selecting a random courtier
				local s = tabb.size(p.characters)
				---@type Character
				local c = tabb.nth(p.characters, love.math.random(s))
				if c then
					if c.loyalty == nil and c ~= root and c.loyalty ~= root and c.realm == root.realm then
						return c, true
					end
				end
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
			if root.traits[TRAIT.CONTENT] then
				return 0
			end
			if root.traits[TRAIT.AMBITIOUS] then
				return 1/12
			end
			if root.province.realm.leader == root then
				return 1/24
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			if WORLD.player_character == root then
				WORLD:emit_notification("I requested loyalty from ".. primary_target.name)
			end
			WORLD:emit_event('request-loyalty', primary_target, root, 1)
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
            if WORLD.player_character == root then
                return true
            end
            return root.age > root.race.elder_age * 0.5 + root.race.middle_age * 0.5
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
            local successor = av.best_successor(root)
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
			if primary_target.realm ~= root.realm then
				return 0
			end
			if primary_target.traits[TRAIT.LAZY] then
				return 1/48
			end
			return 1/12
		end,
		effect = function(root, primary_target, secondary_target)
			ie.set_successor(root, primary_target)
            WORLD:emit_event('succession-set', primary_target, root, nil)
		end
	}
end

return load