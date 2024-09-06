-- local trade_good = require "game.raws.raws-utils".trade_good
local retrieve_use_case = require "game.raws.raws-utils".trade_good_use_case

local pop_utils = require "game.entities.pop".POP
local province_utils = require "game.entities.province".Province
local production_utils = require "game.raws.production-methods"

local tabb = require "engine.table"
local dbm = require "game.economy.diet-breadth-model"
local economic_effects = require "game.raws.effects.economic"
local ev = require "game.raws.values.economical"
local pv = require "game.raws.values.political"

local pro = {}

local ffi = require "ffi"

---@class MarketData
---@field price number
---@field feature number
---@field available number
---@field consumption number
---@field demand number
---@field supply number

---@class POPView
---@field foraging_efficiency number
---@field hydration_efficiency number
---@field age_multiplier number

ffi.cdef[[
	typedef struct {
		float price;
		float feature;
		float available;
		float consumption;
		float demand;
		float supply;
	} good_data;

	typedef struct {
		float foraging_efficiency;
		float hydration_efficiency;
		float age_multiplier;
	} pop_view;

	float sqrtf(float arg );
	float expf( float arg );
]]

local C = ffi.C

local EPSILON = 0.001

local amount_of_goods = DATA.trade_good_size
local amount_of_job_types = tabb.size(JOBTYPE)

---@type MarketData[]
local market_data = ffi.new("good_data[?]", amount_of_goods)

---@type POPView[]
local pop_view = ffi.new("pop_view[1]")

---@type number[]
local pop_job_efficiency = ffi.new("float[?]", amount_of_job_types)

-- TODO: rewrite to ffi

---@type table<use_case_id, number>
local use_case_total_exp = {}
---@type table<use_case_id, number>
local use_case_price_expectation = {}

local zero = 0
local total_realm_donations = 0
local total_local_donations = 0
local total_trade_donations = 0

---Calculates weighted price expectation for a list of goods
-- weight means how effective this trade good
-- which means that price expectation will integrate 1 / weight
---@param set_of_goods table<trade_good_id, number>
---@return number total_exp total value for softmax
---@return number expectation price expectation
local function get_price_expectation_weighted(set_of_goods)
	local total_exp = 0
	for good, weight in pairs(set_of_goods) do
		local c_index = good
		total_exp = total_exp + market_data[c_index].feature / weight
	end

	-- price expectation:
	local price_expectation = 0
	for good, weight in pairs(set_of_goods) do
		local c_index = good
		price_expectation = math.max(0.0001, price_expectation + market_data[c_index].price * market_data[c_index].feature / total_exp / weight)
	end

	return total_exp, price_expectation
end


---Calculates weighted price expectation for a use case according to global market data
-- weight means how effective this trade good
-- which means that price expectation will integrate 1 / weight
---@param use use_case_id
---@return number total_exp total value for softmax
---@return number expectation price expectation
local function get_price_expectation_use_case(use)
	local total_exp = 0
	for _, weight_id in pairs(DATA.use_weight_from_use_case[use]) do
		local trade_good = DATA.use_weight_get_trade_good(weight_id)
		local weight = DATA.use_weight_get_weight(weight_id)
		total_exp = total_exp + market_data[trade_good].feature / weight
	end

	-- price expectation:
	local price_expectation = 0
	for _, weight_id in pairs(DATA.use_weight_from_use_case[use]) do
		local trade_good = DATA.use_weight_get_trade_good(weight_id)
		local weight = DATA.use_weight_get_weight(weight_id)
		price_expectation = math.max(0.0001, price_expectation + market_data[trade_good].price * market_data[trade_good].feature / total_exp / weight)
	end

	return total_exp, price_expectation
end


