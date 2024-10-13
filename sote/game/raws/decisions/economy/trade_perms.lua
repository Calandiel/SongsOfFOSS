
local Decision = require "game.raws.decisions"

local pretriggers = require "game.raws.triggers.tooltiped_triggers".Pretrigger
local triggers = require "game.raws.triggers.tooltiped_triggers".Targeted

local NOT_BUSY = pretriggers.not_busy

local economic_values = require "game.raws.values.economy"
local character_values = require "game.raws.values.character"
local economic_triggers = require "game.raws.triggers.economy"

return function ()

	Decision.CharacterProvince:new_from_trigger_lists (
		'start-negotiations-trade-permission',
		"Ask for trade permissions in this land",
		function(root, primary_target)
			return "Start trade rights negotiations with a ruler of " .. DATA.province_name(primary_target)
		end,
		1 / 12, -- once per year
		{
			NOT_BUSY,
		},
		{
			triggers.settled
		},
		{
			triggers.has_no_local_trade_permit
		},

		function(root, primary_target, secondary_target)
			local realm = PROVINCE_REALM(primary_target)
			local negotiation_target = LEADER(realm)
			local negotiation = DATA.force_create_negotiation(root, negotiation_target)
			local cost = DATA.realm_get_trading_right_cost(realm)

			assert(negotiation_target ~= INVALID_ID)

			---@type NegotiationData
			local negotiation_data = {
				id = negotiation,
				initiator = root,
				target = negotiation_target,
				negotiations_terms_characters = {
					trade = {
						wealth_transfer_from_initiator_to_target = cost + 1,
						goods_transfer_from_initiator_to_target = {}
					}
				},
				negotiations_terms_character_to_realm = {
					{
						target = realm,
						trade_permission = true,
						building_permission = false
					}
				},
				negotiations_terms_realms = {},
				days_of_travel = 10
			}

			WORLD:emit_immediate_event('negotiation-initiator', root, negotiation_data)
		end,

		function(root, primary_target, secondary_target)
			--- we decide if this is a good target during the selection of target
			return 1
		end,
		function(root)
			if DATA.get_savings(root) < 50 then
				return nil, false
			end

			--- prepare a list of good targets
			---@type Province[]
			local targets = {}

			local capitol = CAPITOL(REALM(root))

			DATA.for_each_province_neighborhood_from_origin(capitol, function (item)
				local province = DATA.province_neighborhood_get_target(item)
				if PROVINCE_REALM(province) ~= INVALID_ID then
					table.insert(targets, province)
				end
			end)

			DATA.for_each_realm_subject_relation_from_subject(REALM(root), function (item)
				local province = CAPITOL(DATA.realm_subject_relation_get_overlord(item))
				table.insert(targets, province)
			end)

			DATA.for_each_realm_subject_relation_from_overlord(REALM(root), function (item)
				local province = CAPITOL(DATA.realm_subject_relation_get_subject(item))
				table.insert(targets, province)
			end)

			local best_target = nil
			local best_trade_profits = 1.5 ---arbitrary value to weed out low profit targets

			for _, target in ipairs(targets) do
				local trade_profits = 0

				if economic_triggers.allowed_to_trade(root, PROVINCE_REALM(target)) then
					goto continue
				end

				---@param good trade_good_id
				local function update_potential_profits(good)
					--- checking if we can sell with profit
					local target_sell_price = economic_values.get_pessimistic_local_price(target, good, 5, true) / 5
					local target_buy_price = economic_values.get_local_price(target, good)

					local known_price = DATA.pop_get_price_memory(root, good)
					local greed = character_values.profit_desire(root)

					local stockpile = DATA.province_get_local_storage(PROVINCE(root), good)

					if (target_sell_price > known_price * (1.0 + greed)) and (stockpile > 5) then -- we want to sell there
						trade_profits = trade_profits + target_sell_price - known_price
					end

					if (target_buy_price * (1.0 + greed) < known_price) and (stockpile > 5) then -- we want to buy there
						trade_profits = trade_profits + known_price - target_buy_price
					end
				end

				DATA.for_each_trade_good(update_potential_profits)

				if trade_profits > best_trade_profits then
					best_target = target
					best_trade_profits = trade_profits
				end
				::continue::
			end

			if best_target then
				return best_target, true
			end

			return nil, false
		end
	)

	---TODO: write logic for AI selecting desired provinces to build stuff
	Decision.CharacterProvince:new_from_trigger_lists (
		'start-negotiations-building-permission',
		"Ask for building permissions in this land",
		function(root, primary_target)
			return "Start building rights negotiations with a ruler of " .. DATA.province_get_name(primary_target)
		end,
		0, -- for now never
		{
			NOT_BUSY,
		},
		{
			triggers.settled
		},
		{
			triggers.has_no_local_building_permit
		},

		function(root, primary_target, secondary_target)
			local realm = PROVINCE_REALM(primary_target)
			local negotiation_target = LEADER(realm)
			local negotiation = DATA.force_create_negotiation(root, negotiation_target)
			local cost = DATA.realm_get_building_right_cost(realm)

			assert(negotiation_target ~= INVALID_ID)

			---@type NegotiationData
			local negotiation_data = {
				id = negotiation,
				initiator = root,
				target = negotiation_target,
				negotiations_terms_characters = {
					trade = {
						wealth_transfer_from_initiator_to_target = cost + 1,
						goods_transfer_from_initiator_to_target = {}
					}
				},
				negotiations_terms_character_to_realm = {
					{
						target = realm,
						trade_permission = false,
						building_permission = true
					}
				},
				negotiations_terms_realms = {},
				days_of_travel = 10
			}

			WORLD:emit_immediate_event('negotiation-initiator', root, negotiation_data)
		end,

		function(root, primary_target, secondary_target)
			--- we decide if this is a good target during the selection of target
			return 1
		end,
		function(root)
			return nil, false
		end
	)
end