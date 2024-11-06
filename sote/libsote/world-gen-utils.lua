local wgu = {}

---@param tile_jan_temp number
---@param tile_jul_temp number
---@return number
function wgu.winter_depression_factor(tile_jan_temp, tile_jul_temp)
	local winter_temp = math.min(tile_jan_temp, tile_jul_temp);
	local summer_temp = math.max(tile_jan_temp, tile_jul_temp);
	local winter_depression_factor = 0;

	if winter_temp < 0 and (math.abs(winter_temp) > math.abs(summer_temp)) then
		winter_depression_factor = (math.abs(winter_temp) - math.abs(summer_temp)) * 2;
	end

	return winter_depression_factor;
end

---@param tile_sand number
---@param tile_silt number
---@param tile_clay number
---@return number
function wgu.permiation_calc(tile_sand, tile_silt, tile_clay)
	--* Sand Ceiling = 0.15. Any sand over 0.15 reduces water retention.
	--* Sand Water to subtract = 2. Total amount that can be subtracted from maximum water due to excess sand.
	--* Silt Ceiling = 0.85. Any silt over 0.85 reduces water retention.
	--* Silt Water to subtract = 0.25. Total amount that can be subtracted from maximum water due to excess silt.
	--* Clay Ceiling = 0.2. Any clay over 0.2 reduces water retention.
	--* Clay Water to subtract = 1.25. Total amount that can be subtracted from maximum water due to excess clay.

	local tile_perm = 2.5 --* Maximum water retained per unit

	local total_material = tile_sand + tile_silt + tile_clay
	local sand_percent = tile_sand / total_material
	local silt_percent = tile_silt / total_material
	local clay_percent = tile_clay / total_material

	if sand_percent > 0.15 then
		tile_perm = tile_perm - ((sand_percent - 0.15) / (1 - 0.15)) * 2
	end
	if silt_percent > 0.85 then
		tile_perm = tile_perm - ((silt_percent - 0.85) / (1 - 0.85)) * 0.25
	end
	if clay_percent > 0.2 then
		tile_perm = tile_perm - ((clay_percent - 0.2) / (1 - 0.2)) * 1.25
	end

	return tile_perm / 2.5
end

---@param tile_sand number
---@param tile_silt number
---@param tile_clay number
---@return number
function wgu.permiation_calc_dune(tile_sand, tile_silt, tile_clay)
	local tile_perm = 1

	local total_material = tile_sand + tile_silt + tile_clay
	local sand_percent = 100 * tile_sand / total_material
	local silt_percent = 100 * tile_silt / total_material
	local clay_percent = 100 * tile_clay / total_material

	if silt_percent > 50 then tile_perm = tile_perm * 0.9 end
	if silt_percent > 70 then tile_perm = tile_perm * 0.9 end
	if silt_percent > 80 then tile_perm = tile_perm * 0.9 end
	if silt_percent > 90 then tile_perm = tile_perm * 0.9 end

	if sand_percent > 50 then tile_perm = tile_perm * 0.7 end
	if sand_percent > 65 then tile_perm = tile_perm * 0.7 end
	if sand_percent > 80 then tile_perm = tile_perm * 0.7 end
	if sand_percent > 90 then tile_perm = tile_perm * 0.7 end

	if clay_percent > 50 then tile_perm = tile_perm * 0.8 end
	if clay_percent > 65 then tile_perm = tile_perm * 0.8 end
	if clay_percent > 80 then tile_perm = tile_perm * 0.8 end
	if clay_percent > 90 then tile_perm = tile_perm * 0.8 end

	if silt_percent < 30 then tile_perm = tile_perm * 0.9 end
	if silt_percent < 20 then tile_perm = tile_perm * 0.9 end
	if silt_percent < 10 then tile_perm = tile_perm * 0.9 end

	return tile_perm
end

---@param world table
---@param ti number
function wgu.true_water_for_tile(world, ti)
	local water_movement_contribution = math.max(0, math.sqrt(world.water_movement[ti]) - 10)
	local true_water_calc = world.jan_rainfall[ti] + world.jul_rainfall[ti] + water_movement_contribution
	local wind_factor = world.jan_wind_speed[ti] --*+ world.jul_wind_speed[ti]
	wind_factor = math.min(25, wind_factor)
	wind_factor = (1 - wind_factor / 25) * 0.65 + 0.35
	local permeability = wgu.permiation_calc(world.sand[ti], world.silt[ti], world.clay[ti])
	return true_water_calc * wind_factor * permeability
end

---@param world table
---@param ti number
function wgu.temperature_factor_for_tile(world, ti)
	if world.ice[ti] > 0 then return 0 end

	local temp_factor = (world.jan_temperature[ti] + world.jul_temperature[ti]) / 2
	if temp_factor > 15 then
		temp_factor = 1
	else
		temp_factor = math.max(0, temp_factor / 15)
	end

	return temp_factor + 0.1
end

return wgu