local Decision = require "game.raws.decisions"
local tabb = require "engine.table"
local path = require "game.ai.pathfinding"

local character_values = require "game.raws.values.character"
local office_triggers = require "game.raws.triggers.offices"

return function ()
	---@type DecisionCharacter
	Decision.CharacterProvince:new {
		name = 'collect-tribute',
		ui_name = "Collect tribute",
		tooltip = function(root, primary_target)
			if root.busy then
				return "I am too busy to do it."
			end
			return "Time to visit our tributary."
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 1 / 25,
		pretrigger = function(root)
			if root.busy then return false end
			if not office_triggers.tribute_collector(root, root.realm) then return false end
			return true
		end,
		clickable = function(root, primary_target)
			if primary_target.realm == nil then
				return false
			end
			if primary_target.realm.paying_tribute_to[root.realm] == nil then
				return false
			end
			return true
		end,
		available = function(root, primary_target)
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			return primary_target.realm.budget.tribute.budget / 10
		end,
		ai_targetting_attempts = 2,
		ai_target = function(root)
			local p = root.province
			if p then
				-- Once you target a province, try selecting a random neighbor
				local s = tabb.size(p.neighbors)
				---@type Province
				local ne = tabb.nth(p.neighbors, love.math.random(s))
				if ne then
					if ne.realm and ne.realm ~= p.realm then
						return ne.realm.capitol, true
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
			local travel_time, _ = path.hours_to_travel_days(
				path.pathfind(
					root.realm.capitol,
					primary_target.realm.capitol,
					character_values.travel_speed_race(root.realm.primary_race),
					root.realm.known_provinces
				)
			)
			if travel_time == math.huge then
				travel_time = 150
			end

			root.busy = true

			---@type TributeCollection
			local associated_data = {
				origin = root.realm,
				target = primary_target.realm,
				tribute = 0,
				travel_time = travel_time,
				trade_goods_tribute = {}
			}

			WORLD:emit_action(
				'tribute-collection-1',
				root,
				associated_data,
				travel_time,
				true
			)
		end
	}


    ---@type DecisionCharacter
	Decision.Character:new {
		name = 'collect-tax',
		ui_name = "Collect tax from local province",
		tooltip = function(root, primary_target)
			if root.busy then
				return "I am too busy to do it."
			end
			return "Time to visit collect some taxes."
		end,
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 1 / 2,
		pretrigger = function(root)
			if root.busy then return false end
			if not office_triggers.tribute_collector(root, root.realm) then return false end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			return root.realm.tax_target - root.realm.tax_collected_this_year
		end,
		ai_targetting_attempts = 2,
		ai_target = function(root)
			return nil, true
		end,
		ai_secondary_target = function(root, primary_target)
			--print("ais")
			return nil, true
		end,
		effect = function(root, primary_target, secondary_target)
			root.busy = true

			WORLD:emit_event(
				'tax-collection-1',
				root,
				{},
				10
			)
		end
	}
end