local tabb = require "engine.table"
local pro = {}

---Runs production on a single province!
---@param province Province
function pro.run(province)

	local INCOME_TO_LOCAL_WEALTH_MULTIPLIER = 0.025
	-- First, we need to re-assign pops to jobs

	-- Clear previous months local production!
	tabb.clear(province.local_production)
	tabb.clear(province.local_consumption)

	---Records local consumption!
	---@param good TradeGood
	---@param amount number
	local function record_consumption(good, amount)
		local old = province.local_consumption[good] or 0
		province.local_consumption[good] = old + amount
	end

	---Record local production!
	---@param good TradeGood
	---@param amount number
	local function record_production(good, amount)
		local old = province.local_production[good] or 0
		province.local_production[good] = old + amount
	end

	-- Record "innate" production of goods and services.
	-- These resources come
	record_production(WORLD.trade_goods_by_name['water'], province.hydration)

	local inf = province:get_infrastructure_efficiency()
	local efficiency_from_infrastructure = math.min(1.15, 0.5 + 0.5 * math.sqrt(2 * inf))
	-- Record local production...
	local foragers_count = 0
	local foraging_efficiency = math.min(1.15, (province.foragers_limit / math.max(1, province.foragers)))
	local old_wealth = province.local_wealth -- store wealth before this tick, used to calculate income later
	local population = tabb.size(province.all_pops)
	local min_income_pop = math.max(50, math.min(200, 100 + province.mood * 10))
	local fraction_of_income_given_voluntarily = 0.1 * math.max(0, math.min(1.0, 1.0 - population / min_income_pop))
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
				local efficiency = yield * local_foraging_efficiency * efficiency_from_infrastructure -- add more multiplier to this later
				local throughput_boost = 1 + (province.throughput_boosts[prod] or 0)
				local input_boost = math.max(0, 1 - (province.input_efficiency_boosts[prod] or 0))
				local output_boost = 1 + (province.output_efficiency_boosts[prod] or 0)
				-- TODO: use realm stockpiles to control production efficiency!

				local income = 0
				for input, amount in pairs(prod.inputs) do
					record_consumption(input, amount)
					income = income - province.realm:get_price(input) * amount * efficiency * throughput_boost * input_boost
				end
				for output, amount in pairs(prod.outputs) do
					record_production(output, amount * efficiency)
					income = income +
						province.realm:get_pessimistic_price(output, amount) * amount * efficiency * throughput_boost * output_boost
				end

				if income > 0 then
					province.local_wealth = province.local_wealth + income * INCOME_TO_LOCAL_WEALTH_MULTIPLIER
					local contrib = math.min(0.75, income * fraction_of_income_given_voluntarily)
					province.realm.treasury = province.realm.treasury + contrib
					province.realm.voluntary_contributions_accumulator = province.realm.voluntary_contributions_accumulator + contrib
				end
			else
				if pop.age > pop.race.teen_age then
					foragers_count = foragers_count + 1 -- Record a new forager!
					-- Foragers produce food:
					local food = WORLD.trade_goods_by_name['food']
					local food_produced = math.min(0.9, foraging_efficiency)
					local income = food_produced * province.realm:get_pessimistic_price(food, food_produced)
					if income > 0 then
						province.local_wealth = province.local_wealth + income * INCOME_TO_LOCAL_WEALTH_MULTIPLIER
						local contrib = math.min(0.75, income * fraction_of_income_given_voluntarily)
						province.realm.treasury = province.realm.treasury + contrib
						province.realm.voluntary_contributions_accumulator = province.realm.voluntary_contributions_accumulator + contrib
					end
					record_production(food, food_produced)
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

		record_consumption(WORLD.trade_goods_by_name['food'], food) -- exprimental lack of an age multiplier -- it makes AI for pop growth simpler
		record_consumption(WORLD.trade_goods_by_name['water'], water * age_multiplier)
		record_consumption(WORLD.trade_goods_by_name['healthcare'], 0.2 * age_multiplier)
		record_consumption(WORLD.trade_goods_by_name['amenities'], age_multiplier)

		record_consumption(WORLD.trade_goods_by_name['clothes'], clothing * age_multiplier)
		record_consumption(WORLD.trade_goods_by_name['furniture'], 0.1 * age_multiplier)
		record_consumption(WORLD.trade_goods_by_name['liquors'], 0.2 * age_multiplier)
		record_consumption(WORLD.trade_goods_by_name['containers'], 0.25 * age_multiplier)
		record_consumption(WORLD.trade_goods_by_name['tools'], 0.0125 * age_multiplier)

		record_consumption(WORLD.trade_goods_by_name['meat'], 0.25 * age_multiplier)
	end
	province.local_income = province.local_wealth - old_wealth
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
