local oi = {}

-- local function set_debug(channel, world, ti, r, g, b, a)
-- 	world:set_debug_rgba(channel, ti, r, g, b, a or 255)
-- end

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
function oi.calculate_initial_ice_depth(ti, ice_flow, distance_from_edge)
	-- local ice_depth = (ice_flow[ti] * distance_from_edge[ti]) / 40
	-- ice_depth = math.min(ice_depth, 250)
	-- local ice_depth_debug = -- ice_depth converted to byte

	ice_flow[ti] = ice_flow[ti] * distance_from_edge[ti] / 4
end

------------------------------------------------------------------------------------------------------------------------------------------------------

-- odd stuff in the original impl, port below is commented out: total_ice_movement is initialized to 1, meaning that even if there is no ice movement
-- in the neighbors, the material will still be pushed to the melt zones, by the same amount as the ice moved, for each neighbor that qualifies
-- This one does not seem to have a significant impact on silt storage
function oi.move_material(world, ti, distance_from_edge, ice_moved, texture_material, material_richness, already_added, use_original)
	if use_original then
		local total_ice_movement = 1

		world:for_each_neighbor(ti, function(nti)
			local is_closer_to_edge = distance_from_edge[nti] < distance_from_edge[ti]
			if not is_closer_to_edge then return end
			total_ice_movement = total_ice_movement + ice_moved[nti]
		end)

		world:for_each_neighbor(ti, function(nti)
			local is_closer_to_edge = distance_from_edge[nti] < distance_from_edge[ti]
			if not is_closer_to_edge then return end

			texture_material[nti] = texture_material[nti] + texture_material[ti] * (ice_moved[ti] / total_ice_movement)
			material_richness[nti] = material_richness[nti] + material_richness[ti] * (ice_moved[ti] / total_ice_movement)

			already_added[nti] = true
		end)

		if total_ice_movement > 0 then
			texture_material[ti] = 0
			material_richness[ti] = 0
		end
	else
		local total_ice_movement = 0

		world:for_each_neighbor(ti, function(nti)
			local is_closer_to_edge = distance_from_edge[nti] < distance_from_edge[ti]
			if not is_closer_to_edge then return end
			total_ice_movement = total_ice_movement + ice_moved[nti]
		end)

		if total_ice_movement == 0 then return end

		world:for_each_neighbor(ti, function(nti)
			local is_closer_to_edge = distance_from_edge[nti] < distance_from_edge[ti]
			if not is_closer_to_edge then return end

			texture_material[nti] = texture_material[nti] + texture_material[ti] * (ice_moved[ti] / total_ice_movement)
			material_richness[nti] = material_richness[nti] + material_richness[ti] * (ice_moved[ti] / total_ice_movement)

			already_added[nti] = true
		end)

		texture_material[ti] = 0
		material_richness[ti] = 0
	end
end

-- original code removes the already_added flag for all glacial seeds without discrimination, which seems odd
-- Removing it for all tiles that are not eligible for melt seems to have a significant impact on silt storage
function oi.remove_already_added(ti, already_added, is_eligible_melt_tile, use_original)
	if use_original then
		already_added[ti] = false
	elseif not is_eligible_melt_tile then
		already_added[ti] = false
	end
end

-- using the alternative version of these 2 open issues, already_added retains a bit more tiles than the original (countours as opposed to a few tiles here and there)
-- which seems to have a significant impact on silt storage
------------------------------------------------------------------------------------------------------------------------------------------------------

-- the original code computes the number of expansions based on total material,
-- then proceeds to boost the total material based on whether it's processing an ice age or not
-- so, the question is whether the total material should be altered before or after calculating the no of expansions
-- Has some impact on silt storage for non ice age
function oi.adjust_material_for_province_size_before(total_material, is_ice_age, province_size, use_original)
	if use_original then
		return total_material
	end

	if not is_ice_age then
		return total_material + (province_size * 2000) + 10000 --* Game age gets a boost
	end

	return total_material
end
function oi.adjust_material_for_province_size_after(total_material, is_ice_age, province_size, use_original)
	if not use_original then
		return total_material
	end

	if not is_ice_age then
		return total_material + (province_size * 2000) + 10000 --* Game age gets a boost
	end

	return total_material
end

-- original temp factor is using some temperature bands table:
--* Less than -20 = 0 
--* -20 to -10 = 0.1
--* -10 to 0 = 0.5  
--* 0 to 10 = 0.75
--* 10 to 20 = 1
--* 20 - 30 = 1.5
--* 30 - 40 = 1.25
--* 40 - 50 = 1
--* 50 - 60 = 0.5
--* 60 - 70 = 0
-- and returns 0 for extreme band and anything outside, which seems a bit drastic, maybe it's worth revisiting at some point
function oi.calculate_temp_factor_for_retention_mult(temp_jan, temp_jul)
	local average_temp = oi.avg_temp(temp_jan, temp_jul)

	if average_temp >= 70 then return 0 end
	if average_temp >= 60 then return (70 - average_temp) * 0.05 end
	if average_temp >= 50 then return (60 - average_temp) * 0.05 + 0.5 end
	if average_temp >= 40 then return (50 - average_temp) * 0.025 + 1 end
	if average_temp >= 30 then return (40 - average_temp) * 0.025 + 1.25 end
	if average_temp >= 20 then return (average_temp - 20) * 0.05 + 1 end
	if average_temp >= 10 then return (average_temp - 10) * 0.025 + 0.75 end
	if average_temp >= 0 then return average_temp * 0.025 + 0.5 end
	if average_temp >= -10 then return (average_temp + 10) * 0.04 + 0.1 end
	if average_temp >= -20 then return (average_temp + 20) * 0.01 end

	return 0
end

return oi