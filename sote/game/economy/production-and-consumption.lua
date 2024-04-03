local trade_good = require "game.raws.raws-utils".trade_good
local use_case = require "game.raws.raws-utils".trade_good_use_case
local JOBTYPE = require "game.raws.job_types"

local tabb = require "engine.table"
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
		float age_multiplier;
	} pop_view;

	float sqrtf(float arg );
	float expf( float arg );
]]

local C = ffi.C


local amount_of_goods = tabb.size(RAWS_MANAGER.trade_goods_by_name)
local amount_of_job_types = tabb.size(JOBTYPE)
local amount_of_need_types = tabb.size(NEED)

---@type MarketData[]
local market_data = ffi.new("good_data[?]", amount_of_goods)

---@type POPView[]
local pop_view = ffi.new("pop_view[1]")

---@type number[]
local pop_job_efficiency = ffi.new("float[?]", amount_of_job_types)

---@type number[]
local pop_need_amount = ffi.new("float[?]", amount_of_need_types)

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
		price_expectation = price_expectation + market_data[c_index].price * market_data[c_index].feature / total_exp / weight
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
		market_data[i - 1].available = - consumption + production + storage
		if market_data[i-1].available < 0 then
			market_data[i-1].available = 0
		end

		-- prices:
		local price = ev.get_local_price(province, good)
		market_data[i-1].price = price
		old_prices[good] = price
		market_data[i-1].feature = C.expf(-C.sqrtf(market_data[i-1].price) / (1 + market_data[i-1].available))
		market_data[i - 1].consumption = 0
		market_data[i - 1].supply = 0
		market_data[i - 1].demand = 0
	end

	for tag, use_case in pairs(RAWS_MANAGER.trade_goods_use_cases_by_name) do
		use_case_total_exp[tag], use_case_price_expectation[tag] = get_price_expectation_weighted(use_case.goods)
	end

	-- Clear building stats
	for key, value in pairs(province.buildings) do
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

		if market_data[good_index - 1].available + 0.01 < amount
			or amount < 0
		then
			error(
				"INVALID RECORD OF CONSUMPTION"
				.. "\n amount = "
				.. tostring(amount)
				.. "\n amount = "
				.. tostring(amount)
			)
		end

		market_data[good_index - 1].consumption = market_data[good_index - 1].consumption + amount
		market_data[good_index - 1].available = math.max(0, market_data[good_index - 1].available - amount)

		return market_data[good_index -1].price * amount
	end

	---Record local production!
	---@param good_index number
	---@param amount number
	local function record_production(good_index, amount)
		market_data[good_index - 1].supply = market_data[good_index - 1].supply + amount
		market_data[good_index - 1].available = math.max(0, market_data[good_index - 1].available + amount)

		if (amount < 0) then
			error(
				"INVALID RECORD OF PRODUCTION"
				.. "\n amount = "
				.. tostring(amount)
			)
		end

		return market_data[good_index -1].price * amount
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
	local basic_need_count = total_need_count - life_need_count

	local water_index = RAWS_MANAGER.trade_good_to_index["water"]
	local berries_index = RAWS_MANAGER.trade_good_to_index["berries"]
	local grain_index = RAWS_MANAGER.trade_good_to_index["grain"]
	local timber_index = RAWS_MANAGER.trade_good_to_index["timber"]
	local blanks_index = RAWS_MANAGER.trade_good_to_index["blanks-flint"]
	local meat_index = RAWS_MANAGER.trade_good_to_index["meat"]
	local hide_index = RAWS_MANAGER.trade_good_to_index["hide"]

	local berries_price = market_data[berries_index - 1].price
	local grain_price = market_data[grain_index - 1].price
	local meat_price = market_data[meat_index - 1].price
	local hide_price = market_data[hide_index - 1].price
	local timber_price = market_data[timber_index - 1].price
	local blanks_price = market_data[blanks_index - 1].price

	-- Record "innate" production of goods and services.
	-- These resources come
	record_production(water_index, province.hydration)

	local inf = province:get_infrastructure_efficiency()
	local efficiency_from_infrastructure = math.min(1.5, 0.5 + 0.5 * math.sqrt(2 * inf))
	-- Record local production...
	local last_foraaging_efficiency = math.min(1.15, (province.foragers_limit / math.max(1, province.foragers)))
	last_foraaging_efficiency = last_foraaging_efficiency * last_foraaging_efficiency
	local foragers_count = 0
	local function foraging_efficiency()
		local foraging_efficiency = math.min(1.15, (province.foragers_limit / math.max(1, foragers_count)))
		return foraging_efficiency * foraging_efficiency
	end
	-- builds up to old foragers count
	local function get_foraging_production(pop_view, pop_table, time)
		local effective_time = time * pop_view[zero].foraging_efficiency
		if foragers_count < province.foragers then
			foragers_count = foragers_count + effective_time -- Record a new forager!
			return effective_time * last_foraaging_efficiency
		end
		local initial = foraging_efficiency()
		foragers_count = foragers_count + effective_time -- Record a new forager!
		local final = foraging_efficiency()
		return effective_time * (initial + final) * 0.5
	end
		
	local old_wealth = province.local_wealth -- store wealth before this tick, used to calculate income later
	local population = province:local_population()
	local min_income_pop = math.max(50, math.min(200, 100 + province.mood * 10))


	-- TODO: IMPLEMENT CULTURAL VALUE
	local fraction_of_income_given_voluntarily = 0.1 * math.max(0, math.min(1.0, 1.0 - population / min_income_pop))
	local fraction_of_income_given_to_owner = 0.1

	DISPLAY_INCOME_OWNER_RATIO = (1 - INCOME_TO_LOCAL_WEALTH_MULTIPLIER) * fraction_of_income_given_to_owner

	local timber_production = (province.flora_spread.broadleaf + province.flora_spread.conifer) * 0.1
		+ province.flora_spread.shrub * 0.05 + province.flora_spread.grass * 0.01

	local berries_production = province.flora_spread.shrub + province.flora_spread.broadleaf
	local seeds_production = province.flora_spread.grass + province.flora_spread.conifer

	---Pop forages for food and gives it to warband  \
	-- Not very efficient
	---@param pop_view POPView[]
	---@param pop_table POP
	---@param time number ratio of daily active time pop can spend on foraging
	local function forage_warband(pop_view, pop_table, time)
		local food_produced = get_foraging_production(pop_view, pop_table, time) * 0.25
		local timber_produced = pop_job_efficiency[JOBTYPE.HAULING] * timber_production * 0.1 * time
		local income = record_production(berries_index, timber_produced)
		local warband = pop_table.unit_of_warband
		if warband and warband.leader then
			warband.leader.inventory['berries'] = (warband.leader.inventory['berries'] or 0) + food_produced * berries_production
			warband.leader.inventory['grain'] = (warband.leader.inventory['grain'] or 0) + food_produced * seeds_production
		else
			income = income + income + record_production(berries_index, food_produced * berries_production)
			income = income + income + record_production(berries_index, food_produced * seeds_production)
		end
	end

	---Pop forages for food and game to sells it  \
	-- Not very efficient
	---@param pop_view POPView[]
	---@param pop_table POP
	---@param time number ratio of daily active time pop can spend on foraging
	---@return number income
	local function forage(pop_view, pop_table, time)
		local food_produced = get_foraging_production(pop_view, pop_table, time) * 0.5
		local timber_produced = pop_job_efficiency[JOBTYPE.HAULING] * 0.1 * timber_production * time
		local income = 0
		if pop_table:is_character() then -- hunt for meat and hide
			income = income + record_production(meat_index, food_produced / 2)
			income = income + record_production(hide_index, food_produced / 4)
		else -- forage for food based on province flora_spread
			income = income + record_production(berries_index, food_produced * berries_production)
			income = income + record_production(grain_index, food_produced * seeds_production)
		end
		-- gathering timber
		income = income + record_production(timber_index, timber_produced)
		return income
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
		local use = use_case(use_reference)

		local total_exp = use_case_total_exp[use_reference]
		local price_expectation = use_case_price_expectation[use_reference]
		local demanded_use = math.min(amount, savings / math.max(price_expectation, 0.0001))

		local available = available_goods_for_use(use_reference)
		local potential_amount = math.min(available, demanded_use)

		local total_bought = 0
		local spendings = 0

		for good, weight in pairs(use.goods) do
			local c_index = RAWS_MANAGER.trade_good_to_index[good] - 1
			local goods_price = math.max(market_data[c_index].price, 0.0001)
			local goods_available = market_data[c_index].available
			local goods_available_weight = math.max(market_data[c_index].available / weight / available, 0)
			local goods_feature_weight = math.max(market_data[c_index].feature / total_exp, 0)
			local demanded_amount = demanded_use / weight * goods_feature_weight
			local consumed_amount = math.min(goods_available, demanded_amount,
				potential_amount / weight * goods_available_weight,
				savings / goods_price)
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
	---@param need_index NEED
	---@param need Need
	---@param free_time number
	---@param savings number
	---@param target number
	---@return number free_time_used
	---@return number income
	---@return number expenses
	local function satisfy_need(pop_view, pop_table, need_index, need, free_time, savings, target)
		local income, expenses, total_need_time, total_need_cost = 0, 0, 0, 0

		-- start with calculation of distribution over goods:
		-- "distribution" "density" is precalculated, we only need to find a normalizing coef.
		local need_amount = pop_need_amount[need_index]
		local need_job_efficiency = pop_job_efficiency[need.job_to_satisfy]

		local cottage_time_per_unit = need.time_to_satisfy / need_job_efficiency

		-- collect data, get all need use_cases demand
		-- expected costs and estimated time needed to satisfy
		---@type table<string,{need_amount: number, need_cost: number, need_time: number}>
		local need_cases = {}
		for case, values in pairs(pop_table.need_satisfaction[need_index]) do
			local need_amount = values.demanded
			-- induced demand:
			local price_expectation = math.max(0.0001, use_case_price_expectation[case])
			local induced_demand = math.min(2, math.max(0, 1 / math.max(price_expectation, 0.0001) - 1))
			need_amount = need_amount * (1 + induced_demand)
			need_amount = need_amount * target
			if need_amount < 0 then
				error("Demanded need is lower than zero!")
			end
			-- estimate cost in money and time to satisfy each use_case
			local remaining_need_amount = math.max(0, need_amount - values.consumed)
			local need_cost = price_expectation * remaining_need_amount * POP_BUY_PRICE_MULTIPLIER
			local need_time = remaining_need_amount * cottage_time_per_unit
			need_cases[case] = {need_amount = remaining_need_amount, need_cost = need_cost , need_time = need_time}
			-- count totals for weighting
			total_need_cost = total_need_cost + need_cost
			total_need_time = total_need_time + need_time

		end
		local total_time_used = 0
		for case, values in pairs(need_cases) do
			-- split time and money up to satisfy each need case
			local time_fraction = math.max(free_time * values.need_time / total_need_time, 0)
			local savings_fraction = math.max(savings * values.need_cost / total_need_cost, 0)
			-- attempt to buy from market with savings fraction
			local spendings, consumed = buy_use(case, values.need_amount, savings_fraction)
			pop_table.need_satisfaction[need_index][case].consumed = pop_table.need_satisfaction[need_index][case].consumed + consumed
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

			-- use time fraction to satisfy remaning need
			if time_fraction > 0 then
				local consumed = pop_table.need_satisfaction[need_index][case].consumed
				local demanded = pop_table.need_satisfaction[need_index][case].demanded * target
				need_amount = math.max(0, demanded * 0.5 - consumed)
				if need_amount > 0 then
					local cottage_time = math.min(time_fraction, need_amount * cottage_time_per_unit)
					if need.job_to_satisfy == JOBTYPE.FORAGER then
						foragers_count = foragers_count + cottage_time * pop_view[zero].foraging_efficiency
					end
					local cottaged = cottage_time / cottage_time_per_unit

					if cottaged > need_amount + 0.01
						or cottage_time > time_fraction + 0.01
					then
						error("INVALID COTTAGING ATTEMPT IN SATISFY_NEED"
							.. "\n time_fraction = "
							.. tostring(time_fraction)
							.. "\n cottage_time = "
							.. tostring(cottage_time)
							.. "\n cottaged = "
							.. tostring(cottaged)
							.. "\n need_amount = "
							.. tostring(need_amount)
						)
					end

					pop_table.need_satisfaction[need_index][case].consumed = consumed + cottaged
					total_time_used = total_time_used + cottage_time
				end
			end

			if total_time_used > free_time + 0.01 then
				error("INVALID AMOUNT OF TIME SPENT IN SATISFY NEED"
					.. "\n total_time_used = "
					.. tostring(total_time_used)
					.. "\n free_time = "
					.. tostring(free_time)
				)
			end
		end

		-- return remaining unused time
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
		return total_time_used, income, expenses
	end

	---comment
	---@param pop_view POPView
	---@param pop_table POP
	---@param free_time number
	---@param savings number
	local function satisfy_needs(pop_view, pop_table, free_time, savings)
		local total_expense = 0
		local total_income = 0
		local start_time = free_time
		if WORLD.player_character and WORLD.player_character == pop_table then
			local hunt_time = math.min(OPTIONS["needs-hunt"], free_time)
			total_income = forage(pop_view, pop_table, hunt_time)
			start_time = free_time - hunt_time
		end

		-- work for children first
		local dependants = tabb.filter(pop_table.children, function (a)
			return a. age < a.race.teen_age
		end)
		local dependent_count = 2 * tabb.size(dependants)
		local time_after_children = start_time

		if dependent_count > 1 then
			local time_fraction = start_time / dependent_count
			local savings_fraction = savings / dependent_count
			for _, child in pairs(dependants) do
				for index, need in pairs(NEEDS) do
					if need.life_need then
						local free_time_for_need, income, expense = satisfy_need(
							pop_view, child, index, need,
							time_fraction / life_need_count,
							savings_fraction / life_need_count, 1)

						if free_time_for_need > time_fraction / life_need_count + 0.01
							or savings_fraction / life_need_count + income + 0.01 < expense
						then
							error("INVALID CHILD SATISFY_NEED"
								.. "\n free_time_for_need = "
								.. tostring(free_time_for_need)
								.. "\n time_fraction = "
								.. tostring(time_fraction)
								.. "\n free_time = "
								.. tostring(free_time)
								.. "\n life_need_count = "
								.. tostring(life_need_count)
								.. "\n dependent_count = "
								.. tostring(dependent_count)
								.. "\n savings = "
								.. tostring(savings)
								.. "\n savings_fraction = "
								.. tostring(savings_fraction)
								.. "\n income = "
								.. tostring(income)
								.. "\n expense = "
								.. tostring(expense)
							)
						end

						total_income = total_income + income
						total_expense = total_expense + expense
						time_after_children = time_after_children - free_time_for_need
					end
				end

				if time_after_children < - 0.01
					or savings + total_income + 0.01 < total_expense
				then
					error("INVALID CHILD SATISFY_NEEDS"
						.. "\n time_fraction = "
						.. tostring(time_fraction)
						.. "\n free_time = "
						.. tostring(free_time)
						.. "\n count = "
						.. tostring(dependent_count)
						.. "\n savings = "
						.. tostring(savings)
						.. "\n total_income = "
						.. tostring(total_income)
						.. "\n total_expense = "
						.. tostring(total_expense)
					)
				end
			end
		else
			time_after_children = math.max(0, free_time)
		end

		if time_after_children < - 0.01
			or savings + total_income + 0.01 < total_expense
		then
			error("INVALID LIFE SATISFY_NEEDS"
				.. "\n time_after_life = "
				.. tostring(time_after_children)
				.. "\n free_time = "
				.. tostring(free_time)
				.. "\n savings = "
				.. tostring(savings)
				.. "\n total_income = "
				.. tostring(total_income)
				.. "\n total_expense = "
				.. tostring(total_expense)
			)
		end

		local savings_after_children = savings + total_income - total_expense
		local time_after_life = math.max(0, time_after_children)

		local life_time_fraction = time_after_life / life_need_count
		local savings_fraction = savings_after_children / life_need_count

		-- buying life needs
		for index, need in pairs(NEEDS) do
			if need.life_need then
				local free_time_for_need, income, expense = satisfy_need(
					pop_view, pop_table, index, need, life_time_fraction, savings_fraction, 0.75)

				total_income = total_income + income
				total_expense = total_expense + expense

				time_after_life = time_after_life - free_time_for_need
			end
		end

		if time_after_life < - 0.01
			or savings + total_income + 0.01 < total_expense
		then
			error("INVALID LIFE SATISFY_NEEDS"
				.. "\n time_after_life = "
				.. tostring(time_after_life)
				.. "\n time_after_children = "
				.. tostring(time_after_children)
				.. "\n free_time = "
				.. tostring(free_time)
				.. "\n savings = "
				.. tostring(savings)
				.. "\n total_income = "
				.. tostring(total_income)
				.. "\n total_expense = "
				.. tostring(total_expense)
			)
		end

		local savings_after_life = savings + total_income - total_expense
		local fraction = 1 + total_need_count
		local time_after_basic = math.max(0, time_after_life)

		local basic_time_fraction = time_after_life / fraction
		local basic_savings_fraction = savings_after_life / fraction

		-- buying other needs
		for index, need in pairs(NEEDS) do
				local free_time_for_need, income, expense = satisfy_need(
					pop_view, pop_table, index, need, basic_time_fraction, basic_savings_fraction, 1)

				total_income = total_income + income
				total_expense = total_expense + expense

				time_after_basic = time_after_basic - free_time_for_need
		end

		if time_after_basic < - 0.01
			or savings + total_income + 0.01 < total_expense
		then
			error("INVALID BASIC SATISFY_NEEDS"
				.. "\n time_after_basic = "
				.. tostring(time_after_basic)
				.. "\n time_after_life = "
				.. tostring(time_after_life)
				.. "\n free_time = "
				.. tostring(free_time)
				.. "\n savings = "
				.. tostring(savings)
				.. "\n total_income = "
				.. tostring(total_income)
				.. "\n total_expense = "
				.. tostring(total_expense)
			)
		end

		if savings + total_income + 0.01 < total_expense
			or total_income ~= total_income
			or total_expense ~= total_expense
		then
			error("INVALID SATISFY_NEEDS"
				.. "\n total_income = "
				.. tostring(total_income)
				.. "\n total_expense = "
				.. tostring(total_expense)
				.. "\n savings = "
				.. tostring(savings)
				.. "\n total_income = "
				.. tostring(total_income)
				.. "\n total_expense = "
				.. tostring(total_expense)
				.. "\n time_after_basic = "
				.. tostring(time_after_basic)
				.. "\n free_time = "
				.. tostring(free_time)
			)
		end

		-- adjust pop savings
		economic_effects.add_pop_savings(pop_table, total_income, economic_effects.reasons.Forage)
		economic_effects.add_pop_savings(pop_table, -total_expense, economic_effects.reasons.BasicNeeds)

	end


	local total_popularity = 0
	---@type table<POP, number>
	local donations_to_owners = {}
	local children = tabb.size(tabb.filter(province.home_to, function (a)
		return a.age < a.race.teen_age and a.province == province
	end))
	-- calculate donations for home children
	local wealth_cycle = province.local_wealth / 24
	local wealth_cycle_fraction = math.max(wealth_cycle / province:total_home_population(), 0)
	local donations_for_childen = math.min(wealth_cycle, children * use_case_price_expectation['calories'] * 0.5)
	local donations_for_child = math.max(donations_for_childen / children, 0)

	if donations_for_child ~= donations_for_child
		or wealth_cycle_fraction ~= wealth_cycle_fraction
	then
		error("PROVINCE CHILD DONATIONS IS NAN")
	end
	economic_effects.change_local_wealth(province, -wealth_cycle, economic_effects.reasons.Donation)
	economic_effects.change_local_wealth(province, -donations_for_childen, economic_effects.reasons.Welfare)

	local additional_family_time = {}
	-- sort pops by wealth:
	---@type POP[]
	local pops_by_wealth = tabb.accumulate(
		tabb.join(tabb.copy(province.all_pops), province.characters),
		{},function (a, _, pop)
			-- cycle local wealth to home pop and characters
			economic_effects.add_pop_savings(pop, wealth_cycle_fraction, economic_effects.reasons.Donation)
			-- donation to help parents care for children
			if pop.home_province == province then
				if donations_for_child > 0 then
				local dependents = tabb.size(tabb.filter(pop.children, function (child)
					if child.age < child.race.teen_age then
						if not pop:is_character() then
							additional_family_time[pop] = (additional_family_time[pop] or 0) + child.age / child.race.teen_age
						end
						return true
					end
					return false
					end))
					if dependents > 0 and pop.age >= pop.race.teen_age then
						-- donate children's share to parents
						economic_effects.add_pop_savings(pop, dependents * donations_for_child, economic_effects.reasons.Welfare)
					end
				end
			end
			if not pop:is_character() then
				-- pops donate some of their savings as well:
				local pop_donation_total = pop.savings / 120 * pop.basic_needs_satisfaction
				total_realm_donations = total_realm_donations + pop_donation_total * 0.5
				total_local_donations = total_local_donations + pop_donation_total * 0.25
				total_trade_donations = total_trade_donations + pop_donation_total * 0.25
				economic_effects.add_pop_savings(pop, -pop_donation_total, economic_effects.reasons.Donation)
				-- add to pop satisfy needs list only if no parent
				if not pop.parent then
					table.insert(a, pop)
					-- add children's free time to parent for satisfy needs
				end
			else
				local popularity = pv.popularity(pop, province.realm)
				if popularity > 0 then
					total_popularity = total_popularity + popularity
				end
				table.insert(a, pop)
			end
			-- recalculate pop needs
			local needs_satisfaction = pop.race.male_needs
			if pop.female then needs_satisfaction = pop.race.female_needs end
			-- TODO replace with warband supplies?
			-- block of starvation, if the pop is not able to call staisfy_need
			local consumption_percentage = 0.5
			if pop.unit_of_warband ~= nil and pop.unit_of_warband.status ~= "idle" then
				consumption_percentage = 1
			end
			tabb.accumulate(needs_satisfaction, nil, function (_, need, values)
				tabb.accumulate(values, nil, function (_, k, v)
					pop.need_satisfaction[need][k].consumed = pop.need_satisfaction[need][k].consumed * consumption_percentage
						pop.need_satisfaction[need][k].demanded = needs_satisfaction[need][k]
					if not NEEDS[need].age_independent then
						pop.need_satisfaction[need][k].demanded = pop.need_satisfaction[need][k].demanded * pop:get_age_multiplier()
					end
				end)
			end)
			return a
		end)
	table.sort(pops_by_wealth, function (a, b)
		return a.savings > b.savings
	end)



	PROFILER:start_timer("production-pops-loop")
	for _, pop in ipairs(pops_by_wealth) do

		-- populate pop_view
		local foraging_multiplier = pop.race.male_efficiency[JOBTYPE.FORAGER]
		if pop.female then
			foraging_multiplier = pop.race.female_efficiency[JOBTYPE.FORAGER]
		end
		pop_view[zero].foraging_efficiency = foraging_multiplier
		pop_view[zero].age_multiplier = pop:get_age_multiplier()

		local pop_needs = pop.race.male_needs
		local pop_efficiency = pop.race.male_efficiency
		if pop.female then
			pop_needs = pop.race.female_needs
			pop_efficiency = pop.race.female_efficiency
		end

		-- populate job efficiency
		for tag, value in pairs(JOBTYPE) do
			pop_job_efficiency[value] = pop_efficiency[value]
		end
		for tag, value in pairs(pop_needs) do
			pop_need_amount[tag] = tabb.accumulate(value, 0, function (a, k, v)
				a = a + v
				return a
			end)
			-- can easily add a pop's cultural or religous needs here
			local need = NEEDS[tag]
			if not need.age_independent then
				pop_need_amount[tag] = pop_need_amount[tag] * pop_view[zero].age_multiplier
			end
		end


		-- base income: all adult pops forage and help each other which translates into a bit of wealth
		-- real reason: wealth sources to fuel the economy
		-- buidings are essentially wealth sinks currently
		-- so obviously we need some wealth sources
		-- should be removed when economy simulation will be completed
		local base_income = 1 * pop.age / pop.race.max_age;
		economic_effects.add_pop_savings(pop, base_income, economic_effects.reasons.MonthlyChange)

		-- Drafted pops work only when warband is "idle"
		if (pop.unit_of_warband == nil) or (pop.unit_of_warband.status == "idle") then
			local free_time_of_pop = 1;

			-- if pop is in the warband,
			if pop.unit_of_warband then
				if pop.unit_of_warband.idle_stance == "forage" then
					-- spend some time on foraging for warband:
					forage_warband(pop_view, pop, pop.unit_of_warband.current_free_time_ratio * 0.5)
					free_time_of_pop = pop.unit_of_warband.current_free_time_ratio * 0.5
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
				local work_time = math.min(building.work_ratio, free_time_of_pop)
				local local_foraging_efficiency = 1
				if prod.foraging then
					-- buildings operate off off last month's foraging use, otherwise race conditions on output
					foragers_count = foragers_count + work_time * pop_view[zero].foraging_efficiency
					local_foraging_efficiency = last_foraaging_efficiency
				end
				local yield = prod:get_efficiency(province)

				local efficiency = yield
									* local_foraging_efficiency
									* efficiency_from_infrastructure
									* work_time

				if prod.foraging then
					local timber_produced = pop_job_efficiency[JOBTYPE.HAULING] * yield * timber_production * 0.25
					local timber_income = record_production(timber_index, timber_produced)
					income = income + timber_income

					building.amount_of_outputs['timber'] = (building.amount_of_outputs['timber'] or 0) + timber_produced
					building.earn_from_outputs['timber'] = (building.amount_of_outputs['timber'] or 0) + timber_income
				end
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
						.. tostring(pop.employer.work_ratio)
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

				income = income
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

				income = income

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

				---@type number
				income = income

				free_time_of_pop = free_time_of_pop - math.min(pop.employer.work_ratio, free_time_of_pop) * input_satisfaction * input_satisfaction_2

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
					pop.employer.work_ratio = math.min(1.0, pop.employer.work_ratio * 1.1)
				else
					-- reduce working hours to negate losses or satisfy life needs
					pop.employer.work_ratio =  math.max(0.01, pop.employer.work_ratio * 0.8)
				end

				-- reduce working time if not enough life needs satisfied
				local min_life_satisfaction = tabb.accumulate(pop.need_satisfaction, 1, function (a, need, values)
					if NEEDS[need].life_need then
						local min_need = tabb.accumulate(values, 1, function (b, k, v)
							local ratio = v.consumed / v.demanded
							if ratio < b then
								b = ratio
							end
							return b
						end)
						if min_need < a then
							a = min_need
						end
					end
					return a
				end)
				if min_life_satisfaction < 1/6 then
					pop.employer.work_ratio =  math.max(0.01, pop.employer.work_ratio * 0.8)
				elseif income > 0 then
					pop.employer.work_ratio = math.min(1.0, pop.employer.work_ratio * 1.1)
				end

				if province.trade_wealth < income then
					-- generate some wealth if selling more goods than market can afford
					income = math.min(province.trade_wealth, income) + 0.1 * (income - province.trade_wealth)
				end
				building.worker_income[pop] = (building.worker_income[pop] or 0) + income
				economic_effects.add_pop_savings(pop, income, economic_effects.reasons.Work)
				province.trade_wealth = math.max(0, province.trade_wealth - income)
			end
			PROFILER:end_timer('production-building-update')

			if pop.age < pop.race.teen_age then

				-- gives donation share children if they have no parent
				if not pop.parent then
					if donations_for_child > 0 and pop.home_province == province then
						economic_effects.add_pop_savings(pop, donations_for_child, economic_effects.reasons.Welfare)
					end
				end

				-- children spend time on games and growing up:
				free_time_of_pop = free_time_of_pop * pop.age / pop.race.teen_age
			end

			-- every pop spends some time or wealth on fullfilling their needs:
			local savings_fraction = pop.savings / 12
			if WORLD.player_character and WORLD.player_character == pop then
				savings_fraction = OPTIONS['needs-savings'] * pop.savings
			end
			PROFILER:start_timer("production-satisfy-needs")
			satisfy_needs(pop_view, pop, math.max(free_time_of_pop + (additional_family_time[pop] or 0), 0), math.max(0, savings_fraction))
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

	local to_trade_siphon = province.local_wealth * 0.01
	local from_trade_siphon = province.trade_wealth * 0.01
	economic_effects.change_local_wealth(
		province,
		from_trade_siphon - to_trade_siphon,
		economic_effects.reasons.TradeSiphon
	)
	PROFILER:end_timer('donations')


	province.trade_wealth = province.trade_wealth - from_trade_siphon + to_trade_siphon

	province.local_income = province.local_wealth - old_wealth

	province.foragers = foragers_count -- Record the new number of foragers

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
		province.local_consumption[good] = market_data[index - 1].consumption
		province.local_demand[good] = market_data[index - 1].demand
		province.local_production[good] = market_data[index - 1].supply
	end
end

return pro