local trade_good = require "game.raws.raws-utils".trade_good
local use_case = require "game.raws.raws-utils".trade_good_use_case
local JOBTYPE = require "game.raws.job_types"

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

local amount_of_goods = tabb.size(RAWS_MANAGER.trade_goods_by_name)
local amount_of_job_types = tabb.size(JOBTYPE)

---@type MarketData[]
local market_data = ffi.new("good_data[?]", amount_of_goods)

---@type POPView[]
local pop_view = ffi.new("pop_view[1]")

---@type number[]
local pop_job_efficiency = ffi.new("float[?]", amount_of_job_types)

-- TODO: rewrite to ffi

---@type table<TradeGoodUseCaseReference, number>
local use_case_total_exp = {}
---@type table<TradeGoodUseCaseReference, number>
local use_case_price_expectation = {}

local zero = 0
local total_realm_donations = 0
local total_local_donations = 0
local total_trade_donations = 0

---Calculates weighted price expectation for a list of goods
-- weight means how effective this trade good
-- which means that price expectation will integrate 1 / weight
---@param set_of_goods table<TradeGoodReference, number>
---@return number total_exp total value for softmax
---@return number expectation price expectation
local function get_price_expectation_weighted(set_of_goods)
	local total_exp = 0
	for good, weight in pairs(set_of_goods) do
		local c_index = RAWS_MANAGER.trade_good_to_index[good] - 1
		total_exp = total_exp + market_data[c_index].feature / weight
	end

	-- price expectation:
	local price_expectation = 0
	for good, weight in pairs(set_of_goods) do
		local c_index = RAWS_MANAGER.trade_good_to_index[good] - 1
		price_expectation = math.max(0.0001, price_expectation + market_data[c_index].price * market_data[c_index].feature / total_exp / weight)
	end

	return total_exp, price_expectation
end


