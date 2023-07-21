local tabb = require "engine.table"
local rea = {}


---@param realm Realm
function rea.prerun(realm)
	realm.building_upkeep = 0
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
			if prod == WORLD.trade_goods_by_name['food'] then
				realm.expected_food_consumption = realm.expected_food_consumption + amount
			end
		end
	end

	-- Handle stockpiles of trade goods
	for resource, amount in pairs(realm.production) do
		if resource.category == 'good' then
			local old = realm.resources[resource] or 0
			realm.resources[resource] = math.max(0, old + amount) * 0.999
		end
	end

	-- #############################
	-- ## ACTIVE MONTHLY SPENDING ##
	-- #############################

	-- Handle infrastructure investments
	local total_infrastructure_needed = 0
	for _, province in pairs(realm.provinces) do
		total_infrastructure_needed = total_infrastructure_needed + province.infrastructure_needed
	end
	if total_infrastructure_needed > 0 then
		for _, province in pairs(realm.provinces) do
			local invested = realm.monthly_infrastructure_investment * province.infrastructure_needed /
				total_infrastructure_needed
			invested = math.min(invested, realm.treasury)
			province.infrastructure_investment = province.infrastructure_investment + invested
			EconomicEffects.add_treasury(realm, -invested, EconomicEffects.reasons.Infrastructure)
		end
	end

	-- Handle education investments
	local total_education_needed = realm.education_endowment_needed
	if total_education_needed > 0 then
		local invested = math.min(realm.monthly_education_investment, realm.treasury)
		realm.education_investment = realm.education_investment + invested
		EconomicEffects.add_treasury(realm, -invested, EconomicEffects.reasons.Education)
	end

	-- Handle court investments
	local total_court_needed = realm.court_wealth_needed
	if total_court_needed > 0 then
		local invested = math.min(realm.monthly_court_investment, realm.treasury)
		realm.court_investment = realm.court_investment + invested
		EconomicEffects.add_treasury(realm, -invested, EconomicEffects.reasons.Court)
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
	realm.military_spending = military_upkeep
	local mil_fulf = 1
	if realm.military_spending > 0 then
		mil_fulf = realm.treasury / realm.military_spending
	end
	realm.realized_military_spending = mil_fulf
	EconomicEffects.add_treasury(realm, -realm.military_spending, EconomicEffects.reasons.Military)

	-- "wealth decay" -- to prevent the AI from accidentally overstockpiling so much that the numbers overflow...
	realm.treasury_real_delta = realm.treasury - realm.old_treasury
	realm.old_treasury = realm.treasury
	realm.wasted_treasury = realm.treasury * 0.001
	realm.treasury = realm.treasury * 0.999
	realm.voluntary_contributions = realm.voluntary_contributions_accumulator
	realm.voluntary_contributions_accumulator = 0
end

return rea
