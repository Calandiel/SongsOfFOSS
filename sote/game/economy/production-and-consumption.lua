local trade_good = require "game.raws.raws-utils".trade_good
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

ffi.cdef [[
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

---@type number[]
local need_price_expectation = ffi.new("float[?]", amount_of_need_types)

---@type number[]
local need_total_exp = ffi.new("float[?]", amount_of_need_types)

-- TODO: rewrite to ffi

---@type table<TradeGoodUseCaseReference, number>
local use_case_total_exp = {}
---@type table<TradeGoodUseCaseReference, number>
local use_case_price_expectation = {}

local zero = 0
local total_realm_donations = 0
local total_local_donations = 0
local total_trade_donations = 0


---Calculates price expectation for a list of goods
---@param set_of_goods TradeGoodReference[]
---@return number total_exp total value for softmax
---@return number expectation price expectation
local function get_price_expectation(set_of_goods)
	local total_exp = 0.0
	for _, good in pairs(set_of_goods) do
		local c_index = RAWS_MANAGER.trade_good_to_index[good] - 1
		total_exp = total_exp + market_data[c_index].feature
	end

	-- price expectation:
	local price_expectation = 0.0
	for _, good in pairs(set_of_goods) do
		local c_index = RAWS_MANAGER.trade_good_to_index[good] - 1
		price_expectation = price_expectation + market_data[c_index].price * market_data[c_index].feature / total_exp
	end
	return total_exp, price_expectation
end

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
		price_expectation = price_expectation +
		market_data[c_index].price * market_data[c_index].feature / total_exp / weight
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
		market_data[i - 1].available = -consumption + production + storage
		if market_data[i - 1].available < 0 then
			market_data[i - 1].available = 0
		end

		-- prices:
		local price = ev.get_local_price(province, good)
		market_data[i - 1].price = price
		old_prices[good] = price
		market_data[i - 1].feature = C.expf(-C.sqrtf(market_data[i - 1].price) / (1 + market_data[i - 1].available))

		market_data[i - 1].consumption = 0
		market_data[i - 1].supply = 0
		market_data[i - 1].demand = 0
	end

	for tag, index in pairs(NEED) do
		local need = NEEDS[index]
		need_total_exp[index], need_price_expectation[index] = get_price_expectation(need.goods)
	end

	for tag, use_case in pairs(RAWS_MANAGER.trade_goods_use_cases_by_name) do
		use_case_total_exp[tag], use_case_price_expectation[tag] = get_price_expectation_weighted(use_case.goods)
	end

	-- Clear building stats
	for key, value in pairs(province.buildings) do
		tabb.clear(value.earn_from_outputs)
		tabb.clear(value.spent_on_inputs)
		value.last_donation_to_owner = 0
		value.last_income = 0
		value.subsidy_last = 0
	end

	---Records local consumption!
	---@param good_index number
	---@param amount number
	local function record_consumption(good_index, amount)
		market_data[good_index - 1].consumption = market_data[good_index - 1].consumption + amount
		market_data[good_index - 1].available = market_data[good_index - 1].available - amount

		if (amount < 0) then
			error(
				"INVALID RECORD OF CONSUMPTION"
				.. "\n amount = "
				.. tostring(amount)
			)
		end

		return market_data[good_index - 1].price * amount
	end

	---Record local production!
	---@param good_index number
	---@param amount number
	local function record_production(good_index, amount)
		market_data[good_index - 1].supply = market_data[good_index - 1].supply + amount

		if (amount < 0) then
			error(
				"INVALID RECORD OF PRODUCTION"
				.. "\n amount = "
				.. tostring(amount)
			)
		end

		return market_data[good_index - 1].price * amount
	end


	---Record local demand!
	---@param good_index number
	---@param amount number
	local function record_demand(good_index, amount)
		market_data[good_index - 1].demand = market_data[good_index - 1].demand + amount

		return market_data[good_index - 1].price * amount
	end



	local food_index = RAWS_MANAGER.trade_good_to_index["food"]
	local water_index = RAWS_MANAGER.trade_good_to_index["water"]
	local food_price = market_data[food_index - 1].price

	-- Record "innate" production of goods and services.
	-- These resources come
	record_production(water_index, province.hydration)

	local inf = province:get_infrastructure_efficiency()
	local efficiency_from_infrastructure = math.min(1.5, 0.5 + 0.5 * math.sqrt(2 * inf))
	-- Record local production...
	local foragers_count = 0
	local foraging_efficiency = math.min(1.15, (province.foragers_limit / math.max(1, province.foragers)))
	foraging_efficiency = foraging_efficiency * foraging_efficiency

	local old_wealth = province.local_wealth -- store wealth before this tick, used to calculate income later
	local population = tabb.size(province.all_pops)
	local min_income_pop = math.max(50, math.min(200, 100 + province.mood * 10))


	-- TODO: IMPLEMENT CULTURAL VALUE
	local fraction_of_income_given_voluntarily = 0.1 * math.max(0, math.min(1.0, 1.0 - population / min_income_pop))
	local fraction_of_income_given_to_owner = 0.1

	DISPLAY_INCOME_OWNER_RATIO = (1 - INCOME_TO_LOCAL_WEALTH_MULTIPLIER) * fraction_of_income_given_to_owner

	---Pop forages for food and gives it to warband  \
	-- Not very efficient
	---@param pop POPView[]
	---@param pop_table POP
	---@param time number ratio of daily active time pop can spend on foraging
	local function forage_warband(pop, pop_table, time)
		foragers_count = foragers_count + time -- Record a new forager!
		local food_produced = pop[zero].foraging_efficiency * 0.25 * time

		if pop_table.unit_of_warband.leader then
			pop_table.unit_of_warband.leader.inventory['food'] = (pop_table.unit_of_warband.leader.inventory['food'] or 0) +
			food_produced
		end
	end

	---Pop forages for food and sells it  \
	-- Not very efficient
	---@param pop POPView[]
	---@param pop_table POP
	---@param time number ratio of daily active time pop can spend on foraging
	---@return number income
	local function forage(pop, pop_table, time)
		foragers_count = foragers_count + time -- Record a new forager!
		local food_produced = pop[zero].foraging_efficiency * 0.25 * time
		local income = record_production(food_index, food_produced)

		return income
	end






	---Attepts to satisfy needs of a pop  \
	---Checks if it is more useful to buy a good or to produce it while using your free time
	---@param pop POPView[]
	---@param pop_table POP
	---@param need_index NEED
	---@param need Need
	---@param free_time number
	---@param savings number
	---@return number free_time_left
	---@return number income
	---@return number expenses
	---@return number need_total
	---@return number need_satisfied
	local function satisfy_need(pop, pop_table, need_index, need, free_time, savings)
		if free_time < 0 then
			error("INVALID FREE TIME: " .. tostring(free_time))
		end

		-- start with calculation of distribution over goods:
		-- "distribution" "density" is precalculated, we only need to find a normalizing coef.
		local need_amount = pop_need_amount[need_index]
		local need_job_efficiency = pop_job_efficiency[need.job_to_satisfy]
		local total_exp = need_total_exp[need_index]
		local price_expectation = need_price_expectation[need_index]

		-- local traders are greedy and want some income too
		price_expectation = price_expectation * POP_BUY_PRICE_MULTIPLIER

		local pre_induced_need = need_amount

		-- induced demand:
		local induced_demand = math.min(2, math.max(0, 1 / price_expectation - 1))
		need_amount = need_amount * (1 + induced_demand)

		if need_amount < 0 then
			error("Demanded need is lower than zero!")
		end

		-- time required to satisfy need on your own
		local time_to_satisfy = need.time_to_satisfy / need_job_efficiency * need_amount

		-- actual time pop is able to spend
		local work_time = math.max(math.min(free_time, time_to_satisfy), 0)

		-- utility pop gains from satisfying his needs on his own:
		local utility_satisfy_needs_yourself = math.min(1, work_time / time_to_satisfy)

		-- wealth pop can earn by foraging instead
		local food_produced = pop[zero].foraging_efficiency * 0.5
		local income_per_unit_of_time = food_price * food_produced
		local potential_income = math.min(work_time * income_per_unit_of_time, province.trade_wealth)

		-- how many units pop can buy with potential income + savings
		local buy_potential = math.min(need_amount, (potential_income + savings) / price_expectation)
		local utility_work_and_buy = math.min(1, buy_potential / need_amount)

		-- if WORLD.player_character and province == WORLD.player_character.province then
		-- 	print(need_tag)

		-- 	if pop.employer then
		-- 		print('pop.employer.type.name = ',  pop.employer.type.name)
		-- 	else
		-- 		print('pop.employer.type.name = unemployed')
		-- 	end

		-- 	print('utility_satisfy_needs_yourself = \n', utility_satisfy_needs_yourself)
		-- 	print('utility_work_and_buy = \n', utility_work_and_buy)
		-- end

		-- choose action with best utility
		if utility_work_and_buy < utility_satisfy_needs_yourself then
			if need.job_to_satisfy == JOBTYPE.FORAGER then
				foragers_count = foragers_count + work_time
			end
			return free_time - work_time, 0, 0, pre_induced_need, need_amount * utility_satisfy_needs_yourself
		else
			-- wealth needed to buy required amount of goods:
			local wealth_needed = math.min(price_expectation * buy_potential, province.trade_wealth)
			local forage_time = math.max(0, math.min(free_time, wealth_needed / income_per_unit_of_time))

			local total_bought = 0

			-- forage and buy required goods:
			local forage_income = forage(pop, pop_table, forage_time)
			local expense = 0

			for _, good in pairs(need.goods) do
				local index = RAWS_MANAGER.trade_good_to_index[good]
				local c_index = index - 1

				local available = market_data[c_index].available
				local price = market_data[c_index].price

				---@type number
				local demand = math.min(need_amount, buy_potential * market_data[c_index].feature / total_exp)
				local consumption = math.max(0, math.min(demand, available))

				expense = expense + record_consumption(index, consumption) * POP_BUY_PRICE_MULTIPLIER
				record_demand(index, demand)

				total_bought = total_bought + consumption

				if expense ~= expense or consumption ~= consumption then
					error(
						"INVALID ATTEMPT OF POP TO BUY A NEED:"
						.. "\n consumption * price = "
						.. tostring(consumption * price)
						.. "\n price = "
						.. tostring(price)
						.. "\n total_exp = "
						.. tostring(total_exp)
						.. "\n expense = "
						.. tostring(expense)
						.. "\n total_exp = "
						.. tostring(total_exp)
						.. "\n buy_potential = "
						.. tostring(buy_potential)
					)
				end
			end

			if total_bought < 0 or total_bought > need_amount + 0.01 then
				error(
					"INVALID AMOUNT OF CONSUMED GOODS"
					.. "\n total_bought = "
					.. tostring(total_bought)
					.. "\n need_amount = "
					.. tostring(need_amount)
					.. "\n buy_potential = "
					.. tostring(buy_potential)
					.. "\n potential_income = "
					.. tostring(potential_income)
					.. "\n forage_income = "
					.. tostring(forage_income)
				)
			end

			return free_time - forage_time, forage_income, expense, pre_induced_need, total_bought
		end
	end

	---comment
	---@param pop POPView
	---@param pop_table POP
	---@param free_time number amount of time pop is willing to spend on foraging
	---@param savings number amount of money pop is willing to spend on needs
	local function satisfy_needs(pop, pop_table, free_time, savings)
		pop_table.life_needs_satisfaction = 2

		local total_satisfied = 0
		local total_needs = 0

		local total_life_satisfied = 0
		local total_life_needs = 0

		local total_expense = 0
		local total_income = 0

		-- buying life needs
		for index, need in pairs(NEEDS) do
			if need.life_need then
				local free_time_after_need, income, expense, need_demanded, consumed = satisfy_need(
					pop, pop_table, index, need, free_time, savings)

				if need_demanded > 0 then
					pop_table.need_satisfaction[index] = consumed / need_demanded
				else
					pop_table.need_satisfaction[index] = 0
				end

				total_life_needs = total_life_needs + need_demanded
				total_life_satisfied = total_life_satisfied + consumed

				total_income = total_income + income
				total_expense = total_expense + expense

				free_time = free_time_after_need

				savings = savings + income - expense
			end
		end

		if total_life_needs > 0 then
			pop_table.life_needs_satisfaction = total_life_satisfied / total_life_needs
		else
			pop_table.life_needs_satisfaction = 1
		end

		-- buying base needs
		for index, need in pairs(NEEDS) do
			if not need.life_need then
				local free_time_after_need, income, expense, need_demanded, consumed = satisfy_need(
					pop, pop_table, index, need, free_time, savings)
				if need_demanded > 0 then
					pop_table.need_satisfaction[index] = consumed / need_demanded
				else
					pop_table.need_satisfaction[index] = 0
				end

				total_needs = total_needs + need_demanded
				total_satisfied = total_satisfied + consumed

				total_income = total_income + income
				total_expense = total_expense + expense

				free_time = free_time_after_need

				savings = savings + income - expense
			end
		end

		economic_effects.add_pop_savings(pop_table, total_income, economic_effects.reasons.Forage)
		economic_effects.add_pop_savings(pop_table, -total_expense, economic_effects.reasons.OtherNeeds)

		if total_needs > 0 then
			pop_table.basic_needs_satisfaction = total_satisfied / total_needs
		else
			pop_table.basic_needs_satisfaction = 1
		end
	end


	local use_case = require "game.raws.raws-utils".trade_good_use_case

	---commenting
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
		local demanded_use = math.max(amount, savings / price_expectation)

		local available = available_goods_for_use(use_reference)
		if amount > available then
			amount = available
		end
		local potential_amount = math.min(amount, demanded_use)

		local total_bought = 0
		local spendings = 0

		for good, weight in pairs(use.goods) do
			local c_index = RAWS_MANAGER.trade_good_to_index[good] - 1

			local consumed_amount = potential_amount / weight * market_data[c_index].feature / total_exp
			if consumed_amount > market_data[c_index].available then
				consumed_amount = market_data[c_index].available
			end
			local demanded_amount = demanded_use / weight * market_data[c_index].feature / total_exp

			-- we need to get back to use "units" so we multiplay consumed amount back by weight
			total_bought = total_bought + consumed_amount * weight

			spendings = spendings + record_consumption(c_index + 1, consumed_amount)
			record_demand(c_index + 1, demanded_amount)
		end

		return spendings, total_bought
	end

	---@type table<POP, number>
	local donations_to_owners = {}

	-- sort pops by wealth:
	---@type POP[]
	local pops_by_wealth = {}
	for _, pop in pairs(province.all_pops) do
		table.insert(pops_by_wealth, pop)
	end
	table.sort(pops_by_wealth, function(a, b)
		return a.savings > b.savings
	end)



	PROFILER:start_timer("production-pops-loop")
	for _, pop in ipairs(pops_by_wealth) do
		-- populate pop_view
		local foraging_multiplier = pop.race.male_efficiency[JOBTYPE.FORAGER]
		if pop.female then
			foraging_multiplier = pop.race.female_efficiency[JOBTYPE.FORAGER]
		end
		pop_view[zero].foraging_efficiency = foraging_multiplier * foraging_efficiency
		pop_view[zero].age_multiplier = pop:get_age_multiplier()

		-- populate job efficiency
		if pop.female then
			for tag, value in pairs(JOBTYPE) do
				pop_job_efficiency[value] = pop.race.female_efficiency[value]
			end
			for tag, value in pairs(NEED) do
				local need_tag = NEED[tag]
				pop_need_amount[value] = pop.race.female_needs[need_tag]

				local need = NEEDS[need_tag]
				if not need.age_independent then
					pop_need_amount[value] = pop_need_amount[value] * pop_view[zero].age_multiplier
				end
			end
		else
			for tag, value in pairs(JOBTYPE) do
				pop_job_efficiency[value] = pop.race.male_efficiency[value]
			end
			for tag, value in pairs(NEED) do
				local need_tag = NEED[tag]
				pop_need_amount[value] = pop.race.male_needs[need_tag]

				local need = NEEDS[need_tag]
				if not need.age_independent then
					pop_need_amount[value] = pop_need_amount[value] * pop_view[zero].age_multiplier
				end
			end
		end

		pop_job_efficiency[JOBTYPE.FORAGER] = pop_job_efficiency[JOBTYPE.FORAGER] * foraging_efficiency


		-- base income: all adult pops forage and help each other which translates into a bit of wealth
		-- real reason: wealth sources to fuel the economy
		-- buidings are essentially wealth sinks currently
		-- so obviously we need some wealth sources
		-- should be removed when economy simulation will be completed
		local base_income = 1 * pop.age / 100;
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


				local local_foraging_efficiency = 1
				if prod.foraging then
					foragers_count = foragers_count +
					math.min(building.work_ratio, free_time_of_pop)                    -- Record a new forager!
					local_foraging_efficiency = foraging_efficiency
				end
				local yield = 1
				local local_tile = province.center
				if local_tile then
					yield = prod:get_efficiency(local_tile)
				end

				local efficiency = yield
					* local_foraging_efficiency
					* efficiency_from_infrastructure
					* math.min(pop.employer.work_ratio, free_time_of_pop)

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
					local total_power = prod.forest_dependence * efficiency * throughput_boost * input_boost /
					days_to_deforestate
					require "game.raws.effects.geography".deforest_random_tile(province, total_power)
				end

				local income = 0

				-- real input satisfaction
				local input_satisfaction_2 = 1
				local production_budget = pop.savings / 2

				if efficiency > 0 then
					for input, amount in pairs(prod.inputs) do
						local required = input_boost * amount * efficiency
						local spent, consumed = buy_use(input, required, production_budget)

						input_satisfaction_2 = math.min(input_satisfaction_2, consumed / required)
						income = income - spent
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
					-- reduce working hours to negate losses
					pop.employer.work_ratio = math.max(0.01, pop.employer.work_ratio * 0.5)
				end

				free_time_of_pop = free_time_of_pop -
				math.min(pop.employer.work_ratio, free_time_of_pop) * input_satisfaction * input_satisfaction_2

				if province.trade_wealth > income then
					economic_effects.add_pop_savings(pop, income, economic_effects.reasons.Work)
					province.trade_wealth = province.trade_wealth - income
				end
			end
			PROFILER:end_timer('production-building-update')

			if pop.age < pop.race.teen_age then
				-- parents help their children
				local parent = pop.parent
				if parent then
					local siphon = parent.savings * 0.125 / 2
					if siphon > 0 then
						economic_effects.add_pop_savings(parent, -siphon, economic_effects.reasons.Donation)
						economic_effects.add_pop_savings(pop, siphon, economic_effects.reasons.Donation)
					end
				end

				-- community helps children as well
				if pop.home_province == pop.province then
					local siphon_to_child = math.min(food_price * 0.5, province.local_wealth * 1 / 512)
					if siphon_to_child > 0 then
						economic_effects.add_pop_savings(pop, siphon_to_child, economic_effects.reasons.Donation)
						economic_effects.change_local_wealth(
							province,
							-siphon_to_child,
							economic_effects.reasons.Donation
						)
					end
				end

				-- children spend time on games and growing up:
				free_time_of_pop = free_time_of_pop * pop.age / pop.race.teen_age
			end

			-- every pop spends some time or wealth on fullfilling their needs:
			PROFILER:start_timer("production-satisfy-needs")
			satisfy_needs(pop_view, pop, free_time_of_pop, pop.savings / 10)
			PROFILER:end_timer("production-satisfy-needs")
		end

		::continue::
	end
	PROFILER:end_timer("production-pops-loop")


	--- DISTRIBUTION OF DONATIONS
	PROFILER:start_timer('donations')
	-- pops donate some of their savings as well:
	for _, pop in pairs(province.all_pops) do
		total_realm_donations = total_realm_donations + pop.savings / 100
		total_local_donations = total_local_donations + pop.savings / 20
		total_trade_donations = total_trade_donations + pop.savings / 20

		local pop_donation_total = pop.savings / 100 + pop.savings / 20 + pop.savings / 20

		economic_effects.add_pop_savings(pop, -pop_donation_total, economic_effects.reasons.Donation)
	end

	local total_popularity = 0
	for _, c in pairs(province.characters) do
		local popularity = pv.popularity(c, province.realm)
		if popularity > 0 then
			total_popularity = total_popularity + popularity
		end
	end
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
