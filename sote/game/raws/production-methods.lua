
local dbm = require "game.economy.diet-breadth-model"
local tile_utils = require "game.entities.tile"

local ProductionMethod = {}

---@class production_method_id_data_blob_definition_extended : production_method_id_data_blob_definition
---@field inputs table<use_case_id, number>
---@field outputs table<trade_good_id, number>
---@field jobs table<jobtype_id, number>

---Creates a new production method
---@param o production_method_id_data_blob_definition_extended
---@return production_method_id
function ProductionMethod:new(o)
	if RAWS_MANAGER.do_logging then
		print("ProductionMethod: " .. o.name)
	end

	local new_id = DATA.create_production_method()
	DATA.setup_production_method(new_id, o)

	local job_index = 0
	DATA.for_each_job(function (item)
		if o.jobs[item] == nil then
			return
		end
		DATA.production_method_set_jobs_job(new_id, job_index, item)
		DATA.production_method_set_jobs_amount(new_id, job_index, o.jobs[item])
		job_index = job_index + 1
	end)

	local input_index = 0
	for use_case, amount in pairs(o.inputs) do
		DATA.production_method_set_inputs_amount(new_id, input_index, amount)
		DATA.production_method_set_inputs_use(new_id, input_index, use_case)
		input_index = input_index + 1
	end

	local output_index = 0
	for good, amount in pairs(o.outputs) do
		DATA.production_method_set_outputs_amount(new_id, input_index, amount)
		DATA.production_method_set_outputs_good(new_id, input_index, good)
		output_index = output_index + 1
	end

	if RAWS_MANAGER.production_methods_by_name[o.name] ~= nil then
		local msg = "Failed to load a production method (" .. tostring(o.name) .. ")"
		print(msg)
		error(msg)
	end
	RAWS_MANAGER.production_methods_by_name[o.name] = new_id
	return new_id
end

---@param method production_method_id
---@return number
function ProductionMethod.total_jobs(method)
	local amount = 0
	for i = 0, MAX_SIZE_ARRAYS_PRODUCTION_METHOD do
		local job = DATA.production_method_get_jobs_job(method, i)
		if job == INVALID_ID then
			break
		end
		local job_amount = DATA.production_method_get_jobs_amount(method, i)
		amount = amount + job_amount
	end
	return amount
end

---@param method production_method_id
---@param province province_id
---@return number
function ProductionMethod.get_efficiency(method, province)
	local fat_method = DATA.fatten_production_method(method)
	local fat_province = DATA.fatten_province(province)

	-- Return 0 efficiency for water provinces
	if not DATA.tile_get_is_land(fat_province.center) then
		return 0
	end

	local total_efficiency = 0
	for _, tile_id in pairs(DATA.get_tile_province_membership_from_province(province)) do
		local crop_yield = 1
		if fat_method.crop then
			local jan_rain, jan_temp, jul_rain, jul_temp = tile_utils.get_climate_data(tile_id)
			local t = (jan_temp + jul_temp) / 2
			local r = (jan_rain + jul_rain) / 2
			if r > fat_method.rainfall_ideal_min and r < fat_method.rainfall_ideal_max then
				-- Ideal conditions for growing this plant!
			elseif r < fat_method.rainfall_ideal_min then
				local d = (r - fat_method.rainfall_extreme_min) / (fat_method.rainfall_ideal_min - fat_method.rainfall_extreme_min)
				crop_yield = crop_yield * math.max(0, d)
			elseif r > fat_method.rainfall_ideal_max then
				local d = (r - fat_method.rainfall_ideal_max) /
					(fat_method.rainfall_extreme_max - fat_method.rainfall_ideal_max)
				d = 1 - d
				crop_yield = crop_yield * math.max(0, d)
			end
			if t > fat_method.temperature_ideal_min and r < fat_method.temperature_ideal_max then
				-- Ideal conditions for growing this plant!
			elseif t < fat_method.temperature_ideal_min then
				local d = (t - fat_method.temperature_extreme_min) /
					(fat_method.temperature_ideal_min - fat_method.temperature_extreme_min)
				crop_yield = crop_yield * math.max(0, d)
			elseif t > fat_method.temperature_ideal_max then
				local d = (t - fat_method.temperature_ideal_max) /
					(fat_method.temperature_extreme_max - fat_method.temperature_ideal_max)
				d = 1 - d
				crop_yield = crop_yield * math.max(0, d)
			end
		end
		local soil_efficiency = 1
		if fat_method.clay_ideal_min > 0 or fat_method.clay_ideal_max < 1 then
			local clay = DATA.tile_get_clay(tile_id)
			if clay > fat_method.clay_ideal_min and clay < fat_method.clay_ideal_max then
				-- Ideal conditions!
			elseif clay < fat_method.clay_ideal_min then
				local d = (clay - fat_method.clay_extreme_min) / (fat_method.clay_ideal_min - fat_method.clay_extreme_min)
				soil_efficiency = soil_efficiency * math.max(0, d)
			elseif clay > fat_method.clay_ideal_max then
				local d = (clay - fat_method.clay_ideal_max) /
					(fat_method.clay_extreme_max - fat_method.clay_ideal_max)
				d = 1 - d
				soil_efficiency = soil_efficiency * math.max(0, d)
			end
		end
		total_efficiency = total_efficiency + crop_yield * soil_efficiency
	end
	local nature_yield = 1
	if fat_method.foraging then
		nature_yield = nature_yield * dbm.foraging_efficiency(fat_province.foragers_limit, fat_province.foragers)
	end
	if fat_method.hydration then
		nature_yield = nature_yield * dbm.foraging_efficiency(fat_province.hydration, fat_province.foragers_water)
	end
	if fat_method.forest_dependence > 0 then
		local amount_of_wood = DATA.province_get_foragers_targets_amount(province, FORAGE_RESOURCE.WOOD)
		nature_yield = nature_yield * (amount_of_wood / fat_province.size) * fat_method.forest_dependence
	end
	if fat_method.nature_yield_dependence > 0 then
		nature_yield = nature_yield * math.max(0, fat_province.foragers_limit / fat_province.size) * fat_method.nature_yield_dependence
	end
	return total_efficiency * nature_yield / fat_province.size
end

return ProductionMethod
