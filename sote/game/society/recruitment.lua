local tabb = require "engine.table"
local rec = {}

---Runs recruitment logic on a province, matching pops to needed units
---@param province Province
function rec.run(province)
	--print("rec")
	-- select random warband
	local warband = tabb.random_select_from_set(province.warbands)

	if warband == nil then
		return
	end

	---@type number
	local total_salary = 0

	local pops_to_unregister = {}

	-- try to hire units
	for unit, target in pairs(warband.units_target) do
		if warband.units_current[unit] == nil then
			warband.units_current[unit] = 0
		end

		if warband.units_target[unit] == nil then
			warband.units_target[unit] = 0
		end

		local current = warband.units_current[unit]
		total_salary = total_salary + current * unit.upkeep

		local per_pop_salary_warband = warband:monthly_budget() / warband:size()

		if current < target then
			-- print('not enough soldiers')
			if love.math.random() < warband.morale then
				-- print('attempt to hire')
				for pop, _ in pairs(province.all_pops) do
					local pop_salary = 0

					if pop.employer then
						pop_salary = pop.employer.income_mean
					end

					if (not pop.drafted) and (pop.age > pop.race.teen_age) and (pop.age < pop.race.elder_age) then
						-- print("salary: ", pop_salary, per_pop_salary_warband)
						-- print("savings per month: ", warband:monthly_budget())
						-- print('required savings: ', total_salary + unit.upkeep)
						if (total_salary + unit.upkeep < warband:monthly_budget()) and (pop_salary < per_pop_salary_warband) then
							province:recruit(pop, unit, warband)
							---@type number
							total_salary = total_salary + unit.upkeep
							break
						end
					end
				end
			end
		elseif current > target then
			local pop_to_unregister = nil

			for pop, pop_unit in pairs(warband.units) do
				if pop_unit == unit then
					pop_to_unregister = pop
					break
				end
			end

			if pop_to_unregister then
				table.insert(pops_to_unregister, pop_to_unregister)
			end
		end
	end

	for _, pop in pairs(pops_to_unregister) do
		province:unregister_military_pop(pop)
	end

	if total_salary > warband:monthly_budget() then
		--- Warriors see that your warband is too poor, they are leaving
		--- Select random unit weighted with units amounts

		---@type UnitType
		local unit = tabb.random_select(warband.units_current)

		local pop_to_unregister = nil

		for pop, pop_unit in pairs(warband.units) do
			if pop_unit == unit then
				pop_to_unregister = pop
				break
			end
		end

		if pop_to_unregister ~= nil then
			province:unregister_military_pop(pop_to_unregister)
		end
	end

	--print("done")
end

return rec
