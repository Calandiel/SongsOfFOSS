local tabb = require "engine.table"

local ut = require "game.ui-utils"

local ev = require "game.raws.values.economy"
local et = require "game.raws.triggers.economy"

local building_utils = require "game.entities.building".Building
local pop_utils = require "game.entities.pop".POP
local province_utils = require "game.entities.province".Province
local warband_utils = require "game.entities.warband"

local EconomicEffects = {}

---consumes `days` worth amount of supplies
---@param warband warband_id
---@param days number
---@return number
function EconomicEffects.consume_supplies(warband, days)
	local daily_consumption = warband_utils.daily_supply_consumption(warband)
	local consumption = days * daily_consumption
	local leader = DATA.get_warband_leader_from_warband(warband)

	assert(leader ~= INVALID_ID, "ATTEMPT TO CONSUME SUPPLIES BY WARBAND WITHOUT LEADER")

	local consumed = EconomicEffects.consume_use_case_from_inventory(DATA.warband_leader_get_leader(leader), CALORIES_USE_CASE, consumption)

	-- give some wiggle room for floats
	if consumed > consumption + 0.01
		or consumed < consumption - 0.01 then
		error("CONSUMED WRONG AMOUNT. "
			.. "\n consumed = "
			.. tostring(consumed)
			.. "\n consumption = "
			.. tostring(consumption)
			.. "\n daily_consumption = "
			.. tostring(daily_consumption)
			.. "\n days = "
			.. tostring(days))
	end
	return consumed
end

---Change realm treasury and display effects to player
---@param realm Realm
---@param x number
---@param reason ECONOMY_REASON
function EconomicEffects.change_treasury(realm, x, reason)
	local fat_realm = DATA.fatten_realm(realm)
	fat_realm.budget_treasury = fat_realm.budget_treasury + x

	if reason == ECONOMY_REASON.TAX and x > 0 then
		fat_realm.budget_tax_collected_this_year = fat_realm.budget_tax_collected_this_year + x
	end

	DATA.realm_inc_budget_treasury_change_by_category(realm, reason, x)
	EconomicEffects.display_treasury_change(realm, x, reason)
end

---Register budget incomes and display them
---@param realm Realm
---@param x number
---@param reason ECONOMY_REASON
function EconomicEffects.register_income(realm, x, reason)
	local fat_realm = DATA.fatten_realm(realm)
	fat_realm.budget_change = fat_realm.budget_change + x

	if reason == ECONOMY_REASON.TAX and x > 0 then
		fat_realm.budget_tax_collected_this_year = fat_realm.budget_tax_collected_this_year + x
	end

	DATA.realm_inc_budget_income_by_category(realm, reason, x)
	EconomicEffects.display_treasury_change(realm, x, reason)
end

---Register budget spendings and display them
---DOES NOT ACTUALLY SPENDS MONEY
---@param realm Realm
---@param x number
---@param reason ECONOMY_REASON
function EconomicEffects.register_spendings(realm, x, reason)
	DATA.realm_inc_budget_spending_by_category(realm, reason, x)
	EconomicEffects.display_treasury_change(realm, -x, reason)
end

---Change pop savings and display effects to player
---@param pop pop_id
---@param x number
---@param reason ECONOMY_REASON
function EconomicEffects.add_pop_savings(pop, x, reason)
	DATA.pop_inc_savings(pop, x)

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
	DATA.realm_set_budget_ratio(realm, BUDGET_CATEGORY.EDUCATION, x)
end

---@param realm Realm
---@param x number
function EconomicEffects.set_court_budget(realm, x)
	DATA.realm_set_budget_ratio(realm, BUDGET_CATEGORY.COURT, x)
end

---@param realm Realm
---@param x number
function EconomicEffects.set_infrastructure_budget(realm, x)
	DATA.realm_set_budget_ratio(realm, BUDGET_CATEGORY.INFRASTRUCTURE, x)
end

---@param realm Realm
---@param x number
function EconomicEffects.set_military_budget(realm, x)
	DATA.realm_set_budget_ratio(realm, BUDGET_CATEGORY.MILITARY, x)
end

---comment
---@param realm realm_id
---@param category BUDGET_CATEGORY
---@param x number
function EconomicEffects.set_budget(realm, category, x)
	DATA.realm_set_budget_ratio(realm, category, x)
end

---Directly inject money from treasury to budget category
---@param realm Realm
---@param category BUDGET_CATEGORY
---@param x number
---@param reason ECONOMY_REASON
function EconomicEffects.direct_investment(realm, category, x, reason)
	EconomicEffects.change_treasury(realm, -x, reason)
	DATA.realm_inc_budget_budget(realm, category, x)
