local tabb = require "engine.table"
local retrieve_trade_good = require "game.raws.raws-utils".trade_good
local rea = {}

local economic_effects = require "game.raws.effects.economy"
local economic_values = require "game.raws.values.economy"
local province_utils = require "game.entities.province".Province
local warband_utils = require "game.entities.warband"

local use_case = require "game.raws.raws-utils".trade_good_use_case


---@param realm Realm
function rea.prerun(realm)
	local fat = DATA.fatten_realm(realm)
	DATA.for_each_economy_reason(function (item)
		DATA.realm_set_budget_spending_by_category(realm, item, 0)
		DATA.realm_set_budget_income_by_category(realm, item, 0)
		DATA.realm_set_budget_treasury_change_by_category(realm, item, 0)
	end)
end

---@param realm_id Realm
function rea.run(realm_id)
	local realm = DATA.fatten_realm(realm_id)

	DATA.for_each_trade_good(function (item)
		DATA.realm_set_production(realm_id, item, 0)
		DATA.realm_set_bought(realm_id, item, 0)
		DATA.realm_set_sold(realm_id, item, 0)
	end)

	realm.expected_food_consumption = 0

	local PROVINCE_TO_REALM_STOCKPILE = 0.05
	local REALM_TO_PROVINCE_STOCKPILE = 0.05
	local NEIGHBOURS_GOODS_SHARING = 0.05
	local NEIGHBOURS_WEALTH_SHARING = 0.05

	local INTEGRATION_STEP = 1

	local provinces_count = 0

	-- Loop over all provinces in the realm and "add" their good balances to get our balance.
	DATA.for_each_realm_provinces_from_realm(realm_id, function (item)
		provinces_count = provinces_count + 1
		local province = DATA.realm_provinces_get_province(item)
		DATA.for_each_trade_good(function (trade_good)
			local amount = DATA.province_get_local_production(province, trade_good)
			DATA.realm_inc_production(realm_id, trade_good, amount)
			DATA.realm_inc_sold(realm_id, trade_good, amount)

			local category = DATA.trade_good_get_category(trade_good)
			if category == TRADE_GOOD_CATEGORY.GOOD then
				economic_effects.change_local_stockpile(province, trade_good, amount)
			end
		end)

		DATA.for_each_trade_good(function (trade_good)
			local amount = DATA.province_get_local_consumption(province, trade_good)
			DATA.realm_inc_production(realm_id, trade_good, -amount)
			DATA.realm_inc_bought(realm_id, trade_good, amount)

			local category = DATA.trade_good_get_category(trade_good)
			if category == TRADE_GOOD_CATEGORY.GOOD then
				economic_effects.change_local_stockpile(province, trade_good, -amount)
			end

			local weight = USE_WEIGHT[trade_good][use_case("calories")]
			realm.expected_food_consumption = realm.expected_food_consumption + weight * amount
		end)
	end)

	-- Handle stockpiles of trade goods in realm
	DATA.for_each_trade_good(function (trade_good)
		if DATA.trade_good_get_category(trade_good) == TRADE_GOOD_CATEGORY.GOOD then
			local old = DATA.realm_get_resources(realm_id, trade_good)
			DATA.realm_set_resources(realm_id, trade_good, old * 0.99)
		end
	end)

	-- Stockpiles' waste in provinces
	-- Siphon some goods from realm stockpile to provincial storage

	DATA.for_each_realm_provinces_from_realm(realm_id, function (item)
		local province_id = DATA.realm_provinces_get_province(item)
		local province = DATA.fatten_province(province_id)


		-- diffuse wealth
		local neighbor_count = 0
		DATA.for_each_province_neighborhood_from_origin(province_id, function (item)
			local neighbor_id = DATA.province_neighborhood_get_target(item)
			local neighbor_realm = province_utils.realm(neighbor_id)
			if neighbor_realm ~= INVALID_ID then
				neighbor_count = neighbor_count + 1
			end
		end)


		if neighbor_count > 0 then
			local sharing_trade_wealth = province.trade_wealth * NEIGHBOURS_WEALTH_SHARING / neighbor_count
			local sharing_local_wealth = province.local_wealth * NEIGHBOURS_WEALTH_SHARING / neighbor_count
			DATA.for_each_province_neighborhood_from_origin(province_id, function (neighbourhood)
				local neighbor_id = DATA.province_neighborhood_get_target(neighbourhood)
				local neighbor_realm = province_utils.realm(neighbor_id)
				local neighbor = DATA.fatten_province(neighbor_id)

				if neighbor_realm ~= INVALID_ID then
					economic_effects.change_local_wealth(
						province_id,
						-sharing_local_wealth,
						ECONOMY_REASON.NEIGHBOR_SIPHON
					)
					economic_effects.change_local_wealth(
						neighbor_id,
						sharing_local_wealth,
						ECONOMY_REASON.NEIGHBOR_SIPHON
					)

					province.trade_wealth = province.trade_wealth - sharing_trade_wealth
					neighbor.trade_wealth = neighbor.trade_wealth + sharing_trade_wealth
				end
			end)
		end

		if neighbor_count > 0 then
			DATA.for_each_trade_good(function (trade_good)
				local category = DATA.trade_good_get_category(trade_good)
				if category == TRADE_GOOD_CATEGORY.GOOD then
					-- share some goods and wealth with neighbours
					-- actual goal is to smooth out economy in space a bit
					-- until addition of properly working "trade routes"

					local local_stockpile = DATA.province_get_local_storage(province_id, trade_good)

					local sharing = local_stockpile * NEIGHBOURS_GOODS_SHARING
					economic_effects.change_local_stockpile(province_id, trade_good, -sharing)
					local neighbor_share = sharing / neighbor_count
					DATA.for_each_province_neighborhood_from_origin(province_id, function (neighbourhood)
						local neighbor_id = DATA.province_neighborhood_get_target(neighbourhood)
						local neighbor_realm = province_utils.realm(neighbor_id)
						if neighbor_realm ~= INVALID_ID then
							economic_effects.change_local_stockpile(neighbor_id, trade_good, neighbor_share)
						end
					end)
				end
			end)
		end

		DATA.for_each_trade_good(function (trade_good)
			local category = DATA.trade_good_get_category(trade_good)
			if category == TRADE_GOOD_CATEGORY.GOOD then
				-- decay local stockpiles
				economic_effects.decay_local_stockpile(province_id, trade_good)
			end
		end)
	end)

	-- decay realm stockpiles
	DATA.for_each_trade_good(function (trade_good)
		local category = DATA.trade_good_get_category(trade_good)
		if category == TRADE_GOOD_CATEGORY.GOOD then
			local amount = DATA.realm_get_resources(realm_id, trade_good)
			DATA.realm_set_resources(realm_id, trade_good, amount * 0.95)
		end
	end)

	-- price updates
	-- this fake price update is more harmful than helpful: sharing goods should provide similar effect already

	-- DATA.for_each_realm_provinces_from_realm(realm_id, function (item)
	-- 	local province_id = DATA.realm_provinces_get_province(item)

	-- 	DATA.for_each_trade_good(function(trade_good)
	-- 		local current_price = economic_values.get_local_price(province_id, trade_good)
	-- 		local supply = DATA.province_get_local_production(province_id, trade_good)
	-- 		local demand = DATA.province_get_local_demand(province_id, trade_good)
	-- 		local stockpile = DATA.province_get_local_storage(province_id, trade_good)

	-- 		local trade_volume = math.sqrt(demand + supply + stockpile) + 1
	-- 		local change_rate = math.sqrt(current_price)

	-- 		local balance = demand - supply

	-- 		local balance_power = 0
	-- 		if balance > 0.1 then
	-- 			balance_power = balance - 0.1
	-- 		elseif balance < 0 then
	-- 			balance_power = balance
	-- 		end

	-- 		if trade_volume > 0.1 then
	-- 			local inversed_price =  math.max(0, 1 / (current_price + 1) - 0.5)

	-- 			local average_price_neighbours = 0
	-- 			local neighbours = 0
	-- 			for _, neighbor in pairs(province.neighbors) do
	-- 				if neighbor.realm then
	-- 					neighbours = neighbours + 1
	-- 					average_price_neighbours = average_price_neighbours + economic_values.get_local_price(neighbor, trade_good)
	-- 				end
	-- 			end
	-- 			if neighbours > 0 then
	-- 				average_price_neighbours = average_price_neighbours / neighbours
	-- 			end

	-- 			local price_derivative =
	-- 				balance_power / trade_volume * PRICE_SIGNAL_PER_UNIT * change_rate
	-- 				- stockpile / trade_volume * PRICE_SIGNAL_PER_STOCKPILED_UNIT * change_rate
	-- 				+ inversed_price / trade_volume * PRICE_SIGNAL_PER_UNIT
	-- 				+ average_price_neighbours - current_price


	-- 			-- if WORLD.player_character  then
	-- 			-- 	if WORLD.player_character.province == province then
	-- 			-- 		print(good_reference)
	-- 			-- 		print("current_price " .. current_price)
	-- 			-- 		print('sqrt_trade_volume: ' .. tostring(trade_volume))
	-- 			-- 		print("total price_change: " .. tostring(price_change + base_price_growth))
	-- 			-- 		print("demand supply price_change: " .. tostring((demand - supply) / trade_volume * PRICE_SIGNAL_PER_UNIT))
	-- 			-- 		print("base price growth " .. tostring(base_price_growth))
	-- 			-- 	end
	-- 			-- end

	-- 			if price_derivative ~= price_derivative or price_derivative == math.huge then
	-- 				error(
	-- 					"ERROR!"
	-- 					.. "\n good_reference"
	-- 					.. trade_good
	-- 					.. "\n price_derivative = "
	-- 					.. tostring(price_derivative)
	-- 					.. "\n change_rate = "
	-- 					.. tostring(change_rate)
	-- 					.. "\n current_price = "
	-- 					.. tostring(current_price)
	-- 					.. "\n supply = "
	-- 					.. tostring(supply)
	-- 					.. "\n demand = "
	-- 					.. tostring(demand)
	-- 					.. "\n stockpile = "
	-- 					.. tostring(stockpile)
	-- 					.. "\n trade_volume = "
	-- 					.. tostring(trade_volume)
	-- 					.. "\n balance_power / trade_volume * PRICE_SIGNAL_PER_UNIT * change_rate = "
	-- 					.. tostring(balance_power / trade_volume * PRICE_SIGNAL_PER_UNIT * change_rate)
	-- 					.. "\n stockpile / trade_volume * PRICE_SIGNAL_PER_STOCKPILED_UNIT * change_rate"
	-- 					.. tostring(stockpile / trade_volume * PRICE_SIGNAL_PER_STOCKPILED_UNIT * change_rate)
	-- 					.. "\n inversed_price / trade_volume * PRICE_SIGNAL_PER_UNIT"
	-- 					.. tostring(inversed_price / trade_volume * PRICE_SIGNAL_PER_UNIT)
	-- 					.. "\n (average_price_neighbours - current_price)"
	-- 					.. tostring(average_price_neighbours - current_price)
	-- 				)
	-- 			end

	-- 			economic_effects.change_local_price(province, trade_good, price_derivative * INTEGRATION_STEP)
	-- 		end
	-- 	end)
	-- end

	-- #############################
	-- ## ACTIVE MONTHLY SPENDING ##
	-- #############################

	-- calculate wealth we are able to siphon from treasury
	local treasury_siphon = realm.budget_treasury_target - realm.budget_treasury
	-- if it's negative, then we have excess money in treasury! can invest into montly budget
	if treasury_siphon < 0 then
		economic_effects.register_income(realm_id, -treasury_siphon, ECONOMY_REASON.TREASURY)
		economic_effects.change_treasury(realm_id, treasury_siphon, ECONOMY_REASON.BUDGET)
	end
	treasury_siphon = 0
	-- otherwise, we have to siphon wealth from our monthly income

	--- distribute income to budget categories
	local last_change = realm.budget_change

	-- update tribute ratio
	DATA.realm_set_budget_ratio(realm_id, BUDGET_CATEGORY.TRIBUTE, 0)
	local is_paying_tribute = false
	DATA.for_each_realm_subject_relation_from_subject(realm_id, function (item)
		if DATA.realm_subject_relation_get_wealth_transfer(realm_id) then
			is_paying_tribute = true
		end
	end)

	if is_paying_tribute then
		DATA.realm_set_budget_ratio(realm_id, BUDGET_CATEGORY.TRIBUTE, 0.1)
	end

	local total_ratio = 0
	DATA.for_each_budget_category(function (item)
		total_ratio = total_ratio + DATA.realm_get_budget_ratio(realm_id, item)
	end)

	local treasury_ratio = 1 - total_ratio

	DATA.for_each_budget_category(function (item)
		local ratio = DATA.realm_get_budget_ratio(realm_id, item)
		DATA.realm_inc_budget_to_be_invested(realm_id, item, last_change * ratio)
	end)

	-- send/siphon the rest to/from treasury
	local treasury_investment = last_change * treasury_ratio
	economic_effects.change_treasury(realm_id, treasury_investment, ECONOMY_REASON.MONTHLY_CHANGE)

	-- Handle infrastructure investments
	local total_infrastructure_needed = 0
	local total_infrastructure_invested = 0

	DATA.for_each_realm_provinces_from_realm(realm_id, function (item)
		local province_id = DATA.realm_provinces_get_province(item)
		local province = DATA.fatten_province(province_id)
		total_infrastructure_needed = total_infrastructure_needed + province.infrastructure_needed
		total_infrastructure_invested = total_infrastructure_invested + province.infrastructure_investment
	end)

	DATA.realm_set_budget_target(realm_id, BUDGET_CATEGORY.INFRASTRUCTURE, total_infrastructure_needed)
	DATA.realm_set_budget_budget(realm_id, BUDGET_CATEGORY.INFRASTRUCTURE, total_infrastructure_invested)

	if total_infrastructure_needed > 0 then
		local invested_total = DATA.realm_get_budget_to_be_invested(realm_id, BUDGET_CATEGORY.INFRASTRUCTURE)
		local investment_current = invested_total * 0.5

		DATA.for_each_realm_provinces_from_realm(realm_id, function (item)
			local province_id = DATA.realm_provinces_get_province(item)
			local province = DATA.fatten_province(province_id)
			local province_ratio = province.infrastructure_needed / total_infrastructure_needed
			local invested = invested_total * province_ratio
			province.infrastructure_investment = province.infrastructure_investment + invested
		end)

		DATA.realm_inc_budget_to_be_invested(realm_id, BUDGET_CATEGORY.INFRASTRUCTURE, -investment_current)
	end

	-- #######################
	-- ## Military spending ##
	-- #######################
	DATA.for_each_realm_provinces_from_realm(realm_id, function (item)
		local province_id = DATA.realm_provinces_get_province(item)

		DATA.for_each_warband_location_from_location(province_id, function (location)
			local warband_id = DATA.warband_location_get_warband(location)
			local warband = DATA.fatten_warband(warband_id)

			if warband.treasury > warband.total_upkeep then
				warband.treasury = warband.treasury - warband.total_upkeep
				DATA.for_each_warband_unit_from_warband(warband_id, function (unit)
					local unit_type = DATA.warband_unit_get_type(unit)
					local upkeep = DATA.unit_type_get_upkeep(unit_type)
					local pop = DATA.warband_unit_get_unit(unit)
					economic_effects.add_pop_savings(pop, upkeep, ECONOMY_REASON.UPKEEP)
				end)
			else

			end
		end)
	end)

	-- spend and set military budget target based on capitol guard
	local military_upkeep = 0.0
	local guard = DATA.get_realm_guard_from_realm(realm_id)
	if guard ~= INVALID_ID then
		local warband = DATA.realm_guard_get_guard(guard)
		military_upkeep = warband_utils.predict_upkeep(warband)
		local budget = DATA.realm_get_budget_budget(realm_id, BUDGET_CATEGORY.MILITARY)
		local spendings = budget / 12
		DATA.warband_inc_treasury(warband, spendings)
		DATA.realm_inc_budget_budget(realm_id, BUDGET_CATEGORY.MILITARY, -spendings)
	end
	DATA.realm_set_budget_target(realm_id, BUDGET_CATEGORY.MILITARY, military_upkeep * 12)

	-- invest
	local military_investment = DATA.realm_get_budget_to_be_invested(realm_id, BUDGET_CATEGORY.MILITARY)* 0.1
	DATA.realm_inc_budget_to_be_invested(realm_id, BUDGET_CATEGORY.MILITARY, -military_investment)
	DATA.realm_inc_budget_budget(realm_id, BUDGET_CATEGORY.MILITARY, military_investment)

	-- decay
	local old_budget = DATA.realm_get_budget_budget(realm_id, BUDGET_CATEGORY.MILITARY)
	DATA.realm_set_budget_budget(realm_id, BUDGET_CATEGORY.MILITARY, old_budget * 0.99)


	-- #######################
	-- ## 		Tribute 	##
	-- #######################
	local tribute_collected = DATA.realm_get_budget_budget(realm_id, BUDGET_CATEGORY.TRIBUTE)
	local tribute_collected_this_update = DATA.realm_get_budget_to_be_invested(realm_id, BUDGET_CATEGORY.TRIBUTE)
	DATA.realm_set_budget_budget(
		realm_id,
		BUDGET_CATEGORY.TRIBUTE,
		tribute_collected * 0.99 + tribute_collected_this_update
	)
	DATA.realm_set_budget_to_be_invested(realm_id, BUDGET_CATEGORY.TRIBUTE, 0)


	-- "wealth decay" -- to prevent the AI from accidentally overstockpiling so much that the numbers overflow...
	local treasury = DATA.realm_get_budget_treasury(realm_id)
	local treasure_waste = treasury * 0.001
	economic_effects.register_spendings(realm_id, treasure_waste, ECONOMY_REASON.WASTE)

	local updated_last_change = DATA.realm_get_budget_change(realm_id)
	DATA.realm_set_budget_saved_change(realm_id, updated_last_change)
	DATA.realm_set_budget_change(realm_id, 0)
end

return rea