---Runs production on a single province!
---@param province province_id
function pro.run(province)
	total_realm_donations = 0
	total_local_donations = 0
	total_trade_donations = 0

	local province_size = DATA.province_get_size(province)

	-- how much of income is siphoned to local wealth pool
	INCOME_TO_LOCAL_WEALTH_MULTIPLIER = 0.125 / 4
	-- buying prices for pops are multiplied on this number
	POP_BUY_PRICE_MULTIPLIER = 1.5

	MINIMAL_WORKING_RATIO = 0.2

	---@type table<trade_good_id, number>
	local old_prices = {}

	-- reset data
	---commenting
	---@param good trade_good_id
	local function reset_good_data(good)
		-- available resources calculation:
		local consumption = DATA.province_get_local_consumption(province, good)
		local production = DATA.province_get_local_production(province, good)
		local storage = DATA.province_get_local_storage(province, good)
		market_data[good].available = storage
		if market_data[good].available < 0 then
			error("INVALID START TO PRODUCTION-AND-CONSUMPTION TICK"
			.. "\n market_data[" .. good .. "].available = "
			.. tostring(market_data[good].available)
			.. "\n  consumption = "
			.. tostring(consumption)
			.. "\n  production = "
			.. tostring(production)
			.. "\n  storage = "
			.. tostring(storage)
			)
		end
		-- prices:
		local price = ev.get_local_price(province, good)
		market_data[good].price = price
		old_prices[good] = price
		market_data[good].feature = C.expf(-C.sqrtf(market_data[good].price) / (1 + math.max(storage + production - consumption, 0)))
		market_data[good].consumption = 0
		market_data[good].supply = 0
		market_data[good].demand = 0
	end

	DATA.for_each_trade_good(reset_good_data)

	---commenting
	---@param use use_case_id
	local function update_use_case_data(use)
		use_case_total_exp[use], use_case_price_expectation[use] = get_price_expectation_use_case(use)
	end

	DATA.for_each_use_case(update_use_case_data)

	-- Clear building stats
	for _, location in pairs(DATA.get_building_location_from_location(province)) do
		local building = DATA.building_location_get_building(location)
		local fat_building = DATA.fatten_building(building)

		for i = 0, MAX_SIZE_ARRAYS_PRODUCTION_METHOD -1 do
			DATA.building_set_amount_of_inputs_amount(building, i, 0)
			DATA.building_set_amount_of_outputs_amount(building, i, 0)
			DATA.building_set_amount_of_inputs_good(building, i, INVALID_ID)
			DATA.building_set_amount_of_inputs_use(building, i, INVALID_ID)
		end

		for _, employment in pairs(DATA.get_employment_from_building(building)) do
			DATA.employment_set_worker_income(employment, 0)
		end

		fat_building.last_donation_to_owner = 0
		fat_building.last_income = 0
		fat_building.subsidy_last = 0
	end

	---Records local consumption!
	---@param good_index number
	---@param amount number
	local function record_consumption(good_index, amount)

		if amount < 0
			or market_data[good_index].available < 0
			or market_data[good_index].available < amount
		then
			error(
				"INVALID ATTEMPT AT RECORDING OF CONSUMPTION"
				.. "\n amount = "
				.. tostring(amount)
				.. "\n  market_data[good_index].available = "
				.. tostring(market_data[good_index].available)
			)
		end
		-- to prevent consumption from ever reaching over available
		local consumed_amount = math.min(market_data[good_index].available, amount)

		if market_data[good_index].available < consumed_amount then
			error(
				"INVALID RECORD OF GOODS CONSUMPTION"
				.. "\n  market_data[good_index].available = "
				.. tostring(market_data[good_index].available)
				.. "\n  consumed_amount = "
				.. tostring(consumed_amount)
			)
		end

		market_data[good_index].consumption = market_data[good_index].consumption + consumed_amount
		market_data[good_index].available = market_data[good_index].available - consumed_amount

		return market_data[good_index].price * consumed_amount
	end

	---Record local production!
	---@param good_index number
	---@param amount number
	local function record_production(good_index, amount)

		if (amount < 0) then
			error(
				"INVALID RECORD OF PRODUCTION"
				.. "\n amount = "
				.. tostring(amount)
			)
		end

		market_data[good_index].supply = market_data[good_index].supply + amount
		market_data[good_index].available = market_data[good_index].available + amount

		return market_data[good_index].price * amount
	end


	---Record local demand!
	---@param good_index number
	---@param amount number
	local function record_demand(good_index, amount)
		market_data[good_index].demand = market_data[good_index].demand + amount

		return market_data[good_index].price * amount
	end

	-- Record "innate" production of goods and services.
	-- These resources come
	--local water_index = RAWS_MANAGER.trade_good_to_index["water"]
	--record_production(water_index, province.hydration)

	local efficiency_from_infrastructure = province_utils.get_infrastructure_efficiency(province)
	-- Record local production...
	-- TODO MAKE NEW EFFICIENCY FUNCTION FOR FULL PRODUCTION AT 0 FORAGERS AND 0-ISH AT FORAGERS LIMIT
	local last_foraging_efficiency = dbm.foraging_efficiency(DATA.province_get_foragers_limit(province), DATA.province_get_foragers(province))
	local last_hydration_efficiency = dbm.foraging_efficiency(DATA.province_get_hydration(province) * 0.5, DATA.province_get_foragers_water(province))
	local foragers_count = 0
	local foragers_water = 0
	local foragers_efficiency = 1
	local hydration_efficiency = 1

	local old_wealth = DATA.province_get_local_wealth(province) -- store wealth before this tick, used to calculate income later
	local population = province_utils.local_population(province)
	local mood = DATA.province_get_mood(province)
	local min_income_pop = math.max(50, math.min(200, 100 + mood * 10))


	-- TODO: IMPLEMENT CULTURAL VALUE
	local fraction_of_income_given_voluntarily = 0.1 * math.max(0, math.min(1.0, 1.0 - population / min_income_pop))
	local fraction_of_income_given_to_owner = 0.1

	DISPLAY_INCOME_OWNER_RATIO = (1 - INCOME_TO_LOCAL_WEALTH_MULTIPLIER) * fraction_of_income_given_to_owner


	---Pop forages for food; takes a forager and time and returns a list of output products with amounts \
	-- Not very efficient
	---@param pop_view POPView[]
	---@param pop pop_id
	---@param time number ratio of daily active time pop can spend on foraging
	---@return table<trade_good_id, number> products
	local function forage(pop_view, pop, time)
		local culture = DATA.pop_get_culture(pop)
		local race = DATA.pop_get_race(pop)
	--	print("  " .. pop_table.race.name .. " " .. pop_table.age ..  (pop_table.female and " f" or " m") .. " FORAGING: " .. forage_efficiency .. " FOR ".. time )
		-- weight amount found by searching efficiencies and cultual search times

		---@type table<trade_good_id, number>
		local table_to_accumulate = {}

		---@type table<trade_good_id, number>
		local foraged_goods = {}

		DATA.for_each_trade_good(function (item)
			foraged_goods[item] = 0
		end)

		for i = 0, MAX_RESOURCES_IN_PROVINCE_INDEX do
			local forage_case = DATA.province_get_foragers_targets_forage(province, i)
			if forage_case == FORAGE_RESOURCE.INVALID then
				break
			end

			local required_job =  DATA.forage_resource_get_handle(forage_case)
			local amount = DATA.province_get_foragers_targets_amount(province, i)
			local output_good = DATA.province_get_foragers_targets_output_good(province, i)
			local output_value = DATA.province_get_foragers_targets_output_value(province, i)
			local efficiency = pop_job_efficiency[required_job]

			local search_time = province_size
			local handle_time = amount / efficiency
			local total_time = search_time + handle_time

			local cultural_time = culture.traditional_forager_targets[forage_case]
			local gathered_ratio = cultural_time / total_time
			foraged_goods[output_good] = foraged_goods[output_good] + gathered_ratio * output_good * output_value
		end

		return foraged_goods
	end

	---Pop forages for food and gives it to warband  \
	-- Not very efficient
	---@param pop_view POPView[]
	---@param pop_id pop_id
	---@param time number ratio of daily active time pop can spend on foraging
	local function forage_warband(pop_view, pop_id, warband_id, time)
		local income = 0
		local foraged_food = forage(pop_view, pop_id, time)
		local leadership = DATA.get_warband_leader_from_warband(warband_id)
		if leadership then
			local leader = DATA.warband_leader_get_leader(leadership)
			for good, amount in pairs(foraged_food) do
				DATA.pop_inc_inventory(leader, good, amount)
			end
		else
			for good, amount in pairs(foraged_food) do
				income = income + record_production(good ,amount)
			end
			if income > 0 then
				economic_effects.gift_to_warband(warband_id, pop_id, income)
			end
		end
	end


	---Returns purchasable units of use_case available in province
	---@param use use_case_id
	---@return number amount
	local function available_goods_for_use(use)
		local total_available = 0

		for _, weight_id in pairs(DATA.use_weight_from_use_case[use]) do
			local trade_good = DATA.use_weight_get_trade_good(weight_id)
			total_available = total_available + market_data[trade_good].available
		end

		return total_available
	end

	---Buys goods according to their use and required amount
	---@param use use_case_id
	---@param amount number
	---@param savings number how much money you are ready to spend
	---@return number spendings
	---@return number consumed
	local function buy_use(use, amount, savings)
		if amount < 0 or savings < 0 then return 0, 0 end

		local total_exp = use_case_total_exp[use]
		local price_expectation = use_case_price_expectation[use]
		local demanded_use = math.min(amount, savings / price_expectation)

		local available = available_goods_for_use(use)
		local potential_amount = math.min(available, demanded_use)

		local total_bought = 0
		local spendings = 0

		for _, weight_id in pairs(DATA.use_weight_from_use_case[use]) do
			local trade_good = DATA.use_weight_get_trade_good(weight_id)
			local weight = DATA.use_weight_get_weight(weight_id)

			local goods_price = math.max(market_data[trade_good].price, 0.0001)
			local goods_available = market_data[trade_good].available
			local goods_available_weight = available > 0 and (market_data[trade_good].available / weight / available) or 0
			local goods_feature_weight = total_exp > 0 and (market_data[trade_good].feature / total_exp) or 0
			local demanded_amount = demanded_use / weight * goods_feature_weight
			local consumed_amount = math.max(0, math.min(goods_available, demanded_amount,
				potential_amount / weight * goods_available_weight,
				savings / goods_price))
			if demanded_amount ~= demanded_amount
				or consumed_amount ~= consumed_amount
			then
				error("BUY USE CALCULATED AMOUNT IS NAN"
				.. "\n goods_available = "
				.. tostring(goods_available)
				.. "\n available = "
				.. tostring(available)
				.. "\n goods_available_weight = "
				.. tostring(goods_available_weight)
				.. "\n feature = "
				.. tostring(market_data[trade_good].feature)
				.. "\n total_exp = "
				.. tostring(total_exp)
				.. "\n goods_feature_weight = "
				.. tostring(goods_feature_weight)
				.. "\n savings = "
				.. tostring(savings)
				.. "\n goods_price = "
				.. tostring(goods_price)
				.. "\n amount = "
				.. tostring(amount)
				.. "\n demanded_amount = "
				.. tostring(demanded_amount)
				.. "\n consumed_amount = "
				.. tostring(consumed_amount)
				)
			end
			-- we need to get back to use "units" so we multiplay consumed amount back by weight
			total_bought = total_bought + consumed_amount * weight

			spendings = spendings + record_consumption(trade_good, consumed_amount)
			record_demand(trade_good, demanded_amount)
		end
		if spendings > savings + 0.01
			or total_bought > amount + 0.01
		then
			error("INVALID BUY USE ATTEMPT"
				.. "\n use_reference = "
				.. tostring(use)
				.. "\n spendings = "
				.. tostring(spendings)
				.. "\n savings = "
				.. tostring(savings)
				.. "\n total_bought = "
				.. tostring(total_bought)
				.. "\n amount = "
				.. tostring(amount)
				.. "\n price_expectation = "
				.. tostring(price_expectation)
				.. "\n demanded_use = "
				.. tostring(demanded_use)
				.. "\n available = "
				.. tostring(available)
				.. "\n potential_amount = "
				.. tostring(potential_amount)
			)
		end
		return spendings, total_bought
	end

	---@type number[]
	local cottaging_time_per_entry = {}
	---@type number[]
	local cottaging_use_per_entry = {}

	---@type number[]
	local market_cost_per_entry = {}
	---@type number[]
	local market_use_per_entry = {}

	---comment
	---@param pop_view POPView
	---@param pop_id pop_id
	---@param free_time number
	---@param savings number
	local function satisfy_needs(pop_view, pop_id, free_time, savings)
		-- BUILD TOTAL FAMILY NEEDS
		-- print("FAMILY UNIT: " .. pop_table.name .. " (" .. 1 + tabb.size(pop_table.children) .. ")")
		-- start with family head (parent) as base

		---@type table<number, struct_need_satisfaction>
		local family_unit_satisfaction_data = {}

		-- reset data
		for index = 0, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
			cottaging_time_per_entry[index] = 0
			cottaging_use_per_entry[index] = 0
			market_cost_per_entry[index] = 0
			market_use_per_entry[index] = 0
		end

		-- collect needs of a parent
		for index = 0, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
			local use_case = DATA.pop_get_need_satisfaction_use_case(pop_id, index)
			if use_case == 0 then
				break
			end
			local need = DATA.pop_get_need_satisfaction_need(pop_id, index)
			local demanded = DATA.pop_get_need_satisfaction_demanded(pop_id, index)
			family_unit_satisfaction_data[index] = {need=need, use_case=use_case, consumed=0, demanded=demanded}
		end

		-- collect children's needs
		for _, relation_id in pairs(DATA.parent_child_relation_from_parent[pop_id]) do
			local child = DATA.parent_child_relation_get_child(relation_id)

			for index = 0, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
				local use_case = DATA.pop_get_need_satisfaction_use_case(child, index)
				if use_case == 0 then
					break
				end

				local demanded = DATA.pop_get_need_satisfaction_demanded(child, index)
				family_unit_satisfaction_data[index].demanded = family_unit_satisfaction_data[index].demanded + demanded
			end
		end

	--	print("  TOTAL FAMILY UNIT NEEDS:")
	--	for need, cases in pairs(family_unit_needs) do
	--		print("    " .. NEED_NAME[need] .. ": ")
	--		for case, value in pairs(cases) do
	--			print("      " .. case .. ": " .. value.demanded)
	--		end
	--	end

		-- go through each food use case and forage to satisfy that case
		local culture = DATA.pop_get_culture(pop_id)
		local total_forage_time = free_time
		local foraged_goods = forage(pop_view, pop_id, total_forage_time)
		---@type table<trade_good_id, number>
		local consumed_foraged_goods = {}


		for good, amount in pairs(foraged_goods) do
			DATA.pop_inc_inventory(pop_id, good, amount)
			consumed_foraged_goods[good] = 0
		end

		for index = 0, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
			local use_case = DATA.pop_get_need_satisfaction_use_case(pop_id, index)
			if use_case == 0 then
				break
			end
			local need = DATA.pop_get_need_satisfaction_need(pop_id, index)
	--		print("  USE CASE: " .. use_case .. " SATISFACTION: " .. family_unit_needs[NEED.FOOD][use_case].consumed .. " / " .. family_unit_needs[NEED.FOOD][use_case].demanded)
			-- consume for use case only
			local demanded = DATA.pop_get_need_satisfaction_demanded(pop_id, index)
			for _, weight_id in pairs(DATA.get_use_weight_from_use_case(use_case)) do
				local good = DATA.use_weight_get_trade_good(weight_id)
				local weight = DATA.use_weight_get_weight(weight_id)
				local consumed = family_unit_satisfaction_data[index].consumed
				local amount = DATA.pop_get_inventory(pop_id, good)
				local difference = math.max(0, demanded - consumed)
				if weight and difference > 0 then
					local weighted_amount = weight * amount
					---@type number
					local consumption = math.min(weighted_amount, difference)
					amount = math.max(0, amount - consumption / weight)
					family_unit_satisfaction_data[index].consumed = consumed + consumption
					DATA.pop_inc_inventory(pop_id, good, -consumption)
					consumed_foraged_goods[good] = consumed_foraged_goods[good] + consumption
	--				print("    GOOD: " .. good .. " FORAGED: " .. foraged_goods[good] .. " CONSUMED: " .. consumption .. " -> " .. family_unit_needs[NEED.FOOD][use_case].consumed)
				end
			end
		end

	--	print("  SATISFIED FAMILY UNIT NEEDS: (after forage call)")
	--	for need, cases in pairs(family_unit_needs) do
	--		print("    " .. NEED_NAME[need] .. ": ")
	--		for case, value in pairs(cases) do
	--			print("      " .. case .. ": " .. value.consumed .. " / " .. value.demanded)
	--		end
	--	end

	--	print("  FORAGED GOODS:")
	--	for good, amount in pairs(foraged_goods) do
	--		print("    " ..good .. ": " .. amount)
	--	end

		--  SELL EXCESS TO MARKET
		local income = 0
	--	print("  GOODS SOLD TO MARKET:")

		for good, amount in pairs(foraged_goods) do
			if amount > consumed_foraged_goods[good] then
				local sold_amount = amount - consumed_foraged_goods[good]
				local production = record_production(good, sold_amount)
				DATA.pop_inc_inventory(pop_id, good, -sold_amount)
	--			print("    SOLD :" .. amount .. " OF " .. good .. " FOR " .. production)
				income = income + production
			end
		end

		-- BUYING NEEDS

		-- set up variables
		local savings_temp = savings + income
		local total_expense = 0.0
		local savings_required_to_buy_all_needs = 0

		-- induce additional demand and calculate market costs and total cost
		for index = 0, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
			local use_case = DATA.pop_get_need_satisfaction_use_case(pop_id, index)
			if use_case == 0 then
				break
			end
			local need = DATA.pop_get_need_satisfaction_need(pop_id, index)

			--	print("  ".. NEED_NAME[need_index] .. " free_time: " .. free_time .. " saving: " .. savings ..  " saving: " .. target)
			-- start with calculation of distribution over goods:
			-- "distribution" "density" is precalculated, we only need to find a normalizing coef.

			local demanded = family_unit_satisfaction_data[index].demanded
			local consumed = family_unit_satisfaction_data[index].consumed

			-- induced demand:
			local price_expectation = math.max(use_case_price_expectation[use_case] or 0, 0.0001)
			local induced_demand = math.min(2, math.max(0, 1 / price_expectation - 1))
	--		print("    " .. " case: " .. case .." need: " .. need_amount .. " induced_demand: " .. need_amount * (1 + induced_demand))
			demanded = demanded * (1 + induced_demand)

			if demanded < 0 then
				error("Demanded need is lower than zero!")
			end

			-- estimate cost in money and time to satisfy each use_case
			local remaining_need_amount = math.max(0, demanded - consumed)
			local need_cost = price_expectation * remaining_need_amount * POP_BUY_PRICE_MULTIPLIER

			market_use_per_entry[index] = remaining_need_amount
			market_cost_per_entry[index] = need_cost

			---@type number
			savings_required_to_buy_all_needs = savings_required_to_buy_all_needs + need_cost
		end

		-- use estimation above to complete calculation of budget distribution
		for index = 0, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
			local use_case = DATA.pop_get_need_satisfaction_use_case(pop_id, index)
			if use_case == 0 then
				break
			end
			local need = DATA.pop_get_need_satisfaction_need(pop_id, index)
			local savings_fraction = savings_temp * market_cost_per_entry[index] / savings_required_to_buy_all_needs

			-- attempt to buy from market with savings fraction
			if savings_fraction > 0 then
				local spendings, consumed = buy_use(use_case, market_use_per_entry[index], savings_fraction)

	--			print("    " .. " case: " .. case .." spendings: " .. spendings .. " consumed: " .. consumed)
				local consumed_before_buyment = family_unit_satisfaction_data[index]
				family_unit_satisfaction_data[index].consumed = consumed_before_buyment + consumed

				total_expense = total_expense + spendings

				if consumed > market_use_per_entry[index] + 0.01
					or spendings > savings_fraction + 0.01
				then
					error("INVALID BUY_USE ATTEMPT IN SATISFY_NEED"
						.. "\n case = "
						.. tostring(DATA.use_case_get_description(use_case))
						.. "\n spendings = "
						.. tostring(spendings)
						.. "\n savings_fraction = "
						.. tostring(savings_fraction)
						.. "\n consumed = "
						.. tostring(consumed)
						.. "\n need_amount = "
						.. tostring(market_use_per_entry[index])
					)
				end
			end
		end

		if total_expense > savings_temp + 0.01
			or income ~= income
			or total_expense ~= total_expense
			or savings_temp ~= savings_temp
		then
			error("INVALID SATISFY_NEED"
				.. "\n total_expense = "
				.. tostring(total_expense)
				.. "\n income = "
				.. tostring(income)
				.. "\n savings_temp = "
				.. tostring(savings_temp)
			)
		end

		local low_life_need, high_life_need = false, true

		for index = 0, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
			local use_case = DATA.pop_get_need_satisfaction_use_case(pop_id, index)
			if use_case == 0 then
				break
			end
			local need = DATA.pop_get_need_satisfaction_need(pop_id, index)

			local consumed = family_unit_satisfaction_data[index].consumed
			local demanded = family_unit_satisfaction_data[index].demanded

			local satisfaction_ratio = consumed / demanded

			local is_life_need = DATA.need_get_life_need(need)

			if is_life_need then
				if satisfaction_ratio < 0.6 then
					low_life_need = true
					high_life_need = false
				elseif satisfaction_ratio < 0.8 then
					high_life_need = false
				end
			end

			local demanded_by_pop = DATA.pop_get_need_satisfaction_demanded(pop_id, index)
			DATA.pop_set_need_satisfaction_consumed(pop_id, index, satisfaction_ratio * demanded_by_pop)
		end

		for _, relation_id in pairs(DATA.parent_child_relation_from_parent[pop_id]) do
			local child = DATA.parent_child_relation_get_child(relation_id)

			for index = 0, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
				local use_case = DATA.pop_get_need_satisfaction_use_case(child, index)
				if use_case == 0 then
					break
				end
				local need = DATA.pop_get_need_satisfaction_need(child, index)

				local consumed = family_unit_satisfaction_data[index].consumed
				local demanded = family_unit_satisfaction_data[index].demanded

				local satisfaction_ratio = consumed / demanded

				local is_life_need = DATA.need_get_life_need(need)

				if is_life_need then
					if satisfaction_ratio < 0.6 then
						low_life_need = true
						high_life_need = false
					elseif satisfaction_ratio < 0.8 then
						high_life_need = false
					end
				end

				local demanded_by_pop = DATA.pop_get_need_satisfaction_demanded(child, index)
				DATA.pop_set_need_satisfaction_consumed(child, index, satisfaction_ratio * demanded_by_pop)
			end

			pop_utils.update_satisfaction(child)
		end

		-- adjust pop savings
		economic_effects.add_pop_savings(pop_id, income, economic_effects.reasons.Forage)
		economic_effects.add_pop_savings(pop_id, -total_expense, economic_effects.reasons.BasicNeeds)

		-- for next month determine if it should forage more or less
		local forage_ratio = DATA.pop_get_forage_ratio(pop_id)
		if low_life_need == true then -- any single life need use cases below 50%
			if DATA.pop_get_employer(pop_id) ~= nil then
				---@type number
				forage_ratio = math.min(1 - MINIMAL_WORKING_RATIO, forage_ratio * 1.15)
			else
				forage_ratio = math.min(1, forage_ratio * 1.15)
			end
		elseif high_life_need == true then -- all life need use cases are over 60%
			forage_ratio = math.max(0.01, forage_ratio * 0.9)
		end
		DATA.pop_set_forage_ratio(pop_id, math.min(0.99, forage_ratio))
		DATA.pop_set_work_ratio(pop_id, math.max(0.01, 1 - forage_ratio))
	end


	local total_popularity = 0
	---@type table<pop_id, number>
	local donations_to_owners = {}

	-- pre-update: information gathering / setting variable
	---@type table<pop_id, number>
	local additional_family_time = {}
	---@type table<pop_id, number>
	local tools_satisfaction = {}
	---@type table<pop_id, number>
	local containers_satisfaction = {}
	-- sort pops by wealth:
	---@type pop_id[]
	local pops_by_wealth = tabb.accumulate(
		tabb.join_arrays(
			tabb.map_array(
				DATA.get_pop_location_from_location(province),
				DATA.pop_location_get_pop
			),
			tabb.map_array(
				DATA.get_character_location_from_location(province),
				DATA.character_location_get_character
			)
		),
		{},
		function (a, _, pop)
			-- record total time for family dependents only if in same province
			local home_province = DATA.home_get_home(DATA.get_home_from_pop(pop))
			local age_multiplier = pop_utils.get_age_multiplier(pop)
			local age = DATA.pop_get_age(pop)
			local race = DATA.pop_get_race(pop)
			local teen_age = DATA.race_get_teen_age(race)
			local culture = DATA.pop_get_culture(pop)
			local parent = DATA.pop_get_parent(pop)
			local unit_of_warband = DATA.warband_unit_get_warband(DATA.get_warband_unit_from_unit(pop))
			local forage_ratio = DATA.pop_get_forage_ratio(pop)

			local parent_present = true
			if parent then
				local parent_province = DATA.pop_location_get_pop(DATA.get_pop_location_from_pop(parent))
				if parent_province ~= province then
					parent_present = false
				end
			else
				parent_present = false
			end

			if home_province == province then
				tabb.size(tabb.filter_array(DATA.get_parent_child_relation_from_parent(parent), function (relation)
					local child = DATA.parent_child_relation_get_child(relation)
					local age_child = DATA.pop_get_age(child)
					local teen_age_child = DATA.race_get_teen_age(race)
					if age_child < teen_age_child then
							additional_family_time[pop] = (additional_family_time[pop] or 0) + age / teen_age_child * age_multiplier
						return true
					end
					return false
				end))
			end

			if not IS_CHARACTER(pop) then
				-- pops donate some of their savings as well:
				local savings = DATA.pop_get_savings(pop)
				local pop_donation_total = savings / 120
				total_realm_donations = total_realm_donations + pop_donation_total * 0.4
				total_local_donations = total_local_donations + pop_donation_total * 0.4
				total_trade_donations = total_trade_donations + pop_donation_total * 0.2
			else
				local popularity = pv.popularity(pop, DATA.province_get_realm(province))
				if popularity > 0 then
					total_popularity = total_popularity + popularity
				end
			end
			-- update 'family units', add to pop satisfy needs list only if an 'adult' or an absant parent, either away or none at all
			if (age >= teen_age) or (not parent_present) then
				-- record foraging time of 'family unit' for efficiency

				local water_search = culture.traditional_forager_targets[FORAGE_RESOURCE.WATER]
				local foragers_increase = DATA.race_get_carrying_capacity_weight(race) * age_multiplier
				-- if in warband and foraging, half of free time goes to foraging for warband
				if age < teen_age then
					foragers_increase = foragers_increase * age / teen_age
				elseif unit_of_warband ~= INVALID_ID then
					local fat_warband = DATA.fatten_warband(unit_of_warband)
					if fat_warband.status == WARBAND_STATUS.IDLE and fat_warband.idle_stance == WARBAND_STANCE.FORAGE then
						local weight = foragers_increase * fat_warband.current_free_time_ratio * 0.25
						foragers_count = foragers_count + weight
						---@type number
						foragers_increase = weight * 3
					end
				end
				-- add children's times and weight by desired foraging percentage
				foragers_increase = forage_ratio * (foragers_increase + (additional_family_time[pop] or 0))
				-- add 'family unit' to production and consumption cycle
				table.insert(a, pop)
				foragers_count = foragers_count + foragers_increase * (1 - water_search)
				foragers_water = foragers_water + foragers_increase * water_search
			end

			-- recalculate pop needs
			-- TODO solve starvation from travling/raiding/patroling instead of reducing consumption, replace with warband supplies?
			local consumption_percentage = 0
			if unit_of_warband ~= INVALID_ID and DATA.warband_get_status(unit_of_warband) == WARBAND_STATUS.IDLE then
				consumption_percentage = 0.9
			end

			tools_satisfaction[pop] = 0
			containers_satisfaction[pop] = 0

			-- recalculate foraging efficiency from tools and containers
			for index = 0, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
			local use_case = DATA.pop_get_need_satisfaction_use_case(pop, index)
				if use_case == 0 then
					break
				end
				local need = DATA.pop_get_need_satisfaction_need(pop, index)
				local is_tool = DATA.need_get_tool(need)
				local is_container = DATA.need_get_container(need)

				local consumed = DATA.pop_get_need_satisfaction_consumed(pop, index)
				local demanded = DATA.pop_get_need_satisfaction_demanded(pop, index)

				if is_tool then
					tools_satisfaction[pop] = tools_satisfaction[pop] + consumed / (demanded + 0.1)
				end

				if is_container then
					containers_satisfaction[pop] = containers_satisfaction[pop] + consumed / (demanded + 3)
				end

				-- reset consumption
				DATA.pop_set_need_satisfaction_consumed(pop, index, consumed * consumption_percentage)
			end

			return a
		end
	)

	table.sort(pops_by_wealth, function (a, b)
		return DATA.pop_get_savings(a) > DATA.pop_get_savings(b)
	end)

	-- calculate foragers efficiency base on planned foraging
	foragers_efficiency = dbm.foraging_efficiency(DATA.province_get_foragers_limit(province), foragers_count)
	hydration_efficiency = dbm.foraging_efficiency(DATA.province_get_hydration(province) * 0.5, foragers_water)

	PROFILER:start_timer("production-pops-loop")
	for _, pop in ipairs(pops_by_wealth) do
		local race = DATA.pop_get_race(pop)
		local age = DATA.pop_get_age(pop)
		local teen_age = DATA.race_get_teen_age(race)
		local female = DATA.pop_get_female(pop)
		local unit_of_warband = DATA.warband_unit_get_warband(DATA.get_warband_unit_from_unit(pop))
		local employment = DATA.get_employment_from_worker(pop)
		local building = DATA.employment_get_building(employment)
		local fat_building = DATA.fatten_building(building)

		-- populate pop_view
		pop_view[zero].age_multiplier = pop_utils.get_age_multiplier(pop)

		-- populate job efficiency
		for tag, value in pairs(JOBTYPE) do
			pop_job_efficiency[value] = pop_utils.job_efficiency(pop, value)
		end
		local race_weight = DATA.race_get_carrying_capacity_weight(race)
		pop_view[zero].foraging_efficiency = race_weight * (1 + tools_satisfaction[pop])
		pop_view[zero].hydration_efficiency = race_weight * (1 + containers_satisfaction[pop])

		-- base income: all adult pops forage and help each other which translates into a bit of wealth
		-- real reason: wealth sources to fuel the economy
		-- buidings are essentially wealth sinks currently
		-- so obviously we need some wealth sources
		-- should be removed when economy simulation will be completed
		local base_income = race_weight * age / DATA.race_get_max_age(race);
		economic_effects.add_pop_savings(pop, base_income, economic_effects.reasons.MonthlyChange)

		local free_time_of_pop = 1;
		-- Drafted pops work only when warband is "idle"
		if (unit_of_warband == INVALID_ID) or (DATA.warband_get_status(unit_of_warband) == "idle") then
			-- if pop is in the warband,
			if unit_of_warband ~= INVALID_ID then
				local fat_warband = DATA.fatten_warband(unit_of_warband)
				if fat_warband.idle_stance == "forage" then
					-- spend some time on foraging for warband:
					forage_warband(pop_view, pop, unit_of_warband, fat_warband.current_free_time_ratio * 0.25)
					free_time_of_pop = fat_warband.current_free_time_ratio * 0.75
				else
					-- or spend all the time working like other pops
					free_time_of_pop = fat_warband.current_free_time_ratio
				end
			end

			PROFILER:start_timer('production-building-update')
			if building ~= INVALID_ID then
				local building_type = DATA.building_get_type(building)
				local production_method = DATA.building_type_get_production_method(building_type)
				local fat_method = DATA.fatten_production_method(production_method)

				local income = 0
				local work_time = DATA.pop_get_work_ratio(pop) * free_time_of_pop
				local local_foraging_efficiency = 1
				if fat_method.foraging then
					-- buildings operate off off last month's foraging use, otherwise race conditions on output
					foragers_count = foragers_count + work_time * pop_view[zero].foraging_efficiency
					local_foraging_efficiency = local_foraging_efficiency * math.min(foragers_efficiency, last_foraging_efficiency)
				end
				if fat_method.hydration then
					-- buildings operate off off last month's foraging use, otherwise race conditions on output
					foragers_water = foragers_count + work_time * pop_view[zero].foraging_efficiency
					local_foraging_efficiency = local_foraging_efficiency * math.min(hydration_efficiency, last_hydration_efficiency)
				end
				local yield = production_utils.get_efficiency(production_method, province)

				local efficiency = yield
									* local_foraging_efficiency
									* efficiency_from_infrastructure
									* work_time

				-- expected input satisfaction
				local input_satisfaction = 1

				for i = 0, MAX_SIZE_ARRAYS_PRODUCTION_METHOD - 1 do
					local amount = DATA.production_method_get_inputs_amount(production_method, i)
					local input = DATA.production_method_get_inputs_use(production_method, i)

					if input == INVALID_ID then
						break
					end

					local required_input = amount * efficiency
					local present_input = available_goods_for_use(input)

					local ratio = 0
					if present_input > 0 then
						ratio = math.min(1, present_input / required_input)
					end
					input_satisfaction = math.min(input_satisfaction, ratio)

					if input_satisfaction ~= input_satisfaction then
						error(
							"INVALID INPUT SATISFACTION"
							.. "\n value = "
							.. tostring(input_satisfaction)
							.. "\n required_input = "
							.. tostring(required_input)
							.. "\n present_input = "
							.. tostring(present_input)
							.. "\n ratio = "
							.. tostring(ratio)
						)
					end
				end

				---@type number
				efficiency = efficiency * input_satisfaction

				if efficiency ~= efficiency then
					error(
						"INVALID VALUE OF EFFICIENCY"
						.. "\n efficiency = "
						.. tostring(efficiency)
						.. "\n pop.employer.work_ratio = "
						.. tostring(DATA.pop_get_work_ratio(pop))
						.. "\n efficiency_from_infrastructure = "
						.. tostring(efficiency_from_infrastructure)
						.. "\n local_foraging_efficiency = "
						.. tostring(local_foraging_efficiency)
					)
				end

				local _, input_boost, output_boost, throughput_boost
					= ev.projected_income(
						building,
						race,
						female,
						old_prices,
						efficiency
					)

				if fat_method.forest_dependence > 0 then
					local years_to_deforestate = 50
					local days_to_deforestate = years_to_deforestate * 360
					local total_power = fat_method.forest_dependence * efficiency * throughput_boost * input_boost / days_to_deforestate
					require "game.raws.effects.geography".deforest_random_tile(province, total_power)
				end


				-- real input satisfaction
				local input_satisfaction_2 = 1
				local production_budget = DATA.pop_get_savings(pop) / 2

				if efficiency > 0 then
					for i = 0, MAX_SIZE_ARRAYS_PRODUCTION_METHOD - 1 do
						local amount = DATA.production_method_get_inputs_amount(production_method, i)
						local input = DATA.production_method_get_inputs_use(production_method, i)

						if input == INVALID_ID then
							break
						end
						local required = input_boost * amount * efficiency
						local spent, consumed = buy_use(input, required, production_budget)

						input_satisfaction_2 = math.min(input_satisfaction_2, consumed / required)
						income = income - spent

						DATA.building_inc_amount_of_inputs_amount(building, i, consumed)
						DATA.building_set_amount_of_inputs_good(building, i, input)

						DATA.building_inc_spent_on_inputs_amount(building, i, spent)
						DATA.building_set_spent_on_inputs_good(building, i, input)
					end
				end

				for i = 0, MAX_SIZE_ARRAYS_PRODUCTION_METHOD - 1 do
					local amount = DATA.production_method_get_outputs_amount(production_method, i)
					local output = DATA.production_method_get_outputs_good(production_method, i)

					if output == INVALID_ID then
						break
					end

					local price = market_data[output].price
					local produced = amount * efficiency * throughput_boost * output_boost * input_satisfaction_2
					local earnt = price * produced
					---@type number
					income = income + earnt

					DATA.building_inc_amount_of_outputs_amount(building, i, produced)
					DATA.building_set_amount_of_outputs_good(building, i, output)

					DATA.building_inc_earn_from_outputs_amount(building, i, earnt)
					DATA.building_set_earn_from_outputs_good(building, i, output)

					record_production(output, amount * efficiency * output_boost * throughput_boost)
				end

				local ownership = DATA.get_ownership_from_building(building)
				if ownership ~= INVALID_ID then
					local owner = DATA.ownership_get_owner(ownership)

					if donations_to_owners[owner] == nil then
						donations_to_owners[owner] = 0
					end

					local owner_savings = DATA.pop_get_savings(owner)
					local subsidy = fat_building.subsidy
					if owner_savings + donations_to_owners[owner] > subsidy then
						income = income + subsidy
						donations_to_owners[owner] = donations_to_owners[owner] - subsidy
						fat_building.subsidy_last = fat_building.subsidy
					else
						fat_building.subsidy_last = 0
					end
				end

				if fat_building.income_mean then
					fat_building.income_mean = fat_building.income_mean * 0.5 + income * 0.5
				else
					fat_building.income_mean = income
				end

				fat_building.last_income = fat_building.last_income + income

				--free_time_of_pop = free_time_of_pop - pop.work_ratio * free_time_of_pop * input_satisfaction * input_satisfaction_2

				if income > 0 then
					---@type number
					local contrib = income * fraction_of_income_given_voluntarily
					if ownership ~= INVALID_ID then
						local owner = DATA.ownership_get_owner(ownership)
						---@type number
						contrib = income * fraction_of_income_given_to_owner
						if donations_to_owners[owner] == nil then
							donations_to_owners[owner] = 0
						end
						donations_to_owners[owner] = donations_to_owners[owner] + contrib
						fat_building.last_donation_to_owner = fat_building.last_donation_to_owner + contrib
						income = income - contrib
					end
					-- increase working hours if possible to increase income
					local new_work_ratio = math.min(1, math.max(MINIMAL_WORKING_RATIO, DATA.pop_get_work_ratio(pop) * 1.1))

					DATA.pop_set_work_ratio(pop, new_work_ratio)
					DATA.pop_set_forage_ratio(pop, 1 - new_work_ratio)
				end
				local trade_wealth = DATA.province_get_trade_wealth(province)
				if trade_wealth < income then
					-- generate some wealth if selling more goods than market can afford
					income = math.min(trade_wealth, income) + 0.5 * (income - trade_wealth)
				end
				DATA.employment_inc_worker_income(employment, income)
				economic_effects.add_pop_savings(pop, income, economic_effects.reasons.Work)
				DATA.province_set_trade_wealth(province,  math.max(0, trade_wealth - income))
			end
			PROFILER:end_timer('production-building-update')

			if age < teen_age then
				-- children spend time on games and growing up:
				free_time_of_pop = free_time_of_pop * age / teen_age
			end

			-- every pop spends some time or wealth on fullfilling the need of their children and themselves
			local savings_fraction = DATA.pop_get_savings(pop) / 10
			if WORLD.player_character and WORLD.player_character == pop then
				savings_fraction = OPTIONS['needs-savings'] * DATA.pop_get_savings(pop)
			end

			PROFILER:start_timer("production-satisfy-needs")
			satisfy_needs(pop_view, pop, DATA.pop_get_forage_ratio(pop) * (free_time_of_pop + (additional_family_time[pop] or 0)), math.max(0, savings_fraction))
			PROFILER:end_timer("production-satisfy-needs")
		end

		::continue::
	end
	PROFILER:end_timer("production-pops-loop")


	--- DISTRIBUTION OF DONATIONS
	PROFILER:start_timer('donations')

	local realm_share = total_realm_donations
	if total_popularity > 0.5 then
		realm_share = realm_share * 0.5
		local elites_share = total_realm_donations - realm_share

		for _, location in ipairs(DATA.get_character_location_from_location(province)) do
			local character = DATA.character_location_get_character(location)
			local popularity = pv.popularity(character, DATA.province_get_realm(province))

			if popularity > 0 then
				local share = elites_share * popularity / total_popularity
				if share ~= share then
					error(
						"INVALID DONATION SHARE"
						.. "\n elites_share = "
						.. tostring(elites_share)
						.. "\n popularity = "
						.. tostring(popularity)
						.. "\n total_popularity = "
						.. tostring(total_popularity)
					)
				end
				economic_effects.add_pop_savings(c, share, economic_effects.reasons.Donation)
			end
		end
	end
	economic_effects.register_income(DATA.province_get_realm(province), realm_share, economic_effects.reasons.Donation)
	economic_effects.change_local_wealth(province, total_local_donations, economic_effects.reasons.Donation)
	DATA.province_set_trade_wealth(province, DATA.province_get_trade_wealth(province) + total_trade_donations)

	for character, income in pairs(donations_to_owners) do
		economic_effects.add_pop_savings(character, income, economic_effects.reasons.BuildingIncome)
	end

	PROFILER:end_timer('donations')

	DATA.province_set_local_income(province, DATA.province_get_local_income(province) - old_wealth)
	DATA.province_set_foragers(province, foragers_count)
	DATA.province_set_foragers_water(province, foragers_water)


	--[[
	Buildings without workers are dangerous for simulation if they are handled like this,
	and moreover this code is bugged: it records consumption of use case
	into array of trade goods data. Disabling it for now
	for _, bld_location in pairs(DATA.get_building_location_from_location(province)) do
		local building = DATA.building_location_get_building(bld_location)
		local building_type = DATA.building_get_type(building)
		local production_method = DATA.building_type_get_production_method(building_type)
		local has_jobs = false

		for i = 0, MAX_SIZE_ARRAYS_PRODUCTION_METHOD - 1 do
			local job = DATA.production_method_get_jobs_job(production_method, i)
			if job == INVALID_ID then
				break
			end

			has_jobs = true
			break
		end

		if not has_jobs then
			-- If a building has no jobs, it always works!
			local efficiency = 1
			for i = 0, MAX_SIZE_ARRAYS_PRODUCTION_METHOD - 1 do
				local amount = DATA.production_method_get_inputs_amount(production_method, i)
				local input = DATA.production_method_get_inputs_use(production_method, i)
				if input == INVALID_ID then
					break
				end

				record_consumption(input, amount)
				record_demand(input, amount)
			end

			for i = 0, MAX_SIZE_ARRAYS_PRODUCTION_METHOD - 1 do
				local amount = DATA.production_method_get_outputs_amount(production_method, i)
				local output = DATA.production_method_get_outputs_good(production_method, i)
				if output == INVALID_ID then
					break
				end

				record_production(output, amount * efficiency)
			end
		end
	end
	--]]

	-- At last, record all data

	---comment
	---@param good trade_good_id
	local function record_data(good)
		-- check that we didn't go over the stockpile or possible remaining services from last tick
		if DATA.province_get_local_storage(province, good) + market_data[good].supply - market_data[good].consumption < -EPSILON
		then
			error(
				"INVALID MARKET DATA AFTER PRODUCTION-AND-CONSUPTION TICK"
				.. "\n market_data[".. good .."].available = "
				.. tostring(market_data[good].available)
				.. "\n province.local_storage[".. good .."] = "
				.. tostring(DATA.province_get_local_storage(province, good))
				.. "\n market_data[".. good .."].local_production = "
				.. tostring(DATA.province_get_local_production(province, good))
				.. "\n market_data[".. good .."].local_consumption = "
				.. tostring(DATA.province_get_local_consumption(province, good))
				.. "\n market_data[".. good .."].supply = "
				.. tostring(market_data[good].supply)
				.. "\n market_data[".. good .."].consumption = "
				.. tostring(market_data[good].consumption)
			)
		end
		DATA.province_set_local_consumption(province, good, market_data[good].consumption)
		DATA.province_set_local_demand(province, good, market_data[good].demand)
		DATA.province_set_local_supply(province, good, market_data[good].supply)
	end
	DATA.for_each_trade_good(record_data)
end

return pro