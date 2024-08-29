local tabb = require "engine.table"

local ut = require "game.ui-utils"

local ev = require "game.raws.values.economical"
local et = require "game.raws.triggers.economy"

local EconomicEffects = {}

---@enum (exact) EconomicReason
EconomicEffects.reasons = {
	BasicNeeds = "basic needs",
	Welfare = "welfare",
	Raid = "raid",
	Donation = "donation",
	MonthlyChange = "monthly change",
	YearlyChange = "yearly change",
	Infrastructure = "infrastructure",
	Education = "education",
	Court = "court",
	Military = "military",
	Exploration = "exploration",
	Upkeep = "upkeep",
	NewMonth = "new month",
	LoyaltyGift = "loyalty gift",
	Building = "building",
	BuildingIncome = "building income",
	Treasury = "treasury",
	Budget = "budget",
	Waste = "waste",
	Tribute = "tribute",
	Inheritance = "inheritance",
	Trade = "trade",
	Warband = "warband",
	Water = "water",
	Food = "food",
	OtherNeeds = "other needs",
	Forage = "forage",
	Work = "work",
	Other = "other",
	Siphon = "siphon",
	TradeSiphon = "trade siphon",
	Quest = "quest",
	NeighborSiphon = "neigbour siphon",
	Colonisation = "colonisation",
	Tax = "tax",
	Negotiations = "negotiations"
}

---Change realm treasury and display effects to player
---@param realm Realm
---@param x number
---@param reason EconomicReason
function EconomicEffects.change_treasury(realm, x, reason)
	realm.budget.treasury = realm.budget.treasury + x
	if realm.budget.treasury_change_by_category[reason] == nil then
		realm.budget.treasury_change_by_category[reason] = 0
	end
	realm.budget.treasury_change_by_category[reason] = realm.budget.treasury_change_by_category[reason] + x

	if reason == EconomicEffects.reasons.Tax and x > 0 then
		realm.tax_collected_this_year = realm.tax_collected_this_year + x
	end

	EconomicEffects.display_treasury_change(realm, x, reason)
end

---Register budget incomes and display them
---@param realm Realm
---@param x number
---@param reason EconomicReason
function EconomicEffects.register_income(realm, x, reason)
	realm.budget.change = realm.budget.change + x
	if realm.budget.income_by_category[reason] == nil then
		realm.budget.income_by_category[reason] = 0
	end

	if reason == EconomicEffects.reasons.Tax and x > 0 then
		realm.tax_collected_this_year = realm.tax_collected_this_year + x
	end

	realm.budget.income_by_category[reason] = realm.budget.income_by_category[reason] + x
	EconomicEffects.display_treasury_change(realm, x, reason)
end

---Register budget spendings and display them
---@param realm Realm
---@param x number
---@param reason EconomicReason
function EconomicEffects.register_spendings(realm, x, reason)
	if realm.budget.spending_by_category[reason] == nil then
		realm.budget.spending_by_category[reason] = 0
	end
	realm.budget.spending_by_category[reason] = realm.budget.spending_by_category[reason] + x
	EconomicEffects.display_treasury_change(realm, -x, reason)
end

---Change pop savings and display effects to player
---@param pop pop_id
---@param x number
---@param reason EconomicReason
function EconomicEffects.add_pop_savings(pop, x, reason)
	local savings = DATA.pop_get_savings(pop)
	DATA.pop_set_savings(pop, savings + x)

	if DATA.pop_get_savings(pop) ~= DATA.pop_get_savings(pop) then
		error("BAD POP SAVINGS INCREASE: " .. tostring(x) .. " " .. reason)
	end

	if math.abs(x) > 0 then
		EconomicEffects.display_character_savings_change(pop, x, reason)
	end
end

function EconomicEffects.display_character_savings_change(pop, x, reason)
	if WORLD.player_character == pop then
		WORLD:emit_treasury_change_effect(x, reason, true)
	end
end

function EconomicEffects.display_treasury_change(realm, x, reason)
	if WORLD:does_player_control_realm(realm) then
		WORLD:emit_treasury_change_effect(x, reason)
	end
end

---comment
---@param realm Realm
---@param x number
function EconomicEffects.set_education_budget(realm, x)
	realm.budget.education.ratio = x
