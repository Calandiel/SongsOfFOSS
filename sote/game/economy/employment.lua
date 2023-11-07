local tabb = require 'engine.table'
local emp = {}

local economy_values = require "game.raws.values.economical"

---Employs pops in the province.
---@param province Province
function emp.run(province)
	local human_race = RAWS_MANAGER.races_by_name["human"]

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
			profit = building.income_mean / num_of_workers
		else
			profit =
				economy_values.projected_income(
					building,
					human_race,
					prices,
					1,
					false)
		end
		profits[building] = profit + love.math.random()

		if num_of_workers >= building.type.production_method:total_jobs() then
			-- don't hire
			profits[building] = -1
		end

		-- if profit is negative, fire a worker
		if profit < 0 then
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
		sum_of_exponents = sum_of_exponents + math.exp(profit)
	end

	-- sample with softmax
	local dice = love.math.random()
	local hire_building = nil
	for building, profit in pairs(profits) do
		local softmax = math.exp(profit) / sum_of_exponents
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

	local hire_profit = profits[hire_building]

	-- Lastly, hire new workers
	local potential_job = province:potential_job(hire_building)
	if potential_job == nil then
		return
	end

	-- A worker is needed, try to hire some pop
	local pop = tabb.random_select_from_set(province.all_pops)
	if not pop.drafted and pop.age > pop.race.child_age then
		if pop.job == nil then
			-- pop is not employed
			-- employ him
			province:employ_pop(pop, hire_building)
		else
			-- pop is already employed
			-- consider changing his job
			local pop_current_income = pop.employer.last_income / tabb.size(pop.employer.workers)

			-- TODO: move to cultural value
			local likelihood_of_changing_job = 0.5

			local recalculater_hire_profit = economy_values.projected_income(
				hire_building,
				pop.race,
				prices,
				1,
				false
			)

			if (love.math.random() < likelihood_of_changing_job) and (recalculater_hire_profit > pop_current_income) then
				-- change job!
				province:fire_pop(pop)
				province:employ_pop(pop, hire_building)
			end
		end
	end
end

return emp