end

--- Directly injects money to province infrastructure
---@param realm Realm
---@param province province_id
---@param x number
function EconomicEffects.direct_investment_infrastructure(realm, province, x)
	EconomicEffects.change_treasury(realm, -x, ECONOMY_REASON.INFRASTRUCTURE)
	local current = DATA.province_get_infrastructure_investment(province)
	DATA.province_set_infrastructure_investment(province, current + x)
end

---commenting
---@param province province_id
---@param x number
---@param reason ECONOMY_REASON
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
---@param pop POP
function EconomicEffects.set_ownership(building, pop)
	assert(pop ~= INVALID_ID)
	assert(building ~= INVALID_ID)

	local ownership = DATA.get_ownership_from_building(building)
	if ownership == INVALID_ID then
		local new_ownership = DATA.create_ownership()
		DATA.ownership_set_building(new_ownership, building)
		DATA.ownership_set_owner(new_ownership, pop)
	else
		DATA.ownership_set_owner(ownership, pop)
	end

	local province = building_utils.province(building)

	if pop and WORLD:does_player_see_province_news(province) then
		local building_type = DATA.building_get_type(building)
		local name_building = DATA.building_type_get_name(building_type)
		local pop_name = DATA.pop_get_name(pop)

		if WORLD.player_character == pop then
			WORLD:emit_notification(name_building .. " is now owned by me, " .. pop_name .. ".")
		else
			WORLD:emit_notification(name_building .. " is now owned by " .. pop_name .. ".")
		end
	end
end

---@param building Building
function EconomicEffects.unset_ownership(building)
	local ownership = DATA.get_ownership_from_building(building)

	if ownership == INVALID_ID then
		return
	end

	local owner = DATA.ownership_get_owner(ownership)
	local province = building_utils.province(building)

	DATA.delete_ownership(ownership)

	if WORLD:does_player_see_province_news(province) then
		local building_type = DATA.building_get_type(building)
		local name_building = DATA.building_type_get_name(building_type)
		local pop_name = DATA.pop_get_name(owner)

		if WORLD.player_character == owner then
			WORLD:emit_notification(name_building .. " is no longer owned by me, " .. pop_name .. ".")
		else
			WORLD:emit_notification(name_building .. " is no longer owned by " .. pop_name .. ".")
		end
	end
end

---comment
---@param building_type BuildingType
---@param province province_id
---@param owner POP
---@return Building
function EconomicEffects.construct_building(building_type, province, owner)
	local result_building = building_utils.new(province, building_type)

	local name_building = DATA.building_type_get_name(building_type)
	local province_name = DATA.province_get_name(province)

	if WORLD:does_player_see_province_news(province) then
		WORLD:emit_notification(name_building .. " was constructed in " .. province_name .. ".")
	end

	if owner ~= INVALID_ID then
		EconomicEffects.set_ownership(result_building, owner)
	end

	return result_building
end

---comment
---@param building Building
function EconomicEffects.destroy_building(building)
	EconomicEffects.unset_ownership(building)
	building_utils.remove_from_province(building)
end

---comment
---@param building_type BuildingType
---@param province province_id
---@param owner POP
---@param overseer POP
---@param public boolean
---@return Building
function EconomicEffects.construct_building_with_payment(building_type, province, owner, overseer, public)
	local construction_cost = ev.building_cost(building_type, overseer, public)
	local building = EconomicEffects.construct_building(building_type, province, owner)

	if public or (owner == nil) then
		EconomicEffects.change_treasury(province_utils.realm(province), -construction_cost, ECONOMY_REASON.BUILDING)
	else
		EconomicEffects.add_pop_savings(owner, -construction_cost, ECONOMY_REASON.BUILDING)
	end

	return building
end