end

---@param realm Realm
---@param x number
function EconomicEffects.set_court_budget(realm, x)
	realm.budget.court.ratio = x
end

---@param realm Realm
---@param x number
function EconomicEffects.set_infrastructure_budget(realm, x)
	realm.budget.infrastructure.ratio = x
end

---@param realm Realm
---@param x number
function EconomicEffects.set_military_budget(realm, x)
	realm.budget.military.ratio = x
end

---comment
---@param budget BudgetCategory
---@param x number
function EconomicEffects.set_budget(budget, x)
	budget.ratio = math.max(0, x)
end

---Directly inject money from treasury to budget category
---@param realm Realm
---@param budget_category BudgetCategory
---@param x number
---@param reason EconomicReason
function EconomicEffects.direct_investment(realm, budget_category, x, reason)
	EconomicEffects.change_treasury(realm, -x, reason)
	budget_category.budget = budget_category.budget + x
end

--- Directly injects money to province infrastructure
---@param realm Realm
---@param province province_id
---@param x number
function EconomicEffects.direct_investment_infrastructure(realm, province, x)
	EconomicEffects.change_treasury(realm, -x, EconomicEffects.reasons.Infrastructure)
	local current = DATA.province_get_infrastructure_investment(province)
	DATA.province_set_infrastructure_investment(province, current + x)
end

---commenting
---@param province province_id
---@param x number
---@param reason EconomicReason
function EconomicEffects.change_local_wealth(province, x, reason)
	local current = DATA.province_get_local_wealth(province)

	if current ~= current or x ~= x
	then
		error("NAN LOCAL WEALTH CHANGE"
			.. "\n province.name: "
			.. tostring(DATA.province_get_name(province))
			.. "\n x: "
			.. tostring(x)
			.. "\n reason: "
			.. tostring(reason)
			.. "\n province.local_wealth: "
			.. tostring(current)
		)
	end

	DATA.province_set_local_wealth(province, current + x)
end

---comment
---@param building Building
---@param pop POP?
function EconomicEffects.set_ownership(building, pop)
	building.owner = pop

	if pop then
		pop.owned_buildings[building] = building
	end

	if pop and WORLD:does_player_see_province_news(building.province) then
		if WORLD.player_character == pop then
			WORLD:emit_notification(building.type.name .. " is now owned by me, " .. pop.name .. ".")
		else
			WORLD:emit_notification(building.type.name .. " is now owned by " .. pop.name .. ".")
		end
	end
end

---@param building Building
function EconomicEffects.unset_ownership(building)
	local owner = building.owner

	if owner == nil then
		return
	end

	owner.owned_buildings[building] = nil

	if WORLD:does_player_see_province_news(owner.province) then
		if WORLD.player_character == owner then
			WORLD:emit_notification(building.type.name .. " is no longer owned by me, " .. owner.name .. ".")
		else
			WORLD:emit_notification(building.type.name .. " is no longer owned by " .. owner.name .. ".")
		end
	end
end

---comment
---@param building_type BuildingType
---@param province province_id
---@param owner POP?
---@return Building
function EconomicEffects.construct_building(building_type, province, owner)
	local Building = require "game.entities.building".Building
	local result_building = Building:new(province, building_type)
	EconomicEffects.set_ownership(result_building, owner)

	if WORLD:does_player_see_province_news(province) then
		WORLD:emit_notification(building_type.name .. " was constructed in " .. province.name .. ".")
	end
	return result_building
end

---comment
---@param building Building
function EconomicEffects.destroy_building(building)
	EconomicEffects.unset_ownership(building)
	building:remove_from_province()
end

---comment
---@param building_type BuildingType
---@param province province_id
---@param owner POP?
---@param overseer POP?
---@param public boolean
---@return Building
function EconomicEffects.construct_building_with_payment(building_type, province, owner, overseer, public)
	local construction_cost = ev.building_cost(building_type, overseer, public)
	local building = EconomicEffects.construct_building(building_type, province, owner)

	if public or (owner == nil) then
		EconomicEffects.change_treasury(province.realm, -construction_cost, EconomicEffects.reasons.Building)
	else
		EconomicEffects.add_pop_savings(owner, -construction_cost, EconomicEffects.reasons.Building)
	end

	return building
