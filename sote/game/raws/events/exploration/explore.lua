local tabb = require "engine.table"

local Event = require "game.raws.events"
local event_utils = require "game.raws.events._utils"
local ut = require "game.ui-utils"
local text = require "game.raws.events._localisation"

local province_utils = require "game.entities.province".Province
local warband_utils = require "game.entities.warband"
local realm_utils = require "game.entities.realm".Realm

local economic_triggers = require "game.raws.triggers.economy"

local economy_values = require "game.raws.values.economy"
local political_values = require "game.raws.values.politics"

local economic_effects = require "game.raws.effects.economy"
local political_effects = require "game.raws.effects.politics"


local retrieve_use_case = require "game.raws.raws-utils".trade_good_use_case

local AI_VALUE = require "game.raws.values.ai"

return function()
	Event:new {
		name = "exploration-preparation-ask-for-help",
		event_text = text.exploration_preparation,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = event_utils.constant_false,
		fallback = function(self, associated_data)

		end,
		on_trigger = function(self, character, associated_data)
			local partner = political_values.overseer(LOCAL_REALM(character))

			if not partner then
				WORLD:emit_immediate_event("exploration-failed-to-find-help", character, nil)
				return
			end

			---@type ExplorationConversationData
			local conversation = {
				lied = false,
				partner = partner,
				payment = 0
			}

			---@type ExplorationData
			local exploration_data = {
				explored_province = PROVINCE(character),
				explorer = character,
				last_conversation = conversation,
				_exploration_days_left = province_utils.exploration_days(PROVINCE(character)),
				_exploration_speed = 1.0
			}

			WORLD:emit_immediate_event("exploration-help", partner, exploration_data)
		end
	}

	Event:new {
		name = "exploration-preparation-by-yourself",
		event_text = text.exploration_preparation,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = event_utils.constant_false,
		fallback = function(self, associated_data)

		end,
		on_trigger = function(self, character, associated_data)
			---@type ExplorationData
			local exploration_data = {
				explored_province = PROVINCE(character),
				explorer = character,
				last_conversation = nil,
				_exploration_days_left = province_utils.exploration_days(PROVINCE(character)),
				_exploration_speed = 1.5
			}

			WORLD:emit_immediate_event("exploration-progress", character, exploration_data)
		end
	}


	event_utils.notification_event(
		"exploration-failed-to-find-help",
		function(self, root, associated_data)
			return "I failed to find any help in the exploration of " .. PROVINCE_NAME(PROVINCE(root))
		end,
		function(root, associated_data)
			return "Okay."
		end,
		function(root, associated_data)
			return "Maybe I should try to do it on my own?"
		end
	)

	Event:new {
		name = "exploration-preparation",
		event_text = text.exploration_preparation,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = event_utils.constant_false,
		fallback = function(self, associated_data)

		end,
		options = function(self, character, associated_data)
			return {
				{
					text = "I start immediately.",
					tooltip = "I can't waste any time",
					viable = function() return true end,
					outcome = function()
						---@type ExplorationData
						local exploration_data = {
							explored_province = PROVINCE(character),
							explorer = character,
							last_conversation = nil,
							_exploration_days_left = province_utils.exploration_days(PROVINCE(character)),
							_exploration_speed = 1.5
						}

						WORLD:emit_immediate_event("exploration-progress", character, exploration_data)
					end,
					ai_preference = function()
						return 0.5
					end
				},

				{
					text = "I will ask the local ruler for help.",
					tooltip = "With help, we could proceed much faster",
					viable = function()
						if LOCAL_REALM(character) == INVALID_ID then
							return false
						end
						return political_values.overseer(LOCAL_REALM(character)) ~= nil
					end,
					outcome = function()
						local partner = political_values.overseer(LOCAL_REALM(character))

						if not partner then
							error("Partner is set to null in the exploration preparation event")
						end

						---@type ExplorationConversationData
						local conversation = {
							lied = false,
							partner = partner,
							payment = 0
						}

						---@type ExplorationData
						local exploration_data = {
							explored_province = PROVINCE(character),
							explorer = character,
							last_conversation = conversation,
							_exploration_days_left = province_utils.exploration_days(PROVINCE(character)),
							_exploration_speed = 1.0
						}

						WORLD:emit_immediate_event("exploration-help", partner, exploration_data)
					end,
					ai_preference = function()
						if SAVINGS(character) > 10 then
							return 1
						end

						return 0
					end
				},

				event_utils.option_stop(
					"Reconsider",
					"Stop exploration efforts",
					0.1,
					character
				)
			}
		end
	}


	Event:new {
		name = "exploration-progress",
		event_text = text.exploration_progress,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = event_utils.constant_false,
		fallback = function(self, associated_data)

		end,
		options = function(self, character, associated_data)
			---@type ExplorationData
			associated_data = associated_data

			local food_price = economy_values.get_local_price_of_use(associated_data.explored_province, CALORIES_USE_CASE)

			return {
				{
					text = "Continue exploration",
					tooltip = "I will spend another month on the exploration of this province",
					viable = function()
						return economy_values.days_of_travel(LEADER_OF_WARBAND(character)) >= 30
					end,
					outcome = function()
						-- some free time to at least get some water...
						local free_time = 0.05
						DATA.warband_set_current_free_time_ratio(LEADER_OF_WARBAND(character), free_time)
						local days_left = math.min(
						associated_data._exploration_days_left / warband_utils.exploration_speed(LEADER_OF_WARBAND(character)), 30)
						local potential_days = economy_values.days_of_travel(LEADER_OF_WARBAND(character))
						local actual_days_spent = math.min(days_left, potential_days)

						economic_effects.consume_supplies(
							LEADER_OF_WARBAND(character),
							actual_days_spent *	(1 - free_time)
						)

						associated_data._exploration_days_left =
							associated_data._exploration_days_left
							- actual_days_spent * warband_utils.exploration_speed(LEADER_OF_WARBAND(character))

						if associated_data._exploration_days_left < 1 then
							WORLD:emit_event("exploration-result", character, associated_data, actual_days_spent)
						else
							WORLD:emit_event("exploration-progress", character, associated_data, actual_days_spent)
						end
					end,
					ai_preference = function()
						return 1
					end
				},

				{
					text = "Reduced exploration efforts",
					tooltip =
					"We can't afford to dedicate all our time to exploration. I will let my people forage or work as well.",
					viable = function()
						return economy_values.days_of_travel(LEADER_OF_WARBAND(character)) >= 15
					end,
					outcome = function()
						local free_time = 0.5
						DATA.warband_set_current_free_time_ratio(LEADER_OF_WARBAND(character), free_time)
						local days_left = math.min(
						associated_data._exploration_days_left / warband_utils.exploration_speed(LEADER_OF_WARBAND(character)), 30)
						local potential_days = economy_values.days_of_travel(LEADER_OF_WARBAND(character))
						local actual_days_spent = math.min(days_left, potential_days)

						economic_effects.consume_supplies(
							LEADER_OF_WARBAND(character),
							actual_days_spent *	(1 - free_time)
						)
						associated_data._exploration_days_left = associated_data._exploration_days_left -
						actual_days_spent * warband_utils.exploration_speed(LEADER_OF_WARBAND(character))

						if associated_data._exploration_days_left < 1 then
							WORLD:emit_event("exploration-result", character, associated_data, actual_days_spent)
						else
							WORLD:emit_event("exploration-progress", character, associated_data, actual_days_spent)
						end
					end,
					ai_preference = function()
						return 0.7
					end
				},

				{
					text = "Delay exploration",
					tooltip = "My party will rest next month and forage or work.",
					viable = function()
						return true
					end,
					outcome = function()
						DATA.warband_set_current_free_time_ratio(LEADER_OF_WARBAND(character), 1)
						WORLD:emit_event("exploration-progress", character, associated_data, 30)
					end,
					ai_preference = function()
						return 0.5
					end
				},

				{
					text = "Buy supplies for " .. ut.to_fixed_point2(food_price) .. MONEY_SYMBOL,
					tooltip = "Buy supplies from locals",
					viable = function()
						local result, _ = economic_triggers.can_buy_use(PROVINCE(character), SAVINGS(character), CALORIES_USE_CASE, 1)
						return result
					end,
					outcome = function()
						economic_effects.character_buy_use(character, CALORIES_USE_CASE, 1)
						WORLD:emit_immediate_event("exploration-progress", character, associated_data)
					end,
					ai_preference = function()
						local potential_days = economy_values.days_of_travel(LEADER_OF_WARBAND(character))
						if potential_days < 10 then
							return 1.2
						end

						return 0
					end
				},

				event_utils.option_stop(
					"Abort exploration",
					"I will drop my attempts to explore this province",
					0,
					character
				)
			}
		end
	}

	Event:new {
		name = "exploration-result",
		event_text = text.exploration_result,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = event_utils.constant_false,
		fallback = function(self, associated_data)

		end,
		options = function(self, character, associated_data)
			---@type ExplorationData
			associated_data = associated_data

			return {
				{
					text = "Success",
					tooltip = "We know more about neighboring lands now",
					viable = function()
						return true
					end,
					outcome = function()
						WORLD:emit_immediate_action("explore", character, associated_data)
					end,
					ai_preference = function()
						return 0.5
					end
				}
			}
		end
	}

	Event:new {
		name = "explore",
		automatic = false,
		base_probability = 0,
		event_background_path = "",
		fallback = function(self, associated_data)

		end,
		on_trigger = function(self, root, associated_data)
			if DATA.realm_get_quests_explore(REALM(root))[PROVINCE(root)] then
				economic_effects.add_pop_savings(
					root,
					DATA.realm_get_quests_explore(REALM(root))[PROVINCE(root)],
					ECONOMY_REASON.QUEST
				)
				DATA.realm_get_quests_explore(REALM(root))[PROVINCE(root)] = nil
			end

			political_effects.medium_popularity_boost(root, REALM(root))
			realm_utils.explore(REALM(root), PROVINCE(root))
			UNSET_BUSY(root)
			DATA.warband_set_current_free_time_ratio(LEADER_OF_WARBAND(root), 1)
		end,
	}
end