---character collects tribute into his pocket and returns collected value
---@param collector Character
---@param realm Realm
---@return number
function EconomicEffects.collect_tribute(collector, realm)
	local hauling = pop_utils.get_supply_capacity(collector, INVALID_ID) * 2
	local max_tribute = DATA.realm_get_budget_budget(realm, BUDGET_CATEGORY.TRIBUTE)
	local tribute_amount = math.min(hauling, math.floor(max_tribute))

	if WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification("Tribute collector had arrived. Another day of humiliation. " ..
			tribute_amount .. MONEY_SYMBOL .. " were collected.")
	end

	EconomicEffects.register_spendings(realm, tribute_amount, ECONOMY_REASON.TRIBUTE)
	DATA.realm_inc_budget_budget(realm, BUDGET_CATEGORY.TRIBUTE, -tribute_amount)
	EconomicEffects.add_pop_savings(collector, tribute_amount, ECONOMY_REASON.TRIBUTE)
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

	EconomicEffects.register_income(realm, to_treasury, ECONOMY_REASON.TRIBUTE)
	EconomicEffects.add_pop_savings(collector, -to_treasury, ECONOMY_REASON.TRIBUTE)
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

	EconomicEffects.add_pop_savings(character, -cost, ECONOMY_REASON.TRADE)

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
		local name = DATA.pop_get_name(character)
		WORLD:emit_notification(
			"Trader "
			.. name
			.. " bought "
			.. amount
			.. " "
			.. good
			.. " for "
			.. ut.to_fixed_point2(cost) .. MONEY_SYMBOL
		)
	end

	return true
end

--- Consumes up to amount of use case from inventory in equal parts to available.
--- Returns total amount able to be satisfied.
---@param pop pop_id
---@param use_case use_case_id
---@param amount number
---@return number consumed
function EconomicEffects.consume_use_case_from_inventory(pop, use_case, amount)
	local supply = ev.available_use_case_from_inventory(pop, use_case)
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
		local good_in_inventory = DATA.pop_get_inventory(pop, good)
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
			DATA.pop_set_inventory(pop, good, math.max(0, DATA.pop_get_inventory(pop, good) - used))
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
	local province = PROVINCE(character)
	local savings = DATA.pop_get_savings(character)
	local can_buy, _ = et.can_buy_use(province, savings, use, amount)
	if not can_buy then
		return false
	end

	-- can_buy validates province

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
		local memory = DATA.pop_get_price_memory(character, good)
		if memory == 0 then
			DATA.pop_set_price_memory(character, good, good_price)
		else
			DATA.pop_set_price_memory(character, good, memory * (3 / 4) + good_price * (1 / 4))
		end
		local goods_available = DATA.province_get_local_storage(province, good)
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
		DATA.province_inc_trade_wealth(province, costs)
		---pop's savings are reduced later

		DATA.pop_inc_inventory(character, values.good, amount)
		EconomicEffects.change_local_stockpile(province, values.good, -consumed_amount)

		local trade_volume =
			DATA.province_get_local_consumption(province, values.good)
			+ DATA.province_get_local_production(province, values.good)
			+ consumed_amount
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

	EconomicEffects.add_pop_savings(character, -spendings, ECONOMY_REASON.TRADE)

	if WORLD:does_player_see_province_news(province) then
		WORLD:emit_notification(
			"Trader " .. DATA.pop_get_name(character)
			.. " bought " .. amount	.. " " .. use
			.. " for " .. ut.to_fixed_point2(spendings)
			.. MONEY_SYMBOL
		)
	end
end


--[[ unused code, rewrite on demand, but it would be better to purchase realms goods via some agent
---comment
---@param realm Realm
---@param use use_case_id
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

	EconomicEffects.change_treasury(realm, -spendings, ECONOMY_REASON.TRADE)

	if WORLD:does_player_see_province_news(province) then
		WORLD:emit_notification(realm.name .. " bought " .. amount .. " " .. use .. " for " .. ut.to_fixed_point2(spendings) .. MONEY_SYMBOL .. ".")
	end
end
--]]

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
	local province = PROVINCE(character)
	local price = ev.get_pessimistic_local_price(province, good, amount, true)

	local memory = DATA.pop_get_price_memory(character, good)
	local new_memory = price
	if memory > 0 then
		new_memory = memory * (3 / 4) + price * (1 / 4)
	end

	DATA.pop_set_price_memory(character, good, new_memory)

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

	EconomicEffects.add_pop_savings(character, cost, ECONOMY_REASON.TRADE)
	DATA.province_inc_trade_wealth(province, cost)

	DATA.pop_inc_inventory(character, good, -amount)
	EconomicEffects.change_local_stockpile(province, good, amount)

	local trade_volume =
			DATA.province_get_local_consumption(province, good)
			+ DATA.province_get_local_production(province, good)
			+ amount

	local price_change = amount / trade_volume * PRICE_SIGNAL_PER_STOCKPILED_UNIT * price
	EconomicEffects.change_local_price(province, good, -price_change)

	-- print('!!! SELL')

	if WORLD:does_player_see_province_news(province) then
		WORLD:emit_notification(
			"Trader " .. DATA.pop_get_name(character)
			.. " sold " .. amount .. " " .. good
			.. " for " .. ut.to_fixed_point2(cost) .. MONEY_SYMBOL
		)
	end
	return true
