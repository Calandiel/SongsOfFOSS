local tabb = require "engine.table"
local rec = {}

local warband_utils = require "game.entities.warband"
local demography_effects = require "game.raws.effects.demography"

---Runs recruitment logic on a province, matching pops to needed units
---@param province Province
function rec.run(province)
	---#logging LOGS:write("province recruit " .. tostring(province).."\n")
	---#logging LOGS:flush()

	-- province:validate_population()
	local warbands = DATA.filter_warband_location_from_location(province, ACCEPT_ALL)

	--print("rec")
	-- select random warband
	local warband_location = tabb.random_select_from_set(warbands)

	if warband_location == nil then
		return
	end

	local warband = DATA.warband_location_get_warband(warband_location)
	local monthly_budget = warband_utils.monthly_budget(warband)
	local warband_size = warband_utils.size(warband)

	---@type number
	local total_salary = 0

	---@type pop_id[]
	local pops_to_unregister = {}


	-- try to hire units
	DATA.for_each_unit_type(function (item)
		local target = DATA.warband_get_units_target(warband, item)
		local current = DATA.warband_get_units_current(warband, item)
		local unit = DATA.fatten_unit_type(item)
		total_salary = total_salary + current * unit.upkeep
		local per_pop_salary_warband = monthly_budget / (warband_utils.target_size(warband) + 1)
		if current < target then
			DATA.for_each_pop_location_from_location(province, function (pop_location)
				local pop = DATA.pop_location_get_pop(pop_location)
				local race = DATA.pop_get_race(pop)
				local age = DATA.pop_get_age(pop)
				local teen_age = DATA.race_get_teen_age(race)
				local elder_age = DATA.race_get_elder_age(race)

				if (age < teen_age) then
					return
				end

				if (age > elder_age) then
					return
				end

				local employment = DATA.get_employment_from_worker(pop)
				local pop_salary = DATA.pop_get_savings(pop) / 12

				if DATA.employment_get_building(employment) ~= INVALID_ID then
					local last_income = DATA.employment_get_worker_income(employment)
					pop_salary = pop_salary + last_income
				end

				local unit_of_warband = DATA.get_warband_unit_from_unit(pop)

				if (unit_of_warband ~= INVALID_ID) then
					return
				end

				-- print("salary: ", pop_salary, per_pop_salary_warband)
				-- print("savings per month: ", warband:monthly_budget())
				-- print('required savings: ', total_salary + unit.upkeep)
				if (total_salary + unit.upkeep < monthly_budget) and (pop_salary < per_pop_salary_warband) then
					demography_effects.recruit(pop, item, warband)
					---@type number
					total_salary = total_salary + unit.upkeep
					return
				end
			end)
		elseif current > target then
			local pop_to_unregister = INVALID_ID

			DATA.for_each_warband_unit_from_warband(warband, function (warband_unit)
				local unit_type = DATA.warband_unit_get_type(warband_unit)
				if unit_type == item then
					pop_to_unregister = DATA.warband_unit_get_unit(warband_unit)
					return
				end
			end)

			if pop_to_unregister ~= INVALID_ID then
				table.insert(pops_to_unregister, pop_to_unregister)
			end

			---@type number
			total_salary = total_salary - unit.upkeep
		end
	end)

	for _, pop in pairs(pops_to_unregister) do
		warband_utils.unregister_military(pop)
	end

	if total_salary > monthly_budget then
		--- Warriors see that your warband is too poor, they are leaving
		--- Select random unit weighted with units amounts x salary

		---@type table<unit_type_id, number>
		local weighted_units = {}

		DATA.for_each_unit_type(function (item)
			local current = DATA.warband_get_units_current(warband, item)
			local unit = DATA.fatten_unit_type(item)

			weighted_units[item] = current * unit.upkeep
		end)

		---@type unit_type_id
		local unit = tabb.random_select(weighted_units)

		local pop_to_unregister = INVALID_ID

		DATA.for_each_warband_unit_from_warband(warband, function (warband_unit)
			local unit_type = DATA.warband_unit_get_type(warband_unit)
			if unit_type == unit then
				pop_to_unregister = DATA.warband_unit_get_unit(warband_unit)
				return
			end
		end)

		if pop_to_unregister ~= INVALID_ID then
			warband_utils.unregister_military(pop_to_unregister)
		end
	end

	--print("done")
end

return rec
