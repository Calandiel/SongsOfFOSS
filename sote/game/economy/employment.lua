local tabb = require "engine.table"
local emp = {}

local economy_values = require "game.raws.values.economy"
local province_utils = require "game.entities.province".Province
local building_utils = require "game.entities.building".Building
local method_utils = require "game.raws.production-methods"

---Employs pops in the province.
---@param province province_id
function emp.run(province)
	-- Sample random pop and try to employ it
	---@type pop_id[]
	local eligible_pops = tabb.filter_array(
		tabb.map_array(DATA.get_pop_location_from_location(province), DATA.pop_location_get_pop),
		function (pop)
			local race = DATA.pop_get_race(pop)
			local teen_age = DATA.race_get_teen_age(race)
			return (DATA.pop_get_age(pop) > teen_age) and (DATA.pop_get_work_ratio(pop) > 0.02)
		end
	)

	local pop = tabb.random_select_from_array(eligible_pops)

	-- no need to employ anyone in empty province
	if pop == nil then
		return
	end

	local exp_base = 2
	local exp_modifier = math.log(exp_base)

	-- cache prices:
	---@type table<trade_good_id, number>
	local prices = {}
	local function cache_price(trade_good)
		prices[trade_good] = economy_values.get_local_price(province, trade_good)
	end

	DATA.for_each_trade_good(cache_price)

	-- raw values
	---@type table<Building, number>
	local profits = {}
	---@type table<Building, number>
	local raw_profits = {}
	DATA.for_each_building_location_from_location(province, function (item)
		local building_id = DATA.building_location_get_building(item)
		local building = DATA.fatten_building(building_id)
		local building_type = DATA.building_get_type(building_id)
		local production_method = DATA.building_type_get_production_method(building_type)
		local workers = building_utils.amount_of_workers(building_id)
		local max_workers = method_utils.total_jobs(production_method)

		if workers >= max_workers then
			-- don"t hire
			profits[building_id] = nil
		else

			local profit = 0

			if workers > 0 then
				profit = building.income_mean + building.subsidy_last

				-- if profit is almost negative, eventually fire a worker
				if profit < 0.01 and love.math.random() < 0.25 then
					local _, pop_to_fire = tabb.random_select_from_set(DATA.filter_employment_from_building(building_id, ACCEPT_ALL))
					if pop_to_fire ~= INVALID_ID then
						province_utils.fire_pop(province, DATA.employment_get_worker(pop_to_fire))
					end
				end
			else
				local shortage_modifier = economy_values.estimate_shortage(
					province,
					production_method
				)
				profit =
					economy_values.projected_income(
						building_id,
						DATA.pop_get_race(pop),
						DATA.pop_get_female(pop),
						prices,
						shortage_modifier
					)
				profit = profit + building.subsidy
			end

			-- sanity check to avoid exp overflow
			raw_profits[building_id] = profit
			profits[building_id] = math.min(31, profit / 10) + love.math.random() / 10
		end


	end)

	-- softmax
	---@type number
	local sum_of_exponents = 0
	for _, profit in pairs(profits) do
		---@type number
		sum_of_exponents = sum_of_exponents + math.exp(exp_modifier * profit)
	end

	-- sample with softmax
	local dice = love.math.random()
	---@type Building?
	local hire_building = nil
	for building, profit in pairs(profits) do
		local softmax = math.exp(exp_modifier * profit) / sum_of_exponents

		-- if WORLD.player_character then
		-- 	if WORLD.player_character.province == province then
		-- 		print(building.type.name)
		-- 		print(softmax)
		-- 	end
		-- end

		if dice < softmax then
			hire_building = building
			break
		else
			dice = dice - softmax
		end
	end

	if hire_building == nil then
		return
	end

	-- Lastly, hire new workers
	local potential_job = province_utils.potential_job(province, hire_building)
	if potential_job == nil then
		return
	end

	-- if WORLD.player_character then
	-- 	if WORLD.player_character.province == province then
	-- 		print("roll building for employ: " .. hire_building.type.description)
	-- 		print("expected profit: " .. profits[hire_building])
	-- 		print("pop rolled: " .. pop.name)
	-- 		if pop.job then
	-- 			print("pop job: " .. pop.job.name)
	-- 		else
	-- 			print("pop not employed")
	-- 		end
	-- 		print("pop older than teen? " .. tostring(pop.age > pop.race.teen_age))
	-- 	end
	-- end

	if DATA.pop_get_age(pop) > DATA.race_get_teen_age(DATA.pop_get_race(pop)) then
		if DATA.pop_get_job(pop) then
			-- pop is not employed
			-- employ him
			province_utils.employ_pop(province, pop, hire_building)
		else
			-- pop is already employed
			-- consider changing his job
			local employment = DATA.get_employment_from_worker(pop)
			local employer = DATA.employment_get_building(employment)
			local last_income = DATA.building_get_last_income(employer)
			local workers = building_utils.amount_of_workers(employer)

			local pop_current_income = last_income / workers

			-- TODO: move to cultural value
			local likelihood_of_changing_job = 0.9

			local recalculater_hire_profit = raw_profits[hire_building]

			-- if WORLD.player_character then
			-- 	if WORLD.player_character.province == province then
			-- 		print("pop is already employed")
			-- 		print("pop\"s profit :" .. pop_current_income)
			-- 		print("hire profit :" .. recalculater_hire_profit)
			-- 	end
			-- end

			if (love.math.random() < likelihood_of_changing_job) and (recalculater_hire_profit > pop_current_income) then
				-- change job!
				province_utils.employ_pop(province, pop, hire_building)
			end
		end
	end
end

return emp
