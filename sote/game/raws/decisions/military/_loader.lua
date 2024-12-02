local tabb = require "engine.table"
local path = require "game.ai.pathfinding"

local utils = require "game.raws.raws-utils"
local Decision = require "game.raws.decisions"
local tooltiped_triggers = require "game.raws.triggers.tooltiped_triggers"

local realm_utils = require "game.entities.realm".Realm
local province_utils = require "game.entities.province".Province

local office_triggers = require "game.raws.triggers.offices"
local diplomacy_trigggers = require "game.raws.triggers.diplomacy"
local quests_triggers = require "game.raws.triggers.quests"

local military_values = require "game.raws.values.military"
local diplomacy_values = require "game.raws.values.diplomacy"
local ai_values = require "game.raws.values.ai"

local military_effects = require "game.raws.effects.military"
local economic_effects = require "game.raws.effects.economy"




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
			local realm = REALM(root)
			assert(realm ~= INVALID_ID, "INVALID REALM")
			local province = PROVINCE(root)
			local warband_leader = DATA.get_warband_leader_from_leader(root)
			local warband = INVALID_ID
			if warband_leader == INVALID_ID then
				if office_triggers.guard_leader(root, realm) then
					local guard = DATA.get_realm_guard_from_realm(realm)
					warband = DATA.realm_guard_get_guard(guard)
				end
			else
				warband = DATA.warband_leader_get_warband(warband_leader)
			end
			assert(warband ~= INVALID_ID, "INVALID PARTY")

			realm_utils.add_patrol(realm, province, warband)
		end,
		function(root, primary_target, secondary_target)
			local realm = REALM(root)
			local local_province = PROVINCE(root)
			local local_realm = province_utils.realm(local_province)
			if office_triggers.guard_leader(root, local_realm) then
				return 1
			end
			if DATA.realm_get_prepare_attack_flag(REALM(root)) and (LOYAL_TO(root) == LEADER(REALM(root)) or LEADER(REALM(root)) == root) then
				return 0
			end
			if HAS_TRAIT(root, TRAIT.AMBITIOUS) or HAS_TRAIT(root, TRAIT.WARLIKE) or HAS_TRAIT(root, TRAIT.TRADER) then
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
			if BUSY(root) then return false end
			if SAVINGS(root) < base_raiding_reward or realm_utils.get_realm_ready_military(LOCAL_REALM(root)) == 0 then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if PROVINCE_REALM(primary_target) == LOCAL_REALM(root) then
				return false
			end
			return province_utils.neighbors_realm(primary_target, LOCAL_REALM(root))
		end,
		available = function(root, primary_target)
			if PROVINCE_REALM(primary_target) == INVALID_ID then
				return false
			end
			if diplomacy_trigggers.pays_tribute_to(PROVINCE_REALM(primary_target), LOCAL_REALM(root)) then
				return false
			end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			--print("aiw")
			return SAVINGS(root) / base_raiding_reward / 100 -- 1% chance when have enough wealth
		end,
		ai_targetting_attempts = 2,
		ai_target = function(root)
			for _, province in pairs(DATA.realm_get_known_provinces(REALM(root))) do
				if PROVINCE_REALM(province) == INVALID_ID then
					goto continue
				end

				if realm_utils.is_realm_in_hierarchy(PROVINCE_REALM(province), LOCAL_REALM(root)) then
					goto continue
				end

				if realm_utils.is_realm_in_hierarchy(LOCAL_REALM(root), PROVINCE_REALM(province)) then
					goto continue
				end

				do
					return province, true
				end

				::continue::
			end
			return nil, false
		end,
		ai_secondary_target = function(root, primary_target)
			--print("ais")
			return nil, true
		end,
		effect = function(root, primary_target, secondary_target)
			local realm = REALM(root)
			assert(realm ~= INVALID_ID, "INVALID REALM")

			if DATA.realm_get_quests_raid(realm)[primary_target] == nil then
				DATA.realm_get_quests_raid(realm)[primary_target] = 0
			end

			DATA.realm_get_quests_raid(realm)[primary_target] = DATA.realm_get_quests_raid(realm)[primary_target] + base_raiding_reward
			economic_effects.add_pop_savings(root, -base_raiding_reward, ECONOMY_REASON.QUEST)
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
			if BUSY(root) then return false end
			if SAVINGS(root) < base_raiding_reward then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			return quests_triggers.eligible_for_exploration(REALM(root), primary_target)
		end,
		available = function(root, primary_target)
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			--print("aiw")
			return SAVINGS(root) / base_raiding_reward / 100 -- 1% chance when have enough wealth
		end,
		ai_targetting_attempts = 2,
		ai_target = function(root)
			for _, province in pairs(DATA.realm_get_known_provinces(REALM(root))) do
				if quests_triggers.eligible_for_exploration(REALM(root), province) and love.math.random() < 0.1 then
					return province, true
				end
			end
			return nil, false
		end,
		ai_secondary_target = function(root, primary_target)
			--print("ais")
			return nil, true
		end,
		effect = function(root, primary_target, secondary_target)
			local realm = REALM(root)
			assert(realm ~= INVALID_ID, "INVALID REALM")

			if DATA.realm_get_quests_explore(realm)[primary_target] == nil then
				DATA.realm_get_quests_explore(realm)[primary_target] = 0
			end
			DATA.realm_get_quests_explore(realm)[primary_target] = DATA.realm_get_quests_explore(realm)[primary_target] + base_raiding_reward
			economic_effects.add_pop_savings(root, -base_raiding_reward, ECONOMY_REASON.QUEST)
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
			if BUSY(root) then return false end
			if SAVINGS(root) < base_raiding_reward then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if realm_utils.is_realm_in_hierarchy(REALM(root), PROVINCE_REALM(primary_target)) then
				return true
			end
			return false
		end,
		available = function(root, primary_target)
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			--print("aiw")
			return SAVINGS(root) / base_raiding_reward / 100 -- 1% chance when have enough wealth
		end,
		ai_targetting_attempts = 2,
		ai_target = function(root)
			local result = diplomacy_values.sample_tributary(REALM(root))
			if result ~= nil and love.math.random() < 0.2 then
				return CAPITOL(result), true
			end
			return CAPITOL(REALM(root)), true
		end,
		ai_secondary_target = function(root, primary_target)
			--print("ais")
			return nil, true
		end,
		effect = function(root, primary_target, secondary_target)
			local realm = REALM(root)
			assert(realm ~= nil, "INVALID REALM")

			if DATA.realm_get_quests_patrol(realm)[primary_target] == nil then
				DATA.realm_get_quests_patrol(realm)[primary_target] = 0
			end

			DATA.realm_get_quests_patrol(realm)[primary_target] = DATA.realm_get_quests_patrol(realm)[primary_target] + base_raiding_reward
			economic_effects.add_pop_savings(root, -base_raiding_reward, ECONOMY_REASON.QUEST)
		end
	}

	---@type DecisionCharacterProvince
	Decision.CharacterProvince:new {
		name = 'personal-raid',
		ui_name = "Raid",
		tooltip = function (root, primary_target)
			if BUSY(root) then
				return "You are too busy to consider it."
			end
			local warband = LEADER_OF_WARBAND(root)
			if warband == INVALID_ID then
				return "You are not a leader of a warband."
			end

			local fat = DATA.fatten_warband(warband)
			if fat.current_status ~= WARBAND_STATUS.IDLE then
				return "Your warband is busy."
			end

			if PROVINCE_REALM(primary_target) == INVALID_ID then
				return "Invalid province"
			end
			return "Raid the province " .. PROVINCE_NAME(primary_target)
		end,
		path = function (root, primary_target)
			return path.pathfind(
				PROVINCE(root),
				primary_target,
				military_values.warband_speed(LEADER_OF_WARBAND(root)),
				DATA.realm_get_known_provinces(REALM(root))
			)
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 1 / 6,
		pretrigger = function(root)
			if BUSY(root) then return false end
			if LEADER_OF_WARBAND(root) == INVALID_ID then return false end
			local fat = DATA.fatten_warband(LEADER_OF_WARBAND(root))
			if fat.current_status ~= WARBAND_STATUS.IDLE then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			return true
		end,
		available = function(root, primary_target)
			if PROVINCE_REALM(primary_target) == INVALID_ID then
				return false
			end
			return true
		end,
		ai_target = function(root)

			local target = ai_values.sample_raiding_target(root)

			if target ~= nil then
				return target, true
			end

			return nil, false
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if HAS_TRAIT(root, TRAIT.WARLIKE) then
				local reward = (DATA.realm_get_quests_raid(REALM(root))[primary_target] or 0) + 0.2
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
			if BUSY(root) then
				return "You are too busy to consider it."
			end
			local warband = LEADER_OF_WARBAND(root)
			if warband == INVALID_ID then
				return "You are not a leader of a warband."
			end
			if DATA.warband_get_current_status(warband) ~= WARBAND_STATUS.IDLE then
				return "Your warband is busy."
			end
			if PROVINCE_REALM(primary_target) == INVALID_ID then
				return "Invalid province"
			end
			if PROVINCE_REALM(primary_target) ~= REALM(root)then
				return'You can\'t patrol provinces of other realms'
			end
			return "Patrol the province " .. PROVINCE_NAME(primary_target)
		end,
		path = function (root, primary_target)
			return path.pathfind(
				PROVINCE(root),
				primary_target,
				military_values.warband_speed(LEADER_OF_WARBAND(root)),
				DATA.realm_get_known_provinces(REALM(root))
			)
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 0,
		pretrigger = function(root)
			if BUSY(root) then
				return false
			end
			local warband = LEADER_OF_WARBAND(root)
			if warband == INVALID_ID then
				return false
			end
			if DATA.warband_get_current_status(warband) ~= WARBAND_STATUS.IDLE then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			return true
		end,
		available = function(root, primary_target)
			if PROVINCE_REALM(primary_target) == INVALID_ID then
				return false
			end
			if PROVINCE_REALM(primary_target) ~= REALM(root)then
				return false
			end
			return true
		end,
		ai_target = function(root)
			return PROVINCE(root), true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			local reward = (DATA.realm_get_quests_patrol(REALM(root))[primary_target] or 0) + 0.2

			if HAS_TRAIT(root, TRAIT.TRADER) then
				return reward / 500
			end

			if LEADER_OF_WARBAND(root) ~= INVALID_ID then
				return reward / 200
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			realm_utils.add_patrol(REALM(root), primary_target, LEADER_OF_WARBAND(root))
		end
	}
end