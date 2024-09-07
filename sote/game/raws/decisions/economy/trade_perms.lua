
local Decision = require "game.raws.decisions"

local pretriggers = require "game.raws.triggers.tooltiped_triggers".Pretrigger
local triggers = require "game.raws.triggers.tooltiped_triggers".Targeted

local NOT_BUSY = pretriggers.not_busy

local economic_values = require "game.raws.values.economy"
local economic_triggers = require "game.raws.triggers.economy"

return function ()

	Decision.CharacterProvince:new_from_trigger_lists (
		'start-negotiations-trade-permission',
		"Ask for trade permissions in this land",
		function(root, primary_target)
			return "Start trade rights negotiations with " .. primary_target.name
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
			---@type NegotiationData
			local negotiation_data = {
				initiator = root,
				target = primary_target.realm.leader,
				negotiations_terms_characters = {
					trade = {
						wealth_transfer_from_initiator_to_target = primary_target.realm.trading_right_cost + 1,
						goods_transfer_from_initiator_to_target = {}
					}
				},
				negotiations_terms_character_to_realm = {
					{
						target = primary_target.realm,
						trade_permission = true,
						building_permission = false
					}
				},
				negotiations_terms_realms = {},
				days_of_travel = 10
			}

			---@type Character
			local negotiation_target = primary_target.realm.leader

			assert(negotiation_target ~= nil)

			root.current_negotiations[negotiation_target] = negotiation_target
			negotiation_target.current_negotiations[root] = root

			WORLD:emit_immediate_event('negotiation-initiator', root, negotiation_data)
		end,

		function(root, primary_target, secondary_target)
			--- we decide if this is a good target during the selection of target
			return 1
		end,
		function(root)
			if root.savings < 50 then
				return nil, false
			end

			--- prepare a list of good targets
			---@type Province[]
			local targets = {}
			for _, province in pairs(root.realm.capitol.neighbors) do
				if province.realm then
					table.insert(targets, province)
				end
			end
			for _, overlord in pairs(root.realm.paying_tribute_to) do
				table.insert(targets, overlord.capitol)
			end
			for _, tributary in pairs(root.realm.tributaries) do
				table.insert(targets, tributary.capitol)
			end

			local best_target = nil
			local best_trade_profits = 1.5 ---arbitrary value to weed out low profit targets

			local local_stockpile = root.province.local_storage

			for _, target in ipairs(targets) do
				local trade_profits = 0

				if economic_triggers.allowed_to_trade(root, target.realm) then
					goto continue
				end

				---@param good trade_good_id
				local function update_potential_profits(good)
					--- checking if we can sell with profit
					local target_sell_price = economic_values.get_pessimistic_local_price(target, good, 5, true) / 5
					local target_buy_price = economic_values.get_local_price(target, good)

					local known_price = root.price_memory[good] or 0

					local greed = 0.1
					if root.traits[TRAIT.GREEDY] then
						greed = 0.5
					end

					if (target_sell_price > known_price * (1.0 + greed)) and ((local_stockpile[good] or 0) > 5) then -- we want to sell there
						trade_profits = trade_profits + target_sell_price - known_price
					end

					if (target_buy_price * (1.0 + greed) < known_price) and ((target.local_storage[good] or 0) > 5) then -- we want to buy there
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
			return "Start building rights negotiations with " .. primary_target.name
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
			---@type NegotiationData
			local negotiation_data = {
				initiator = root,
				target = primary_target.realm.leader,
				negotiations_terms_characters = {
					trade = {
						wealth_transfer_from_initiator_to_target = primary_target.realm.building_right_cost + 1,
						goods_transfer_from_initiator_to_target = {}
					}
				},
				negotiations_terms_character_to_realm = {
					{
						target = primary_target.realm,
						trade_permission = false,
						building_permission = true
					}
				},
				negotiations_terms_realms = {},
				days_of_travel = 10
			}

			---@type Character
			local negotiation_target = primary_target.realm.leader

			assert(negotiation_target ~= nil)

			root.current_negotiations[negotiation_target] = negotiation_target
			negotiation_target.current_negotiations[root] = root

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