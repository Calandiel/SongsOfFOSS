local tabb = require "engine.table"

local Event = require "game.raws.events"
local event_utils = require "game.raws.events._utils"
local ut = require "game.ui-utils"
local text = require "game.raws.events._localisation"
local economic_effects = require "game.raws.effects.economic"
local political_effects = require "game.raws.effects.political"
local political_values = require "game.raws.values.political"

local AI_VALUE = require "game.raws.values.ai_preferences"

return function()
	Event:new {
		name = "exploration-preparation-ask-for-help",
		event_text = text.exploration_preparation,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = event_utils.constant_false,

		on_trigger = function (self, character, associated_data)
			local partner = political_values.overseer(character.province.realm)

			if partner == nil then
				WORLD:emit_immediate_event("exploration-failed-to-find-help", character, nil)
			end

			---@type ExplorationConversationData
			local conversation = {
				lied = false,
				partner = partner,
				payment = 0
			}

			---@type ExplorationData
			local exploration_data = {
				explored_province = character.province,
				explorer = character,
				last_conversation = conversation,
				_exploration_days_left = character.province.movement_cost,
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

		on_trigger = function (self, character, associated_data)
			---@type ExplorationData
			local exploration_data = {
				explored_province = character.province,
				explorer = character,
				last_conversation = nil,
				_exploration_days_left = character.province.movement_cost,
				_exploration_speed = 1.5
			}

			WORLD:emit_immediate_event("exploration-progress", character, exploration_data)
		end
	}


	event_utils.notification_event(
		"exploration-failed-to-find-help",
		function (self, root, associated_data)
			return "I failed to find any help in exploration of " .. root.province.name
		end,
		function (root, associated_data)
			return "Okay."
		end,
		function (root, associated_data)
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
		options = function(self, character, associated_data)

			return {
				{
					text = "I start immediately.",
					tooltip = "I can't waste any time",
					viable = function() return true end,
					outcome = function()
						---@type ExplorationData
						local exploration_data = {
							explored_province = character.province,
							explorer = character,
							last_conversation = nil,
							_exploration_days_left = character.province.movement_cost,
							_exploration_speed = 1.5
						}

						WORLD:emit_immediate_event("exploration-progress", character, exploration_data)
					end,
					ai_preference = function ()
						return 0.5
					end
				},

				{
					text = "I will ask local ruler for help.",
					tooltip = "With help we could proceed much faster",
					viable = function()
						if character.province.realm == nil then
							return false
						end
						return political_values.overseer(character.province.realm) ~= nil
					end,
					outcome = function ()
						local partner = political_values.overseer(character.province.realm)

						---@type ExplorationConversationData
						local conversation = {
							lied = false,
							partner = partner,
							payment = 0
						}

						---@type ExplorationData
						local exploration_data = {
							explored_province = character.province,
							explorer = character,
							last_conversation = conversation,
							_exploration_days_left = character.province.movement_cost,
							_exploration_speed = 1.0
						}

						WORLD:emit_immediate_event("exploration-help", partner, exploration_data)
					end,
					ai_preference = function ()
						if character.savings > 10 then
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
		options = function(self, character, associated_data)
			---@type ExplorationData
			associated_data = associated_data

			if character.dead then
				return {
					{
						text = "I am dead",
						tooltip = "I will remain dead",
						viable = function()
							return true
						end,
						outcome = function()
						end,
						ai_preference = function ()
							return 1
						end
					},
				}
			end

			return {
				{
					text = "Continue exploration",
					tooltip = "I will spend another month on exploration of this province",
					viable = function()
						return character.leading_warband:days_of_travel() >= 30
					end,
					outcome = function()
						-- some free time to at least get some water...
						character.leading_warband.current_free_time_ratio = 0.05
						local days_left = math.min(associated_data._exploration_days_left / character.leading_warband:exploration_speed(), 30)
						local potential_days = character.leading_warband:days_of_travel()
						local actual_days_spent = math.min(days_left, potential_days)

						character.leading_warband:consume_supplies(actual_days_spent * (1 - character.leading_warband.current_free_time_ratio))
						associated_data._exploration_days_left = associated_data._exploration_days_left - actual_days_spent * character.leading_warband:exploration_speed()

						if associated_data._exploration_days_left < 1 then
							WORLD:emit_event("exploration-result", character, associated_data, actual_days_spent)
						else
							WORLD:emit_event("exploration-progress", character, associated_data, actual_days_spent)
						end
					end,
					ai_preference = function ()
						return 1
					end
				},

				{
					text = "Reduced exploration efforts",
					tooltip = "We can't afford to dedicate all our time to exploration. I will let my people to forage or work as well.",
					viable = function()
						return character.leading_warband:days_of_travel() >= 15
					end,
					outcome = function()
						character.leading_warband.current_free_time_ratio = 0.5
						local days_left = math.min(associated_data._exploration_days_left / character.leading_warband:exploration_speed(), 30)
						local potential_days = character.leading_warband:days_of_travel()
						local actual_days_spent = math.min(days_left, potential_days)

						character.leading_warband:consume_supplies(actual_days_spent * (1 - character.leading_warband.current_free_time_ratio))
						associated_data._exploration_days_left = associated_data._exploration_days_left - actual_days_spent * character.leading_warband:exploration_speed()

						if associated_data._exploration_days_left < 1 then
							WORLD:emit_event("exploration-result", character, associated_data, actual_days_spent)
						else
							WORLD:emit_event("exploration-progress", character, associated_data, actual_days_spent)
						end
					end,
					ai_preference = function ()
						return 0.7
					end
				},

				{
					text = "Delay exploration",
					tooltip = "My party will rest during next month and will forage or work.",
					viable = function()
						return true
					end,
					outcome = function ()
						character.leading_warband.current_free_time_ratio = 1.0
						WORLD:emit_event("exploration-progress", character, associated_data, 30)
					end,
					ai_preference = function ()
						return 0.5
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
					outcome = function ()
						WORLD:emit_immediate_action("explore", character, associated_data)
					end,
					ai_preference = function ()
						return 0.5
					end
				}
			}
		end
	}

	Event:new {
		name = "explore",
		automatic = false,
		on_trigger = function(self, root, associated_data)
            if root.dead then
                return
            end

			if root.realm.quests_explore[root.province] then
				economic_effects.add_pop_savings(root, root.realm.quests_explore[root.province], economic_effects.reasons.Quest)
				root.realm.quests_explore[root.province] = nil
			end

			political_effects.medium_popularity_boost(root, root.realm)
            root.realm:explore(root.province)
            root.busy = false
			root.leading_warband.current_free_time_ratio = 1.0
		end,
	}
end