---Runs production on a single province!
---@param province Province
function pro.run(province)
	total_realm_donations = 0
	total_local_donations = 0
	total_trade_donations = 0

	-- how much of income is siphoned to local wealth pool
	INCOME_TO_LOCAL_WEALTH_MULTIPLIER = 0.125 / 4
	-- buying prices for pops are multiplied on this number
	POP_BUY_PRICE_MULTIPLIER = 1.5

	---@type table<TradeGoodReference, number>
	local old_prices = {}

	-- reset data
	for i, good in ipairs(RAWS_MANAGER.trade_goods_list) do
		-- available resources calculation:
		local consumption = province.local_consumption[good] or 0
		local production = province.local_production[good] or 0
		local storage = province.local_storage[good] or 0
		market_data[i - 1].available = storage
		if market_data[i - 1].available < 0 then
			error("INVALID START TO PRODUCTION-AND-CONSUMPTION TICK"
			.. "\n market_data[" .. i - 1 .. "].available = "
			.. tostring(market_data[i - 1].available)
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
		market_data[i - 1].price = price
		old_prices[good] = price
		market_data[i - 1].feature = C.expf(-C.sqrtf(market_data[i - 1].price) / (1 + math.max(storage + production - consumption, 0)))
		market_data[i - 1].consumption = 0
		market_data[i - 1].supply = 0
		market_data[i - 1].demand = 0
	end

	for tag, use_case in pairs(RAWS_MANAGER.trade_goods_use_cases_by_name) do
		use_case_total_exp[tag], use_case_price_expectation[tag] = get_price_expectation_weighted(use_case.goods)
	end

	-- Clear building stats
	for _, value in pairs(province.buildings) do
		tabb.clear(value.amount_of_outputs)
		tabb.clear(value.earn_from_outputs)
		tabb.clear(value.amount_of_inputs)
		tabb.clear(value.spent_on_inputs)
		tabb.clear(value.worker_income)
		value.last_donation_to_owner = 0
		value.last_income = 0
		value.subsidy_last = 0
	end

	---Records local consumption!
	---@param good_index number
	---@param amount number
	local function record_consumption(good_index, amount)

		if amount < 0
			or market_data[good_index - 1].available < 0
			or market_data[good_index - 1].available < amount
		then
			error(
				"INVALID ATTEMPT AT RECORDING OF CONSUMPTION"
				.. "\n amount = "
				.. tostring(amount)
				.. "\n  market_data[good_index - 1].available = "
				.. tostring(market_data[good_index - 1].available)
			)
		end
		-- to prevent consumption from ever reaching over available
		local consumed_amount = math.min(market_data[good_index - 1].available, amount)

		if market_data[good_index - 1].available < consumed_amount then
			error(
				"INVALID RECORD OF GOODS CONSUMPTION"
				.. "\n  market_data[good_index - 1].available = "
				.. tostring(market_data[good_index - 1].available)
				.. "\n  consumed_amount = "
				.. tostring(consumed_amount)
			)
		end

		market_data[good_index - 1].consumption = market_data[good_index - 1].consumption + consumed_amount
		market_data[good_index - 1].available = market_data[good_index - 1].available - consumed_amount

		return market_data[good_index - 1].price * consumed_amount
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

		market_data[good_index - 1].supply = market_data[good_index - 1].supply + amount
		market_data[good_index - 1].available = market_data[good_index - 1].available + amount

		return market_data[good_index - 1].price * amount
	end


	---Record local demand!
	---@param good_index number
	---@param amount number
	local function record_demand(good_index, amount)
		market_data[good_index - 1].demand = market_data[good_index - 1].demand + amount

		return market_data[good_index - 1].price * amount
	end

	local total_need_count = tabb.size(NEED)
	local life_need_count = tabb.size(tabb.filter(NEEDS, function (a)
		return a.life_need
	end))

	-- Record "innate" production of goods and services.
	-- These resources come
	--local water_index = RAWS_MANAGER.trade_good_to_index["water"]
	--record_production(water_index, province.hydration)

	local efficiency_from_infrastructure = province:get_infrastructure_efficiency()
	-- Record local production...
	-- TODO MAKE NEW EFFICIENCY FUNCTION FOR FULL PRODUCTION AT 0 FORAGERS AND 0-ISH AT FORAGERS LIMIT
	local last_foraging_efficiency = dbm.foraging_efficiency(province.foragers_limit, province.foragers)
	local last_hydration_efficiency = dbm.foraging_efficiency(province.hydration * 0.5, province.foragers_water)
	local foragers_count = 0
	local foragers_water = 0
	local foragers_efficiency = 1
	local hydration_efficiency = 1

	local old_wealth = province.local_wealth -- store wealth before this tick, used to calculate income later
	local population = province:local_population()
	local min_income_pop = math.max(50, math.min(200, 100 + province.mood * 10))


	-- TODO: IMPLEMENT CULTURAL VALUE
	local fraction_of_income_given_voluntarily = 0.1 * math.max(0, math.min(1.0, 1.0 - population / min_income_pop))
	local fraction_of_income_given_to_owner = 0.1

	DISPLAY_INCOME_OWNER_RATIO = (1 - INCOME_TO_LOCAL_WEALTH_MULTIPLIER) * fraction_of_income_given_to_owner


	---Pop forages for plants, game, and fish; takes a forager and time and returns a list of output products with amounts \
	-- Not very efficient
	---@param pop_view POPView[]
	---@param pop_table POP
	---@param use_case TradeGoodUseCaseReference
	---@param time number ratio of daily active time pop can spend on foraging
	---@return table<TradeGoodReference, number> products
	local function forage(pop_view, pop_table, use_case, time)
		local forage_efficiency, handle_efficiency
		if use_case == 'water' then
			forage_efficiency, handle_efficiency = hydration_efficiency, pop_view[zero].hydration_efficiency -- pulling from water pool
		else
			forage_efficiency, handle_efficiency = foragers_efficiency, pop_view[zero].foraging_efficiency -- pulling from calories pool
		end
	--	print("  " .. pop_table.race.name .. " " .. pop_table.age ..  (pop_table.female and " f" or " m") .. " FORAGING: " .. forage_efficiency .. " FOR ".. time )
    	-- weight amount found by searching efficiencies and cultual search times
		local forage_goods = tabb.accumulate(province.foragers_targets, {}, function (forage_goods, province_resource, province_values)
			local cultural_resource = pop_table.culture.traditional_forager_targets[use_case].targets[province_resource]
			if cultural_resource and province_values.amount > 0 then
	--			print("    RESOURCE: " .. dbm.ForageResourceName[province_resource] .. " FOR ".. cultural_resource * time )
				local amount = province_values.amount
				-- foraging efficiency reduces search times from overabundance and reduces when competing for limited CC
				local search = amount / province.size / forage_efficiency
				local handle = pop_job_efficiency[province_values.handle] * handle_efficiency
				local dividend = amount * search
				local divisor = search + amount / handle * search
				local output =  dividend / divisor * cultural_resource * time
				tabb.accumulate(province_values.output, nil, function (_, good, amount)
	--				print("      GOOD: " .. good .. " COLLECTED: ".. amount * output )
					forage_goods[good] = (forage_goods[good] or 0) + amount * output
				end)
			end
			return forage_goods
		end)
	--	print("   Total Resources")
		for good, value in pairs(forage_goods) do
	--		print("   -: " .. good .. " " .. value)
		end
		return forage_goods
	end

	---Pop forages for food and gives it to warband  \
	-- Not very efficient
	---@param pop_view POPView[]
	---@param pop_table POP
	---@param time number ratio of daily active time pop can spend on foraging
	local function forage_warband(pop_view, pop_table, time)
		local warband = pop_table.unit_of_warband
		local income = 0
		local foraged_food = forage(pop_view, pop_table, 'calories', time)
		if warband and warband.leader then
			for good, amount in pairs(foraged_food) do
				warband.leader.inventory[good] = (warband.leader.inventory[good] or 0) + amount
			end
		else
			for good, amount in pairs(foraged_food) do
			local good_index = RAWS_MANAGER.trade_good_to_index[good]
				income = income + record_production(good_index ,amount)
			end
			if income > 0 then
				if warband then
					economic_effects.gift_to_warband(warband, pop_table, income)
				else
					economic_effects.add_pop_savings(pop_table, income, economic_effects.reasons.Forage)
				end
			end
		end
	end


	---Returns purchasable units of use_case available in province
	---@param use_reference TradeGoodUseCaseReference
	---@return number amount
	local function available_goods_for_use(use_reference)
		local use = use_case(use_reference)
		local total_available = 0

		for good, weight in pairs(use.goods) do
			local c_index = RAWS_MANAGER.trade_good_to_index[good] - 1
			total_available = total_available + market_data[c_index].available
		end

		return total_available
	end

	---Buys goods according to their use and required amount
	---@param use_reference TradeGoodUseCaseReference
	---@param amount number
	---@param savings number how much money you are ready to spend
	---@return number spendings
	---@return number consumed
	local function buy_use(use_reference, amount, savings)
		if amount < 0 or savings < 0 then return 0, 0 end
		local use = use_case(use_reference)

		local total_exp = use_case_total_exp[use_reference]
		local price_expectation = use_case_price_expectation[use_reference]
		local demanded_use = math.min(amount, savings / price_expectation)

		local available = available_goods_for_use(use_reference)
		local potential_amount = math.min(available, demanded_use)

		local total_bought = 0
		local spendings = 0

		for good, weight in pairs(use.goods) do
			local c_index = RAWS_MANAGER.trade_good_to_index[good] - 1
			local goods_price = math.max(market_data[c_index].price, 0.0001)
			local goods_available = market_data[c_index].available
			local goods_available_weight = available > 0 and (market_data[c_index].available / weight / available) or 0
			local goods_feature_weight = total_exp > 0 and (market_data[c_index].feature / total_exp) or 0
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
				.. tostring(market_data[c_index].feature)
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

			spendings = spendings + record_consumption(c_index + 1, consumed_amount)
			record_demand(c_index + 1, demanded_amount)
		end
		if spendings > savings + 0.01
			or total_bought > amount + 0.01
		then
			error("INVALID BUY USE ATTEMPT"
				.. "\n use_reference = "
				.. tostring(use_reference)
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

	---comment
	---@param pop_view POPView
	---@param pop_table POP
	---@param need_satisfaction table<NEED, table<TradeGoodUseCaseReference, {consumed: number, demanded: number}>>
	---@param need_index NEED
	---@param need Need
	---@param free_time number
	---@param savings number
	---@return number free_time_used
	---@return number expenses
	---@return table<TradeGoodUseCase, number> consumed
	local function satisfy_need(pop_view, pop_table, need_satisfaction, need_index, need, free_time, savings)
		local income, expenses, total_need_time, total_need_cost = 0, 0, 0.001, 0.001
		local total_bought = {[need_index] = {}}
	--	print("  ".. NEED_NAME[need_index] .. " free_time: " .. free_time .. " saving: " .. savings ..  " saving: " .. target)
		-- start with calculation of distribution over goods:
		-- "distribution" "density" is precalculated, we only need to find a normalizing coef.
		local need_job_efficiency = pop_job_efficiency[need.job_to_satisfy]

		local cottage_time_per_unit = need.time_to_satisfy / need_job_efficiency

		-- collect data, get all need use_cases demand
		-- expected costs and estimated time needed to satisfy
		---@type table<string,{need_amount: number, need_cost: number, need_time: number}>
		local need_cases = {}
		for case, value in pairs(need_satisfaction[need_index]) do
			if use_case_total_exp[case] > 0 then
				local need_amount = value.demanded
				-- induced demand:
				local price_expectation = math.max(use_case_price_expectation[case] or 0, 0.0001)
				local induced_demand = math.min(2, math.max(0, 1 / price_expectation - 1))
		--		print("    " .. " case: " .. case .." need: " .. need_amount .. " induced_demand: " .. need_amount * (1 + induced_demand))
				need_amount = need_amount * (1 + induced_demand)
				need_amount = need_amount
				if need_amount < 0 then
					error("Demanded need is lower than zero!")
				end
				-- estimate cost in money and time to satisfy each use_case
				local remaining_need_amount = math.max(0, need_amount - value.consumed)
				local need_cost = price_expectation * remaining_need_amount * POP_BUY_PRICE_MULTIPLIER
				local need_time = remaining_need_amount * cottage_time_per_unit
				need_cases[case] = {need_amount = remaining_need_amount, need_cost = need_cost , need_time = need_time}
				-- count totals for weighting
				total_need_cost = total_need_cost + need_cost
				total_need_time = total_need_time + need_time
			end
		end
		local total_time_used = 0
		for case, values in pairs(need_cases) do
			-- split time and money up to satisfy each need case
--			local time_fraction = free_time * values.need_time / total_need_time
			local savings_fraction = savings * values.need_cost / total_need_cost
			-- attempt to buy from market with savings fraction
			if savings_fraction > 0 then
				local spendings, consumed = buy_use(case, values.need_amount, savings_fraction)
	--			print("    " .. " case: " .. case .." spendings: " .. spendings .. " consumed: " .. consumed)
				total_bought[need_index][case] = (total_bought[need_index][case] or 0) + consumed
				expenses = expenses + spendings

				if consumed > values.need_amount + 0.01
					or spendings > savings_fraction + 0.01
				then
					error("INVALID BUY_USE ATTEMPT IN SATISFY_NEED"
						.. "\n case = "
						.. tostring(case)
						.. "\n spendings = "
						.. tostring(spendings)
						.. "\n savings_fraction = "
						.. tostring(savings_fraction)
						.. "\n consumed = "
						.. tostring(consumed)
						.. "\n need_amount = "
						.. tostring(values.need_amount)
					)
				end
			end
--[[
			-- use time fraction to satisfy remaning need
			if time_fraction > 0 then
				local demanded = math.max(0, (need_satisfaction[need_index][case].demanded or 0) * target
					- (total_bought[need_index][case] or 0))
				local need_amount = math.max(0, demanded - (total_bought[need_index][case] or 0))
				if need_amount > 0 then
					local cottage_time = math.min(time_fraction, need_amount * cottage_time_per_unit)
					if need.job_to_satisfy == JOBTYPE.FORAGER then
						foragers_count = foragers_count + cottage_time
					end
					local cottaged = cottage_time / cottage_time_per_unit

					if cottaged > need_amount + 0.01
						or cottage_time > time_fraction + 0.01
					then
						error("INVALID COTTAGING ATTEMPT IN SATISFY_NEED"
							.. "\n time_fraction = "
							.. tostring(time_fraction)
							.. "\n total_need_time = "
							.. tostring(total_need_time)
							.. "\n total_need_cost = "
							.. tostring(total_need_cost)
							.. "\n need_amount = "
							.. tostring(need_amount)
						)
					end

					total_time_used = total_time_used + cottage_time
					total_bought[need_index][case] = (total_bought[need_index][case] or 0) + cottaged

					if total_bought[need_index][case] ~= total_bought[need_index][case] then
						error("NAN IN SATISFY_NEED"
							.. "\n cottage_time_per_unit = "
							.. tostring(cottage_time_per_unit)
							.. "\n cottage_time = "
							.. tostring(cottage_time)
							.. "\n need_job_efficiency = "
							.. tostring(need_job_efficiency)
						)
					end
				end

			end
]]
			if total_time_used > free_time + 0.01 then
				error("INVALID AMOUNT OF TIME SPENT IN SATISFY NEED"
					.. "\n total_time_used = "
					.. tostring(total_time_used)
					.. "\n free_time = "
					.. tostring(free_time)
				)
			end
		end

		if total_time_used > free_time + 0.01
			or expenses > savings + income + 0.01
		then
			error("INVALID SATISFY_NEED"
				.. "\n total_time_used = "
				.. tostring(total_time_used)
				.. "\n free_time = "
				.. tostring(free_time)
				.. "\n expenses = "
				.. tostring(expenses)
				.. "\n income = "
				.. tostring(income)
				.. "\n savings = "
				.. tostring(savings)
			)
		end
		return total_time_used, expenses, total_bought
	end

	---comment
	---@param pop_view POPView
	---@param pop_table POP
	---@param free_time number
	---@param savings number
	local function satisfy_needs(pop_view, pop_table, free_time, savings)

		-- BUILD TOTAL FAMILY NEEDS
	--	print("FAMILY UNIT: " .. pop_table.name .. " (" .. 1 + tabb.size(pop_table.children) .. ")")
		-- start with family head (parent) as base
		---@type table<NEED, table<TradeGoodReference, {consumed: number, demanded: number}>>
		local family_unit_needs = tabb.accumulate(pop_table.need_satisfaction, {}, function (family_head_needs, need, use_cases) ---@param family_head_needs table<NEED, table<TradeGoodUseCaseReference, {consumed: number, demanded: number}>>
			family_head_needs[need] = tabb.accumulate(use_cases, {}, function (need_satisfaction, case, case_values)---@param need_satisfaction table<TradeGoodUseCaseReference, {consumed: number, demanded: number}>
				need_satisfaction[case] = {consumed = 0, demanded = case_values.demanded}
				return need_satisfaction
			end)
			return family_head_needs
		end)

	--	print("  FAMILY HEAD NEADS:")
	--	for need, need_use_case in pairs(family_unit_needs) do
	--		print("    " .. NEED_NAME[need] .. ": ")
	--		for case, value in pairs(need_use_case) do
	--			print("      " .. case .. ": " .. value.consumed .. " / " .. value.demanded)
	--		end
	--	end

		-- collect children's needs
		tabb.accumulate(pop_table.children, nil, function (_, _, v)
	--		print("  CHILD NEEDS: " .. v.name)
			tabb.accumulate(v.need_satisfaction, nil, function (_, need, use_cases)
	--			print("    " .. NEED_NAME[need] .. ": ")
				tabb.accumulate(use_cases, nil, function (_, case, case_values)
	--				print("      " .. case .. ": " .. case_values.consumed .. " / " .. case_values.demanded)
					family_unit_needs[need][case] = {consumed = 0, demanded = (family_unit_needs[need][case].demanded or 0) + case_values.demanded}
				end)
			end)
		end)

	--	print("  TOTAL FAMILY UNIT NEEDS:")
	--	for need, cases in pairs(family_unit_needs) do
	--		print("    " .. NEED_NAME[need] .. ": ")
	--		for case, value in pairs(cases) do
	--			print("      " .. case .. ": " .. value.demanded)
	--		end
	--	end

		-- go through each food use case and forage to satisfy that case
		local total_forage_time = 0
		local foraged_goods = tabb.accumulate(pop_table.culture.traditional_forager_targets, {}, function (a, use_case, values)
			local forage_time = free_time * values.search
			total_forage_time = total_forage_time + forage_time
			local foraged_goods = forage(pop_view, pop_table, use_case, forage_time)
	--		print("  USE CASE: " .. use_case .. " SATISFACTION: " .. family_unit_needs[NEED.FOOD][use_case].consumed .. " / " .. family_unit_needs[NEED.FOOD][use_case].demanded)
			-- consume for use case only
			for good, amount in pairs(foraged_goods) do
				local weight = RAWS_MANAGER.trade_goods_use_cases_by_name[use_case].goods[good]
				local difference = math.max(0, family_unit_needs[NEED.FOOD][use_case].demanded - family_unit_needs[NEED.FOOD][use_case].consumed)
				if weight and difference > 0 and family_unit_needs[NEED.FOOD][use_case].demanded > family_unit_needs[NEED.FOOD][use_case].consumed then
					local weighted_amount = weight * amount
					local consumption = math.min(weighted_amount, difference)
					amount = math.max(0, amount - consumption / weight)
					family_unit_needs[NEED.FOOD][use_case].consumed = family_unit_needs[NEED.FOOD][use_case].consumed + consumption
	--				print("    GOOD: " .. good .. " FORAGED: " .. foraged_goods[good] .. " CONSUMED: " .. consumption .. " -> " .. family_unit_needs[NEED.FOOD][use_case].consumed)
				end
				-- add any remaing to list of goods to sell
				if amount > 0 then
					a[good] =( a[good] or 0) + amount
				end
			end
			return a
		end)
		local time_after_foraging = math.max(0, free_time - total_forage_time)

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
			if amount > 0 then
				local good_index = RAWS_MANAGER.trade_good_to_index[good]
				local production = record_production(good_index, amount)
	--			print("    SOLD :" .. amount .. " OF " .. good .. " FOR " .. production)
				income = income + production
			end
		end

		-- BUYING NEEDS
		local cottaging_time, need_buy_cost, time_after_needs = {}, {}, math.max(0, time_after_foraging)
		local total_needs_cottage_time = tabb.accumulate(NEEDS, 0, function (total_needs_cottage_time, index, need)
			local cummulative_use_totals = tabb.accumulate(family_unit_needs[index], 0, function (a, case, value)
				return a + math.max(0, value.demanded - value.consumed)
			end)
			cottaging_time[index] = cummulative_use_totals * need.time_to_satisfy / pop_job_efficiency[need.job_to_satisfy]
			return total_needs_cottage_time + cottaging_time[index]
		end)

		local total_need_cost = tabb.accumulate(NEEDS, 0, function (total_needs_cost, index, need)
			local cummulative_use_totals = tabb.accumulate(family_unit_needs[index], 0, function (a, case, value)
				return a + math.max(0, value.demanded - value.consumed) * use_case_price_expectation[case]
			end)
			need_buy_cost[index] = cummulative_use_totals
			return total_needs_cost + cummulative_use_totals
		end)
		local need_weight = life_need_count + total_need_count
		local savings_temp = savings + income
		local total_expense = 0
		for index, need in pairs(NEEDS) do
			local time_fraction = time_after_foraging * cottaging_time[index] / total_needs_cottage_time
			local savings_fraction = savings_temp * need_buy_cost[index] / total_need_cost * 0.99 -- to counter potential float errors
			local free_time_for_need, expense, consumed = satisfy_need(
				pop_view, pop_table, family_unit_needs, index, need,
				time_fraction,
				savings_fraction)

			total_expense = total_expense + expense

			time_after_needs = time_after_needs - free_time_for_need

			tabb.accumulate(consumed[index], nil, function (_, k, v)
	--			print("  " .. NEED_NAME[index] .. " BOUGHT: " .. " " .. k .. " " .. v)
				family_unit_needs[index][k].consumed = family_unit_needs[index][k].consumed + v
			end)

			if expense > savings_fraction + 0.01
				or free_time_for_need > time_fraction + 0.01
				or savings + income + 0.01 < total_expense
			then
				error("INVALID SATISFY_NEED"
					.. "\n need = "
					.. tostring(NEED_NAME[index])
					.. "\n expense = "
					.. tostring(expense)
					.. "\n savings_fraction = "
					.. tostring(savings_fraction)
					.. "\n savings = "
					.. tostring(savings)
					.. "\n income = "
					.. tostring(income)
					.. "\n total_expense = "
					.. tostring(total_expense)
					.. "\n free_time_for_need = "
					.. tostring(free_time_for_need)
					.. "\n time_faction = "
					.. tostring(time_fraction)
				)
			end
		end

		local low_life_need, high_life_need = false, true
		-- DISTRIBUTE CONSUMPTION TO PARENT AND CHILDREN
		for need, cases in pairs(family_unit_needs) do
	--		print("    " .. NEED_NAME[need] .. ": ")
			for case, value in pairs(cases) do
	--			print("      " .. case .. ": " .. value.consumed .. " / " .. value.demanded)
				local satisfaction_ratio = value.consumed  / value.demanded
				if NEEDS[need].life_need then
					if satisfaction_ratio < 0.6 then
						low_life_need = true
						high_life_need = false
					elseif satisfaction_ratio < 0.8 then
						high_life_need = false
					end
				end
				pop_table.need_satisfaction[need][case].consumed = satisfaction_ratio * pop_table.need_satisfaction[need][case].demanded
				pop_table:get_need_satisfaction()
				for _, child in pairs(pop_table.children) do
					if child.need_satisfaction[need] and child.need_satisfaction[need][case] then
						child.need_satisfaction[need][case].consumed = satisfaction_ratio * child.need_satisfaction[need][case].demanded
					end
				end
			end
		end

		--update children statisfaction rations
		for _, child in pairs(pop_table.children) do
			child:get_need_satisfaction()
		end
		if savings + income + 0.01 < total_expense
			or income ~= income
			or total_expense ~= total_expense
		then
			error("INVALID SATISFY_NEEDS"
				.. "\n savings = "
				.. tostring(savings)
				.. "\n income = "
				.. tostring(income)
				.. "\n total_expense = "
				.. tostring(total_expense)
				.. "\n time_after_needs = "
				.. tostring(time_after_needs)
				.. "\n free_time = "
				.. tostring(free_time)
			)
		end

		-- adjust pop savings
		economic_effects.add_pop_savings(pop_table, income, economic_effects.reasons.Forage)
		economic_effects.add_pop_savings(pop_table, -total_expense, economic_effects.reasons.BasicNeeds)

		-- for next month determine if it should forage more or less
		if low_life_need == true then -- any single life need use cases below 50%
			pop_table.forage_ratio = math.min(0.99, pop_table.forage_ratio * 1.15)
			pop_table.work_ratio = math.max(0.01, 1 - pop_table.forage_ratio)
		elseif high_life_need == true then -- all life need use cases are over 60%
			pop_table.forage_ratio = math.max(0.01, pop_table.forage_ratio * 0.9)
			pop_table.work_ratio = math.max(0.01, 1 - pop_table.forage_ratio)
		end
	end


	local total_popularity = 0
	---@type table<POP, number>
	local donations_to_owners = {}

	-- pre-update: information gathering / setting variable
	local additional_family_time = {}
	local tools_satisfaction, storage_satisfaction = {}, {}
	-- sort pops by wealth:
	---@type POP[]
	local pops_by_wealth = tabb.accumulate(
		tabb.join(tabb.copy(province.all_pops), province.characters),
		{},function (a, _, pop)
			-- record total time for family dependents only if in same province
			if pop.home_province == province then
				tabb.size(tabb.filter(pop.children, function (child)
					if child.age < child.race.teen_age then
							additional_family_time[pop] = (additional_family_time[pop] or 0) + child.age / child.race.teen_age * pop:get_age_multiplier()
						return true
					end
					return false
				end))
			end
			if not pop:is_character() then
				-- pops donate some of their savings as well:
				local pop_donation_total = pop.savings / 120
				total_realm_donations = total_realm_donations + pop_donation_total * 0.4
				total_local_donations = total_local_donations + pop_donation_total * 0.4
				total_trade_donations = total_trade_donations + pop_donation_total * 0.2
			else
				local popularity = pv.popularity(pop, province.realm)
				if popularity > 0 then
					total_popularity = total_popularity + popularity
				end
			end
			-- update 'family units', add to pop satisfy needs list only if an 'adult' or an absant parent, either away or none at all
			if (pop.age >= pop.race.teen_age) or (not pop.parent or pop.parent.province ~= pop.province) then
				-- record foraging time of 'family unit' for efficiency
				local water_search = pop.culture.traditional_forager_targets['water'].search
				local foragers_increase = pop.race.carrying_capacity_weight * pop:get_age_multiplier()
				-- if in warband and foraging, half of free time goes to foraging for warband
				if pop.age < pop.race.teen_age then
					foragers_increase = foragers_increase * pop.age / pop.race.teen_age
				elseif pop.unit_of_warband and pop.unit_of_warband.status == "idle" and pop.unit_of_warband.idle_stance == "forage" then
					local weight = foragers_increase * pop.unit_of_warband.current_free_time_ratio * 0.25
					foragers_count = foragers_count + weight
					foragers_increase = weight * 3
				end
				-- add children's times and weight by desired foraging percentage
				foragers_increase = pop.forage_ratio * (foragers_increase + (additional_family_time[pop] or 0))
				-- add 'family unit' to production and consumption cycle
				table.insert(a, pop)
				foragers_count = foragers_count + foragers_increase * (1 - water_search)
				foragers_water = foragers_water + foragers_increase * water_search
				
			end
			-- recalculate pop needs
			-- TOTO solve starvation from travling/raiding/patroling instead of reducing consumption, replace with warband supplies? 
			local consumption_percentage = 0
			if pop.unit_of_warband ~= nil and pop.unit_of_warband.status ~= "idle" then
				consumption_percentage = 0.9
			end
			-- reset consumption and update demands of need satisfaction
			local forage_time = pop.forage_ratio
			local water_search = pop.culture.traditional_forager_targets['water'].search
			tabb.accumulate(NEEDS, nil, function (_, need_index, _)
				-- get foraging efficiencies from satisfactions and add needs from pop's foraging plans
				if forage_time > 0.01 then
					-- get food foraging efficiency from tools satisfaction
					if need_index == NEED.TOOLS then
						if pop.need_satisfaction[NEED.TOOLS] then
							-- weight foraging_efficiency by tools satisfaction
							local tools_like_need = pop.need_satisfaction[NEED.TOOLS]['tools-like']
							local tools_like_satisfaction = tools_like_need.consumed / tools_like_need.demanded
							local containers_need = pop.need_satisfaction[NEED.TOOLS]['containers']
							local containers_satisfaction = containers_need.consumed / containers_need.demanded
							-- between 0 and 0.5 with induced demand
							tools_satisfaction[pop] = tools_like_satisfaction / (tools_like_satisfaction + 3)
							storage_satisfaction[pop] = containers_satisfaction / (containers_satisfaction + 3)
						else
							tools_satisfaction[pop] = 0
							storage_satisfaction[pop] = 0
						end
					-- get water foraging efficiency from storage satisfaction
					end
					-- add tools and storage based on foraging increase
					if not pop.need_satisfaction[NEED.TOOLS] then
						pop.need_satisfaction[NEED.TOOLS] = {
							['tools-like'] = {consumed = 0, demanded = 0},
							['containers'] = {consumed = 0, demanded = 0}
						}
					end
					pop.need_satisfaction[NEED.TOOLS]['tools-like'].demanded = pop.race.carrying_capacity_weight * pop.forage_ratio * (1 - water_search) * pop:get_age_multiplier()
					pop.need_satisfaction[NEED.TOOLS]['containers'].demanded = pop.race.carrying_capacity_weight * pop.forage_ratio * water_search * pop:get_age_multiplier()
				else
					-- remove tools and storage need from pop table since not really foraging
					pop.need_satisfaction[NEED.TOOLS]['tools-like'] = nil
					pop.need_satisfaction[NEED.TOOLS]['containers'] = nil
					if pop.need_satisfaction[NEED.TOOLS] and tabb.size(pop.need_satisfaction[NEED.TOOLS]) == 0 then pop.need_satisfaction[NEED.TOOLS] = nil end
				end
				-- reset any other need
				if pop.need_satisfaction[need_index] then
					tabb.accumulate(pop.need_satisfaction[need_index], nil, function (_, k, values)
						pop.need_satisfaction[need_index][k].consumed = pop.need_satisfaction[need_index][k].consumed * consumption_percentage
					end)
				end
			end)
			return a
		end)
	table.sort(pops_by_wealth, function (a, b)
		return a.savings > b.savings
	end)

	-- calculate foragers efficiency base on planned foraging
	foragers_efficiency = dbm.foraging_efficiency(province.foragers_limit, foragers_count)
	hydration_efficiency = dbm.foraging_efficiency(province.hydration * 0.5, foragers_water)

	PROFILER:start_timer("production-pops-loop")
	for _, pop in ipairs(pops_by_wealth) do

		-- populate pop_view
		pop_view[zero].age_multiplier = pop:get_age_multiplier()

		-- populate job efficiency
		for tag, value in pairs(JOBTYPE) do
			pop_job_efficiency[value] = pop:job_efficiency(value)
		end
		pop_view[zero].foraging_efficiency = pop.race.carrying_capacity_weight * (1 + tools_satisfaction[pop])
		pop_view[zero].hydration_efficiency = pop.race.carrying_capacity_weight * (1 + storage_satisfaction[pop])

		-- base income: all adult pops forage and help each other which translates into a bit of wealth
		-- real reason: wealth sources to fuel the economy
		-- buidings are essentially wealth sinks currently
		-- so obviously we need some wealth sources
		-- should be removed when economy simulation will be completed
		local base_income = pop.race.carrying_capacity_weight * pop.age / pop.race.max_age;
		economic_effects.add_pop_savings(pop, base_income, economic_effects.reasons.MonthlyChange)

		local free_time_of_pop = 1;
		-- Drafted pops work only when warband is "idle"
		if (pop.unit_of_warband == nil) or (pop.unit_of_warband.status == "idle") then
			-- if pop is in the warband,
			if pop.unit_of_warband then
				if pop.unit_of_warband.idle_stance == "forage" then
					-- spend some time on foraging for warband:
					forage_warband(pop_view, pop, pop.unit_of_warband.current_free_time_ratio * 0.25)
					free_time_of_pop = pop.unit_of_warband.current_free_time_ratio * 0.75
				else
					-- or spend all the time working like other pops
					free_time_of_pop = pop.unit_of_warband.current_free_time_ratio
				end
			end

			PROFILER:start_timer('production-building-update')
			local building = pop.employer
			if building ~= nil then
				local prod = building.type.production_method

				local income = 0
				local work_time = pop.work_ratio * free_time_of_pop
				local local_foraging_efficiency = 1
				if prod.foraging then
					-- buildings operate off off last month's foraging use, otherwise race conditions on output
					foragers_count = foragers_count + work_time * pop_view[zero].foraging_efficiency
					local_foraging_efficiency = local_foraging_efficiency * math.min(foragers_efficiency, last_foraging_efficiency)
				end
				if prod.hydration then
					-- buildings operate off off last month's foraging use, otherwise race conditions on output
					foragers_water = foragers_count + work_time * pop_view[zero].foraging_efficiency
					local_foraging_efficiency = local_foraging_efficiency * math.min(hydration_efficiency, last_hydration_efficiency)
				end
				local yield = prod:get_efficiency(province)

				local efficiency = yield
									* local_foraging_efficiency
									* efficiency_from_infrastructure
									* work_time

				-- expected input satisfaction
				local input_satisfaction = 1

				for input, amount in pairs(prod.inputs) do
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
						.. tostring(pop.work_ratio)
						.. "\n efficiency_from_infrastructure = "
						.. tostring(efficiency_from_infrastructure)
						.. "\n local_foraging_efficiency = "
						.. tostring(local_foraging_efficiency)
					)
				end

				local _, input_boost, output_boost, throughput_boost
					= ev.projected_income(
						pop.employer,
						pop.race,
						pop.female,
						old_prices,
						efficiency
					)

				if prod.forest_dependence > 0 then
					local years_to_deforestate = 50
					local days_to_deforestate = years_to_deforestate * 360
					local total_power = prod.forest_dependence * efficiency * throughput_boost * input_boost / days_to_deforestate
					require "game.raws.effects.geography".deforest_random_tile(province, total_power)
				end


				-- real input satisfaction
				local input_satisfaction_2 = 1
				local production_budget = pop.savings / 2

				if efficiency > 0 then
					for input, amount in pairs(prod.inputs) do
						local required = input_boost * amount * efficiency
						local spent, consumed = buy_use(input, required, production_budget)

						input_satisfaction_2 = math.min(input_satisfaction_2, consumed / required)
						income = income - spent

						building.amount_of_inputs[input] = (building.amount_of_inputs[input] or 0) + consumed
						building.spent_on_inputs[input] = (building.spent_on_inputs[input] or 0) + spent
					end
				end

				for output, amount in pairs(building.type.production_method.outputs) do
					local output_index = RAWS_MANAGER.trade_good_to_index[output]

					local price = market_data[output_index - 1].price
					local produced = amount * efficiency * throughput_boost * output_boost * input_satisfaction_2
					local earnt = price * produced
					income = income + earnt

					building.amount_of_outputs[output] = (building.amount_of_outputs[output] or 0) + produced
					building.earn_from_outputs[output] = (building.earn_from_outputs[output] or 0) + earnt

					record_production(output_index, amount * efficiency * output_boost * throughput_boost)
				end

				local owner = pop.employer.owner
				if owner then
					if donations_to_owners[owner] == nil then
						donations_to_owners[owner] = 0
					end
					if owner.savings + donations_to_owners[owner] > pop.employer.subsidy then
						income = income + pop.employer.subsidy
						donations_to_owners[owner] = donations_to_owners[owner] - pop.employer.subsidy
						pop.employer.subsidy_last = pop.employer.subsidy
					else
						pop.employer.subsidy_last = 0
					end
				end

				if pop.employer.income_mean then
					pop.employer.income_mean = pop.employer.income_mean * 0.5 + income * 0.5
				else
					pop.employer.income_mean = income
				end

				pop.employer.last_income = pop.employer.last_income + income

				--free_time_of_pop = free_time_of_pop - pop.work_ratio * free_time_of_pop * input_satisfaction * input_satisfaction_2

				if income > 0 then
					---@type number
					local contrib = income * fraction_of_income_given_voluntarily
					if owner then
						---@type number
						contrib = income * fraction_of_income_given_to_owner
						if donations_to_owners[owner] == nil then
							donations_to_owners[owner] = 0
						end
						donations_to_owners[owner] = donations_to_owners[pop.employer.owner] + contrib
						pop.employer.last_donation_to_owner = pop.employer.last_donation_to_owner + contrib
						income = income - contrib
					end
					-- increase working hours if possible to increase income
					pop.forage_ratio = math.min(0.99, pop.forage_ratio * 1.1)
					pop.work_ratio = math.max(0.01, 1 - pop.forage_ratio)
				end

				if province.trade_wealth < income then
					-- generate some wealth if selling more goods than market can afford
					income = math.min(province.trade_wealth, income) + 0.5 * (income - province.trade_wealth)
				end
				building.worker_income[pop] = (building.worker_income[pop] or 0) + income
				economic_effects.add_pop_savings(pop, income, economic_effects.reasons.Work)
				province.trade_wealth = math.max(0, province.trade_wealth - income)
			end
			PROFILER:end_timer('production-building-update')

			if pop.age < pop.race.teen_age then
				-- children spend time on games and growing up:
				free_time_of_pop = free_time_of_pop * pop.age / pop.race.teen_age
			end

			-- every pop spends some time or wealth on fullfilling the need of their children and themselves
			local savings_fraction = pop.savings / 10
			if WORLD.player_character and WORLD.player_character == pop then
				savings_fraction = OPTIONS['needs-savings'] * pop.savings
			end
			PROFILER:start_timer("production-satisfy-needs")
			satisfy_needs(pop_view, pop, pop.forage_ratio * (free_time_of_pop + (additional_family_time[pop] or 0)), math.max(0, savings_fraction))
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

		for _, c in pairs(province.characters) do
			local popularity = pv.popularity(c, province.realm)

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
	economic_effects.register_income(province.realm, realm_share, economic_effects.reasons.Donation)
	economic_effects.change_local_wealth(province, total_local_donations, economic_effects.reasons.Donation)
	province.trade_wealth = province.trade_wealth + total_trade_donations

	for character, income in pairs(donations_to_owners) do
		economic_effects.add_pop_savings(character, income, economic_effects.reasons.BuildingIncome)
	end

	PROFILER:end_timer('donations')

	province.local_income = province.local_wealth - old_wealth

	province.foragers = foragers_count -- Record the new number of foragers
	province.foragers_water = foragers_water

	for _, bld in pairs(province.buildings) do
		local prod = bld.type.production_method
		if tabb.size(prod.jobs) == 0 then
			-- If a building has no jobs, it always works!
			local efficiency = 1
			for input, amount in pairs(prod.inputs) do
				local input_index = RAWS_MANAGER.trade_good_to_index[input]
				record_consumption(input_index, amount)
				record_demand(input_index, amount)
			end
			for output, amount in pairs(prod.outputs) do
				local output_index = RAWS_MANAGER.trade_good_to_index[output]
				record_production(output_index, amount * efficiency)
			end
		end
	end

	-- At last, record all data

	for good, index in pairs(RAWS_MANAGER.trade_good_to_index) do
		-- check that we didn't go over the stockpile or possible remaining services from last tick
		if (province.local_storage[good] or 0) + market_data[index - 1].supply - market_data[index - 1].consumption < -EPSILON
		then
			error(
				"INVALID MARKET DATA AFTER PRODUCTION-AND-CONSUPTION TICK"
				.. "\n market_data[".. good .."].available = "
				.. tostring(market_data[index - 1].available)
				.. "\n province.local_storage[".. good .."] = "
				.. tostring(province.local_storage[good])
				.. "\n market_data[".. good .."].local_production = "
				.. tostring(province.local_production[good])
				.. "\n market_data[".. good .."].local_consumption = "
				.. tostring(province.local_consumption[good])
				.. "\n market_data[".. good .."].supply = "
				.. tostring(market_data[index - 1].supply)
				.. "\n market_data[".. good .."].consumption = "
				.. tostring(market_data[index - 1].consumption)
			)
		end

		province.local_consumption[good] = market_data[index - 1].consumption
		province.local_demand[good] = market_data[index - 1].demand
		province.local_production[good] = market_data[index - 1].supply
	end
end

return pro