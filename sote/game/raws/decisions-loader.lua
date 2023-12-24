
local tabb = require "engine.table"
local ll = {}
local military_effects = require "game.raws.effects.military"
local utils = require "game.raws.raws-utils"
local ef = require "game.raws.effects.economic"

function ll.load()
	local Decision = require "game.raws.decisions"

	require "game.raws.decisions.war-decisions" ()
	require "game.raws.decisions.character-decisions" ()
	require "game.raws.decisions.office-decisions" ()
	require "game.raws.decisions.diplomacy" ()
	require "game.raws.decisions.interpersonal" ()
	require "game.raws.decisions.travel" ()

	-- Logic flow:
	-- 1. Loop through all realms
	-- 2. Loop through all decisions
	-- 3. Check base probability (AI only) << base_probability >>
	-- 4. Check pretrigger << pretrigger >>
	-- 5. Select target (AI only) << ai_target >>
	-- 6. Check clickability << clickable >>
	-- 6a. If clickability failed, go back to 5, up to << ai_targetting_attempts >> times (AI only)
	-- 7. Select secondary target (AI only) << ai_secondary_target >>
	-- 8. Check is the decision is available (can be used on that specific target) << available >>
	-- 9. Check action probability (AI only) << ai_will_do >>
	-- 10. Apply decisions << effect >>

	--[[
	Decision.Realm:new {
		name = 'cheat-for-money',
		ui_name = 'Money Cheat',
		tooltip = "Because developers don't wanna wait for monthly income when testing buildings",
		sorting = 0,
		base_probability = 0,
		effect = function(realm, primary_target, secondary_target)
			realm.treasury = realm.treasury + 1000
		end,
	}
	Decision.Realm:new {
		name = 'never-possible',
		ui_name = 'this should never be visible',
		sorting = 0,
		secondary_target = 'tile',
		base_probability = 0,
		effect = function(realm, primary_target, secondary_target)
			print("This should never happen!")
		end,
		pretrigger = function()
			return false
		end
	}
	Decision.Realm:new {
		name = 'target-debug',
		ui_name = 'debugging (province selection)',
		tooltip = "This decision does nothing. It exists only to debug secondary target selection",
		sorting = 0,
		primary_target = 'province',
		secondary_target = 'province',
		base_probability = 0, -- AI will never do this, it's just for debugging the system
		effect = function(realm, primary_target, secondary_target)
			print("Stuff is happening!")
			WORLD:emit_event(RAWS_MANAGER.events_by_name['default'], realm, nil)
		end,
		clickable = function(realm, primary_target)
			return primary_target.realm == realm
		end,
		get_secondary_targets = function(realm, primary_target)
			local r = {}
			for _, province in pairs(realm.provinces) do
				r[#r + 1] = province
			end
			return r
		end,
	}
	--]]
	local gift_cost_per_pop = require "game.gifting".gift_cost_per_pop
	Decision.Realm:new {
		name = 'give-gifts',
		ui_name = "Hand out gifts",
		tooltip = utils.constant_string("Hand out gifts to the local population, effectively bribing them for support."),
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 1 / 25,
		pretrigger = function(root)
			---@type Realm
			local root = root
			return root.budget.treasury > 10
		end,
		clickable = function(root, primary_target)
			---@type Realm
			local root = root
			---@type Province
			local primary_target = primary_target
			return root == primary_target.realm
		end,
		available = function(root, primary_target)
			---@type Realm
			local root = root
			---@type Province
			local primary_target = primary_target
			local pop = primary_target:population()
			return root.budget.treasury > pop * gift_cost_per_pop
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			-- AI will only do it if mood in the province is negative
			if primary_target.mood < 0 then
				return 1
			else
				return 0
			end
		end,
		ai_targetting_attempts = 1,
		ai_target = function(root)
			---@type Realm
			local root = root
			local n = tabb.size(root.provinces)
			local r = tabb.nth(root.provinces, love.math.random(n))
			if r then
				return r, true
			else
				return nil, false
			end
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		effect = function(root, primary_target, secondary_target)
			---@type Realm
			local root = root
			---@type Province
			local primary_target = primary_target
			primary_target.mood = math.min(10, primary_target.mood + 0.05)
			ef.change_treasury(root, -primary_target:population() * gift_cost_per_pop, EconomicEffects.reasons.Donation)
			if WORLD:does_player_control_realm(root) then
				WORLD:emit_notification("Population of " .. primary_target.name .. " is jubilant after receiving our gifts!")
			end
		end
	}
	Decision.Realm:new {
		name = 'explore-province',
		ui_name = "Explore province",
		tooltip = utils.constant_string("Explore province"),
		sorting = 1,
		primary_target = 'province',
		secondary_target = 'none',
		base_probability = 1 / 12,
		-- The first check -- used to cull potential decision takers
		pretrigger = function(root)
			return true
		end,
		-- Controls if the action is clickable by the player
		clickable = function(root, primary_target)
			---@type Realm
			local root = root
			---@type Province
			local primary_target = primary_target
			local explore_cost = root:get_explore_cost(primary_target)
			return explore_cost < root.budget.treasury
		end,
		-- Controls if the action can be clicked by the player
		available = function(root, primary_target, secondary_target)
			return true
		end,
		-- Returns probability that the AI will take the action (after all other checks)
		ai_will_do = function(root, primary_target, secondary_target)
			return 1
		end,
		-- Number of attempts an AI will take to select the target
		ai_targetting_attempts = 1,
		-- Returns a potential target (the target may be invalid)
		ai_target = function(root)
			---@type Realm
			local root = root
			local n = tabb.size(root.known_provinces)
			local r = tabb.nth(root.known_provinces, love.math.random(n))
			if r then
				return r, true
			else
				return nil, false
			end
		end,
		-- Returns a secondary target (the target may be invalid)
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		-- If all checks are met, this function is applied
		-- Put any effects of the decision here
		-- Use events and notifications when applicable!
		effect = function(root, primary_target, secondary_target)
			---@type Realm
			local root = root
			root:explore(primary_target)
			--print("Exploration from decision! Tresury: ", root.treasury)
		end
	}
	Decision.Realm:new {
		name = 'offend-locals',
		ui_name = "Offend locals",
		tooltip = utils.constant_string("(DEBUG EVENT) Sometimes, offending the people you rule over is just the thing you want to do!."),
		sorting = 1,
		primary_target = 'province',
		secondary_target = 'none',
		base_probability = 0 / 12,
		-- The first check -- used to cull potential decision takers
		pretrigger = function(root)
			return true
		end,
		-- Controls if the action is clickable by the player
		clickable = function(root, primary_target)
			---@type Realm
			local root = root
			---@type Province
			local primary_target = primary_target
			return root == primary_target.realm
		end,
		-- Controls if the action can be clicked by the player
		available = function(root, primary_target, secondary_target)
			return true
		end,
		-- Returns probability that the AI will take the action (after all other checks)
		ai_will_do = function(root, primary_target, secondary_target)
			return 0
		end,
		-- Number of attempts an AI will take to select the target
		ai_targetting_attempts = 1,
		-- Returns a potential target (the target may be invalid)
		ai_target = function(root)
			---@type Realm
			local root = root
			local n = tabb.size(root.provinces)
			local r = tabb.nth(root.provinces, love.math.random(n))
			if r then
				return r, true
			else
				return nil, false
			end
		end,
		-- Returns a secondary target (the target may be invalid)
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		-- If all checks are met, this function is applied
		-- Put any effects of the decision here
		-- Use events and notifications when applicable!
		effect = function(root, primary_target, secondary_target)
			---@type Realm
			local root = root
			---@type Province
			local primary_target = primary_target
			primary_target.mood = primary_target.mood - 1
			if WORLD:does_player_control_realm(root) then
				WORLD:emit_notification("People were greatly upset!")
			end
		end
	}
end

return ll
