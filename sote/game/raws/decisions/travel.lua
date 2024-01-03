local tabb = require "engine.table"

local pathfinding = require "game.ai.pathfinding"
local Decision = require "game.raws.decisions"

local TRAIT = require "game.raws.traits.generic"
local RANK = require "game.raws.ranks.character_ranks"


local character_values = require "game.raws.values.character"
local military_values = require "game.raws.values.military"


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
			local days = pathfinding.hours_to_travel_days(path_property(root, primary_target))
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
		base_probability = 0.9, -- Almost every month
		pretrigger = function(root)
			if root.busy then return false end
			if root.leading_warband == nil then return false end
			return true
		end,
		clickable = function(root, primary_target)
			if primary_target.realm == nil then return false end
			if primary_target == root.province then return false end

			return true
		end,
		available = function(root, primary_target)
			if root.busy then return false end
			local days = pathfinding.hours_to_travel_days(path_property(root, primary_target))
			if root.leading_warband:days_of_travel() < days then
				return false
			end

			return true
		end,
		ai_target = function(root)
			---@type Province[]
			local targets = {}
			for _, province in pairs(root.realm.capitol.neighbors) do
				if province.realm then
					targets[province] = province
				end
			end
			for _, overlord in pairs(root.realm.paying_tribute_to) do
				targets[overlord.capitol] = overlord.capitol
			end
			for _, tributary in pairs(root.realm.tributaries) do
				targets[tributary.capitol] = tributary.capitol
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
			if root.rank == RANK.CHIEF then
				return 0
			end

			if root.traits[TRAIT.TRADER] then
				return 1 / 12 -- travel once per year
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

			WORLD:emit_immediate_event("travel-start", root, data)
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
		base_probability = 0.8, -- Almost every month
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
				return 1 / 36 -- travel home once a few years
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
			if root.traits[TRAIT.TRADER] then
				return 1 / 36 -- explore sometimes
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			root.busy = true
			WORLD:emit_immediate_event("exploration-preparation", root, root.province)
		end
	}
end


return load
