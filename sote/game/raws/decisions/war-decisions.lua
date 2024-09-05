local Decision = require "game.raws.decisions"
local utils = require "game.raws.raws-utils"

local function load()

	---@type DecisionCharacter
	Decision.Character:new {
		name = 'take-up-command-warband',
		ui_name = "Take command of my warband",
		tooltip = function(root, primary_target)
			if root.recruiter_for_warband and root.recruiter_for_warband.leader and root ~= root.recruiter_for_warband.leader then
				return "Since I am not the leader, I must seek permission to take up command of this warband."
			end
			return "I have decided take up command of my warband."
		end,
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			if root.busy then return false end
			if not root.recruiter_for_warband and not root.leading_warband then return false end
			if root.unit_of_warband then return false end
			return true
		end,
		clickable = function(root, primary_target)
			if (not root.recruiter_for_warband and not root.leading_warband) or root.unit_of_warband then return false end
			return true
		end,
		available = function(root, primary_target)
			if root.recruiter_for_warband and root.recruiter_for_warband.leader and root ~= root.recruiter_for_warband.leader then return false end
			return true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if root.traits[TRAIT.WARLIKE] or root.traits[TRAIT.AMBITIOUS] or root.traits[TRAIT.HARDWORKER] then
				return 1
			end

			if root.traits[TRAIT.CONTENT] or root.traits[TRAIT.LAZY] then
				return 0
			end

			return 0.5
		end,
		effect = function(root, primary_target, secondary_target)
			-- for right now, one or the other
			local warband = root.leading_warband
			if not warband then
				warband = root.recruiter_for_warband
			end
			WORLD:emit_immediate_event("pick-commander-unit", root, warband)
		end
	}

	---@type DecisionCharacter
	Decision.Character:new {
		name = 'give-up-command-warband',
		ui_name = "Give up commanding my warband",
		tooltip = utils.constant_string("I have decided give up command of my warband."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			if root.busy then return false end
			if not root.unit_of_warband then return false end
			if root ~= root.unit_of_warband.commander then return false end
			return true
		end,
		clickable = function(root, primary_target)
			if not root.unit_of_warband then return false end
			return true
		end,
		available = function(root, primary_target)
			return true
		end,
		ai_secondary_target = function(root, primary_target)

			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if root.traits[TRAIT.WARLIKE] or root.traits[TRAIT.AMBITIOUS] or root.traits[TRAIT.HARDWORKER] then
				return 0
			end

			if root.traits[TRAIT.CONTENT] or root.traits[TRAIT.LAZY] then
				return 1
			end

			return 0.1
		end,
		effect = function(root, primary_target, secondary_target)
			-- commander is always a unit
			local warband = root.unit_of_warband
			warband:unset_commander()
		end
	}

	for _, unit in pairs(RAWS_MANAGER.unit_types_by_name) do
		Decision.Character:new {
			name = 'recruit-' .. DATA.unit_type_get_name(unit),
			ui_name = "(AI) Recruit " .. DATA.unit_type_get_name(unit),
			tooltip = utils.constant_string("I will hire a new unit."),
			sorting = 5,
			primary_target = "none",
			secondary_target = 'none',
			base_probability = 1 / 12 , -- Once every year on average
			pretrigger = function(root)
				if WORLD:is_player(root) then
					if OPTIONS.debug_mode then
						return true
					else
						return false
					end
				end
				local recruiter = DATA.get_warband_recruiter_from_recruiter(root)
				local warband = DATA.warband_recruiter_get_warband(recruiter)
				if warband == nil then
					return false
				end
				if (warband.units_current[unit] or 0) < (warband.units_target[unit] or 0) then
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
			available = function(root, primary_target)
				return true
			end,
			ai_secondary_target = function(root, primary_target)
				return nil, true
			end,
			ai_will_do = function(root, primary_target, secondary_target)
				local warband = root.recruiter_for_warband
				if warband == nil then
					return 0
				end

				local predicted_upkeep = warband:predict_upkeep() + unit.upkeep

				if warband.treasury < predicted_upkeep * 12 * 5 then
					return 0
				end

				return root.culture.traditional_units[unit.name]
			end,
			effect = function(root, primary_target, secondary_target)
				local warband = root.recruiter_for_warband
				if warband == nil then
					return
				end
				warband.units_target[unit] = (warband.units_target[unit] or 0) + 1
			end
		}

		Decision.Character:new {
			name = 'fire-' .. DATA.unit_type_get_name(unit),
			ui_name = "Fire " .. DATA.unit_type_get_name(unit),
			tooltip = utils.constant_string("I will fire a unit."),
			sorting = 5,
			primary_target = "none",
			secondary_target = 'none',
			base_probability = 1 / 12 , -- Once every year on average
			pretrigger = function(root)
				if WORLD:is_player(root) then
					if OPTIONS.debug_mode then
						return true
					else
						return false
					end
				end

				local warband = root.recruiter_for_warband
				if warband == nil then
					return false
				end
				if (warband.units_target[unit] or 0) == 0 then
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
			available = function(root, primary_target)
				return true
			end,
			ai_secondary_target = function(root, primary_target)
				return nil, true
			end,
			ai_will_do = function(root, primary_target, secondary_target)
				local warband = root.recruiter_for_warband
				if warband == nil then
					return 0
				end

				local predicted_upkeep = warband:predict_upkeep()

				if warband.treasury / 12 > predicted_upkeep * 2 then
					return 0
				end

				return 1 - root.culture.traditional_units[unit.name]
			end,
			effect = function(root, primary_target, secondary_target)
				local warband = root.recruiter_for_warband
				if warband == nil then
					return
				end
				warband.units_target[unit] = (warband.units_target[unit] or 0) - 1
			end
		}
	end


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
