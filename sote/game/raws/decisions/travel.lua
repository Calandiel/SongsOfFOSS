local tabb = require "engine.table"

local pathfinding = require "game.ai.pathfinding"
local Decision = require "game.raws.decisions"

local TRAIT = require "game.raws.traits.generic"
local RANK = require "game.raws.ranks.character_ranks"


local character_values = require "game.raws.values.character"
local military_values = require "game.raws.values.military"
local economy_values = require "game.raws.values.economical"
local economy_effects = require "game.raws.effects.economic"
local economy_triggers = require "game.raws.triggers.economy"


local function load()
	---Returns travel time and path
	---@param root Character
	---@param primary_target Province
	---@return number, Province[]|nil
	local function path_property (root, primary_target)
		local warband = root.leading_warband
		if warband then
			return pathfinding.pathfind(
				root.province,
				primary_target,
				military_values.warband_speed(warband),
				root.realm.known_provinces
			)
		end
		return pathfinding.pathfind(
			root.province,
			primary_target,
			character_values.travel_speed(root),
			root.realm.known_provinces
		)
	end

	---@class TravelData
	---@field destination Province
	---@field travel_time number
	---@field goal "travel"|"migration"
	---@field path Province[]

	---@type DecisionCharacterProvince
	Decision.CharacterProvince:new {
		name = 'travel',
		ui_name = "Travel",
		tooltip = function(root, primary_target)
			if root.leading_warband == nil then
				return "You have to gather a party and supplies in order to travel."
			end
			local hours, path = path_property(root, primary_target)
			if path == nil then
				return "Impossible to reach"
			end
			local days = pathfinding.hours_to_travel_days(hours)
			if root.leading_warband:days_of_travel() < days then
				return "Not enough supplies to reach this province."
			end
			if root.leading_warband.status ~= "idle" then
				return "Your party is busy with " .. root.leading_warband.status
			end
			if root.busy then
				return "You are too busy to consider it."
			end
			return "Travel to " .. primary_target.name
		end,
		path = path_property,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 1 / 12, -- Almost every yeaer
		pretrigger = function(root)
			if root.busy then return false end
			if root.leading_warband == nil then return false end

			-- check is expensive so limit it to traders and players
			if (not root.traits[TRAIT.TRADER]) and (WORLD.player_character ~= root) then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if primary_target.realm == nil then return false end
			if primary_target == root.province then return false end

			return true
		end,
		available = function(root, primary_target)
			if root.busy then return false end
			local hours, path = path_property(root, primary_target)
			if path == nil then
				return false
			end
			local days = pathfinding.hours_to_travel_days(hours)

			if root.leading_warband:days_of_travel() < days then
				return false
			end

			return true
		end,
		ai_target = function(root)
			---@type Province[]
			local targets = {}
			for _, province in pairs(root.realm.capitol.neighbors) do
				if province.realm and economy_triggers.allowed_to_trade(root, province.realm) then
					targets[province] = province
				end
			end
			for _, overlord in pairs(root.realm.paying_tribute_to) do
				if economy_triggers.allowed_to_trade(root, overlord) then
					targets[overlord.capitol] = overlord.capitol
				end
			end
			for _, tributary in pairs(root.realm.tributaries) do
				if economy_triggers.allowed_to_trade(root, tributary) then
					targets[tributary.capitol] = tributary.capitol
				end
			end
			for _, reward in pairs(root.realm.quests_explore) do
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
			local reward = root.realm.quests_explore[primary_target] or 0

			if root.rank == RANK.CHIEF then
				return 0
			end

			if root.traits[TRAIT.TRADER] then
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
			root.busy = true

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
			if root.busy then
				return "You are too busy to consider it."
			end
			return "Travel to the capital of your realm"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 1/36, -- travel home once a few years
		pretrigger = function(root)
			if root.busy then return false end
			if root.province == root.realm.capitol then
				return false
			end
			return true
		end,
		clickable = function(root)
			return true
		end,
		available = function(root)
			if root.busy then return false end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if root.traits[TRAIT.CHIEF] and root.province ~= root.realm.capitol then
				return 1
			end
			if root.traits[TRAIT.TRADER] then
				return 1
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			local travel_time, _ = pathfinding.hours_to_travel_days(
				pathfinding.pathfind(
					root.province,
					root.realm.capitol,
					character_values.travel_speed(root),
					root.realm.known_provinces
				)
			)

			if travel_time == math.huge then
				travel_time = 150
			end
			root.busy = true

			WORLD:emit_action("travel", root, root.realm.capitol, travel_time, true)
		end
	}

	Decision.Character:new {
		name = 'explore-province',
		ui_name = "Explore local province",
		tooltip = function(root, primary_target)
			if root.busy then
				return "You are too busy to consider it."
			end
			return "Explore province"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 0.5,
		pretrigger = function(root)
			if root.busy then return false end
			for _, neighbor in pairs(root.province.neighbors) do
				if root.realm.known_provinces[neighbor] == nil then
					return true
				end
			end
			return false
		end,
		clickable = function(root, primary_target)
			return true
		end,
		available = function(root, primary_target, secondary_target)
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			local reward = root.realm.quests_explore[root.province] or 0

			if root.traits[TRAIT.TRADER] then
				return 1 / 36 + reward / 40 -- explore sometimes
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			root.busy = true

			if  WORLD.player_character ~= root then
				WORLD:emit_immediate_event("exploration-preparation", root, root.province)
			elseif OPTIONS["exploration"] == 0 then
				WORLD:emit_immediate_event("exploration-preparation", root, root.province)
			elseif OPTIONS["exploration"] == 1 then
				WORLD:emit_immediate_action("exploration-preparation-by-yourself", root, root.province)
			elseif OPTIONS["exploration"] == 2 then
				WORLD:emit_immediate_action("exploration-preparation-ask-for-help", root, root.province)
			end
		end
	}

	Decision.Character:new {
		name = 'ai-party-forage',
		ui_name = "(AI) Set party to forage stance",
		tooltip = function(root, primary_target)
			if root.leading_warband == nil then
				return "You are not leading any party"
			end
			if root.busy then
				return "You are too busy to consider it."
			end
			return "Explore province"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 0.2,
		pretrigger = function(root)

			if root.leading_warband == nil then
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
			if root.leading_warband then
				if root.leading_warband:days_of_travel() < 15 then
					return 1
				end
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			root.leading_warband.idle_stance = "forage"
		end
	}


	Decision.Character:new {
		name = 'ai-party-supplies',
		ui_name = "(AI) Buy supplies",
		tooltip = function(root, primary_target)
			if root.leading_warband == nil then
				return "You are not leading any party"
			end
			if root.busy then
				return "You are too busy to consider it."
			end
			return "Explore province"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 1,
		pretrigger = function(root)
			if root.leading_warband == nil then
				return false
			end
			if WORLD:is_player(root) then
				if OPTIONS.debug_mode then
					return true
				else
					return false
				end
			end

			if not economy_triggers.can_buy(root, 'food', 1) then
				return false
			end

			if (root.leading_warband:days_of_travel() > 30) then
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
			economy_effects.buy(root, 'food', 1)
			root.leading_warband.idle_stance = "forage"
		end
	}

	Decision.Character:new {
		name = 'ai-party-work',
		ui_name = "(AI) Set party to work stance",
		tooltip = function(root, primary_target)
			if root.leading_warband == nil then
				return "You are not leading any party"
			end
			if root.busy then
				return "You are too busy to consider it."
			end
			return "Explore province"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 0.2,
		pretrigger = function(root)
			if root.leading_warband == nil then
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
			if root.recruiter_for_warband then
				return 1
			end

			if root.leading_warband then
				if root.leading_warband:days_of_travel() > 50 then
					return 1
				end
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			root.leading_warband.idle_stance = "work"
		end
	}

end


return load
