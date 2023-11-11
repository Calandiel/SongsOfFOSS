local tabb = require "engine.table"
local emp = {}

local economy_values = require "game.raws.values.economical"

---Employs pops in the province.
---@param province Province
function emp.run(province)
	-- Sample random pop and try to employ it
	local pop = tabb.random_select_from_set(province.all_pops)

	-- no need to employ anyone in empty province
	if pop == nil then
		return
	end

	local exp_base = 1.1
	local exp_modifier = math.log(exp_base)

	-- cache prices:
	---@type table<TradeGoodReference, number>
	local prices = {}
	for good_name, _ in pairs(RAWS_MANAGER.trade_goods_by_name) do
		prices[good_name] = economy_values.get_local_price(province, good_name)
	end

	-- raw values
	---@type table<Building, number>
	local profits = {}
	for _, building in pairs(province.buildings) do
		local num_of_workers = tabb.size(building.workers)
		local profit = 0
		if num_of_workers > 0 then
			profit = building.income_mean
		else
			profit =
				economy_values.projected_income(
					building,
					pop.race,
					pop.female,
					prices,
					1,
					false)
		end

		-- sanity check to avoid exp overflow
		profits[building] = math.min(100, profit) + love.math.random()

		if num_of_workers >= building.type.production_method:total_jobs() then
			-- don"t hire
			profits[building] = nil
		end

		-- if profit is almost negative, eventually fire a worker
		if profit < 0.01 and love.math.random() < 0.05 then
			local pop = tabb.random_select_from_set(building.workers)
			if pop then
				province:fire_pop(pop)
			end
		end
	end

	-- softmax
	---@type number
	local sum_of_exponents = 0
	for _, profit in pairs(profits) do
		---@type number
		sum_of_exponents = sum_of_exponents + math.exp(exp_modifier * profit)
	end

	-- sample with softmax
	local dice = love.math.random()
	local hire_building = nil
	for building, profit in pairs(profits) do
		local softmax = math.exp(exp_modifier * profit) / sum_of_exponents
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
	local potential_job = province:potential_job(hire_building)
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

	if not pop.drafted and pop.age > pop.race.teen_age then
		if pop.job == nil then
			-- pop is not employed
			-- employ him
			province:employ_pop(pop, hire_building)
		else
			-- pop is already employed
			-- consider changing his job
			local pop_current_income = pop.employer.last_income / tabb.size(pop.employer.workers)

			-- TODO: move to cultural value
			local likelihood_of_changing_job = 0.05

			local recalculater_hire_profit = economy_values.projected_income(
				hire_building,
				pop.race,
				pop.female,
				prices,
				1,
				false
			)

			-- if WORLD.player_character then
			-- 	if WORLD.player_character.province == province then
			-- 		print("pop is already employed")
			-- 		print("pop\"s profit :" .. pop_current_income)
			-- 		print("hire profit :" .. recalculater_hire_profit)
			-- 	end
			-- end

			if (love.math.random() < likelihood_of_changing_job) and (recalculater_hire_profit > pop_current_income) then
				-- change job!
				province:fire_pop(pop)
				province:employ_pop(pop, hire_building)
			end
		end
	end


	-- destroy unused building
	---@type Building[]
	local to_destroy = {}
	for _, building in pairs(province.buildings) do
		if tabb.size(building.workers) == 0 then
			building.unused = building.unused + 1
		else
			building.unused = 0
		end

		if building.unused > 360 then
			table.insert(to_destroy, building)
		end
	end

	for _, building in pairs(to_destroy) do
		-- print(building.type.description .. " was destroyed due to being unused for a long time")
		EconomicEffects.destroy_building(building)
	end
end

return emp