end

---character collects tribute into his pocket and returns collected value
---@param collector Character
---@param realm Realm
---@return number
function EconomicEffects.collect_tribute(collector, realm)
	local tribute_amount = math.min(10, math.floor(realm.budget.tribute.budget))

	if WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification("Tribute collector had arrived. Another day of humiliation. " ..
			tribute_amount .. MONEY_SYMBOL .. " were collected.")
	end

	EconomicEffects.register_spendings(realm, tribute_amount, EconomicEffects.reasons.Tribute)
	realm.budget.tribute.budget = realm.budget.tribute.budget - tribute_amount

	EconomicEffects.add_pop_savings(collector, tribute_amount, EconomicEffects.reasons.Tribute)

	return tribute_amount
end

---@param collector Character
---@param realm Realm
---@param tribute number
function EconomicEffects.return_tribute_home(collector, realm, tribute)
	local payment_multiplier = 0.1

	for i = 0, MAX_TRAIT_INDEX do
		local trait = DATA.pop_get_traits(collector, i)
		if trait == TRAIT.GREEDY then
			payment_multiplier = payment_multiplier * 5
		end
	end

	local payment = tribute * payment_multiplier
	local to_treasury = tribute - payment

	if WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification("Tribute collector had arrived back. He brought back " ..
			to_treasury .. MONEY_SYMBOL .. " wealth.")
	end

	EconomicEffects.register_income(realm, to_treasury, EconomicEffects.reasons.Tribute)
	EconomicEffects.add_pop_savings(collector, -to_treasury, EconomicEffects.reasons.Tribute)
end

---comment
---@param province province_id
---@param good trade_good_id
---@param x number
function EconomicEffects.change_local_price(province, good, x)
	local current_price = DATA.province_get_local_prices(province, good)
	DATA.province_set_local_prices(province, good, math.max(0.001, current_price + x))

	if current_price ~= current_price or current_price == math.huge or x ~= x then
		error(
			"INVALID PRICE CHANGE"
			.. "\n change = "
			.. tostring(x)
		)
	end
end

---comment
---@param province province_id
---@param good trade_good_id
---@param x number
function EconomicEffects.change_local_stockpile(province, good, x)
	local current_stockpile = DATA.province_get_local_storage(province, good)
	if x < 0 and current_stockpile + 0.01 < -x then
		error(
			"INVALID LOCAL STOCKPILE CHANGE"
			.. "\n change = "
			.. tostring(x)
			.. "\n province.local_storage[ ['" .. DATA.trade_good_get_name(good) .. "'] = "
			.. tostring(current_stockpile)
		)
	end
	if x ~= x or current_stockpile ~= current_stockpile then
		error(
			"NAN IN LOCAL STOCKPILE CHANGE"
			.. "\n change = "
			.. tostring(x)
		)
	end

	DATA.province_set_local_storage(province, good, current_stockpile + x)

end

---comment
---@param province province_id
---@param good trade_good_id
function EconomicEffects.decay_local_stockpile(province, good)
	local current_stockpile = DATA.province_get_local_storage(province, good)
	DATA.province_set_local_storage(province, good, current_stockpile * 0.85)
end

