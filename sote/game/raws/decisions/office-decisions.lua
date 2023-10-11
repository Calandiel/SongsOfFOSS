local tabb = require "engine.table"
local Decision = require "game.raws.decisions"
local gift_cost_per_pop = require "game.gifting".gift_cost_per_pop
local utils = require "game.raws.raws-utils"
local EconomicEffects = require "game.raws.effects.economic"
local MilitaryEffects = require "game.raws.effects.military"
local PoliticalEffects = require "game.raws.effects.political"
local TRAIT = require "game.raws.traits.generic"

local ot = require "game.raws.triggers.offices"


local function load()
    Decision.Character:new {
		name = 'suggest-to-be-overseer',
		ui_name = "Hire overseer",
		tooltip = utils.constant_string("Suggest character to help you with administration of the realm."),
		sorting = 1,
		primary_target = 'character',
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			return true
		end,
		clickable = function(root, primary_target)
            if not ot.designates_offices(root, primary_target.province) then return false end
            if not ot.valid_overseer(primary_target, root.realm)        then return false end
            return true
		end,
		available = function(root, primary_target)
            return true
		end,
		ai_target = function(root)
			local p = root.province
            if p == nil             then return nil, false end
            -- Once you target a province, try selecting a random courtier
            local s = tabb.size(p.characters)
            ---@type Character
            local c = tabb.nth(p.characters, love.math.random(s))
            if c then
                if c.loyalty == root or c.traits[TRAIT.GOOD_ORGANISER] then
                    return c, true
                end
            end
			return nil, false
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
            if root.traits[TRAIT.GOOD_ORGANISER] then
                return 0
            end
            
			if root.traits[TRAIT.BAD_ORGANISER] then
                if primary_target.traits[TRAIT.GOOD_ORGANISER] then
                    return 1
                end
                if not primary_target.traits[TRAIT.BAD_ORGANISER] then
                    return 0.8
                end
                if primary_target.loyalty == root then
                    return 0.5
                end
                return 0
            end

            if primary_target.traits[TRAIT.GOOD_ORGANISER] then
                return 0.9
            end
            if primary_target.loyalty == root then
                return 0.5
            end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			if WORLD.player_character == root then
				WORLD:emit_notification("I asked ".. primary_target.name .. " to assist me in administration.")
			end
			WORLD:emit_event('request-help-overseer', primary_target, root, 1)
		end
	}


    Decision.Character:new {
		name = 'fire-overseer',
		ui_name = "Fire overseer.",
		tooltip = utils.constant_string("Fire character from overseer position."),
		sorting = 1,
		primary_target = 'character',
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			return true
		end,
		clickable = function(root, primary_target)
            local realm = root.province.realm

            if not ot.designates_offices(root, primary_target.province) then return false end
            if realm and (realm.overseer ~= primary_target)             then return false end

            return true
		end,
		available = function(root, primary_target)
            return true
		end,
		ai_target = function(root)
			local p = root.province
            if p == nil             then return nil, false end
            -- Once you target a province, try selecting a random courtier
            local s = tabb.size(p.characters)
            ---@type Character
            local c = tabb.nth(p.characters, love.math.random(s))
            if c then
                if c.loyalty == root or c.traits[TRAIT.GOOD_ORGANISER] then
                    return c, true
                end
            end
			return nil, false
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
            return 0
		end,
		effect = function(root, primary_target, secondary_target)
			if WORLD.player_character == root then
				WORLD:emit_notification("I asked ".. primary_target.name .. " to assist me in administration.")
			end

            PoliticalEffects.remove_overseer(root.province.realm)
		end
	}
end

return load