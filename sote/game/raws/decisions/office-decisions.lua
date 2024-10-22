local tabb = require "engine.table"
local messages = require "game.raws.effects.messages"

local Decision = require "game.raws.decisions"

local gift_cost_per_pop = require "game.gifting".gift_cost_per_pop
local utils = require "game.raws.raws-utils"
local realm_utils = require "game.entities.realm".Realm
local province_utils = require "game.entities.province".Province

local ot = require "game.raws.triggers.offices"

local demography_values = require "game.raws.values.demography"
local office_values = require "game.raws.values.office"
local character_values = require "game.raws.values.character"
local ai = require "game.raws.values.ai"

local office_effects = require "game.raws.effects.office"

local economy_effects = require "game.raws.effects.economy"
local military_effects = require "game.raws.effects.military"
local PoliticalEffects = require "game.raws.effects.politics"

local pretriggers = require "game.raws.triggers.tooltiped_triggers".Pretrigger
local triggers = require "game.raws.triggers.tooltiped_triggers".Targeted

local DESIGNATES_OFFICES_LOCAL = pretriggers.designates_offices_local
local VALID_OVERSEER = triggers.valid_overseer
local ORDERS_CAN_REACH_THE_TARGET = triggers.orders_can_reach_target
local TARGET_IS_TAX_COLLECTOR = triggers.target_is_tax_collector
local IS_RULER_LOCAL = pretriggers.leader_of_local_territory
local NO_GUARD_LOCAL = pretriggers.no_guard_at_local_realm
local GUARD_ESTABLISHED = pretriggers.guard_at_local_realm
local GUARD_ESTABLISHED_AND_HAS_NO_LEADER = pretriggers.local_guard_exists_and_has_no_officer

