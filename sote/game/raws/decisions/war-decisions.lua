local tabb = require "engine.table"
local Decision = require "game.raws.decisions"
local gift_cost_per_pop = require "game.gifting".gift_cost_per_pop
local tg = require "game.raws.raws-utils".trade_good
local ev = require "game.raws.raws-utils".event
local utils = require "game.raws.raws-utils"
local path = require "game.ai.pathfinding"

local function load()

	-- Decision.Realm:new {
	-- 	name = 'declare-war',
	-- 	ui_name = "Send envoys to declare war",
	-- 	tooltip = utils.constant_string("<tooltip>"),
	-- 	sorting = 1,
	-- 	primary_target = "realm",
	-- 	secondary_target = 'none',
	-- 	base_probability = 1 / 12 / 5, -- Once every five years on average
	-- 	pretrigger = function(root)
	-- 		--print("pre")
	-- 		---@type Realm
	-- 		local root = root
	-- 		return root:get_realm_ready_military() > 0
	-- 	end,
	-- 	clickable = function(root, primary_target)
	-- 		--print("cli")
	-- 		---@type Realm
	-- 		local root = root
	-- 		---@type Realm
	-- 		local primary_target = primary_target
	-- 		if primary_target == root then
	-- 			return false
	-- 		end
	-- 		if root:at_war_with(primary_target) then
	-- 			return false
	-- 		end
	-- 		return primary_target:neighbors_realm(root)
	-- 	end,
	-- 	available = function(root, primary_target)
	-- 		--print("avl")
	-- 		---@type Realm
	-- 		local root = root
	-- 		---@type Realm
	-- 		local primary_target = primary_target
	-- 		return root ~= primary_target
	-- 	end,
	-- 	ai_targetting_attempts = 2,
	-- 	ai_target = function(root)
	-- 		--print("ait")
	-- 		---@type Realm
	-- 		local root = root
	-- 		local n = tabb.size(root.provinces)
	-- 		---@type Province
	-- 		local p = tabb.nth(root.provinces, love.math.random(n))
	-- 		if p then
	-- 			-- Once you target a province, try selecting a random neighbor
	-- 			local s = tabb.size(p.neighbors)
	-- 			---@type Province
	-- 			local ne = tabb.nth(p.neighbors, love.math.random(s))
	-- 			if ne then
	-- 				if ne.realm then
	-- 					if ne.realm ~= root then
	-- 						return ne.realm, true
	-- 					end
	-- 				end
	-- 			end
	-- 		end
	-- 		return nil, false
	-- 	end,
	-- 	ai_secondary_target = function(root, primary_target)
	-- 		return nil, true
	-- 	end,
	-- 	ai_will_do = function(root, primary_target, secondary_target)
	-- 		---@type Realm
	-- 		local root = root
	-- 		-- Don't declare wars if people are unhappy
	-- 		if root:get_average_mood() <= 0 then
	-- 			return 0
	-- 		end
	-- 		-- Don't declare wars if you're already in one
	-- 		if tabb.size(root.wars) > 0 then
	-- 			return 0
	-- 		end
	-- 		--return 1
	-- 		-- DISABLE WARS FOR NOW
	-- 		return 0
	-- 	end,
	-- 	effect = function(root, primary_target, secondary_target)
	-- 		--print("eff")
	-- 		---@type Realm
	-- 		local root = root
	-- 		---@type Realm
	-- 		local primary_target = primary_target

	-- 		local travel_time, _ = path.hours_to_travel_days(path.pathfind(root.capitol, primary_target.capitol))
	-- 		if travel_time == math.huge then
	-- 			travel_time = 150
	-- 		end

	-- 		local war = require "game.entities.war":new()
	-- 		war.attackers[root] = root
	-- 		war.defenders[primary_target] = primary_target
	-- 		root.wars[war] = war
	-- 		primary_target.wars[war] = war

	-- 		if not WORLD:does_player_control_realm(primary_target) then
	-- 			WORLD:emit_action('war-declaration', root, {
	-- 				aggresor = root
	-- 			}, travel_time, false)
	-- 		end
	-- 	end
	-- }
end

return load
