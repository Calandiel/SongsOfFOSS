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

-- strange one, it has a bunch of code that does nothing, so the initial intention is unclear
-- it is named 'initial ice depth' but it doesn't seem to be used for that?
function oi.calculate_initial_ice_depth(ti, ice_flow, distance_from_edge)
	-- local ice_depth = (ice_flow[ti] * distance_from_edge[ti]) / 40
	-- ice_depth = math.min(ice_depth, 250)
	-- local ice_depth_debug = -- ice_depth converted to byte

	ice_flow[ti] = ice_flow[ti] * distance_from_edge[ti] / 4
end

-- odd stuff in the original impl, port below is commented out: total_ice_movement is initialized to 1, meaning that even if there is no ice movement
-- in the neighbors, the material will still be pushed to the melt zones, by the same amount as the ice moved, for each neighbor that qualifies
---@param gti integer glacial seed tile index
function oi.move_material(world, gti, distance_from_edge, ice_moved, texture_material, material_richness, already_added, use_original)
	if use_original then
		local total_ice_movement = 1

		world:for_each_neighbor(gti, function(nti)
			local is_closer_to_edge = distance_from_edge[nti] < distance_from_edge[gti]
			if not is_closer_to_edge then return end
			total_ice_movement = total_ice_movement + ice_moved[nti]
		end)

		world:for_each_neighbor(gti, function(nti)
			local is_closer_to_edge = distance_from_edge[nti] < distance_from_edge[gti]
			if not is_closer_to_edge then return end

			texture_material[nti] = texture_material[nti] + texture_material[gti] * (ice_moved[gti] / total_ice_movement)
			material_richness[nti] = material_richness[nti] + material_richness[gti] * (ice_moved[gti] / total_ice_movement)

			already_added[nti] = true
		end)

		if total_ice_movement > 0 then
			texture_material[gti] = 0
			material_richness[gti] = 0
		end
	else
		local total_ice_movement = 0

		world:for_each_neighbor(gti, function(nti)
			local is_closer_to_edge = distance_from_edge[nti] < distance_from_edge[gti]
			if not is_closer_to_edge then return end
			total_ice_movement = total_ice_movement + ice_moved[nti]
		end)

		if total_ice_movement == 0 then return end

		world:for_each_neighbor(gti, function(nti)
			local is_closer_to_edge = distance_from_edge[nti] < distance_from_edge[gti]
			if not is_closer_to_edge then return end

			texture_material[nti] = texture_material[nti] + texture_material[gti] * (ice_moved[gti] / total_ice_movement)
			material_richness[nti] = material_richness[nti] + material_richness[gti] * (ice_moved[gti] / total_ice_movement)

			-- the whole logic around 'already_added' seems to be a bit off, since its primary usage is in the code that builds melt provinces
			-- and there is a lot of logic around adding a new tile to a melt province; so, I would rather skip the assignment below
			-- even though the original code starts building the melt provinces with quite a bit of tiles "already added"
			-- already_added[nti] = true
		end)

		texture_material[gti] = 0
		material_richness[gti] = 0
	end
end

-- original code removes the already_added flag for all glacial seeds without discrimination, which seems odd
-- I will alter the original, by removing it only for the seeds that are not eligible for melting
function oi.remove_already_added(ti, already_added, is_eligible_melt_tile, use_original)
	if use_original then
		already_added[ti] = nil
	elseif not is_eligible_melt_tile then
		already_added[ti] = nil
	end
end

-- the original code computes the number of expansions based on total material,
-- then proceeds to change the total material based on whether it's processing an ice age or not
-- so, the question is whether the total material should be altered before or after calculating the no of expansions
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

return oi