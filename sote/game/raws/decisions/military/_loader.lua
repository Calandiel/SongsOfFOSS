local tabb = require "engine.table"
local path = require "game.ai.pathfinding"

local utils = require "game.raws.raws-utils"
local Decision = require "game.raws.decisions"
local tooltiped_triggers = require "game.raws.triggers.tooltiped_triggers"

local military_effects = require "game.raws.effects.military"
local military_values = require "game.raws.values.military"
local economic_effects = require "game.raws.effects.economic"

local office_triggers = require "game.raws.triggers.offices"


local NOT_BUSY = tooltiped_triggers.Pretrigger.not_busy
local OR = tooltiped_triggers.Pretrigger.OR
local LEADING_WARBAND_IDLE = tooltiped_triggers.Pretrigger.leading_idle_warband
local LEADINING_GUARD_IDLE = tooltiped_triggers.Pretrigger.leading_idle_guard

return function ()
	local base_raiding_reward = 20

	Decision.Character:new_from_trigger_lists(
		"patrol-warband",
		"Patrol local area",
		utils.constant_string("I will protect local territory against raiders."),
		0.5,
		{
			NOT_BUSY,
			OR {
				LEADING_WARBAND_IDLE,
				LEADINING_GUARD_IDLE
			}
		},
		{},
		{},
		function(root, primary_target, secondary_target)
			local realm = root.province.realm
			assert(realm ~= nil, "INVALID REALM")
			local province = root.province
			local warband = root.leading_warband
			if office_triggers.guard_leader(root, root.province.realm) then
				warband = realm.capitol_guard
			end
			assert(warband ~= nil, "INVALID PARTY")
			realm:add_patrol(province, warband)
		end,
		function(root, primary_target, secondary_target)
			if office_triggers.guard_leader(root, root.province.realm) then
				return 1
			end
			if root.realm.prepare_attack_flag == true and (root.loyalty == root.realm.leader or root.realm.leader == root) then
				return 0
			end
			if root.traits[TRAIT.AMBITIOUS] or root.traits[TRAIT.WARLIKE] or root.traits[TRAIT.TRADER] then
				return 0.0
			end
			return 0.6
		end
	)

	---@type DecisionCharacterProvince
	Decision.CharacterProvince:new {
		name = 'invest-quest-raid',
		ui_name = "Provide raiding quest reward " .. tostring(base_raiding_reward),
		tooltip = utils.constant_string("Declare province as target for future raids. Can avoid diplomatic issues. Loots only from the local provincial wealth pool."),
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 1 / 12 / 4,
		path = nil,
		pretrigger = function(root)
			if root.busy then return false end
			if root.savings < base_raiding_reward or root.province.realm:get_realm_ready_military() == 0 then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if primary_target.realm == root then
				return false
			end
			return primary_target:neighbors_realm(root.province.realm)
		end,
		available = function(root, primary_target)
			if primary_target.realm == nil then
				return false
			end
			if primary_target.realm.paying_tribute_to[root.realm] then
				return false
			end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			--print("aiw")
			return root.savings / base_raiding_reward / 100 -- 1% chance when have enough wealth
		end,
		ai_targetting_attempts = 2,
		ai_target = function(root)
			for _, province in pairs(root.realm.known_provinces) do
				if province.realm then
					if not province.realm:is_realm_in_hierarchy(root.realm) and not root.realm:is_realm_in_hierarchy(province.realm) then
						for __, neighbor in pairs(province.neighbors) do
							if neighbor.realm and neighbor.realm:is_realm_in_hierarchy(root.realm) then
								return province, true
							end
						end
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
			local realm = root.realm
			assert(realm ~= nil, "INVALID REALM")

			if realm.quests_raid[primary_target] == nil then
				realm.quests_raid[primary_target] = 0
			end

			realm.quests_raid[primary_target] = realm.quests_raid[primary_target] + base_raiding_reward
			economic_effects.add_pop_savings(root, -base_raiding_reward, economic_effects.reasons.Quest)
		end
	}

	---@type DecisionCharacterProvince
	Decision.CharacterProvince:new {
		name = 'invest-quest-explore',
		ui_name = "Provide exploration quest reward " .. tostring(base_raiding_reward),
		tooltip = utils.constant_string("Declare province as exploration target"),
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 1 / 12 / 4,
		path = nil,
		pretrigger = function(root)
			if root.busy then return false end
			if root.savings < base_raiding_reward then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if primary_target.realm == nil then
				return false
			end
			for _, neighbor in pairs(primary_target.neighbors) do
				if root.realm.known_provinces[neighbor] == nil then
					return true
				end
			end
			return false
		end,
		available = function(root, primary_target)
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			--print("aiw")
			return root.savings / base_raiding_reward / 100 -- 1% chance when have enough wealth
		end,
		ai_targetting_attempts = 2,
		ai_target = function(root)
			for _, province in pairs(root.realm.known_provinces) do
				for __, neighbor in pairs(province.neighbors) do
					if root.realm.known_provinces[neighbor] == nil and love.math.random() < 0.1 then
						return province, true
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
			local realm = root.realm
			assert(realm ~= nil, "INVALID REALM")
			if realm.quests_explore[primary_target] == nil then
				realm.quests_explore[primary_target] = 0
			end
			realm.quests_explore[primary_target] = realm.quests_explore[primary_target] + base_raiding_reward
			economic_effects.add_pop_savings(root, -base_raiding_reward, economic_effects.reasons.Quest)
		end
	}

	---@type DecisionCharacterProvince
	Decision.CharacterProvince:new {
		name = 'invest-quest-patrol',
		ui_name = "Provide patrol quest reward " .. tostring(base_raiding_reward),
		tooltip = utils.constant_string("Declare province as patrol target"),
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 1 / 12 / 4,
		path = nil,
		pretrigger = function(root)
			if root.busy then return false end
			if root.savings < base_raiding_reward then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if root.realm:is_realm_in_hierarchy(primary_target.realm) then
				return true
			end
			return false
		end,
		available = function(root, primary_target)
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			--print("aiw")
			return root.savings / base_raiding_reward / 100 -- 1% chance when have enough wealth
		end,
		ai_targetting_attempts = 2,
		ai_target = function(root)
			for _, realm in pairs(root.realm.tributaries) do
				if love.math.random() < 0.1 then
					return realm.capitol, true
				end
			end
			return root.realm.capitol, true
		end,
		ai_secondary_target = function(root, primary_target)
			--print("ais")
			return nil, true
		end,
		effect = function(root, primary_target, secondary_target)
			local realm = root.realm
			assert(realm ~= nil, "INVALID REALM")

			if realm.quests_patrol[primary_target] == nil then
				realm.quests_patrol[primary_target] = 0
			end

			realm.quests_patrol[primary_target] = realm.quests_patrol[primary_target] + base_raiding_reward
			economic_effects.add_pop_savings(root, -base_raiding_reward, economic_effects.reasons.Quest)
		end
	}

	---@type DecisionCharacterProvince
	Decision.CharacterProvince:new {
		name = 'personal-raid',
		ui_name = "Raid",
		tooltip = function (root, primary_target)
			if root.busy then
				return "You are too busy to consider it."
			end
			local warband = root.leading_warband
			if warband == nil then
				return "You are not a leader of a warband."
			end
			if warband and warband.status ~= 'idle' then
				return "Your warband is busy."
			end
			if primary_target.realm == nil then
				return "Invalid province"
			end
			return "Raid the province " .. primary_target.name
		end,
		path = function (root, primary_target)
			return path.pathfind(
				root.province,
				primary_target,
				military_values.warband_speed(root.leading_warband),
				root.realm.known_provinces
			)
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 1 / 6,
		pretrigger = function(root)
			if root.busy then return false end
			if root.leading_warband == nil then return false end
			if root.leading_warband.status ~= 'idle' then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			return true
		end,
		available = function(root, primary_target)
			if primary_target.realm == nil then
				return false
			end
			return true
		end,
		ai_target = function(root)
			---@type Province[]
			local targets = {}
			for _, province in pairs(root.realm.known_provinces) do
				if province.realm and root.realm.tributaries[province.realm] == nil and province.realm:neighbors_realm(root.realm) then
					table.insert(targets, province)
				end
			end

			for province, reward in pairs(root.realm.quests_raid) do
				table.insert(targets, province)
			end

			local index, prov =  tabb.random_select_from_set(targets)
			if prov then
				return prov, true
			end

			return nil, false
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if root.realm.tributaries[primary_target] then
				return 0
			end

			if root.traits[TRAIT.WARLIKE] then
				local reward = (root.realm.quests_raid[primary_target] or 0) + 0.2
				return 0.7 + reward / 100
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			military_effects.covert_raid(root, primary_target)
		end
	}

	---@type DecisionCharacterProvince
	Decision.CharacterProvince:new {
		name = 'patrol-target',
		ui_name = "Patrol targeted province",
		tooltip = function (root, primary_target)
			if root.busy then
				return "You are too busy to consider it."
			end
			local warband = root.leading_warband
			if warband == nil then
				return "You are not a leader of a warband."
			end
			if warband and warband.status ~= 'idle' then
				return "Your warband is busy."
			end
			if primary_target.realm == nil then
				return "Invalid province"
			end
			if primary_target.realm ~= root.realm then
				return'You can\'t patrol provinces of other realms'
			end
			return "Patrol the province " .. primary_target.name
		end,
		path = function (root, primary_target)
			return path.pathfind(
				root.province,
				primary_target,
				military_values.warband_speed(root.leading_warband),
				root.realm.known_provinces
			)
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 0,
		pretrigger = function(root)
			if root.busy then
				return false
			end
			local warband = root.leading_warband
			if warband == nil then
				return false
			end
			if warband and warband.status ~= 'idle' then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			return true
		end,
		available = function(root, primary_target)
			if primary_target.realm == nil then
				return false
			end
			if primary_target.realm ~= root.realm then
				return false
			end
			return true
		end,
		ai_target = function(root)
			return root.province, true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			local reward = (root.realm.quests_patrol[primary_target] or 0) + 0.2

			if root.traits[TRAIT.TRADER] then
				return reward / 500
			end

			if root.leading_warband then
				return reward / 200
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			root.realm:add_patrol(primary_target, root.leading_warband)
		end
	}
end