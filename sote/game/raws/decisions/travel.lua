local tabb = require "engine.table"

local pathfinding = require "game.ai.pathfinding"
local Decision = require "game.raws.decisions"

local warband_utils = require "game.entities.warband"
local pop_utils = require "game.entities.pop".POP

local character_values = require "game.raws.values.character"
local military_values = require "game.raws.values.military"
local economy_values = require "game.raws.values.economy"

local economy_effects = require "game.raws.effects.economy"
local economy_triggers = require "game.raws.triggers.economy"


local function load()
	---Returns travel time and path
	---@param root Character
	---@param primary_target Province
	---@return number, Province[]|nil
	local function path_property(root, primary_target)
		local warband = LEADER_OF_WARBAND(root)
		if warband then
			return pathfinding.pathfind(
				PROVINCE(root),
				primary_target,
				military_values.warband_speed(warband),
				DATA.realm_get_known_provinces(REALM(root))
			)
		end
		return pathfinding.pathfind(
			PROVINCE(root),
			primary_target,
			character_values.travel_speed(root),
			DATA.realm_get_known_provinces(REALM(root))
		)
	end

	---@class (exact) TravelData
	---@field destination Province
	---@field travel_time number
	---@field goal "travel"|"migration"
	---@field path Province[]

	---@type DecisionCharacterProvince
	Decision.CharacterProvince:new {
		name = 'travel',
		ui_name = "Travel",
		tooltip = function(root, primary_target)
			local warband = LEADER_OF_WARBAND(root)
			local status = DATA.warband_get_status(warband)

			if warband == INVALID_ID then
				return "You have to gather a party and supplies in order to travel."
			end
			local hours, path = path_property(root, primary_target)
			if path == nil then
				return "Impossible to reach"
			end
			local days = pathfinding.hours_to_travel_days(hours)
			if warband_utils.days_of_travel(warband) < days then
				return "Not enough supplies to reach this province."
			end
			if status ~= WARBAND_STATUS.IDLE then
				return "Your party is busy with " .. DATA.warband_status_get_name(status)
			end
			if BUSY(root) then
				return "You are too busy to consider it."
			end
			return "Travel to " .. PROVINCE_NAME(primary_target)
		end,
		path = path_property,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 1 / 12, -- Almost every yeaer
		pretrigger = function(root)
			if BUSY(root) then return false end
			if LEADER_OF_WARBAND(root) == INVALID_ID then return false end

			-- check is expensive so limit it to traders and players
			if (not HAS_TRAIT(root, TRAIT.TRADER)) and (WORLD.player_character ~= root) then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if PROVINCE_REALM(primary_target) == nil then return false end
			if primary_target == PROVINCE(root) then return false end

			return true
		end,
		available = function(root, primary_target)
			if BUSY(root) then return false end
			local hours, path = path_property(root, primary_target)
			if path == nil then
				return false
			end
			local days = pathfinding.hours_to_travel_days(hours)

			if warband_utils.days_of_travel(LEADER_OF_WARBAND(root)) < days then
				return false
			end

			return true
		end,
		ai_target = function(root)
			---@type Province[]
			local targets = {}

			DATA.for_each_province_neighborhood_from_origin(CAPITOL(REALM(root)), function (item)
				local province = DATA.province_neighborhood_get_target(item)
				local realm = PROVINCE_REALM(province)
				if realm ~= INVALID_ID and economy_triggers.allowed_to_trade(root, realm) then
					targets[province] = province
				end
			end)


			DATA.for_each_realm_subject_relation_from_subject(REALM(root), function (item)
				local overlord = DATA.realm_subject_relation_get_overlord(item)
				if economy_triggers.allowed_to_trade(root, overlord) then
					targets[CAPITOL(overlord)] = CAPITOL(overlord)
				end
			end)

			DATA.for_each_realm_subject_relation_from_overlord(REALM(root), function (item)
				local subject = DATA.realm_subject_relation_get_subject(item)
				if economy_triggers.allowed_to_trade(root, subject) then
					targets[CAPITOL(subject)] = CAPITOL(subject)
				end
			end)

			for _, reward in pairs(DATA.realm_get_quests_explore(REALM(root))) do
				targets[_] = _
			end

			-- TODO: ADD TRADE AGREEMENTS AND ADD CAPITOLS OF REALMS WITH TRADE AGREEMENTS SIGNED AS POTENTIAL TARGETS HERE

			local _, prov = tabb.random_select_from_set(targets)
			if prov then
				return prov, true
			end

			return nil, false
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			local reward = DATA.realm_get_quests_explore(REALM(root))[primary_target] or 0

			if RANK(root) == CHARACTER_RANK.CHIEF then
				return 0
			end

			if HAS_TRAIT(root, TRAIT.TRADER) then
				return 1
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			local hours, path = path_property(root, primary_target)

			if path == nil then
				return
			end

			local days = pathfinding.hours_to_travel_days(hours)

			if days > 150 then
				days = 150
			end
			SET_BUSY(root)

			---@type TravelData
			local data = {
				destination = primary_target,
				goal = "travel",
				path = path,
				travel_time = days
			}

			if OPTIONS["travel-start"] == 0 and WORLD.player_character == root then
				WORLD:emit_immediate_event("travel-start", root, data)
			else
				WORLD:emit_immediate_action("travel-start-action", root, data)
			end
		end
	}

	Decision.Character:new {
		name = 'travel-capital',
		ui_name = "Travel to capital province",
		tooltip = function(root, primary_target)
			if BUSY(root) then
				return "You are too busy to consider it."
			end
			return "Travel to the capital of your realm"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 1 / 36, -- travel home once a few years
		pretrigger = function(root)
			if BUSY(root) then return false end
			if PROVINCE(root) == CAPITOL(REALM(root)) then
				return false
			end
			return true
		end,
		clickable = function(root)
			return true
		end,
		available = function(root)
			if BUSY(root) then return false end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if RANK(root) == CHARACTER_RANK.CHIEF and PROVINCE(root) ~= CAPITOL(REALM(root)) then
				return 1
			end
			if HAS_TRAIT(root, TRAIT.TRADER) then
				return 1
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			local travel_time, _ = pathfinding.hours_to_travel_days(
				pathfinding.pathfind(
					PROVINCE(root),
					CAPITOL(REALM(root)),
					character_values.travel_speed(root),
					DATA.realm_get_known_provinces(REALM(root))
				)
			)

			if travel_time == math.huge then
				travel_time = 150
			end
			SET_BUSY(root)

			WORLD:emit_action("travel", root, CAPITOL(REALM(root)), travel_time, true)
		end
	}

	Decision.Character:new {
		name = 'explore-province',
		ui_name = "Explore local province",
		tooltip = function(root, primary_target)
			if BUSY(root) then
				return "You are too busy to consider it."
			end
			return "Explore province"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 0.5,
		pretrigger = function(root)
			if BUSY(root) then return false end

			local potential_to_explore = false

			DATA.for_each_province_neighborhood_from_origin(PROVINCE(root), function (item)
				local neighbor = DATA.province_neighborhood_get_target(item)
				if DATA.realm_get_known_provinces(REALM(root))[neighbor] == nil then
					potential_to_explore = true
				end
			end)

			return potential_to_explore
		end,
		clickable = function(root, primary_target)
			return true
		end,
		available = function(root, primary_target, secondary_target)
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			local reward = DATA.realm_get_quests_explore(REALM(root))[PROVINCE(root)] or 0

			if HAS_TRAIT(root, TRAIT.TRADER) then
				return 1 / 36 + reward / 40 -- explore sometimes
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			SET_BUSY(root)

			if WORLD.player_character ~= root then
				WORLD:emit_immediate_event("exploration-preparation", root, PROVINCE(root))
			elseif OPTIONS["exploration"] == 0 then
				WORLD:emit_immediate_event("exploration-preparation", root, PROVINCE(root))
			elseif OPTIONS["exploration"] == 1 then
				WORLD:emit_immediate_action("exploration-preparation-by-yourself", root, PROVINCE(root))
			elseif OPTIONS["exploration"] == 2 then
				WORLD:emit_immediate_action("exploration-preparation-ask-for-help", root, PROVINCE(root))
			end
		end
	}

	Decision.Character:new {
		name = 'ai-party-forage',
		ui_name = "(AI) Set party to forage stance",
		tooltip = function(root, primary_target)
			if LEADER_OF_WARBAND(root) == INVALID_ID then
				return "You are not leading any party"
			end
			if BUSY(root) then
				return "You are too busy to consider it."
			end
			return "Explore province"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 0.2,
		pretrigger = function(root)
			if LEADER_OF_WARBAND(root) == INVALID_ID then
				return false
			end

			if WORLD:is_player(root) then
				if OPTIONS.debug_mode then
					return true
				else
					return false
				end
			end

			return true
		end,
		clickable = function(root, primary_target)
			if WORLD:is_player(root) then
				if OPTIONS.debug_mode then
					return true
				else
					return false
				end
			end
			return true
		end,
		available = function(root, primary_target, secondary_target)
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if LEADER_OF_WARBAND(root) ~= INVALID_ID then
				if warband_utils.days_of_travel(LEADER_OF_WARBAND(root)) < 15 then
					return 1
				end
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			DATA.warband_set_idle_stance(LEADER_OF_WARBAND(root), WARBAND_STANCE.FORAGE)
		end
	}


	Decision.Character:new {
		name = 'ai-party-supplies',
		ui_name = "(AI) Buy supplies",
		tooltip = function(root, primary_target)
			if LEADER_OF_WARBAND(root) == INVALID_ID then
				return "You are not leading any party"
			end
			if BUSY(root) then
				return "You are too busy to consider it."
			end
			return "Explore province"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 1,
		pretrigger = function(root)
			if LEADER_OF_WARBAND(root) == INVALID_ID then
				return false
			end
			if WORLD:is_player(root) then
				if OPTIONS.debug_mode then
					return true
				else
					return false
				end
			end

			if not economy_triggers.can_buy_use(PROVINCE(root), SAVINGS(root), CALORIES_USE_CASE, 1) then
				return false
			end

			if (warband_utils.days_of_travel(LEADER_OF_WARBAND(root)) > 30) then
				return false
			end

			return true
		end,
		clickable = function(root, primary_target)
			if WORLD:is_player(root) then
				if OPTIONS.debug_mode then
					return true
				else
					return false
				end
			end
			return true
		end,
		available = function(root, primary_target, secondary_target)
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			return 1
		end,
		effect = function(root, primary_target, secondary_target)
			economy_effects.character_buy_use(root, CALORIES_USE_CASE, 1)
			DATA.warband_set_idle_stance(LEADER_OF_WARBAND(root), WARBAND_STANCE.FORAGE)
		end
	}

	Decision.Character:new {
		name = 'ai-party-work',
		ui_name = "(AI) Set party to work stance",
		tooltip = function(root, primary_target)
			if LEADER_OF_WARBAND(root) == INVALID_ID then
				return "You are not leading any party"
			end
			if BUSY(root) then
				return "You are too busy to consider it."
			end
			return "Explore province"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 0.2,
		pretrigger = function(root)
			if LEADER_OF_WARBAND(root) == INVALID_ID then
				return false
			end

			if WORLD:is_player(root) then
				if OPTIONS.debug_mode then
					return true
				else
					return false
				end
			end

			return true
		end,
		clickable = function(root, primary_target)
			if WORLD:is_player(root) then
				if OPTIONS.debug_mode then
					return true
				else
					return false
				end
			end
			return true
		end,
		available = function(root, primary_target, secondary_target)
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if RECRUITER_OF_WARBAND(root) ~= INVALID_ID then
				return 1
			end

			if LEADER_OF_WARBAND(root) ~= INVALID_ID then
				if warband_utils.days_of_travel(LEADER_OF_WARBAND(root)) > 50 then
					return 1
				end
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			DATA.warband_set_idle_stance(LEADER_OF_WARBAND(root), WARBAND_STANCE.WORK)
		end
	}
end


return load