end

---comment
---@param character Character
---@param realm Realm
---@param amount number
function EconomicEffects.gift_to_tribe(character, realm, amount)
	local savings = DATA.pop_get_savings(character)
	if savings < amount then
		return
	end

	EconomicEffects.add_pop_savings(character, -amount, ECONOMY_REASON.DONATION)
	EconomicEffects.change_treasury(realm, amount, ECONOMY_REASON.DONATION)

	local capitol = DATA.realm_get_capitol(realm)

	local mood_change = amount / (province_utils.local_population(capitol) + 1) / 100

	DATA.province_inc_mood(capitol, mood_change)
	EconomicEffects.gain_popularity(character, realm, mood_change)
end

function EconomicEffects.gain_popularity(character, realm, amount)
	local popularity = INVALID_ID
	DATA.for_each_popularity_from_who(character, function (item)
		local where = DATA.popularity_get_where(item)
		if where == realm then
			popularity = item
		end
	end)

	if popularity == INVALID_ID then
		local new = DATA.create_popularity()
		DATA.popularity_set_who(new, character)
		DATA.popularity_set_where(new, character)
		DATA.popularity_set_value(new, amount)
	else
		DATA.popularity_inc_value(popularity, amount)
	end
end

---comment
---@param warband Warband
---@param character Character
---@param amount number
function EconomicEffects.gift_to_warband(warband, character, amount)
	assert(warband ~= INVALID_ID)
	assert(character ~= INVALID_ID)

	local savings = DATA.pop_get_savings(character)
	local treasury = DATA.warband_get_treasury(warband)

	if amount > 0 then
		if savings < amount then
			amount = savings
		end
	else
		if treasury < -amount then
			amount = treasury
		end
	end

	EconomicEffects.add_pop_savings(character, -amount, ECONOMY_REASON.WARBAND)
	DATA.warband_inc_treasury(warband, amount)
end

---commenting
---@param character Character
---@return number
function EconomicEffects.collect_tax(character)
	local total_tax = 0
	local tax_collection_ability = 0.05

	for i = 0, MAX_TRAIT_INDEX do
		local trait = DATA.pop_get_traits(character, i)
		if trait == INVALID_ID then
			break
		end
		if trait == TRAIT.GREEDY then
			tax_collection_ability = tax_collection_ability + 0.03
		elseif trait == TRAIT.HARDWORKER then
			tax_collection_ability = tax_collection_ability + 0.01
		elseif trait == TRAIT.LAZY then
			tax_collection_ability = tax_collection_ability - 0.01
		end
	end

	DATA.for_each_pop_location(function (item)
		local pop = DATA.pop_location_get_pop(item)
		local savings = DATA.pop_get_savings(pop)
		if savings > 0 then
			total_tax = total_tax + savings * tax_collection_ability
			EconomicEffects.add_pop_savings(pop, -savings * tax_collection_ability, ECONOMY_REASON.TAX)
		end
	end)
	return total_tax
end

---Grants trading rights to character
---@param character Character
---@param realm Realm
function EconomicEffects.grant_trade_rights(character, realm)
	local rights = INVALID_ID
	DATA.for_each_personal_rights_from_person(character, function (item)
		local item_realm = DATA.personal_rights_get_realm(item)
		if item_realm == realm then
			rights = item_realm
		end
	end)

	if rights == INVALID_ID then
		local new = DATA.fatten_personal_rights(DATA.create_personal_rights())
		new.can_trade = true
		new.person = character
		new.realm = realm
	else
		DATA.personal_rights_set_can_trade(character, true)
	end
end

---Grants trading rights to character
---@param character Character
---@param realm Realm
function EconomicEffects.grant_building_rights(character, realm)
	local rights = INVALID_ID
	DATA.for_each_personal_rights_from_person(character, function (item)
		local item_realm = DATA.personal_rights_get_realm(item)
		if item_realm == realm then
			rights = item_realm
		end
	end)

	if rights == INVALID_ID then
		local new = DATA.fatten_personal_rights(DATA.create_personal_rights())
		new.can_build = true
		new.person = character
		new.realm = realm
	else
		DATA.personal_rights_set_can_build(character, true)
	end
end

---Clears all trading rights of character
---@param character Character
function EconomicEffects.abandon_personal_rights(character)
	local to_remove = DATA.filter_personal_rights_from_person(character, ACCEPT_ALL)
	for index, value in ipairs(to_remove) do
		DATA.delete_personal_rights(value)
	end
end




return EconomicEffects
