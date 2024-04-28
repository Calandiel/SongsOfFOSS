local tabb = require "engine.table"
local emp = {}

local economy_values = require "game.raws.values.economical"

---Employs pops in the province.
---@param province Province
function emp.run(province)
	-- Sample random pop and try to employ it
	---@type table<POP, POP>
	local eligible_pops = tabb.filter(province.all_pops, function (pop)
		return (pop.age > pop.race.teen_age) and (pop.forage_ratio < 1)
	end)

	local pop = tabb.random_select_from_set(eligible_pops)

	-- no need to employ anyone in empty province
	if pop == nil then
		return
	end

	local exp_base = 2
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
	---@type table<Building, number>
	local raw_profits = {}
	for _, building in pairs(province.buildings) do
		local num_of_workers = tabb.size(building.workers)

		if num_of_workers >= building.type.production_method:total_jobs() then
			-- don"t hire
			profits[building] = nil
		else

			local profit = 0

			if num_of_workers > 0 then
				profit = building.income_mean + building.subsidy_last

				-- if profit is almost negative, eventually fire a worker
				if profit < 0.05 and love.math.random() < 0.9 then
					local pop = tabb.random_select_from_set(building.workers)
					if pop then
						province:fire_pop(pop)
					end
				end
			else
				local shortage_modifier = economy_values.estimate_shortage(
					province,
					building.type.production_method
				)
				profit =
					economy_values.projected_income(
						building,
						pop.race,
						pop.female,
						prices,
						shortage_modifier
					)
				profit = profit + building.subsidy
			end
			-- sanity check to avoid exp overflow
			raw_profits[building] = profit
			profits[building] = math.min(31, profit / 10) + love.math.random() / 10
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

	if pop.age > pop.race.teen_age then
		if pop.job == nil then
			-- pop is not employed
			-- employ him
			province:employ_pop(pop, hire_building)
		else
			-- pop is already employed
			-- consider changing his job
			local pop_current_income = pop.employer.last_income / tabb.size(pop.employer.workers)

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
				province:fire_pop(pop)
				province:employ_pop(pop, hire_building)
			end
		end
	end
end

return emp
