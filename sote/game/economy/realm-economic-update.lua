local tabb = require "engine.table"
local good = require "game.raws.raws-utils".trade_good
local rea = {}

local economic_effects = require "game.raws.effects.economic"
local economic_values = require "game.raws.values.economical"


---@param realm Realm
function rea.prerun(realm)
	realm.budget.spending_by_category = {}
	realm.budget.income_by_category = {}
	realm.budget.treasury_change_by_category = {}
end

---@param realm Realm
function rea.run(realm)

	tabb.clear(realm.production)
	tabb.clear(realm.bought)
	tabb.clear(realm.sold)

	realm.expected_food_consumption = 0

	local PROVINCE_TO_REALM_STOCKPILE = 0.1
	local REALM_TO_PROVINCE_STOCKPILE = 0.05
	local NEIGHBOURS_GOODS_SHARING = 0.075
	local NEIGHBOURS_WEALTH_SHARING = 0.075 / 4

	local INTEGRATION_STEP = 1

	-- Loop over all provinces in the realm and "add" their good balances to get our balance.
	for _, province in pairs(realm.provinces) do
		for prod, amount in pairs(province.local_production) do
			local old = realm.production[prod] or 0
			realm.production[prod] = old + amount
			local vold = realm.sold[prod] or 0
			realm.sold[prod] = vold + amount

			local resource = good(prod)
			if resource.category == 'good' then
				economic_effects.change_local_stockpile(province, prod, amount)

				local to_realm_stockpile = amount * PROVINCE_TO_REALM_STOCKPILE
				economic_effects.change_local_stockpile(province, prod, -to_realm_stockpile)

				province.realm.resources[prod] = province.realm.resources[prod] or 0
				province.realm.resources[prod] = province.realm.resources[prod] + to_realm_stockpile
			end
		end
		for prod, amount in pairs(province.local_consumption) do
			local old = realm.production[prod] or 0
			realm.production[prod] = old - amount
			local vold = realm.bought[prod] or 0
			realm.bought[prod] = vold + amount -- a '+', even tho we're consuming, because this stands for volume
			if prod == 'food' then
				realm.expected_food_consumption = realm.expected_food_consumption + amount
			end

			local resource = good(prod)
			if resource.category == 'good' then
				economic_effects.change_local_stockpile(province, prod, -amount)
			end
		end
	end

	-- Handle stockpiles of trade goods in realm
	for resource_reference, amount in pairs(realm.resources) do
		local resource = good(resource_reference)
		if resource.category == 'good' then
			local old = amount or 0
			realm.resources[resource_reference] = math.max(0, old) * 0.99
		end
	end

	-- Stockpiles' waste in provinces
	-- Siphon some goods from realm stockpile to provincial storage
	local amount_of_provinces = tabb.size(realm.provinces)
	for _, province in pairs(realm.provinces) do
		-- diffuse wealth
		local sharing_trade_wealth = province.trade_wealth * NEIGHBOURS_WEALTH_SHARING
		local sharing_local_wealth = province.local_wealth * NEIGHBOURS_WEALTH_SHARING
		for _, neigbour in pairs(province.neighbors) do
			if neigbour.realm then
				economic_effects.change_local_wealth(
					province,
					-sharing_local_wealth,
					economic_effects.reasons.NeighborSiphon
				)
				economic_effects.change_local_wealth(
					neigbour,
					sharing_local_wealth,
					economic_effects.reasons.NeighborSiphon
				)

				province.trade_wealth = province.trade_wealth - sharing_trade_wealth
				neigbour.trade_wealth = neigbour.trade_wealth + sharing_trade_wealth
			end
		end

		for resource_reference, amount in pairs(province.local_storage) do
			local resource = good(resource_reference)
			if resource.category == 'good' then

				-- share some goods and wealth with neigbours
				-- actual goal is to smooth out economy in space a bit
				-- until addition of properly working "trade routes"
				local sharing = province.local_storage[resource_reference] * NEIGHBOURS_GOODS_SHARING

				for _, neigbour in pairs(province.neighbors) do
					if neigbour.realm then
						economic_effects.change_local_stockpile(province, resource_reference, -sharing)
						economic_effects.change_local_stockpile(neigbour, resource_reference, sharing)
					end
				end

				local old = amount or 0
				local siphon = (realm.resources[resource_reference] or 0)
				                * REALM_TO_PROVINCE_STOCKPILE
								/ amount_of_provinces

				-- decay local stockpiles
				economic_effects.decay_local_stockpile(province, resource_reference)

				-- siphon some goods from realm stockpile
				economic_effects.change_local_stockpile(province, resource_reference, siphon)
				realm.resources[resource_reference] = (realm.resources[resource_reference] or 0) - siphon
			end
		end
	end

	for resource_reference, amount in pairs(realm.resources) do
		realm.resources[resource_reference] = amount * 0.9
	end

	-- price updates
	for _, province in pairs(realm.provinces) do
		for good_reference, trade_good in pairs(RAWS_MANAGER.trade_goods_by_name) do
			local current_price = economic_values.get_local_price(province, good_reference)
			local supply = province.local_production[good_reference] or 0
			local demand = province.local_demand[good_reference] or 0
			local stockpile = province.local_storage[good_reference] or 0
			local trade_volume = math.sqrt(demand + supply + stockpile) + 1
			local change_rate = math.sqrt(current_price)

			local balance = demand - supply

			local balance_power = 0
			if balance > 0.1 then
				balance_power = balance - 0.1
			elseif balance < 0 then
				balance_power = balance
			end

			if trade_volume > 0.1 then
				local inversed_price =  math.max(0, 1 / (current_price + 1) - 0.5)

				local average_price_neighbours = 0
				local neighbours = 0
				for _, neigbour in pairs(province.neighbors) do
					if neigbour.realm then
						neighbours = neighbours + 1
						average_price_neighbours = average_price_neighbours + economic_values.get_local_price(neigbour, good_reference)
					end
				end
				if neighbours > 0 then
					average_price_neighbours = average_price_neighbours / neighbours
				end

				local price_derivative =
					balance_power / trade_volume * PRICE_SIGNAL_PER_UNIT * change_rate
					- stockpile / trade_volume * PRICE_SIGNAL_PER_STOCKPILED_UNIT * change_rate
					+ inversed_price * trade_good.base_price / trade_volume * PRICE_SIGNAL_PER_UNIT
					+ average_price_neighbours - current_price


				-- if WORLD.player_character  then
				-- 	if WORLD.player_character.province == province then
				-- 		print(good_reference)
				-- 		print("current_price " .. current_price)
				-- 		print('sqrt_trade_volume: ' .. tostring(trade_volume))
				-- 		print("total price_change: " .. tostring(price_change + base_price_growth))
				-- 		print("demand supply price_change: " .. tostring((demand - supply) / trade_volume * PRICE_SIGNAL_PER_UNIT))
				-- 		print("base price growth " .. tostring(base_price_growth))
				-- 	end
				-- end

				if price_derivative ~= price_derivative or price_derivative == math.huge then
					error(
						"ERROR!"
						.. "\n good_reference"
						.. good_reference
						.. "\n price_derivative = "
						.. tostring(price_derivative)
						.. "\n change_rate = "
						.. tostring(change_rate)
						.. "\n current_price = "
						.. tostring(current_price)
						.. "\n supply = "
						.. tostring(supply)
						.. "\n demand = "
						.. tostring(demand)
						.. "\n stockpile = "
						.. tostring(stockpile)
						.. "\n trade_volume = "
						.. tostring(trade_volume)
						.. "\n balance_power / trade_volume * PRICE_SIGNAL_PER_UNIT * change_rate = "
						.. tostring(balance_power / trade_volume * PRICE_SIGNAL_PER_UNIT * change_rate)
						.. "\n stockpile / trade_volume * PRICE_SIGNAL_PER_STOCKPILED_UNIT * change_rate"
						.. tostring(stockpile / trade_volume * PRICE_SIGNAL_PER_STOCKPILED_UNIT * change_rate)
						.. "\n inversed_price * trade_good.base_price / trade_volume * PRICE_SIGNAL_PER_UNIT"
						.. tostring(inversed_price * trade_good.base_price / trade_volume * PRICE_SIGNAL_PER_UNIT)
						.. "\n (average_price_neighbours - current_price)"
						.. tostring(average_price_neighbours - current_price)
					)
				end

				economic_effects.change_local_price(province, good_reference, price_derivative * INTEGRATION_STEP)
			end
		end
	end

	-- #############################
	-- ## ACTIVE MONTHLY SPENDING ##
	-- #############################
	local budget = realm.budget

	-- calculate wealth we are able to siphon from treasury
	local treasury_siphon = budget.treasury_target - budget.treasury
	-- if it's negative, then we have excess money in treasury! can invest into montly budget
	if treasury_siphon < 0 then
		economic_effects.register_income(realm, -treasury_siphon, economic_effects.reasons.Treasury)
		economic_effects.change_treasury(realm, treasury_siphon, economic_effects.reasons.Budget)
	end
	treasury_siphon = 0
	-- otherwise, we have to siphon wealth from our monthly income

	--- distribute income to budget categories
	local last_change = budget.change

	-- update tribute ratio
	budget.tribute.ratio = 0.0
	if tabb.size(realm.paying_tribute_to) > 0 then
		budget.tribute.ratio = 0.1
	end

	local total_ratio = budget.education.ratio
						+ budget.court.ratio
						+ budget.military.ratio
						+ budget.infrastructure.ratio
						+ budget.tribute.ratio

	local treasury_ratio = 1 - total_ratio


	budget.education.to_be_invested 		= last_change * budget.education.ratio 			+ budget.education.to_be_invested
	budget.court.to_be_invested 			= last_change * budget.court.ratio 				+ budget.court.to_be_invested
	budget.military.to_be_invested 			= last_change * budget.military.ratio 			+ budget.military.to_be_invested
	budget.infrastructure.to_be_invested 	= last_change * budget.infrastructure.ratio
	budget.tribute.to_be_invested 			= last_change * budget.tribute.ratio

	-- send/siphon the rest to/from treasury
	local treasury_investment = last_change * treasury_ratio
	economic_effects.change_treasury(realm, treasury_investment, economic_effects.reasons.MonthlyChange)


	-- Handle infrastructure investments
	local total_infrastructure_needed = 0
	local total_infrastructure_invested = 0
	for _, province in pairs(realm.provinces) do
		---@type number
		total_infrastructure_needed = total_infrastructure_needed + province.infrastructure_needed
		total_infrastructure_invested = total_infrastructure_invested + province.infrastructure_investment
	end
	realm.budget.infrastructure.target = total_infrastructure_needed
	realm.budget.infrastructure.budget = total_infrastructure_invested

	if total_infrastructure_needed > 0 then
		local invested_total = budget.infrastructure.to_be_invested
		for _, province in pairs(realm.provinces) do
			local province_ratio = province.infrastructure_needed / province.infrastructure_needed
			local invested = invested_total * province_ratio
			province.infrastructure_investment = province.infrastructure_investment + invested
		end
		-- budget.infrastructure.to_be_invested = 0
	end

	-- #######################
	-- ## Military spending ##
	-- #######################
	for _, province in pairs(realm.provinces) do
		for _, warband in pairs(province.warbands) do
			if warband.treasury > warband.total_upkeep then
				warband.treasury = warband.treasury - warband.total_upkeep
				for pop, unit in pairs(warband.units) do
					economic_effects.add_pop_savings(pop, unit.upkeep, economic_effects.reasons.Upkeep)
				end
			else

			end
		end
	end

	-- spend and set target based on capitol guard
	local military_upkeep = 0.0
	if realm.capitol_guard then
		military_upkeep = realm.capitol_guard:predict_upkeep()
		local spendings = realm.budget.military.budget / 12
		realm.capitol_guard.treasury = realm.capitol_guard.treasury + spendings
		realm.budget.military.budget = realm.budget.military.budget - spendings
	end

	realm.budget.military.target = military_upkeep * 12
	-- invest
	local military_investment = budget.military.to_be_invested * 0.1
	budget.military.to_be_invested = budget.military.to_be_invested - military_investment
	realm.budget.military.budget = realm.budget.military.budget + military_investment

	-- spend
	realm.budget.military.budget = realm.budget.military.budget - military_upkeep
	realm.budget.military.budget = realm.budget.military.budget * 0.99


	-- #######################
	-- ## 		Tribute 	##
	-- #######################
	budget.tribute.budget = budget.tribute.budget * 0.99 + budget.tribute.to_be_invested


	-- "wealth decay" -- to prevent the AI from accidentally overstockpiling so much that the numbers overflow...
	local treasure_waste = realm.budget.treasury * 0.001
	economic_effects.register_spendings(realm, treasure_waste, economic_effects.reasons.Waste)

	realm.budget.saved_change = realm.budget.change
	realm.budget.change = 0
end

return rea