local function load()

	Decision.CharacterCharacter:new_from_trigger_lists(
		"suggest-to-be-overseer",
		"Hire overseer",
		function (root, primary_target)
			return
				"Suggest " .. NAME(primary_target)
				.. " to help you with administration of "
				.. DATA.realm_get_name(REALM(root)) .. "."
		end,
		1 / 12,
		{
			DESIGNATES_OFFICES_LOCAL
		},
		{
			VALID_OVERSEER
		},
		{
		},
		function(root, primary_target, secondary_target)
			messages.on_overseer_hire_request(root, primary_target)
			WORLD:emit_immediate_event('request-help-overseer', primary_target, root)
		end,

		function(root, primary_target, secondary_target)
			if character_values.is_traveller(primary_target) then
				return 0
			end
			local score_difference = character_values.admin_score(primary_target) - character_values.admin_score(root)
			if score_difference < 0 then
				return 0
			end
			if LOYAL_TO(primary_target) == root then
				return score_difference + 0.5
			end
			return score_difference
		end,
		ai.sample_random_candidate
	)

	Decision.Character:new {
		name = 'fire-overseer',
		ui_name = "Fire overseer.",
		tooltip = utils.constant_string("Fire character from overseer position."),
		sorting = 1,
		primary_target = 'character',
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			if not ot.designates_offices(root, PROVINCE(root)) then return false end
			return true
		end,
		clickable = function(root, primary_target)
			local realm = REALM(root)
			if not ot.designates_offices(root, PROVINCE(primary_target)) then return false end
			if office_values.overseer(realm) ~= primary_target then return false end
			return true
		end,
		available = function(root, primary_target)
			return true
		end,
		ai_target = function(root)
			local overseer = office_values.overseer(REALM(root))
			if overseer == INVALID_ID then
				return nil, false
			end
			return overseer, true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			if WORLD.player_character == root then
				WORLD:emit_notification("I fired ".. primary_target.name .. " from the position of overseer.")
			end
			if WORLD.player_character == primary_target then
				WORLD:emit_notification("I was fired from overseer position.")
			end

			PoliticalEffects.remove_overseer(REALM(root))
		end
	}

	Decision.Character:new {
		name = 'suggest-to-be-tribute-collector',
		ui_name = "Hire tribute collector",
		tooltip = utils.constant_string("Suggest character to help you with collection of tribute."),
		sorting = 1,
		primary_target = 'character',
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			if not ot.designates_offices(root, PROVINCE(root)) then return false end
			return true
		end,
		clickable = function(root, primary_target)
			if not ot.designates_offices(root, PROVINCE(primary_target)) then return false end
			if not ot.valid_tribute_collector_candidate(primary_target, REALM(root))   then return false end
			return true
		end,
		ai.sample_random_candidate,
		ai_will_do = function(root, primary_target, secondary_target)
			local loyalty_multiplier = 1
			if primary_target.loyalty == root then
				loyalty_multiplier = 2
			end

			if primary_target.traits[TRAIT.TRADER] then
				return 0
			end

			local realm = REALM(root)

			if office_values.count_collectors(realm) < 1 + province_utils.local_population(CAPITOL(realm)) / 20 then
				return 0.25 * loyalty_multiplier
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			if WORLD.player_character == root then
				WORLD:emit_notification("I asked ".. primary_target.name .. " to assist me in administration.")
			end
			if WORLD.player_character == primary_target then
				WORLD:emit_notification("I was asked by ".. primary_target.name .. " to assist him with tribute collection.")
			end
			WORLD:emit_immediate_event('request-help-tribute-collection', primary_target, root)
		end
	}

	Decision.CharacterCharacter:new_from_trigger_lists(
		'fire-tribute-collector',
		"Fire tribute collector.",
		function (root, primary_target)
			return "Fire " .. NAME(primary_target) .. " from tribute collector position"
		end,
		0,
		{
			DESIGNATES_OFFICES_LOCAL
		},
		{
			TARGET_IS_TAX_COLLECTOR
		},
		{
			ORDERS_CAN_REACH_THE_TARGET,
		},
		function(root, primary_target, secondary_target)
			messages.on_tax_collector_fired_initiator(root, primary_target)
			office_effects.fire_tax_collector(primary_target)
		end,
		function(root, primary_target, secondary_target)
			return 0
		end,
		function(root)
			return nil, false
		end
	)

	Decision.Character:new_from_trigger_lists(
		'establish-guard',
		"Establish guard",
		utils.constant_string("Establish guard - a group of warriors devoted to protection of your current capitol."),
		1,
		{
			DESIGNATES_OFFICES_LOCAL,
			NO_GUARD_LOCAL
		},
		{
		},
		{
		},
		function(root, primary_target, secondary_target)
			military_effects.gather_guard(province_utils.realm(PROVINCE(root)))
		end,
		function(root, primary_target, secondary_target)
			return 1
		end
	)

	Decision.CharacterCharacter:new_from_trigger_lists(
		'suggest-to-be-guard-leader',
		"Hire guard commander.",
		function (root, primary_target)
			return "Suggest " .. NAME(primary_target) .. " to help you with defense of the realm."
		end,
		0.1,
		{
			DESIGNATES_OFFICES_LOCAL,
			GUARD_ESTABLISHED_AND_HAS_NO_LEADER,
		},
		{ },
		{ },
		function(root, primary_target, secondary_target)

			if WORLD.player_character == root then
				WORLD:emit_notification("I asked ".. NAME(primary_target) .. " to assist me in defense of the realm.")
			end
			if WORLD.player_character == primary_target then
				WORLD:emit_notification("I was asked to assist " .. NAME(root) .. " with military tasks.")
			end

			WORLD:emit_immediate_event('request-help-guard-leader', primary_target, root)
		end,
		function(root, primary_target, secondary_target)
			if character_values.is_traveller(primary_target) then
				return 0
			end
			return 0.25
		end,

		function(root)
			local province = PROVINCE(root)
			local local_realm = LOCAL_REALM(root)
			local candidate = demography_values.sample_character_from_province(province)

			if candidate ~= nil then
				if ot.valid_guard_leader(candidate, local_realm) then
					return candidate, true
				end
			end
			return nil, false
		end
	)
end

return load