local tabb = require "engine.table"

local Event = require "game.raws.events"
local EventUtils = require "game.raws.events._utils"

local diplomacy_effects = require "game.raws.effects.diplomacy"
local political_values = require "game.raws.values.politics"
local economy_values = require "game.raws.values.economy"
local economy_effects = require "game.raws.effects.economy"
local economy_triggers = require "game.raws.triggers.economy"
local localisation = require "game.raws.events._localisation"
local AI_VALUE = require "game.raws.values.ai"



local function negotiation_options(self, character, associated_data)
	---@type NegotiationData
	associated_data = associated_data

	return {
		--- this option is not used by NPC: NPC will use predefined negotiation terms set by decisions
		{
			text = localisation.add_personal_term_option(self, character, associated_data),
			tooltip = localisation.add_personal_term_option_tooltip(self, character, associated_data),
			viable = function() return true end,
			outcome = function()
				WORLD:emit_immediate_event("negotiation-initiator-add-personal-term", character, associated_data)
			end,

			ai_preference = function ()
				return 0
			end
		},

		--- this option is not used by NPC: NPC will use predefined negotiation terms set by decisions
		{
			text = localisation.add_realm_term_option(self, character, associated_data),
			tooltip = localisation.add_realm_term_option_tooltip(self, character, associated_data),
			viable = function() return true end,
			outcome = function()
				WORLD:emit_immediate_event("negotiation-initiator-realm-select-origin", character, associated_data)
			end,
			ai_preference = function ()
				return 0
			end
		},

		--- instead, NPC will proceed with already prepared negotiation terms
		{
			text = "Suggest",
			tooltip = localisation.send_negotiation_terms_tooltip(self, character, associated_data),
			viable = function() return true end,
			outcome = function()
				WORLD:emit_immediate_event("negotiation-target", associated_data.target, associated_data)
			end,
			ai_preference = function ()
				return 1
			end
		},

		--- AI doesn't back down: this logic should be handled in according decision
		{
			text = "Back down",
			tooltip = "Back down",
			viable = function() return true end,
			outcome = function()
				WORLD:emit_immediate_event("negotiation-end-no-reason", character, associated_data)
			end,
			ai_preference = function ()
				return 0
			end
		}
	}
end

