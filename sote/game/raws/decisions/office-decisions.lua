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
		ai_will_do = function(root, primary_target, secondary_target)
			if primary_target.traits[TRAIT.TRADER] then
				return 0
			end

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
			if WORLD.player_character == primary_target then
				WORLD:emit_notification("I was asked to assist " .. root.name .. " with administrative tasks.")
			end

			WORLD:emit_immediate_event('request-help-overseer', primary_target, root)
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
				WORLD:emit_notification("I fired ".. primary_target.name .. " from the position of overseer.")
			end
			if WORLD.player_character == primary_target then
				WORLD:emit_notification("I was fired from overseer position.")
			end

            PoliticalEffects.remove_overseer(root.province.realm)
		end
	}

    Decision.Character:new {
		name = 'suggest-to-be-tribute-collector',
		ui_name = "Hire tribute collector",
		tooltip = utils.constant_string("Suggest character to help you with collection of tribute."),
		sorting = 1,
		primary_target = 'character',
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			return true
		end,
		clickable = function(root, primary_target)
            if not ot.designates_offices(root, primary_target.province)     then return false end
            if not ot.valid_tribute_collector_candidate(primary_target, root.realm)   then return false end
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
				if (c.realm == root.realm) and (not c.traits[TRAIT.TRADER]) and not (root.realm.overseer == c) then
					return c, true
				end
            end
			return nil, false
		end,
		ai_will_do = function(root, primary_target, secondary_target)
            local loyalty_multiplier = 1
            if primary_target.loyalty == root then
                loyalty_multiplier = 2
            end

			if primary_target.traits[TRAIT.TRADER] then
				return 0
			end

            if tabb.size(root.realm.tributaries) == 0 then
                return 0
            end

            if tabb.size(root.realm.tribute_collectors) == 0 and tabb.size(root.realm.tributaries) > 0 then
                return 10
            end			

            return 0.5 * loyalty_multiplier - tabb.size(root.realm.tribute_collectors) / tabb.size(root.realm.tributaries)
		end,
		effect = function(root, primary_target, secondary_target)
			if WORLD.player_character == root then
				WORLD:emit_notification("I asked ".. primary_target.name .. " to assist me in administration.")
			end
			if WORLD.player_character == primary_target then
				WORLD:emit_notification("I was asked by ".. primary_target.name .. " to assist him with tribute collection.")
			end
			WORLD:emit_immediate_event('request-help-tribute-collection', primary_target, root, 1)
		end
	}


    Decision.Character:new {
		name = 'fire-tribute-collector',
		ui_name = "Fire tribute collector.",
		tooltip = utils.constant_string("Fire character from tribute collector position."),
		sorting = 1,
		primary_target = 'character',
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			return true
		end,
		clickable = function(root, primary_target)
            local realm = root.province.realm

            if not ot.designates_offices(root, primary_target.province)     then return false end
            if realm and not realm.tribute_collectors[primary_target]       then return false end

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
				WORLD:emit_notification("I fired ".. primary_target.name .. " from the position of tribute collector.")
			end
			if WORLD.player_character == primary_target then
				WORLD:emit_notification("I was fired from the position of tribute collector.")
			end
            PoliticalEffects.remove_tribute_collector(root.province.realm, primary_target)
		end
	}
end

return load