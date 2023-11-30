local good = require "game.raws.raws-utils".trade_good
local JOBTYPE = require "game.raws.job_types"

local tabb = require "engine.table"
local EconomicEffects = require "game.raws.effects.economic"
local ev = require "game.raws.values.economical"
local pv = require "game.raws.values.political"

local pro = {}

local NEEDS =  {
	water = 1,
	healthcare = 0.2,
	amenities = 1,
	hide = 0.1,
	leather = 0.3,
	clothes = 1,
	furniture = 0.1,
	liquors = 0.2,
	containers = 0.25,
	tools = 0.0125,
	["knapping-blanks"] = 0.0005,
	meat = 0.25
}

---Runs production on a single province!
---@param province Province
function pro.run(province)

	-- local INCOME_TO_LOCAL_WEALTH_MULTIPLIER = 0.025
	INCOME_TO_LOCAL_WEALTH_MULTIPLIER = 0.075
	-- First, we need to re-assign pops to jobs

	-- save old prices:
	---@type table<TradeGoodReference, number>
	local old_prices = {}
	for good_name, price in pairs(RAWS_MANAGER.trade_goods_by_name) do
		old_prices[good_name] = ev.get_local_price(province, good_name)
	end

	-- Clear previous months local production!
	tabb.clear(province.local_production)
	tabb.clear(province.local_consumption)

	-- Clear building stats
	for key, value in pairs(province.buildings) do
		tabb.clear(value.earn_from_outputs)
		tabb.clear(value.spent_on_inputs)
		value.last_donation_to_owner = 0
		value.last_income = 0
	end

	---Records local consumption!
	---@param good TradeGoodReference
	---@param amount number
	local function record_consumption(good, amount)
		local old = province.local_consumption[good] or 0
		province.local_consumption[good] = old + amount
	end

	---Record local production!
	---@param good TradeGoodReference
	---@param amount number
	local function record_production(good, amount)
		local old = province.local_production[good] or 0
		province.local_production[good] = old + amount
	end

	-- Record "innate" production of goods and services.
	-- These resources come
	record_production('water', province.hydration)

	local inf = province:get_infrastructure_efficiency()
	local efficiency_from_infrastructure = math.min(1.15, 0.5 + 0.5 * math.sqrt(2 * inf))
	-- Record local production...
	local foragers_count = 0
	local foraging_efficiency = math.min(1.15, (province.foragers_limit / math.max(1, province.foragers)))
	local old_wealth = province.local_wealth -- store wealth before this tick, used to calculate income later
	local population = tabb.size(province.all_pops)
	local min_income_pop = math.max(50, math.min(200, 100 + province.mood * 10))

	-- TODO: IMPLEMENT CULTURAL VALUE
	local fraction_of_income_given_voluntarily = 0.1 * math.max(0, math.min(1.0, 1.0 - population / min_income_pop))
	local fraction_of_income_given_to_owner = 0.1

	DISPLAY_INCOME_OWNER_RATIO = (1 - INCOME_TO_LOCAL_WEALTH_MULTIPLIER) * fraction_of_income_given_to_owner

	local total_donations = 0

	---@type table<POP, number>
	local donations_to_owners = {}

	for _, pop in pairs(province.all_pops) do
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

				local input_satisfaction = 1

				for input, amount in pairs(prod.inputs) do
					local required_input = amount
					local present_input = province.local_storage[input] or 0
					local ratio = present_input / required_input
					input_satisfaction = math.min(input_satisfaction, ratio)
				end

				-- (1 - prod.self_sourcing_fraction) is a modifier to efficiency during 100% shortage
				-- 1 is a modifier to efficiency during 0% shortage, i.e. 1.0 input satisfaction

				local shortage_modifier =
					(1 - prod.self_sourcing_fraction) * (1 - input_satisfaction)
					+ 1 * input_satisfaction

				local efficiency = yield
									* local_foraging_efficiency
									* efficiency_from_infrastructure
									* shortage_modifier -- add more multipliers to this later
									* pop.employer.work_ratio


				local income, input_boost, output_boost, throughput_boost
					= ev.projected_income(
						pop.employer,
						pop.race,
						pop.female,
						old_prices,
						efficiency,
						true
					)

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
					record_consumption(input, amount * efficiency * input_boost * throughput_boost)end
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
					province.local_wealth = province.local_wealth + income * INCOME_TO_LOCAL_WEALTH_MULTIPLIER
					income = income - income * INCOME_TO_LOCAL_WEALTH_MULTIPLIER
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
					pop.employer.work_ratio = math.min(1.0, pop.employer.work_ratio * 1.2)
				else
					-- reduce working hours to negate losses
					pop.employer.work_ratio = math.max(0.01, pop.employer.work_ratio * 0.8)
				end
			else
				if pop.age > pop.race.teen_age then
					foragers_count = foragers_count + 1 -- Record a new forager!

					local foraging_multiplier = pop.race.male_efficiency[JOBTYPE.FORAGER]

					-- Foragers produce food:
					local food_produced = math.min(0.9, foraging_efficiency * foraging_multiplier)
					local food_price = ev.get_pessimistic_local_price(province, 'food', food_produced)
					local income = food_produced * food_price
					if income > 0 then
						province.local_wealth = province.local_wealth + income * INCOME_TO_LOCAL_WEALTH_MULTIPLIER

						-- commented to test changes and to be able to switch it on demand
						-- local contrib = math.min(0.75, income * fraction_of_income_given_voluntarily)
						local contrib = income * fraction_of_income_given_voluntarily

						total_donations = total_donations + contrib
					end
					record_production('food', food_produced)
				end
			end
		end
		-- Record POP consumption
		local age_multiplier = pop:get_age_multiplier()

		local water = pop.race.male_water_needs
		local food = pop.race.male_food_needs
		local clothing = pop.race.male_clothing_needs
		if pop.female then
			water = pop.race.female_water_needs
			food = pop.race.female_food_needs
			clothing = pop.race.female_clothing_needs
		end


		-- for some goods there is always some demand
		record_consumption('food', food) -- exprimental lack of an age multiplier -- it makes AI for pop growth simpler
		record_consumption('water', water * age_multiplier)

		local wealth_multiplier = province.local_wealth / 12 / population --- we are ready to spend our wealth during a year per pop

		for good, need in pairs(NEEDS) do
			local demand = need * age_multiplier
			if good == 'clothes' then
				demand = demand * clothing
			end
			local total_cost = old_prices[good] * demand
			local ratio = math.max(0.25, math.min(1, wealth_multiplier / (total_cost + 0.05)))

			record_consumption(good, demand * ratio)
		end
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
			EconomicEffects.add_pop_savings(c, elites_share * pv.popularity(c, province.realm) / total_popularity, EconomicEffects.reasons.Donation)
		end
	end
	EconomicEffects.register_income(province.realm, realm_share, EconomicEffects.reasons.Donation)

	for character, income in pairs(donations_to_owners) do
		EconomicEffects.add_pop_savings(character, income, EconomicEffects.reasons.BuildingIncome)
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

			end
			for output, amount in pairs(prod.outputs) do
				record_production(output, amount * efficiency)
			end
		end
	end


end

return pro
