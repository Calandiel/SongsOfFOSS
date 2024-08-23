local wgu = {}

--@param tile_jan_temp number
--@param tile_jul_temp number
--@return number
function wgu.winter_depression_factor(tile_jan_temp, tile_jul_temp)
	local winter_temp = math.min(tile_jan_temp, tile_jul_temp);
	local summer_temp = math.max(tile_jan_temp, tile_jul_temp);
	local winter_depression_factor = 0;

	if winter_temp < 0 and (math.abs(winter_temp) > math.abs(summer_temp)) then
		winter_depression_factor = (math.abs(winter_temp) - math.abs(summer_temp)) * 2;
	end

	return winter_depression_factor;
end

return wgu