return function ()

	--- first event in the chain allows to select what kind of term you want to add:

	Event:new {
		name = "negotiation-initiator",
		event_text = localisation.negotiate,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = negotiation_options
	}

	Event:new {
		name = "negotiation-initiator-got-adjustment",
		event_text = localisation.negotiate_adjustment,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = negotiation_options
	}

	Event:new {
		name = "negotiation-initiator-add-personal-term",
		event_text = localisation.negotiate,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type NegotiationData
			associated_data = associated_data

			return {
				{
					text = "Return",
					tooltip = "Return to negotiation draft",
					viable = function() return true end,
					outcome = function()
						WORLD:emit_immediate_event("negotiation-initiator", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				},

				{
					text = "Wealth",
					tooltip = "Draft wealth transaction",
					viable = function() return true end,
					outcome = function()
						WORLD:emit_immediate_event("negotiation-initiator-add-personal-term-wealth", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				},

				{
					text = "Goods",
					tooltip = "Draft goods transaction",
					viable = function() return true end,
					outcome = function()
						WORLD:emit_immediate_event("negotiation-initiator-add-personal-term-goods", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				},

				{
					text = "Trade permission",
					tooltip = "Request personal trade permission",
					viable = function()
						return true
					end,
					outcome = function()
						WORLD:emit_immediate_event("negotiation-initiator-add-personal-term-trade-permission", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				},

				{
					text = "Building permission",
					tooltip = "Request personal building permission",
					viable = function()
						return true
					end,
					outcome = function()
						WORLD:emit_immediate_event("negotiation-initiator-add-personal-term-building-permission", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				}
			}
		end
	}

	Event:new {
		name = "negotiation-initiator-realm-select-origin",
		event_text = function(self, root, associated_data) return "I need to choose one of my realms" end,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type NegotiationData
			associated_data = associated_data

			local options_list = {
				{
					text = "Return",
					tooltip = "Return to negotiation draft",
					viable = function() return true end,
					outcome = function()
						WORLD:emit_immediate_event("negotiation-initiator", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				}
			}

			for _, realm in pairs(character.leader_of) do
				table.insert(options_list, {
					text = realm.name,
					tooltip = "Choose " .. realm.name,
					viable = function ()
						return true
					end,
					outcome = function ()
						associated_data.selected_realm_origin = realm
						WORLD:emit_immediate_event("negotiation-initiator-realm-select-target", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				})
			end

			return options_list
		end
	}

	Event:new {
		name = "negotiation-initiator-realm-select-target",
		event_text = function(self, root, associated_data) return "I need to choose which realm I target" end,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type NegotiationData
			associated_data = associated_data

			local options_list = {
				{
					text = "Return",
					tooltip = "Return to negotiation draft",
					viable = function() return true end,
					outcome = function()
						WORLD:emit_immediate_event("negotiation-initiator", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				}
			}

			for _, realm in pairs(associated_data.target.leader_of) do
				table.insert(options_list, {
					text = realm.name,
					tooltip = "Choose " .. realm.name,
					viable = function ()
						return realm ~= associated_data.selected_realm_origin
					end,
					outcome = function ()
						associated_data.selected_realm_target = realm
						WORLD:emit_immediate_event("negotiation-initiator-add-realm-term", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				})
			end

			return options_list
		end
	}

	local wealth_transfer_options = {0.125, 0.5, 1, 5, 10, 100}

	Event:new {
		name = "negotiation-initiator-add-personal-term-wealth",
		event_text = localisation.negotiate,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type NegotiationData
			associated_data = associated_data

			local options_list = {
				{
					text = "Return",
					tooltip = "Return to personal negotiation draft",
					viable = function() return true end,
					outcome = function()
						WORLD:emit_immediate_event("negotiation-initiator-add-personal-term", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				}
			}

			--- wealth transfer options
			local trade_table = associated_data.negotiations_terms_characters.trade

			--- from initiator
			for _, amount in ipairs(wealth_transfer_options) do
				table.insert(options_list, {
					text = "Transfer " .. tostring(amount) .. " of wealth",
					tooltip = "I will additionally transfer this amount of wealth to my target",
					viable = function() return true end,
					outcome = function()
						trade_table.wealth_transfer_from_initiator_to_target =
							trade_table.wealth_transfer_from_initiator_to_target + amount
						WORLD:emit_immediate_event("negotiation-initiator-add-personal-term-wealth", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				})
			end

			--- to initiator
			for _, amount in ipairs(wealth_transfer_options) do
				table.insert(options_list, {
					text = "Demand " .. tostring(amount) .. " of wealth",
					tooltip = "I will additionally demand this amount of wealth from my target",
					viable = function() return true end,
					outcome = function()
						trade_table.wealth_transfer_from_initiator_to_target =
							trade_table.wealth_transfer_from_initiator_to_target + amount
						WORLD:emit_immediate_event("negotiation-initiator-add-personal-term-wealth", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				})
			end

			return options_list
		end
	}

	Event:new {
		name = "negotiation-initiator-add-personal-term-goods",
		event_text = localisation.negotiate,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type NegotiationData
			associated_data = associated_data

			local options_list = {
				{
					text = "Return",
					tooltip = "Return to personal negotiation draft",
					viable = function() return true end,
					outcome = function()
						WORLD:emit_immediate_event("negotiation-initiator-add-personal-term", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				}
			}

			--- wealth transfer options
			local trade_table = associated_data.negotiations_terms_characters.trade

			--- from initiator
			local function personal_goods_option(trade_good)
				table.insert(options_list, {
					text = "Transfer " .. DATA.trade_good_description[trade_good],
					tooltip = "I will additionally transfer a unit of this good to target",
					viable = function() return true end,
					outcome = function()
						trade_table.goods_transfer_from_initiator_to_target[trade_good] =
							(trade_table.goods_transfer_from_initiator_to_target[trade_good] or 0) + 1
						WORLD:emit_immediate_event("negotiation-initiator-add-personal-term-goods", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				})
			end

			DATA.for_each_trade_good(personal_goods_option)

			--- to initiator
			local function trade_good_request_option(trade_good)
				table.insert(options_list, {
					text = "Demand " .. DATA.trade_good_get_description(trade_good),
					tooltip = "I will additionally require a unit of this good from target",
					viable = function() return true end,
					outcome = function()
						trade_table.goods_transfer_from_initiator_to_target[trade_good] =
							(trade_table.goods_transfer_from_initiator_to_target[trade_good] or 0) - 1
						WORLD:emit_immediate_event("negotiation-initiator-add-personal-term-goods", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				})
			end
			DATA.for_each_trade_good(trade_good_request_option)

			return options_list
		end
	}

	Event:new {
		name = "negotiation-initiator-add-personal-term-trade-permission",
		event_text = function(self, root, associated_data) return "I need to choose in which realm I want to trade" end,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type NegotiationData
			associated_data = associated_data

			local options_list = {
				{
					text = "Return",
					tooltip = "Return to negotiation draft",
					viable = function() return true end,
					outcome = function()
						WORLD:emit_immediate_event("negotiation-initiator-add-personal-term", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				}
			}

			for _, realm in pairs(associated_data.target.leader_of) do
				table.insert(options_list, {
					text = realm.name,
					tooltip = "Choose " .. realm.name,
					viable = function ()
						-- if we are already allowed to trade there, we can't buy permission
						if economy_triggers.allowed_to_trade(character, realm) then
							return false
						end
						return true
					end,
					outcome = function ()
						---@type NegotiationCharacterToRealm
						local new_term = {
							target = realm,
							trade_permission = true,
							building_permission = false
						}
						table.insert(associated_data.negotiations_terms_character_to_realm, new_term)

						WORLD:emit_immediate_event("negotiation-initiator-add-personal-term", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				})
			end

			return options_list
		end
	}

	Event:new {
		name = "negotiation-initiator-add-personal-term-building-permission",
		event_text = function(self, root, associated_data) return "I need to choose in which realm I want to be allowed to build" end,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type NegotiationData
			associated_data = associated_data

			local options_list = {
				{
					text = "Return",
					tooltip = "Return to negotiation draft",
					viable = function() return true end,
					outcome = function()
						WORLD:emit_immediate_event("negotiation-initiator-add-personal-term", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				}
			}

			for _, realm in pairs(associated_data.target.leader_of) do
				table.insert(options_list, {
					text = realm.name,
					tooltip = "Choose " .. realm.name,
					viable = function ()
						-- if we are already allowed to trade there, we can't buy permission
						if economy_triggers.allowed_to_trade(character, realm) then
							return false
						end
						return true
					end,
					outcome = function ()
						---@type NegotiationCharacterToRealm
						local new_term = {
							target = realm,
							trade_permission = false,
							building_permission = true
						}
						table.insert(associated_data.negotiations_terms_character_to_realm, new_term)

						WORLD:emit_immediate_event("negotiation-initiator-add-personal-term", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				})
			end

			return options_list
		end
	}


	Event:new {
		name = "negotiation-initiator-add-realm-term",
		event_text = localisation.negotiate,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type NegotiationData
			associated_data = associated_data

			---@type EventOption[]
			local options_list = {
				{
					text = "Return",
					tooltip = "Return to negotiation draft",
					viable = function() return true end,
					outcome = function()
						WORLD:emit_immediate_event("negotiation-initiator", character, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				}
			}

			local origin = associated_data.selected_realm_origin
			local target = associated_data.selected_realm_target

			assert(origin)
			assert(target)

			---@type NegotiationRealmToRealm?
			local negotiation = nil

			for _, candidate in ipairs(associated_data.negotiations_terms_realms) do
				if candidate.root == origin and candidate.target == target then
					negotiation = candidate
					break
				end
			end

			if negotiation == nil then
				negotiation = {
					free = false,
					root = origin,
					target = target,
					subjugate = false,
					demand_freedom = false,
					trade = {
						goods_transfer_from_initiator_to_target = {},
						wealth_transfer_from_initiator_to_target = 0
					},
				}
				table.insert(associated_data.negotiations_terms_realms, negotiation)
			end


			if origin.tributaries[target] == nil then
				table.insert(options_list, {
					text = "Demand tribute",
					tooltip = "Demand that the target become my tributary",
					viable = function ()
						return true
					end,
					outcome = function ()
						negotiation.subjugate = true
						WORLD:emit_immediate_event("negotiation-initiator-add-realm-term", character, associated_data)
					end
				})
			end

			if origin.tributaries[target] == target then
				table.insert(options_list, {
					text = "Set free",
					tooltip = "Set your subject free",
					viable = function ()
						return true
					end,
					outcome = function ()
						negotiation.free = true
						WORLD:emit_immediate_event("negotiation-initiator-add-realm-term", character, associated_data)
					end
				})
			end

			if target.tributaries[origin] == origin then
				table.insert(options_list, {
					text = "Demand freedom",
					tooltip = "Demand freedom from overlord",
					viable = function ()
						return true
					end,
					outcome = function ()
						negotiation.demand_freedom = true
						WORLD:emit_immediate_event("negotiation-initiator-add-realm-term", character, associated_data)
					end
				})
			end

			return options_list
		end
	}

	Event:new {
		name = "negotiation-target",
		event_text = localisation.negotiate,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type NegotiationData
			associated_data = associated_data

			--- NPC calculates if this agreement is beneficial for him:

			local trade_agreement = associated_data.negotiations_terms_characters.trade
			local wealth_gain = 0
			---negative number
			local wealth_reduction = 0

			if trade_agreement.wealth_transfer_from_initiator_to_target > 0 then
				wealth_gain = wealth_gain + trade_agreement.wealth_transfer_from_initiator_to_target
			else
				wealth_reduction = wealth_reduction + trade_agreement.wealth_transfer_from_initiator_to_target
			end

			for good, amount in pairs(trade_agreement.goods_transfer_from_initiator_to_target) do
				local change = amount * character.price_memory[good]

				if change > 0 then
					wealth_gain = wealth_gain + change
				else
					wealth_reduction = wealth_reduction + change
				end
			end

			--- NPC calculates if this agreement is benefitial for his realms
			local realm_wealth_gain = 0
			for _, item in ipairs(associated_data.negotiations_terms_realms) do
				local origin = item.root
				local realm = item.target

				if item.subjugate then
					realm_wealth_gain = realm_wealth_gain - economy_values.realm_independence_price(realm)
				end

				if item.free then
					realm_wealth_gain = realm_wealth_gain + economy_values.potential_monthly_tribute_size(realm) * 120
				end

				if item.demand_freedom then
					realm_wealth_gain = realm_wealth_gain - economy_values.potential_monthly_tribute_size(origin) * 120
				end
			end

			local desired_gift = 0

			for _, item in ipairs(associated_data.negotiations_terms_character_to_realm) do
				if item.trade_permission then
					desired_gift = desired_gift + item.target.trading_right_cost
				end

				if item.building_permission then
					desired_gift = desired_gift + item.target.building_right_cost
				end
			end

			local perceived_change = wealth_gain + wealth_reduction - desired_gift + realm_wealth_gain

			--- greedy characters desire far more money
			if character.traits[TRAIT.GREEDY] then
				perceived_change = wealth_gain + wealth_reduction * 2 - desired_gift * 2 + realm_wealth_gain
			end

			return {
				{
					text = "OK",
					tooltip = "OK",
					viable = function() return true end,
					outcome = function()
						WORLD:emit_immediate_event("negotiation-initiator-target-agrees", associated_data.initiator, associated_data)
					end,
					ai_preference = function ()
						return perceived_change
					end
				},
				{
					text = "Not OK",
					tooltip = "Not OK",
					viable = function() return true end,
					outcome = function()
						WORLD:emit_immediate_event("negotiation-end-failure-initiator", associated_data.initiator, associated_data)
					end,
					ai_preference = function ()
						return -1
					end
				},
				{
					text = "Ask for more money(AI)",
					tooltip = "Ask for more money(AI)",
					viable = function() return true end,
					outcome = function()
						associated_data.negotiations_terms_characters.trade.wealth_transfer_from_initiator_to_target =
							associated_data.negotiations_terms_characters.trade.wealth_transfer_from_initiator_to_target
							- perceived_change
							+ 1

						WORLD:emit_immediate_event("negotiation-initiator-got-adjustment", associated_data.initiator, associated_data)
					end,
					ai_preference = function ()
						return 0
					end
				}
			}
		end
	}

	Event:new {
		name = "negotiation-initiator-target-agrees",
		event_text = localisation.negotiate,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		options = function(self, character, associated_data)
			---@type NegotiationData
			associated_data = associated_data

			--- calculate if this is a valid agreement
			local valid = true

			local initiator = character
			local target = associated_data.target

			--- personal trade agreement
			local trade = associated_data.negotiations_terms_characters.trade

			local invalid_conditions = ""

			if trade.wealth_transfer_from_initiator_to_target > 0 then
				if initiator.savings < trade.wealth_transfer_from_initiator_to_target then
					valid = false
					invalid_conditions = invalid_conditions .. "Initiator doesn't have enough wealth \n"
				end
			else
				if target.savings < -trade.wealth_transfer_from_initiator_to_target then
					valid = false
					invalid_conditions = invalid_conditions .. "Target doesn't have enough wealth \n"
				end
			end

			for good, amount in pairs(trade.goods_transfer_from_initiator_to_target) do
				if amount > 0 then
					if initiator.inventory[good] < amount then
						valid = false
						invalid_conditions = invalid_conditions .. "Initiator doesn't have enough " .. good .. "\n"
					end
				else
					if target.inventory[good] < -amount then
						valid = false
						invalid_conditions = invalid_conditions .. "Target doesn't have enough " .. good .. "\n"
					end
				end
			end

			local diplomacy = associated_data.negotiations_terms_realms

			if not valid then
				return {
					{
						text = "Invalid agreement",
						tooltip = invalid_conditions,
						viable = function ()
							return true
						end,
						outcome = function ()
							return
						end,
						ai_preference = function ()
							return 1
						end
					}
				}
			end

			return {
				{
					text = "Negotiations were successful!",
					tooltip = "OK",
					viable = function() return true end,
					outcome = function()
						--- enforce negotiation

						--- transfer wealth
						economy_effects.add_pop_savings(initiator, -trade.wealth_transfer_from_initiator_to_target, ECONOMY_REASON.NEGOTIATIONS)
						economy_effects.add_pop_savings(target, trade.wealth_transfer_from_initiator_to_target, ECONOMY_REASON.NEGOTIATIONS)

						--- transfer goods
						for good, amount in pairs(trade.goods_transfer_from_initiator_to_target) do
							initiator.inventory[good] = (initiator.inventory[good] or 0) - amount
							target.inventory[good] = (target.inventory[good] or 0) + amount
						end

						--- enforce diplomatic stance
						for _, item in ipairs(diplomacy) do
							local A = item.root
							local B = item.target

							if item.demand_freedom then
								diplomacy_effects.unset_tributary(B, A)
							end

							if item.free then
								diplomacy_effects.unset_tributary(A, B)
							end

							if item.subjugate then
								diplomacy_effects.set_tributary(A, B)
							end
						end

						for _, item in ipairs(associated_data.negotiations_terms_character_to_realm) do
							if item.trade_permission then
								economy_effects.grant_trade_rights(initiator, item.target)
							end

							if item.building_permission then
								economy_effects.grant_building_rights(initiator, item.target)
							end
						end
					end,
					ai_preference = function ()
						return 1
					end
				},
			}
		end
	}

	EventUtils.notification_event(
		"negotiation-end-no-reason",
		localisation.negotiation_back_down,
		localisation.option_okay,
		localisation.option_okay,
		function (root, associated_data)
			---@type NegotiationData
			associated_data = associated_data

			root.current_negotiations[associated_data.target] = nil
			associated_data.target.current_negotiations[root] = nil
		end
	)

	EventUtils.notification_event(
		"negotiation-end-success-initiator",
		localisation.target_accepts,
		localisation.option_okay,
		localisation.option_okay,
		function (root, associated_data)
			---@type NegotiationData
			associated_data = associated_data


			root.current_negotiations[associated_data.target] = nil
			associated_data.target.current_negotiations[root] = nil
		end
	)

	EventUtils.notification_event(
		"negotiation-end-failure-initiator",
		localisation.target_declines,
		localisation.option_okay,
		localisation.option_okay,
		function (root, associated_data)
			---@type NegotiationData
			associated_data = associated_data

			root.current_negotiations[associated_data.target] = nil
			associated_data.target.current_negotiations[root] = nil
		end
	)
end