local tabb = require "engine.table"
local good = require "game.raws.raws-utils".trade_good
local rea = {}


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
	local NEIGHBOURS_GOODS_SHARING = 0.01

	-- Loop over all provinces in the realm and "add" their good balances to get our balance.
	for _, province in pairs(realm.provinces) do
		for prod, amount in pairs(province.local_production) do
			local old = realm.production[prod] or 0
			realm.production[prod] = old + amount
			local vold = realm.sold[prod] or 0
			realm.sold[prod] = vold + amount

			local resource = good(prod)
			if resource.category == 'good' then
				province.local_storage[prod] = province.local_storage[prod] or 0
				province.local_storage[prod] = province.local_storage[prod] + amount * (1 - PROVINCE_TO_REALM_STOCKPILE)

				province.realm.resources[prod] = province.realm.resources[prod] or 0
				province.realm.resources[prod] = province.realm.resources[prod] + amount * PROVINCE_TO_REALM_STOCKPILE


				local sharing = province.local_storage[prod] * NEIGHBOURS_GOODS_SHARING
				local random_neigbour = tabb.random_select_from_set(province.neighbors)

				if random_neigbour.realm then
					province.local_storage[prod] = province.local_storage[prod] - sharing
					random_neigbour.local_storage[prod] = (random_neigbour.local_storage[prod] or 0) + sharing
				end
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
				province.local_storage[prod] = province.local_storage[prod] or 0
				province.local_storage[prod] = province.local_storage[prod] - amount
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
		for resource_reference, amount in pairs(province.local_storage) do
			local resource = good(resource_reference)
			if resource.category == 'good' then
				local old = amount or 0
				local siphon = (realm.resources[resource_reference] or 0)
				                * REALM_TO_PROVINCE_STOCKPILE
								/ amount_of_provinces

				province.local_storage[resource_reference] = math.max(0, old + siphon) * 0.99
				realm.resources[resource_reference] = (realm.resources[resource_reference] or 0) - siphon
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
		EconomicEffects.register_income(realm, -treasury_siphon, EconomicEffects.reasons.Treasury)
		EconomicEffects.change_treasury(realm, treasury_siphon, EconomicEffects.reasons.Budget)
	end
	treasury_siphon = 0
	-- otherwise, we have to siphon wealth from our monthly income

	--- distribute income to budget categories
	local last_change = budget.change

	-- update tribute ratio
	budget.tribute.ratio = 0.0
	if tabb.size(realm.paying_tribute_to) == 0 then
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
	EconomicEffects.change_treasury(realm, treasury_investment, EconomicEffects.reasons.MonthlyChange)


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
			warband.treasury = warband.treasury - warband.total_upkeep
			province.local_wealth = province.local_wealth + warband.total_upkeep * 0.8
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
	EconomicEffects.register_spendings(realm, treasure_waste, EconomicEffects.reasons.Waste)

	realm.budget.saved_change = realm.budget.change
	realm.budget.change = 0
end

return rea
