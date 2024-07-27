local oi = {}

local function set_debug(world, ti, r, g, b)
	world.debug_r[ti] = r
	world.debug_g[ti] = g
	world.debug_b[ti] = b
end

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

-- strange one, it has a bunch of code that does nothing, so the initial intention is unclear
-- it is named 'initial ice depth' but it doesn't seem to be used for that?
-- tmp_float_2 -> ice_flow
-- tmp_int_1 -> distance_from_edge
function oi.calculate_initial_ice_depth(world, ti)
	-- local ice_depth = (world.tmp_float_2[ti] * world.tmp_int_1[ti]) / 40
	-- ice_depth = math.min(ice_depth, 250)
	-- local ice_depth_debug = -- ice_depth converted to byte

	world.tmp_float_2[ti] = world.tmp_float_2[ti] * world.tmp_int_1[ti] / 4
end

return oi