---comment
---@param character Character
---@param good trade_good_id
---@param amount number
function EconomicEffects.buy(character, good, amount)
	local can_buy, _ = et.can_buy(character, good, amount)
	if not can_buy then
		return false
	end

	-- can_buy validates province

	local province = DATA.character_location_get_location(DATA.get_character_location_from_character(character))

	local price = ev.get_local_price(province, good)

	local price_memory = DATA.pop_get_price_memory(character, good)

	if price_memory == 0 then
		DATA.pop_set_price_memory(character, good, price)
	else
		DATA.pop_set_price_memory(character, good, price_memory * (3 / 4) + price * (1 / 4))
	end

	local cost = price * amount

	if cost ~= cost then
		error(
			"WRONG BUY OPERATION "
			.. "\n price = "
			.. tostring(price)
			.. "\n amount = "
			.. tostring(amount)
		)
	end

	EconomicEffects.add_pop_savings(character, -cost, EconomicEffects.reasons.Trade)

	local trade_wealth = DATA.province_get_trade_wealth(province)
	DATA.province_set_trade_wealth(province, trade_wealth + cost)

	local inventory = DATA.pop_get_inventory(character, good)
	DATA.pop_set_inventory(character, good, inventory + amount)

	EconomicEffects.change_local_stockpile(province, good, -amount)

	local trade_volume =
		DATA.province_get_local_consumption(province, good)
		+ DATA.province_get_local_production(province, good)
		+ amount

	local price_change = amount / trade_volume * PRICE_SIGNAL_PER_STOCKPILED_UNIT * price

	EconomicEffects.change_local_price(province, good, price_change)

	-- print('!!! BUY')

	if WORLD:does_player_see_province_news(province) then
		WORLD:emit_notification("Trader " ..
			character.name .. " bought " .. amount .. " " .. good .. " for " .. ut.to_fixed_point2(cost) .. MONEY_SYMBOL)
	end

	return true
end

---Returns available units for satisfying a use case from pop inventory or realm resources
---@param pop pop_id
---@param use_case use_case_id
---@return number
function EconomicEffects.available_use_case_from_inventory(pop, use_case)
	local supply = tabb.accumulate(DATA.use_weight_from_use_case[use_case], 0, function(a, _, weight_id)
		local good = DATA.use_weight_get_trade_good(weight_id)
		local weight = DATA.use_weight_get_weight(weight_id)
		local good_in_inventory = inventory[good] or 0
		if good_in_inventory > 0 then
			a = a + good_in_inventory * weight
		end
		return a
	end)
	return supply
end

--- Consumes up to amount of use case from inventory in equal parts to available.
--- Returns total amount able to be satisfied.
---@param pop pop_id
---@param use_case use_case_id
---@param amount number
---@return number consumed
function EconomicEffects.consume_use_case_from_inventory(pop, use_case, amount)
	local supply = EconomicEffects.available_use_case_from_inventory(inventory, use_case)
	if supply < amount then
		error("NOT ENOUGH IN INVENTORY: "
			.. "\n supply = "
			.. tostring(supply)
			.. "\n amount = "
			.. tostring(amount))
	end
	local consumed = tabb.accumulate(DATA.use_weight_from_use_case[use_case], 0, function(a, _, weight_id)
		local good = DATA.use_weight_get_trade_good(weight_id)
		local weight = DATA.use_weight_get_weight(weight_id)
		local good_in_inventory = inventory[good] or 0
		if good_in_inventory > 0 then
			local available = good_in_inventory * weight
			local satisfied = available / supply * amount
			local used = satisfied / weight
			if satisfied > available + 0.01
				or used > good_in_inventory + 0.01
			then
				error("CONSUMED TOO MUCH FROM INVENTORY"
					.. "\n good_in_inventory = "
					.. tostring(good_in_inventory)
					.. "\n weight = "
					.. tostring(weight)
					.. "\n available = "
					.. tostring(available)
					.. "\n satisfied = "
					.. tostring(satisfied)
					.. "\n supply = "
					.. tostring(supply)
					.. "\n amount = "
					.. tostring(amount)
					.. "\n used = "
					.. tostring(used)
				)
			end
			inventory[good] = math.max(0, inventory[good] - used)
			a = a + satisfied
		end
		return a
	end)

	if consumed > amount + 0.01 then
		error("CONSUMED TOO MUCH: "
			.. "\n consumed = "
			.. tostring(consumed)
			.. "\n amount = "
			.. tostring(amount))
	end

	return consumed
end

