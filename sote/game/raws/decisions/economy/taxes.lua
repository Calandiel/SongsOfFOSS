local Decision = require "game.raws.decisions"
local tabb = require "engine.table"
local path = require "game.ai.pathfinding"

local character_values = require "game.raws.values.character"
local diplomacy_values = require "game.raws.values.diplomacy"

local office_triggers = require "game.raws.triggers.offices"

return function ()
	---@type DecisionCharacter
	Decision.CharacterProvince:new {
		name = 'collect-tribute',
		ui_name = "Collect tribute",
		tooltip = function(root, primary_target)
			if DATA.pop_get_busy(root) then
				return "I am too busy to do it."
			end
			return "Time to visit our tributary."
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 1 / 25,
		pretrigger = function(root)
			if DATA.pop_get_busy(root) then return false end
			if not office_triggers.tribute_collector(root, REALM(root)) then return false end
			return true
		end,
		clickable = function(root, primary_target)
			return diplomacy_values.province_pays_taxes(REALM(root), primary_target)
		end,
		available = function(root, primary_target)
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			return DATA.realm_get_budget_budget(PROVINCE_REALM(primary_target), BUDGET_CATEGORY.TRIBUTE) / 20
		end,
		ai_targetting_attempts = 2,
		ai_target = function(root)
			local target = diplomacy_values.sample_tributary(REALM(root))

			if target == nil then
				return nil, false
			end

			return CAPITOL(target), true
		end,
		ai_secondary_target = function(root, primary_target)
			--print("ais")
			return nil, true
		end,
		effect = function(root, primary_target, secondary_target)
			local travel_time, _ = path.hours_to_travel_days(
				path.pathfind(
					CAPITOL(REALM(root)),
					primary_target,
					character_values.travel_speed_race(RACE(root)),
					DATA.realm_get_known_provinces(REALM(root))
				)
			)
			if travel_time == math.huge then
				travel_time = 150
			end

			DATA.pop_set_busy(root, true)

			---@type TributeCollection
			local associated_data = {
				origin = REALM(root),
				target = PROVINCE_REALM(primary_target),
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
			if BUSY(root) then
				return "I am too busy to do it."
			end
			return "Time to visit collect some taxes."
		end,
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 1 / 2,
		pretrigger = function(root)
			if BUSY(root) then return false end
			if not office_triggers.tribute_collector(root, REALM(root)) then return false end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			local tax_target = DATA.realm_get_budget_tax_target(REALM(root))
			local tax_collected = DATA.realm_get_budget_tax_collected_this_year(REALM(root))
			return tax_target - tax_collected
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
			SET_BUSY(root)

			WORLD:emit_event(
				'tax-collection-1',
				root,
				{},
				10
			)
		end
	}
end