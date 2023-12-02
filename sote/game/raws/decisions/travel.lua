local tabb = require "engine.table"

local path = require "game.ai.pathfinding"
local Decision = require "game.raws.decisions"

local TRAIT = require "game.raws.traits.generic"
local RANK = require "game.raws.ranks.character_ranks"


local character_values = require "game.raws.values.character"


local function load()
	---@type DecisionCharacterProvince
	Decision.CharacterProvince:new {
		name = 'travel',
		ui_name = "Travel",
		tooltip = function(root, primary_target)
			if root.busy then
				return "You are too busy to consider it."
			end
			return "Travel to " .. primary_target.name
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 0.9, -- Almost every month
		pretrigger = function(root)
			if root.busy then return false end
			if root.leading_warband then return false end
			return true
		end,
		clickable = function(root, primary_target)
			if primary_target.realm == nil then return false end
			if primary_target == root.province then return false end

			return true
		end,
		available = function(root, primary_target)
			if root.busy then return false end

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
			local travel_time, _ = path.hours_to_travel_days(path.pathfind(root.province, primary_target))
			if travel_time == math.huge then
				travel_time = 150
			end
			root.busy = true

			WORLD:emit_action("travel", root, primary_target, travel_time, true)
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
			local travel_time, _ = path.hours_to_travel_days(
				path.pathfind(
					root.province,
					root.realm.capitol,
					character_values.travel_speed(root)
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
		base_probability = 0.8, -- Almost every month
		pretrigger = function(root)
			if root.busy then return false end
			return true
		end,
		clickable = function(root)
			return true
		end,
		available = function(root)
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
			-- TODO: action for now, replace with proper event chain later
			WORLD:emit_immediate_action("explore", root, root)
		end
	}
end


return load
