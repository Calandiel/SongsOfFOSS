local oi = {}

-- strange way to average
function oi.avg_temp(temp_jan, temp_jul)
	return temp_jan + temp_jul
end

-- only july rainfall is divided by 80? Calandiel suggested to just average jan and jul rainfall
function oi.rainfall_contrib_to_ice_depth(jan_rainfall, jul_rainfall)
	return jan_rainfall + (jul_rainfall / 80)
end

-- the concept of "true elevation" seems to have various definitions throughout the original code
-- for example, for water tiles, it might look at waterbody's waterlevel and ice, while the version used in glacial formation simply returns 0
function oi.true_elevation(world, ti)
	return world.is_land[ti] and world.elevation[ti] or 0
end

return oi