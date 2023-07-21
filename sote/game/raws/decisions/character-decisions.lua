local tabb = require "engine.table"
local Decision = require "game.raws.decisions"
local gift_cost_per_pop = require "game.gifting".gift_cost_per_pop
local tg = require "game.raws.raws-utils".trade_good
local ev = require "game.raws.raws-utils".event
local utils = require "game.raws.raws-utils"
local path = require "game.ai.pathfinding"

local function load()

    local base_gift_size = 50
    local base_popularity_change = 0.05

	Decision:new {
		name = 'donate-money-local-wealth',
		ui_name = "Donate money to capital wealth pool in exchange for popularity.",
		tooltip = utils.constant_string("<tooltip>"),
		sorting = 1,
		primary_target = "character",
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			--print("pre")
			---@type Realm
			local root = root

			return true
		end,
		clickable = function(root, primary_target)
			--print("cli")
			---@type Realm
			local root = root
			---@type Character
			local primary_target = primary_target

            return true
		end,
		available = function(root, primary_target)
			--print("avl")
			---@type Realm
			local root = root
			---@type Character
			local primary_target = primary_target

			if primary_target.savings > base_gift_size then
                return true
            end
            return false
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			---@type Realm
			local root = root
            
            if primary_target.savings > base_gift_size * 2 then
                return 0.5
            end

            return 0
		end,
		effect = function(root, primary_target, secondary_target)
			--print("eff")
			---@type Realm
			local root = root
			---@type Character
			local primary_target = primary_target

            local province = root.capitol

			province.mood = math.min(10, province + 0.5 / province:population())
            province.local_wealth = province.local_wealth + base_gift_size
            primary_target.savings = primary_target.savings - base_gift_size
            primary_target.popularity = primary_target.popularity + base_popularity_change
            
			if WORLD:does_player_see_realm_news(root) then
				WORLD:emit_notification(primary_target.name .. " donates money to capital population! His popularity grows...")
			end
		end
	}
end

return load
