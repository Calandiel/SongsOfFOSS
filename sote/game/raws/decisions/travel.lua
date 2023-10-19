local tabb = require "engine.table"

local path = require "game.ai.pathfinding"
local Decision = require "game.raws.decisions"
local TRAIT = require "game.raws.traits.generic"

local function load()
    ---@type DecisionCharacterProvince
	Decision.CharacterProvince:new {
		name = 'travel',
		ui_name = "Travel",
		tooltip = function (root, primary_target)
            if root.busy then
                return "You are too busy to consider it."
            end
            return "Travel to " .. primary_target.name
        end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 0.9 , -- Almost every month
		pretrigger = function(root)
			if root.leading_warband then return false end
			return true
		end,
		clickable = function(root, primary_target)
            if primary_target.realm == nil then return false end

			return true
		end,
		available = function(root, primary_target)
			if root.busy then return false end

			return true
		end,
        ai_target = function(root)
            local targets = {}
            for _, province in pairs(root.province.neighbors) do
                if province.realm then
                    table.insert(targets, province)
                end
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
            if root.traits[TRAIT.TRADER] then
                return 1 / 12                   -- travel once per year
            end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
            local travel_time, _ = path.hours_to_travel_days(path.pathfind(root.realm.capitol, primary_target.realm.capitol))
			if travel_time == math.huge then
				travel_time = 150
			end

            WORLD:emit_action("travel", root, primary_target, travel_time, true)
		end
	}
end


return load