---comment
---@param character Character
---@param use use_case_id
---@param amount number
function EconomicEffects.character_buy_use(character, use, amount)
	local can_buy, _ = et.can_buy_use(character.province, character.savings, use, amount)
	if not can_buy then
		return false
	end

	-- can_buy validates province
	---@type province_id
	local province = character.province
	local price = ev.get_local_price_of_use(province, use)

	local cost = price * amount

	if cost ~= cost then
		error(
			"WRONG BUY OPERATION "
			.. "\n price = "
			.. tostring(price)
			.. "\n amount = "
			.. tostring(amount)
		)
	end

	local price_expectation = ev.get_local_price_of_use(province, use)
	local use_available = ev.get_local_amount_of_use(province, use)

	local total_bought = 0
	local spendings = 0

	---@type {good: trade_good_id, weight: number, price: number, available: number}[]
	local goods = {}
	for _, weight_id in pairs(DATA.use_weight_from_use_case[use]) do
		local good = DATA.use_weight_get_trade_good(weight_id)
		local weight = DATA.use_weight_get_weight(weight_id)
		local good_price = ev.get_local_price(province, good)
		if character.price_memory[good] == nil then
			character.price_memory[good] = good_price
		else
			character.price_memory[good] = character.price_memory[good] * (3 / 4) + good_price * (1 / 4)
		end
		local goods_available = province.local_storage[good] or 0
		if goods_available > 0 then
			goods[#goods + 1] = { good = good, weight = weight, price = good_price, available = goods_available }
		end
	end
	for _, values in pairs(goods) do
		local good_use_amount = values.available * values.weight
		local goods_available_weight = math.max(good_use_amount / use_available, 0)
		local consumed_amount = amount / values.weight * goods_available_weight

		if goods_available_weight ~= goods_available_weight
			or consumed_amount ~= consumed_amount
		then
			error("CHARACTER BUY USE CALCULATED AMOUNT IS NAN"
				.. "\n use = "
				.. tostring(use)
				.. "\n use_available = "
				.. tostring(use_available)
				.. "\n good = "
				.. tostring(values.good)
				.. "\n good_price = "
				.. tostring(values.price)
				.. "\n goods_available = "
				.. tostring(values.available)
				.. "\n good_use_amount = "
				.. tostring(good_use_amount)
				.. "\n good use weight = "
				.. tostring(values.weight)
				.. "\n goods_available_weight = "
				.. tostring(goods_available_weight)
				.. "\n consumed_amount = "
				.. tostring(consumed_amount)
				.. "\n amount = "
				.. tostring(amount)
			)
		end

		-- we need to get back to use "units" so we multiplay consumed amount back by weight
		total_bought = total_bought + consumed_amount * values.weight

		local costs = consumed_amount * values.price
		spendings = spendings + costs

		--MAKE TRANSACTION
		province.trade_wealth = province.trade_wealth + costs
		character.inventory[values.good] = (character.inventory[values.good] or 0) + amount

		EconomicEffects.change_local_stockpile(province, values.good, -consumed_amount)

		local trade_volume = (province.local_consumption[values.good] or 0) +
			(province.local_production[values.good] or 0) + consumed_amount
		local price_change = consumed_amount / trade_volume * PRICE_SIGNAL_PER_STOCKPILED_UNIT * values.price

		EconomicEffects.change_local_price(province, values.good, price_change)
	end
	if total_bought < amount - 0.01
		or total_bought > amount + 0.01
	then
		error("INVALID CHARACTER BUY USE ATTEMPT"
			.. "\n use = "
			.. tostring(use)
			.. "\n spendings = "
			.. tostring(spendings)
			.. "\n total_bought = "
			.. tostring(total_bought)
			.. "\n amount = "
			.. tostring(amount)
			.. "\n price_expectation = "
			.. tostring(price_expectation)
			.. "\n use_available = "
			.. tostring(use_available)
		)
	end

	EconomicEffects.add_pop_savings(character, -spendings, EconomicEffects.reasons.Trade)

	if WORLD:does_player_see_province_news(province) then
		WORLD:emit_notification("Trader " ..
			character.name ..
			" bought " .. amount .. " " .. use .. " for " .. ut.to_fixed_point2(spendings) .. MONEY_SYMBOL)
	end
end

---comment
---@param realm Realm
---@param use trade_good_id
---@param amount number
function EconomicEffects.realm_buy_use(realm, use, amount)
	local can_buy, _ = et.can_buy_use(realm.capitol, realm.budget.treasury, use, amount)
	if not can_buy then
		return false
	end

	local use_case = require "game.raws.raws-utils".trade_good_use_case(use)

	-- can_buy validates province
	---@type province_id
	local province = realm.capitol
	local price = ev.get_local_price_of_use(province, use)

	local cost = price * amount

	if cost ~= cost then
		error(
			"WRONG BUY OPERATION "
			.. "\n price = "
			.. tostring(price)
			.. "\n amount = "
			.. tostring(amount)
		)
	end

	local price_expectation = ev.get_local_price_of_use(province, use)
	local use_available = ev.get_local_amount_of_use(province, use)

	local total_bought = 0
	local spendings = 0

	---@type {good: trade_good_id, weight: number, price: number, available: number}[]
	local goods = {}
	for _, weight_id in pairs(DATA.use_weight_from_use_case[use]) do
		local good = DATA.use_weight_get_trade_good(weight_id)
		local weight = DATA.use_weight_get_weight(weight_id)
		local good_price = ev.get_local_price(province, good)
		local goods_available = province.local_storage[good] or 0
		if goods_available > 0 then
			goods[#goods + 1] = { good = good, weight = weight, price = good_price, available = goods_available }
		end
	end
	for _, values in pairs(goods) do
		local good_use_amount = values.available * values.weight
		local goods_available_weight = math.max(good_use_amount / use_available, 0)
		local consumed_amount = amount / values.weight * goods_available_weight

		if goods_available_weight ~= goods_available_weight
			or consumed_amount ~= consumed_amount
		then
			error("REALM BUY USE CALCULATED AMOUNT IS NAN"
				.. "\n use = "
				.. tostring(use)
				.. "\n use_available = "
				.. tostring(use_available)
				.. "\n good = "
				.. tostring(values.good)
				.. "\n good_price = "
				.. tostring(values.price)
				.. "\n goods_available = "
				.. tostring(values.available)
				.. "\n good_use_amount = "
				.. tostring(good_use_amount)
				.. "\n good use weight = "
				.. tostring(values.weight)
				.. "\n goods_available_weight = "
				.. tostring(goods_available_weight)
				.. "\n consumed_amount = "
				.. tostring(consumed_amount)
				.. "\n amount = "
				.. tostring(amount)
			)
		end

		-- we need to get back to use "units" so we multiplay consumed amount back by weight
		total_bought = total_bought + consumed_amount * values.weight

		local costs = consumed_amount * values.price
		spendings = spendings + costs

		--MAKE TRANSACTION
		province.trade_wealth = province.trade_wealth + costs
		realm.resources[values.good] = (realm.resources[values.good] or 0) + amount

		EconomicEffects.change_local_stockpile(province, values.good, -amount)

		local trade_volume = (province.local_consumption[values.good] or 0) +
			(province.local_production[values.good] or 0) + amount
		local price_change = amount / trade_volume * PRICE_SIGNAL_PER_STOCKPILED_UNIT * values.price

		EconomicEffects.change_local_price(province, values.good, price_change)
	end
	if total_bought < amount - 0.01
		or total_bought > amount + 0.01
	then
		error("INVALID REALM BUY USE ATTEMPT"
			.. "\n use = "
			.. tostring(use)
			.. "\n spendings = "
			.. tostring(spendings)
			.. "\n total_bought = "
			.. tostring(total_bought)
			.. "\n amount = "
			.. tostring(amount)
			.. "\n price_expectation = "
			.. tostring(price_expectation)
			.. "\n use_available = "
			.. tostring(use_available)
		)
	end

	EconomicEffects.change_treasury(realm, -spendings, EconomicEffects.reasons.Trade)

	if WORLD:does_player_see_province_news(province) then
		WORLD:emit_notification(realm.name .. " bought " .. amount .. " " .. use .. " for " .. ut.to_fixed_point2(spendings) .. MONEY_SYMBOL .. ".")
	end
end

---comment
---@param character Character
---@param good trade_good_id
---@param amount number
function EconomicEffects.sell(character, good, amount)
	local can_sell, _ = et.can_sell(character, good, amount)
	if not can_sell then
		return false
	end

	-- can_sell validates province
	---@type province_id
	local province = character.province
	local price = ev.get_pessimistic_local_price(province, good, amount, true)

	if character.price_memory[good] == nil then
		character.price_memory[good] = price
	else
		character.price_memory[good] = character.price_memory[good] * (3 / 4) + price * (1 / 4)
	end

	local cost = price * amount

	if cost ~= cost then
		error(
			"WRONG SELL OPERATION "
			.. "\n price = "
			.. tostring(price)
			.. "\n amount = "
			.. tostring(amount)
		)
	end

	EconomicEffects.add_pop_savings(character, cost, EconomicEffects.reasons.Trade)
	province.trade_wealth = province.trade_wealth - cost
	character.inventory[good] = (character.inventory[good] or 0) - amount
	EconomicEffects.change_local_stockpile(province, good, amount)

	local trade_volume = (province.local_consumption[good] or 0) + (province.local_production[good] or 0) + amount
	local price_change = amount / trade_volume * PRICE_SIGNAL_PER_STOCKPILED_UNIT * price
	EconomicEffects.change_local_price(province, good, -price_change)

	-- print('!!! SELL')

	if WORLD:does_player_see_province_news(province) then
		WORLD:emit_notification("Trader " ..
			character.name .. " sold " .. amount .. " " .. good .. " for " .. ut.to_fixed_point2(cost) .. MONEY_SYMBOL)
	end
	return true
end

---comment
---@param character Character
---@param realm Realm
---@param amount number
function EconomicEffects.gift_to_tribe(character, realm, amount)
	if character.savings < amount then
		return
	end

	EconomicEffects.add_pop_savings(character, -amount, EconomicEffects.reasons.Donation)
	EconomicEffects.change_treasury(realm, amount, EconomicEffects.reasons.Donation)

	realm.capitol.mood = realm.capitol.mood + amount / realm.capitol:local_population() / 100
	character.popularity[realm] = (character.popularity[realm] or 0) +
		amount / (realm.capitol:local_population() + 1) / 100
end

---comment
---@param warband Warband
---@param character Character
---@param amount number
function EconomicEffects.gift_to_warband(warband, character, amount)
	if warband == nil then
		return
	end

	if amount > 0 then
		if character.savings < amount then
			amount = character.savings
		end
	else
		if warband.treasury < -amount then
			amount = warband.treasury
		end
	end

	EconomicEffects.add_pop_savings(character, -amount, EconomicEffects.reasons.Warband)
	warband.treasury = warband.treasury + amount
end

---commenting
---@param character Character
---@return number
function EconomicEffects.collect_tax(character)
	local total_tax = 0
	local tax_collection_ability = 0.05
	if character.traits[traits.HARDWORKER] then
		tax_collection_ability = tax_collection_ability + 0.01
	end
	if character.traits[traits.GREEDY] then
		tax_collection_ability = tax_collection_ability + 0.03
	end
	if character.traits[traits.LAZY] then
		tax_collection_ability = tax_collection_ability - 0.01
	end
	for _, pop in pairs(character.province.all_pops) do
		if pop.savings > 0 then
			total_tax = total_tax + pop.savings * tax_collection_ability
			EconomicEffects.add_pop_savings(pop, -pop.savings * tax_collection_ability, EconomicEffects.reasons.Tax)
		end
	end
	return total_tax
end

---Grants trading rights to character
---@param character Character
---@param realm Realm
function EconomicEffects.grant_trade_rights(character, realm)
	character.has_trade_permits_in[realm] = realm
	realm.trading_right_given_to[character] = character
end

---Clears all trading rights of character
---@param character Character
function EconomicEffects.abandon_trade_rights(character)
	---@type Realm[]
	local realms = {}

	for _, realm in pairs(character.has_trade_permits_in) do
		table.insert(realms, realm)
	end

	for _, realm in ipairs(realms) do
		character.has_trade_permits_in[realm] = nil
		realm.trading_right_given_to[character] = nil
	end
end

---Grants trading rights to character
---@param character Character
---@param realm Realm
function EconomicEffects.grant_building_rights(character, realm)
	character.has_building_permits_in[realm] = realm
	realm.building_right_given_to[character] = character
end

---Clears all trading rights of character
---@param character Character
function EconomicEffects.abandon_building_rights(character)
	---@type Realm[]
	local realms = {}

	for _, realm in pairs(character.has_building_permits_in) do
		table.insert(realms, realm)
	end

	for _, realm in ipairs(realms) do
		character.has_building_permits_in[realm] = nil
		realm.building_right_given_to[character] = nil
	end
end

return EconomicEffects
