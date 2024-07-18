local oi = {}

-- strange way to average
function oi.avg_temp(temp_jan, temp_jul)
	return temp_jan + temp_jul
end

-- only july rainfall is divided by 80? Calandiel suggested to just average jan and jul rainfall
function oi.rainfall_contrib_to_ice_depth(jan_rainfall, jul_rainfall)
	return jan_rainfall + (jul_rainfall / 80)
end

return oi