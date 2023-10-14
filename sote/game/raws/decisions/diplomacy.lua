local tabb = require "engine.table"
local path = require "game.ai.pathfinding"

local Decision = require "game.raws.decisions"
local utils = require "game.raws.raws-utils"
local dt = require "game.raws.triggers.diplomacy"
local ot = require "game.raws.triggers.offices"
local pv = require "game.raws.values.political"

local TRAIT = require "game.raws.traits.generic"

local function load()
    Decision.Character:new {
		name = 'request-tribute',
		ui_name = "Request tribute",
		tooltip = function (root, primary_target)
			if root.busy then
				return "You are busy."
			end
			return "Suggest " .. primary_target.name .. " to become your tributary."
		end,
		sorting = 1,
		primary_target = 'character',
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
            if not ot.decides_foreign_policy(root, root.realm) then return false end
            if root.realm.prepare_attack_flag then return false end
			if root.busy then return false end

			return true
		end,
		clickable = function(root, primary_target)
            ---@type Character
            local primary_target = primary_target
            if not dt.valid_negotiators(root, primary_target) then return false end
            if primary_target.realm.paying_tribute_to == root.realm then return false end

			return true
		end,
		available = function(root, primary_target)
			if not dt.valid_negotiators(root, primary_target) then return false end
            if primary_target.realm.paying_tribute_to == root.realm then return false end
            
			return true
		end,
		ai_target = function(root)
			--print("ait")
			---@type Realm
			local realm = root.realm
            if realm == nil then
                return nil, false
            end

            -- select random province
			local n = tabb.size(realm.provinces)
			local p = tabb.nth(realm.provinces, love.math.random(n))

			if p then
				-- Once you target a province, try selecting a random neighbor
				local s = tabb.size(p.neighbors)
				local ne = tabb.nth(p.neighbors, love.math.random(s))

				if ne then
					if ne.realm then
						if ne.realm ~= root.realm then
							return ne.realm.leader, true
						end
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
			primary_target = primary_target
			
            local _, root_power = pv.military_strength(root)
            local _, target_power = pv.military_strength(primary_target)
            local trait_modifier = 0
            if root.traits[TRAIT.WARLIKE] then
                trait_modifier = 2.0
            end
            if root.traits[TRAIT.LAZY] then
                trait_modifier = trait_modifier * 0.25
            end
            if root.traits[TRAIT.CONTENT] then
                trait_modifier = trait_modifier * 0.25
            end
            if root.traits[TRAIT.AMBITIOUS] then
                trait_modifier = trait_modifier * 1.5
            end

            if target_power == 0 and root_power > 0 then
                return trait_modifier
            end

            return (root_power - target_power) / target_power * trait_modifier
		end,
		effect = function(root, primary_target, secondary_target)
			if WORLD.player_character == root then
				WORLD:emit_notification("I requested ".. primary_target.name .. " to become my tributary.")
            elseif WORLD:does_player_see_realm_news(root.realm) then
                WORLD:emit_notification("Our chief requested ".. primary_target.name .. " to become his tributary.")
			end

			WORLD:emit_event('request-tribute', primary_target, root, 10)
		end
	}

	

	---@type DecisionCharacter
	Decision.Character:new {
		name = 'collect-tribute',
		ui_name = "Collect tribute",
		tooltip = function (root, primary_target) 
			if root.busy then
				return "I am too busy to do it."
			end
			return "Time to visit our tributary."
		end,
		sorting = 1,
		primary_target = "character",
		secondary_target = 'none',
		base_probability = 1 / 25,
		pretrigger = function(root)
			if not ot.tribute_collector(root, root.realm) then return false end
			return true
		end,
		clickable = function(root, primary_target)
			--print("avl")
			---@type Character
			local root = root
			---@type Province
			local primary_target = primary_target

			if primary_target.realm.paying_tribute_to ~= root.realm then
				return false
			end

			return true
		end,
		available = function(root, primary_target)
			if root.busy then
				return false
			end

			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			return primary_target.realm.budget.tribute.budget / 10
		end,
		ai_targetting_attempts = 2,
		ai_target = function(root)
			--print("ait")
			---@type Character
			local root = root
			---@type Province
			local p = root.province

			if p then
				-- Once you target a province, try selecting a random neighbor
				local s = tabb.size(p.neighbors)
				---@type Province
				local ne = tabb.nth(p.neighbors, love.math.random(s))
				if ne then
					if ne.realm and ne.realm ~= p.realm then
						return ne.realm.leader, true
					end
				end
			end
			return nil, false
		end,
		ai_secondary_target = function(root, primary_target)
			--print("ais")
			return nil, true
		end,
		effect = function(root, primary_target, secondary_target)
			---@type Character
			primary_target = primary_target

			local travel_time, _ = path.hours_to_travel_days(path.pathfind(root.realm.capitol, primary_target.realm.capitol))
			if travel_time == math.huge then
				travel_time = 150
			end

			root.busy = true

			---@type TributeCollection
			local associated_data = {
				origin = root.realm,
				target = primary_target.realm,
				tribute = 0,
				travel_time = travel_time
			}

			WORLD:emit_action(
				'tribute-collection-1',
				root,
				root,
				associated_data,
				travel_time,
				true
			)
		end
	}
end

return load