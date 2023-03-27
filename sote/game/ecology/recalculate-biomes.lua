local re = {}

function re.run()

	for _, t in pairs(WORLD.tiles) do
		local slopeiness = 0
		for n in t:iter_neighbors() do
			slopeiness = slopeiness + math.abs(n.elevation - t.elevation)
		end
		slopeiness = slopeiness / 4

		for _, b in pairs(WORLD.biomes_load_order) do
			if slopeiness < b.minimum_slope or slopeiness > b.maximum_slope then
				goto continue
			end

			if b.aquatic ~= not t.is_land then
				goto continue
			end
			if b.marsh ~= t.has_marsh then
				goto continue
			end
			if b.icy ~= (t.ice > 0.001) then
				goto continue
			end
			if t.elevation < b.minimum_elevation or t.elevation > b.maximum_elevation then
				goto continue
			end

			-- climate checks
			local r_ja, t_ja, r_ju, t_ju = t:get_climate_data()
			local rain = (r_ja + r_ju) / 2
			if rain < b.minimum_rain or rain > b.maximum_rain then
				goto continue
			end

			--local tile_perm =
			local tile_perm = t:soil_permeability()
			local available_water = rain * 2 * tile_perm
			if available_water < b.minimum_available_water or available_water > b.maximum_available_water then
				goto continue
			end

			local temperature = (t_ja + t_ju) / 2
			if temperature < b.minimum_temperature or temperature > b.maximum_temperature then
				goto continue
			end

			local summer_temperature = math.max(t_ja, t_ju)
			local winter_temperature = math.min(t_ja, t_ju)
			if summer_temperature < b.minimum_summer_temperature or summer_temperature > b.maximum_summer_temperature then
				goto continue
			end
			if winter_temperature < b.minimum_winter_temperature or winter_temperature > b.maximum_winter_temperature then
				goto continue
			end

			-- soil checks
			local soil_depth = t:soil_depth()
			if soil_depth < b.minimum_soil_depth or soil_depth > b.maximum_soil_depth then
				goto continue
			end
			local richness = t.soil_minerals
			if richness < b.minimum_soil_richness or richness > b.maximum_soil_richness then
				goto continue
			end
			if t.sand < b.minimum_sand or t.sand > b.maximum_sand then
				goto continue
			end
			if t.clay < b.minimum_clay or t.clay > b.maximum_clay then
				goto continue
			end
			if t.silt < b.minimum_silt or t.silt > b.maximum_silt then
				goto continue
			end

			-- vegetation based checks
			local trees = t.broadleaf + t.conifer
			local dead_land = 1 - t.broadleaf - t.conifer - t.shrub - t.grass
			local conifer_frac = 0.5
			if trees > 0 then
				conifer_frac = t.conifer / trees
			end
			if t.shrub < b.minimum_shrubs or t.shrub > b.maximum_shrubs then
				goto continue
			end
			if t.grass < b.minimum_grass or t.grass > b.maximum_grass then
				goto continue
			end
			if trees < b.minimum_trees or trees > b.maximum_trees then
				goto continue
			end
			if dead_land < b.minimum_dead_land or dead_land > b.maximum_dead_land then
				goto continue
			end
			if conifer_frac < b.minimum_conifer_fraction or conifer_frac > b.maximum_conifer_fraction then
				goto continue
			end

			t.biome = b

			::continue::
		end
	end
end

return re
