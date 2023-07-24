local tabb = require "engine.table"
local Decision = require "game.raws.decisions"
local gift_cost_per_pop = require "game.gifting".gift_cost_per_pop
local utils = require "game.raws.raws-utils"
local EconomicEffects = require "game.raws.effects.economic"

local function load()

    local base_gift_size = 20
    local base_popularity_change = 0.05
	local base_raiding_reward = 50
	local base_raiding_reward_per_unit = 0.1

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
            return 0
		end,
		effect = function(root, primary_target, secondary_target)
			---@type Character
			local root = root
            local province = root.province
			if province == nil then return end

			root.savings = root.savings + base_gift_size
			if WORLD:does_player_see_realm_news(province.realm) then
				WORLD:emit_notification(root.name .. " IS CHEATER!!! But nobody cares.")
			end
		end
	}

    ---@type DecisionCharacter
	Decision.Character:new {
		name = 'donate-wealth-local-wealth',
		ui_name = "Donate wealth to locals.",
		tooltip = utils.constant_string("Donate wealth (" .. tostring(base_gift_size) .. ") to local wealth pool in exchange for popularity."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			--print("pre")
			---@type Character
			local root = root
			if root.savings >= base_gift_size then
                return true
            end
			return true
		end,
		clickable = function(root, primary_target)
			--print("cli")
			---@type Character
			local root = root

            return true
		end,
		available = function(root, primary_target)
			--print("avl")
			---@type Character
			local root = root

			if root.savings >= base_gift_size then
                return true
            end
            return false
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			---@type Character
			local root = root
            
            if root.savings > base_gift_size * 2 then
                return 0.5
            end

            return 0
		end,
		effect = function(root, primary_target, secondary_target)
			--print("eff")
			---@type Character
			local root = root
            local province = root.province
			if province == nil then return end

			province.mood = math.min(10, province.mood + 0.5 / province:population())
			province.local_wealth = province.local_wealth + base_gift_size
			root.savings = root.savings - base_gift_size
			root.popularity = root.popularity + base_popularity_change

			if WORLD:does_player_see_realm_news(province.realm) then
				WORLD:emit_notification(root.name .. " donates money to population of " .. province.name .. "! His popularity grows...")
			end
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
			--print("pre")
			---@type Character
			local root = root
			if root.savings >= base_gift_size then
                return true
            end
			return true
		end,
		clickable = function(root, primary_target)
			--print("cli")
			---@type Character
			local root = root

            return true
		end,
		available = function(root, primary_target)
			--print("avl")
			---@type Character
			local root = root

            local province = root.province
			if province == nil then return false end
			local realm = province.realm
			if realm == nil then return false end

			if root.savings >= base_gift_size then
                return true
            end
            return false
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			---@type Character
			local root = root
            
			--- rich characters want to donate money to the state more
            if root.savings > base_gift_size then
                return ((root.savings / base_gift_size) - 1) * 0.001
            end

            return 0
		end,
		effect = function(root, primary_target, secondary_target)
			--print("eff")
			---@type Character
			local root = root
            local province = root.province
			if province == nil then return end
			local realm = province.realm
			if realm == nil then return end


			province.mood = math.min(10, province.mood + 0.5 / province:population())
			EconomicEffects.add_treasury(realm, base_gift_size, "donation")
			root.savings = root.savings - base_gift_size

			if WORLD:does_player_see_realm_news(realm) then
				WORLD:emit_notification(root.name .. " donates money to the tribe of " .. realm.name .. "!")
			end
		end
	}

	-- War related events
	---@type DecisionCharacter
	Decision.Character:new {
		name = 'covert-raid',
		ui_name = "Covert raid",
		tooltip = utils.constant_string("Declare province as target for future raids. Can avoid diplomatic issues. Loots only from the local provincial wealth pool."),
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 1 / 25,
		pretrigger = function(root)
			--print("pre")
			---@type Character
			local root = root
			if root.savings < base_raiding_reward or root.province.realm:get_realm_ready_military() == 0 then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			--print("cli")
			---@type Character
			local root = root
			---@type Province
			local primary_target = primary_target
			if primary_target.realm == root then
				return false
			end
			
			return primary_target:neighbors_realm(root.province.realm)
		end,
		available = function(root, primary_target)
			--print("avl")
			---@type Character
			local root = root
			---@type Province
			local primary_target = primary_target
			if root.savings < base_raiding_reward then
				return false
			end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			--print("aiw")
			return 0.5
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
						return ne, true
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
			local root = root
			---@type Province
			local primary_target = primary_target

			local reward_flag = require "game.entities.realm".RewardFlag:new {
				owner = root,
				reward = base_raiding_reward,
				target = primary_target,
				flag_type = 'raid'
			}
			EconomicEffects.add_pop_savings(root, -base_raiding_reward, "reward flag")

			root.province.realm:add_reward_flag(reward_flag)
		end
	}
end

return load
