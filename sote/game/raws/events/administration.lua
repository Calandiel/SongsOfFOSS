local tabb = require "engine.table"

local Event = require "game.raws.events"
local E_ut = require "game.raws.events._utils"

local AI_VALUE = require "game.raws.values.ai"

local political_effects = require "game.raws.effects.politics"

local function load()
	Event:new {
		name = "request-help-overseer",
		fallback = function(self, associated_data) end,
		event_text = function(self, character, associated_data)
			---@type Character
			associated_data = associated_data

			local name = NAME(associated_data)
			local temp = 'his'
			if DATA.pop_get_female(associated_data) then
				temp = 'her'
			end
			return name .. " requested my participation in " .. temp .. " administration. My task would be overseering construction and other public activities. What should I do?"
		end,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type Character
			associated_data = associated_data

			return {
				{
					text = "Accept",
					tooltip = "Accept the request",
					viable = function() return true end,
					outcome = function()
						political_effects.set_overseer(LOCAL_REALM(associated_data), character)
						WORLD:emit_immediate_event("request-help-overseer-success-notification", associated_data, character)
					end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data, 0, {
						ambition = true,
						help = true,
						work = true
					})
				},
				{
					text = "Refuse",
					tooltip = "Refuse the request",
					viable = function() return true end,
					outcome = function()
						if associated_data == WORLD.player_character then
							WORLD:emit_notification(NAME(character) .. " refused to assist me.")
						end
						if character == WORLD.player_character then
							WORLD:emit_notification("I refused to assist " .. NAME(associated_data))
						end
						WORLD:emit_immediate_event("request-help-overseer-failure-notification", associated_data, character)
					end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data, 0, {})
				}
			}
		end
	}

	E_ut.notification_event(
		"request-help-overseer-success-notification",
		function(self, character, associated_data)
			---@type Character
			local associated_data = associated_data
			return NAME(associated_data) .. " agreed to assist me and became an overseer."
		end,
		function (root, associated_data)
			return "Good!"
		end,
		function (root, associated_data)
			return ""
		end
	)

	E_ut.notification_event(
		"request-help-overseer-failure-notification",
		function(self, character, associated_data)
			---@type Character
			local associated_data = associated_data
			return NAME(associated_data) .. " refused to assist me."
		end,
		function (root, associated_data)
			return "Good!"
		end,
		function (root, associated_data)
			return ""
		end
	)

	Event:new {
		name = "request-help-tribute-collection",
		fallback = function(self, associated_data) end,
		event_text = function(self, character, associated_data)
			---@type Character
			associated_data = associated_data

			local name = NAME(associated_data)
			local temp = 'his'
			if DATA.pop_get_female(associated_data) then
				temp = 'her'
			end
			return name .. " requested my participation in " .. temp .. " administration. My task would be collection of tribute from our subjects. What is my response?"
		end,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type Character
			associated_data = associated_data

			local realm = REALM(character)

			if not realm then
				return {}
			end

			local tributary_count = 0
			local tax_collectors = 1

			DATA.for_each_tax_collector_from_realm(realm, function (item)
				tax_collectors = tax_collectors + 1
			end)

			DATA.for_each_realm_subject_relation_from_overlord(realm, function (item)
				tributary_count = tributary_count + 1
			end)

			local share_of_tribute_per_tributary = tributary_count / tax_collectors
			local expected_income = share_of_tribute_per_tributary * 24

			return {
				{
					text = "Accept",
					tooltip = "Accept the request",
					viable = function() return true end,
					outcome = function()
						political_effects.set_tribute_collector(LOCAL_REALM(associated_data), character)
						WORLD:emit_immediate_event("request-help-tribute-collection-success-notification", associated_data, character)
					end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data, expected_income, {
						help = true,
						work = true,
					})
				},
				{
					text = "Refuse",
					tooltip = "Refuse the request",
					viable = function() return true end,
					outcome = function()
						if associated_data == WORLD.player_character then
							WORLD:emit_notification(NAME(character) .. " refused to assist me.")
						end
						if character == WORLD.player_character then
							WORLD:emit_notification("I refused to assist " .. NAME(associated_data))
						end
						WORLD:emit_immediate_event("request-help-tribute-collection-failure-notification", associated_data, character)
					end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data, 0, {})
				}
			}
		end
	}

	E_ut.notification_event(
		"request-help-tribute-collection-success-notification",
		function(self, character, associated_data)
			---@type Character
			local associated_data = associated_data
			return NAME(associated_data) .. " agreed to assist me and became a tribute collector."
		end,
		function (root, associated_data)
			return "Good!"
		end,
		function (root, associated_data)
			return ""
		end
	)

	E_ut.notification_event(
		"request-help-tribute-collection-failure-notification",
		function(self, character, associated_data)
			---@type Character
			local associated_data = associated_data
			return NAME(associated_data) .. " refused to assist me."
		end,
		function (root, associated_data)
			return "Oh well.."
		end,
		function (root, associated_data)
			return ""
		end
	)


	Event:new {
		name = "request-help-guard-leader",
		fallback = function(self, associated_data) end,
		event_text = function(self, character, associated_data)
			---@type Character
			associated_data = associated_data

			local name = NAME(associated_data)
			local temp = 'his'
			if DATA.pop_get_female(associated_data) then
				temp = 'her'
			end
			return name .. " requested my participation in " .. temp .. " guard. My task would be patrolling our lands and protecting them from intruders. What should I do?"
		end,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type Character
			associated_data = associated_data

			return {
				{
					text = "Accept",
					tooltip = "Accept the request",
					viable = function() return true end,
					outcome = function()
						political_effects.set_guard_leader(LOCAL_REALM(associated_data), character)
						WORLD:emit_immediate_event("request-help-guard-leader-success-notification", associated_data, character)
					end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data, 0, {
						ambition = true,
						help = true,
						work = true
					})
				},
				{
					text = "Refuse",
					tooltip = "Refuse the request",
					viable = function() return true end,
					outcome = function()
						if associated_data == WORLD.player_character then
							WORLD:emit_notification(NAME(character) .. " refused to assist me.")
						end
						if character == WORLD.player_character then
							WORLD:emit_notification("I refused to assist " .. NAME(associated_data))
						end
						WORLD:emit_immediate_event("request-help-guard-leader-failure-notification", associated_data, character)
					end,
					ai_preference = AI_VALUE.generic_event_option(character, associated_data, 0, {})
				}
			}
		end
	}

	E_ut.notification_event(
		"request-help-guard-leader-success-notification",
		function(self, character, associated_data)
			---@type Character
			local associated_data = associated_data
			return NAME(associated_data) .. " agreed to assist me and became a leader of our guards."
		end,
		function (root, associated_data)
			return "Good!"
		end,
		function (root, associated_data)
			return ""
		end
	)

	E_ut.notification_event(
		"request-help-guard-leader-failure-notification",
		function(self, character, associated_data)
			---@type Character
			local associated_data = associated_data
			return NAME(associated_data) .. " refused to assist me."
		end,
		function (root, associated_data)
			return "Good!"
		end,
		function (root, associated_data)
			return ""
		end
	)
end

return load