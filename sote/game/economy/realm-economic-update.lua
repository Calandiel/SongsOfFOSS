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
	-- Loop over all provinces in the realm and "add" their good balances to get our balance.
	for _, province in pairs(realm.provinces) do
		for prod, amount in pairs(province.local_production) do
			--if prod.category == 'good' or prod.category == 'capacity' then
			local old = realm.production[prod] or 0
			realm.production[prod] = old + amount
			local vold = realm.sold[prod] or 0
			realm.sold[prod] = vold + amount
			--else
			-- Nothing to do, services aren't resolved per realm...
			-- Actually (!), let's keep track of them anyway so that we can store prices per realm
			--end
		end
		for prod, amount in pairs(province.local_consumption) do
			--if prod.category == 'good' or prod.category == 'capacity' then
			local old = realm.production[prod] or 0
			realm.production[prod] = old - amount
			local vold = realm.bought[prod] or 0
			realm.bought[prod] = vold + amount -- a '+', even tho we're consuming, because this stands for volume
			--else
			-- Nothing to do, services aren't resolved per realm...
			-- Actually (!), let's keep track of them anyway so that we can store prices per realm
			--end
			if prod == RAWS_MANAGER.trade_goods_by_name['food'] then
				realm.expected_food_consumption = realm.expected_food_consumption + amount
			end
		end
	end

	-- Handle stockpiles of trade goods
	for resource_reference, amount in pairs(realm.production) do
		local resource = good(resource_reference)
		if resource.category == 'good' then
			local old = realm.resources[resource_reference] or 0
			realm.resources[resource_reference] = math.max(0, old + amount) * 0.999
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
	local treasury_ratio = 1 - budget.education.ratio - budget.court.ratio - budget.military.ratio - budget.infrastructure.ratio

	budget.education.to_be_invested 		= last_change * budget.education.ratio + budget.education.to_be_invested
	-- EconomicEffects.register_spendings(realm, last_change * budget.education.ratio, EconomicEffects.reasons.Infrastructure)

	budget.court.to_be_invested 			= last_change * budget.court.ratio + budget.court.to_be_invested
	-- EconomicEffects.register_spendings(realm, last_change * budget.court.ratio, EconomicEffects.reasons.Court)

	budget.military.to_be_invested 			= last_change * budget.military.ratio + budget.military.to_be_invested
	-- EconomicEffects.register_spendings(realm, last_change * budget.military.ratio, EconomicEffects.reasons.Military)

	budget.infrastructure.to_be_invested 	= last_change * budget.infrastructure.ratio + budget.infrastructure.to_be_invested
	-- EconomicEffects.register_spendings(realm, last_change * budget.infrastructure.ratio, EconomicEffects.reasons.Infrastructure)

	-- send the rest to treasury
	local treasury_investment = last_change * treasury_ratio
	EconomicEffects.change_treasury(realm, treasury_investment, EconomicEffects.reasons.MonthlyChange)


	-- Handle infrastructure investments
	local total_infrastructure_needed = 0
	for _, province in pairs(realm.provinces) do
		---@type number
		total_infrastructure_needed = total_infrastructure_needed + province.infrastructure_needed
	end
	realm.budget.infrastructure.target = total_infrastructure_needed
	if total_infrastructure_needed > 0 then
		local invested_total = budget.infrastructure.to_be_invested
		for _, province in pairs(realm.provinces) do
			local province_ratio = province.infrastructure_needed / province.infrastructure_needed
			local invested = invested_total * province_ratio
			province.infrastructure_investment = province.infrastructure_investment + invested
		end
		budget.infrastructure.to_be_invested = 0
	end

	-- #######################
	-- ## Military spending ##
	-- #######################
	local military_upkeep = 0
	for _, province in pairs(realm.provinces) do
		for unit, ta in pairs(province.units) do
			local count = tabb.size(ta)
			military_upkeep = military_upkeep + count * unit.upkeep
		end
	end

	-- target
	realm.budget.military.target = military_upkeep * 12

	-- invest
	local military_investment = budget.military.to_be_invested * 0.1
	budget.military.to_be_invested = budget.military.to_be_invested - military_investment
	realm.budget.military.budget = realm.budget.military.budget + military_investment

	-- spend
	realm.budget.military.budget = realm.budget.military.budget - military_upkeep
	


	-- "wealth decay" -- to prevent the AI from accidentally overstockpiling so much that the numbers overflow...
	local treasure_waste = realm.budget.treasury * 0.001
	EconomicEffects.register_spendings(realm, treasure_waste, EconomicEffects.reasons.Waste)

	realm.budget.saved_change = realm.budget.change
	realm.budget.change = 0
end

return rea
