local good = require "game.raws.raws-utils".trade_good

local tabb = require "engine.table"
local EconomicEffects = require "game.raws.effects.economic"
local ev = require "game.raws.values.economical"
local pv = require "game.raws.values.political"

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

	-- IMPLEMENT CULTURAL VALUE
	local fraction_of_income_given_voluntarily = 0.1 * math.max(0, math.min(1.0, 1.0 - population / min_income_pop))

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
									* shortage_modifier -- add more multiplier to this later
				local throughput_boost = 1 + (province.throughput_boosts[prod] or 0)
				local input_boost = math.max(0, 1 - (province.input_efficiency_boosts[prod] or 0))
				local output_boost = 1 + (province.output_efficiency_boosts[prod] or 0)
				-- TODO: use realm stockpiles to control production efficiency!

				-- if depends on forests, then reduce local forest coverage over time
				-- sample random tile from province to avoid weird looking pimples
				if prod.forest_dependence > 0 then
					local deforested_tile = tabb.random_select_from_set(province.tiles)
					local years_to_deforestate = 50
					local days_to_deforestate = years_to_deforestate * 360
					local input_power = prod.forest_dependence * efficiency * throughput_boost * input_boost / days_to_deforestate
					local woods = deforested_tile.broadleaf + deforested_tile.conifer + deforested_tile.shrub
					if woods > 0 then
						local broadleaf_ratio = deforested_tile.broadleaf / woods
						local conifer_ratio = deforested_tile.conifer / woods
						local shrub_ratio = deforested_tile.shrub / woods

						local broad_leaf_change = math.min(deforested_tile.broadleaf, input_power * broadleaf_ratio)
						local conifer_change = math.min(deforested_tile.conifer, input_power * conifer_ratio)
						local shrub_change = math.min(deforested_tile.shrub, input_power * shrub_ratio)

						deforested_tile.broadleaf = deforested_tile.broadleaf - broad_leaf_change
						deforested_tile.conifer = deforested_tile.conifer - conifer_change
						deforested_tile.shrub = deforested_tile.shrub - shrub_change

						local total_change = broad_leaf_change + conifer_change + shrub_change
						deforested_tile.grass = deforested_tile.grass + total_change
					end
				end

				local income = 0
				for input, amount in pairs(prod.inputs) do
					record_consumption(input, amount)
					local price = ev.get_local_price(province, input)
					income = income
							- price * amount * efficiency * throughput_boost * input_boost
				end
				income = income
				for output, amount in pairs(prod.outputs) do
					record_production(output, amount * efficiency)
					local price = ev.get_pessimistic_local_price(province, output, amount)
					income = income
							+ price * amount * efficiency * throughput_boost * output_boost
				end

				if pop.employer.income_mean then
					pop.employer.income_mean = pop.employer.income_mean * 0.5 + income * 0.5
				else
					pop.employer.income_mean = income
				end

				if income > 0 then
					province.local_wealth = province.local_wealth + income * INCOME_TO_LOCAL_WEALTH_MULTIPLIER
					local contrib = math.min(0.75, income * fraction_of_income_given_voluntarily)
					local owner = pop.employer.owner
					if owner then
						if donations_to_owners[owner] == nil then
							donations_to_owners[owner] = 0
						end
						donations_to_owners[owner] = donations_to_owners[pop.employer.owner] + contrib
					else
						total_donations = total_donations + contrib
					end
					-- province.realm.voluntary_contributions_accumulator = province.realm.voluntary_contributions_accumulator + contrib
				end
			else
				if pop.age > pop.race.teen_age then
					foragers_count = foragers_count + 1 -- Record a new forager!
					-- Foragers produce food:
					local food_produced = math.min(0.9, foraging_efficiency)
					local food_price = ev.get_pessimistic_local_price(province, 'food', food_produced)
					local income = food_produced * food_price
					if income > 0 then
						province.local_wealth = province.local_wealth + income * INCOME_TO_LOCAL_WEALTH_MULTIPLIER
						local contrib = math.min(0.75, income * fraction_of_income_given_voluntarily)
						total_donations = total_donations + contrib
						-- province.realm.voluntary_contributions_accumulator = province.realm.voluntary_contributions_accumulator + contrib
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

		record_consumption('food', food) -- exprimental lack of an age multiplier -- it makes AI for pop growth simpler
		record_consumption('water', water * age_multiplier)
		record_consumption('healthcare', 0.2 * age_multiplier)
		record_consumption('amenities', age_multiplier)

		record_consumption('clothes', clothing * age_multiplier)
		record_consumption('furniture', 0.1 * age_multiplier)
		record_consumption('liquors', 0.2 * age_multiplier)
		record_consumption('containers', 0.25 * age_multiplier)
		record_consumption('tools', 0.0125 * age_multiplier)

		record_consumption('meat', 0.25 * age_multiplier)
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
