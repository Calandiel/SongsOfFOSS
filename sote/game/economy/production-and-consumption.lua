local trade_good = require "game.raws.raws-utils".trade_good
local JOBTYPE = require "game.raws.job_types"

local tabb = require "engine.table"
local economic_effects = require "game.raws.effects.economic"
local ev = require "game.raws.values.economical"
local pv = require "game.raws.values.political"

local pro = {}

---Runs production on a single province!
---@param province Province
function pro.run(province)

	-- how much of income is siphoned to local wealth pool
	INCOME_TO_LOCAL_WEALTH_MULTIPLIER = 0.125 / 4
	-- buying prices for pops are multiplied on this number
	POP_BUY_PRICE_MULTIPLIER = 1.5


	-- save old prices:
	---@type table<TradeGoodReference, number>
	local old_prices = {}
	---@type table<TradeGoodReference, number>
	local old_inverted_prices_exp = {}
	for good_name, price in pairs(RAWS_MANAGER.trade_goods_by_name) do
		old_prices[good_name] = ev.get_local_price(province, good_name)
		old_inverted_prices_exp[good_name] = math.exp(-old_prices[good_name])
	end

	-- save available resources:
	---@type table<TradeGoodReference, number>
	local available_last_time = {}
	for good, value in pairs(province.local_consumption) do
		available_last_time[good] = (available_last_time[good] or 0) - value
	end
	for good, value in pairs(province.local_production) do
		available_last_time[good] = (available_last_time[good] or 0) + value
	end
	for good, value in pairs(province.local_storage) do
		available_last_time[good] = (available_last_time[good] or 0) + value
	end


	-- Clear previous months local production!
	tabb.clear(province.local_production)
	tabb.clear(province.local_consumption)
	tabb.clear(province.local_demand)

	-- Clear building stats
	for key, value in pairs(province.buildings) do
		tabb.clear(value.earn_from_outputs)
		tabb.clear(value.spent_on_inputs)
		value.last_donation_to_owner = 0
		value.last_income = 0
		value.subsidy_last = 0
	end

	---Records local consumption!
	---@param good TradeGoodReference
	---@param amount number
	local function record_consumption(good, amount)
		local old = province.local_consumption[good] or 0
		province.local_consumption[good] = old + amount
		available_last_time[good] = (available_last_time[good] or 0) - amount

		if province.local_production[good] ~= province.local_production[good] then
			error(
				"INVALID RECORD OF CONSUMPTION"
				.. "\n amount = "
				.. tostring(amount)
				.. "\n old = "
				.. tostring(old)
			)
		end

		return old_prices[good] * amount
	end

	---Record local production!
	---@param good TradeGoodReference
	---@param amount number
	local function record_production(good, amount)
		local old = province.local_production[good] or 0
		province.local_production[good] = old + amount

		if province.local_production[good] ~= province.local_production[good] then
			error(
				"INVALID RECORD OF PRODUCTION"
				.. "\n amount = "
				.. tostring(amount)
				.. "\n old = "
				.. tostring(old)
			)
		end

		return old_prices[good] * amount
	end


	---Record local demand!
	---@param good TradeGoodReference
	---@param amount number
	local function record_demand(good, amount)
		local old = province.local_demand[good] or 0
		province.local_demand[good] = old + amount

		return old_prices[good] * amount
	end



	-- Record "innate" production of goods and services.
	-- These resources come
	record_production('water', province.hydration)

	local inf = province:get_infrastructure_efficiency()
	local efficiency_from_infrastructure = math.min(1.5, 0.5 + 0.5 * math.sqrt(2 * inf))
	-- Record local production...
	local foragers_count = 0
	local foraging_efficiency = math.min(1.15, (province.foragers_limit / math.max(1, province.foragers)))
	local old_wealth = province.local_wealth -- store wealth before this tick, used to calculate income later
	local population = tabb.size(province.all_pops)
	local min_income_pop = math.max(50, math.min(200, 100 + province.mood * 10))
	local total_donations = 0

	-- TODO: IMPLEMENT CULTURAL VALUE
	local fraction_of_income_given_voluntarily = 0.1 * math.max(0, math.min(1.0, 1.0 - population / min_income_pop))
	local fraction_of_income_given_to_owner = 0.1

	DISPLAY_INCOME_OWNER_RATIO = (1 - INCOME_TO_LOCAL_WEALTH_MULTIPLIER) * fraction_of_income_given_to_owner

	---@param pop POP
	local function forage(pop)
		foragers_count = foragers_count + 1 -- Record a new forager!

		local foraging_multiplier = pop.race.male_efficiency[JOBTYPE.FORAGER]
		if pop.female then
			foraging_multiplier = pop.race.female_efficiency[JOBTYPE.FORAGER]
		end

		-- Foragers produce food:
		local food_produced = foraging_efficiency * foraging_multiplier * 0.5
		local food_price = old_prices['food']
		---@type number
		local income = food_produced * food_price
		if income > 0 then
			---@type number
			local contribution_to_local_wealth = income * INCOME_TO_LOCAL_WEALTH_MULTIPLIER
			province.local_wealth = province.local_wealth + contribution_to_local_wealth
			income = income - contribution_to_local_wealth

			---@type number
			local contrib = income * fraction_of_income_given_voluntarily
			total_donations = total_donations + contrib
			income = income - contrib
		end

		record_production('food', food_produced)
		if province.trade_wealth > income then
			economic_effects.add_pop_savings(pop, income, economic_effects.reasons.Forage)
			province.trade_wealth = province.trade_wealth - income
		end
	end

	---@type table<POP, number>
	local donations_to_owners = {}

	-- idle warbands participate in hunting and gathering:
	for _, warband in pairs(province.warbands) do
		if warband.status == 'idle' then
			for _, pop in pairs(warband.pops) do
				forage(pop)
			end
		end
	end


	local population_size = province:population()

	for _, pop in pairs(province.all_pops) do
		-- base income: all adult pops forage and help each other which translates into a bit of wealth
		-- real reason: wealth sources to fuel the economy
		-- buidings are essentially wealth sinks currently
		-- so obviously we need some wealth sources
		-- should be removed when economy simulation will be completed
		if pop.age > pop.race.teen_age then
			economic_effects.add_pop_savings(pop, 1 / population_size, economic_effects.reasons.MonthlyChange)
		end
		-- Drafted pops don't work -- they may not even be in the province in the first place...
		if not pop.drafted then
			if pop.employer ~= nil then
				local prod = pop.employer.type.production_method
				local local_foraging_efficiency = 1
				if prod.foraging then
					foragers_count = foragers_count + 1 -- Record a new forager!
					local_foraging_efficiency = foraging_efficiency
				end
				local yield = 1
				local local_tile = province.center
				if pop.employer.tile then
					local_tile = pop.employer.tile
				end
				if local_tile then
					yield = prod:get_efficiency(local_tile)

				end

				local efficiency = yield
									* local_foraging_efficiency
									* efficiency_from_infrastructure
									* pop.employer.work_ratio

				local input_satisfaction = 1

				for input, amount in pairs(prod.inputs) do
					local required_input = amount * efficiency
					local present_input = math.max(0, available_last_time[input] or 0)
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

				-- (1 - prod.self_sourcing_fraction) is a modifier to efficiency during 100% shortage
				-- 1 is a modifier to efficiency during 0% shortage, i.e. 1.0 input satisfaction

				local shortage_modifier =
					(1 - prod.self_sourcing_fraction) * (1 - input_satisfaction)
					+ 1 * input_satisfaction

				efficiency = efficiency * shortage_modifier

				local income, input_boost, output_boost, throughput_boost
					= ev.projected_income(
						pop.employer,
						pop.race,
						pop.female,
						old_prices,
						efficiency,
						true
					)

				-- if WORLD.player_character then
				-- 	if WORLD.player_character.province == province then
				-- 		if pop.employer.owner == WORLD.player_character then
				-- 			print('%?')
				-- 			print(pop.employer.type.name)
				-- 			print("infra_eff: ", efficiency_from_infrastructure)
				-- 			print("shortage_modifier: ", shortage_modifier)
				-- 			print("work_ratio: ", pop.employer.work_ratio)
				-- 			print("income: ", income)
				-- 		end
				-- 	end
				-- end

				if efficiency ~= efficiency then
					error(
						"INVALID VALUE OF EFFICIENCY"
						.. "\n value = "
						.. tostring(efficiency)
						.. "\n shortage_modifier = "
						.. tostring(shortage_modifier)
						.. "\n pop.employer.work_ratio = "
						.. tostring(pop.employer.work_ratio)
						.. "\n efficiency_from_infrastructure = "
						.. tostring(efficiency_from_infrastructure)
						.. "\n local_foraging_efficiency = "
						.. tostring(local_foraging_efficiency)
					)
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

				for input, amount in pairs(prod.inputs) do
					record_consumption(input, amount * efficiency * input_boost * throughput_boost)
					record_demand(input, amount * efficiency * input_boost * throughput_boost)
				end
				for output, amount in pairs(prod.outputs) do
					record_production(output, amount * efficiency * output_boost * throughput_boost)
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
					local contribution_to_local_wealth = income * INCOME_TO_LOCAL_WEALTH_MULTIPLIER
					province.local_wealth = province.local_wealth + contribution_to_local_wealth
					income = income - contribution_to_local_wealth

					---@type number
					local contrib = income * fraction_of_income_given_voluntarily
					local owner = pop.employer.owner
					if owner then
						---@type number
						contrib = income * fraction_of_income_given_to_owner
						if donations_to_owners[owner] == nil then
							donations_to_owners[owner] = 0
						end
						donations_to_owners[owner] = donations_to_owners[pop.employer.owner] + contrib
						pop.employer.last_donation_to_owner = pop.employer.last_donation_to_owner + contrib
					else
						total_donations = total_donations + contrib
					end
					income = income - contrib

					-- increase working hours if possible to increase income
					pop.employer.work_ratio = math.min(1.0, pop.employer.work_ratio * 1.1)
				else
					-- reduce working hours to negate losses
					pop.employer.work_ratio = math.max(0.01, pop.employer.work_ratio * 0.5)
				end

				if province.trade_wealth > income then
					economic_effects.add_pop_savings(pop, income, economic_effects.reasons.Work)
					province.trade_wealth = province.trade_wealth - income
				end
			else
				if pop.age > pop.race.teen_age then
					forage(pop)
				else
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
					local siphon_to_child = math.min(old_prices['food'] * 0.5, province.local_wealth * 1 / 512)
					if siphon_to_child > 0 then
						economic_effects.add_pop_savings(pop, siphon_to_child, economic_effects.reasons.Donation)
						province.local_wealth = province.local_wealth - siphon_to_child
					end
				end
			end
		else
			-- drafted pops are paid with military upkeep
			-- and forage as handled above loop
		end

		-- Record POP consumption
		local age_multiplier = pop:get_age_multiplier()

		local total_needs = 0
		local total_satisfied = 0

		local total_life_needs = 0
		local total_life_satisfied = 0

		local needs = pop.race.male_needs
		if pop.female then
			needs = pop.race.female_needs
		end

		local old_savings = math.max(0, pop.savings / 10)
		local current_savings = old_savings

		---comment
		---@param need Need
		---@param demand number
		local function buy_need(need, demand)
			---@type number
			local total_demand = demand
			if not need.age_independent then
				total_demand = total_demand * age_multiplier
			end

			-- now calculate distribution over goods:
			local total_exp = 0
			for _, good in pairs(need.goods) do
				total_exp = total_exp + old_inverted_prices_exp[good]
			end

			local total_available = 0
			for _, good in pairs(need.goods) do
				total_available = total_available + math.max(0, (available_last_time[good] or 0))
			end

			-- if WORLD.player_character then
			-- 	if WORLD.player_character.province == province then
			-- 		print(need_name)
			-- 		print("total available:")
			-- 		print(total_available)
			-- 	end
			-- end

			-- calculate price expectation
			local price = 0
			for _, good in pairs(need.goods) do
				price = price + old_prices[good] * old_inverted_prices_exp[good] / total_exp
			end


			local total_cost = price * total_demand * POP_BUY_PRICE_MULTIPLIER

			-- calculate ratios of what pop could buy with current money
			-- and ratio of available goods on market
			local ratio_could_buy = math.min(1, math.max(0, current_savings) / total_cost)
			local ratio_can_buy = math.min(1, math.max(0, total_available) / total_demand)

			local ratio = math.min(ratio_can_buy, ratio_could_buy)

			-- if WORLD.player_character then
			-- 	if WORLD.player_character.province == province then
			-- 		print("ratio_could_buy ", ratio_could_buy)
			-- 		print("ratio_can_buy ", ratio_can_buy)
			-- 	end
			-- end

			current_savings = current_savings - total_cost * ratio

			if current_savings ~= current_savings then
				error(
					"INVALID ATTEMPT OF POP TO BUY A NEED: total_cost = "
					.. tostring(total_cost)
					.. " ratio = "
					.. tostring(ratio)
				)
			end

			total_needs = total_needs + total_demand
			total_satisfied = total_satisfied + total_demand * ratio

			if need.life_need then
				total_life_needs = total_life_needs + total_demand
				total_life_satisfied = total_life_satisfied + total_demand * ratio
			end


			-- register consumption/demand of goods according to distribution
			-- demand and consumption should be separate one day...
			for _, good in pairs(need.goods) do
				local demand = total_demand * old_inverted_prices_exp[good] / total_exp
				record_consumption(good, demand * ratio)
				record_demand(good, demand * ratio_could_buy)
			end
		end

		-- buying life needs
		for need_name, demand in pairs(needs) do
			local need = NEEDS[need_name]
			if need == nil then
				error("WRONG NEED NAME: " .. need_name)
			end
			if need.life_need then
				buy_need(need, demand)
			end
		end

		-- buying base needs
		for need_name, demand in pairs(needs) do
			local need = NEEDS[need_name]
			if need == nil then
				error("WRONG NEED NAME: " .. need_name)
			end
			if not need.life_need then
				buy_need(need, demand)
			end
		end

		economic_effects.add_pop_savings(pop, current_savings - old_savings, economic_effects.reasons.OtherNeeds)
		province.trade_wealth = province.trade_wealth - current_savings + old_savings

		pop.basic_needs_satisfaction = total_satisfied / total_needs
		pop.life_needs_satisfaction = total_life_satisfied / total_life_needs
	end

	--- DISTRIBUTION OF DONATIONS
	local total_popularity = 0
	for _, c in pairs(province.characters) do
		total_popularity = total_popularity + pv.popularity(c, province.realm)
	end
	local realm_share = total_donations
	if total_popularity > 0 then
		realm_share = total_donations * 0.5
		local elites_share = total_donations - realm_share
		for _, c in pairs(province.characters) do
			economic_effects.add_pop_savings(c, elites_share * pv.popularity(c, province.realm) / total_popularity, economic_effects.reasons.Donation)
		end
	end
	economic_effects.register_income(province.realm, realm_share, economic_effects.reasons.Donation)

	for character, income in pairs(donations_to_owners) do
		economic_effects.add_pop_savings(character, income, economic_effects.reasons.BuildingIncome)
	end

	province.local_income = province.local_wealth - old_wealth
	local to_trade_siphon = province.local_wealth * 0.01
	local from_trade_siphon = province.trade_wealth * 0.01
	province.local_wealth = province.local_wealth + from_trade_siphon - to_trade_siphon
	province.trade_wealth = province.trade_wealth - from_trade_siphon + to_trade_siphon

	province.foragers = foragers_count -- Record the new number of foragers

	for _, bld in pairs(province.buildings) do
		local prod = bld.type.production_method
		if tabb.size(prod.jobs) == 0 then
			-- If a building has no jobs, it always works!
			local efficiency = 1
			for input, amount in pairs(prod.inputs) do
				record_consumption(input, amount)
				record_demand(input, amount)
			end
			for output, amount in pairs(prod.outputs) do
				record_production(output, amount * efficiency)
			end
		end
	end


end

return pro
