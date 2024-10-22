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

return wgu