local tile = require "game.entities.tile"
local re = {}

function re.run_fast()
	DATA.for_each_tile(function (t)
		local elevation = DATA.tile_get_elevation(t)
		local slope = 0
		for n in tile.iter_neighbors(t) do
			local n_elevation = DATA.tile_get_elevation(n)
			slope = slope + math.abs(n_elevation - elevation)
		end
		slope = slope / 4
		DATA.tile_set_slope(t, slope)
	end)


	for _, b_id in pairs(RAWS_MANAGER.biomes_load_order) do
		DCON.apply_biome(b_id - 1)
	end

	---@type table<biome_id, number>
	local tiles_per_biome = {}
	DATA.for_each_tile(function (item)
		local biome = DATA.tile_get_biome(item)
		tiles_per_biome[biome] = (tiles_per_biome[biome] or 0) + 1
	end)

	for _, b_id in pairs(RAWS_MANAGER.biomes_load_order) do
		print(DATA.biome_get_name(b_id) .. ";" .. tostring(tiles_per_biome[b_id] or 0))
	end
end

function re.run()
	DATA.for_each_tile(function (t)
		local elevation = DATA.tile_get_elevation(t)
		local slope = 0
		for n in tile.iter_neighbors(t) do
			local n_elevation = DATA.tile_get_elevation(n)
			slope = slope + math.abs(n_elevation - elevation)
		end
		slope = slope / 4
		DATA.tile_set_slope(t, slope)
	end)

	DATA.for_each_tile(function (t)
		local elevation = DATA.tile_get_elevation(t)

		local slope = 0
		for n in tile.iter_neighbors(t) do
			local n_elevation = DATA.tile_get_elevation(n)
			slope = slope + math.abs(n_elevation - elevation)
		end
		slope = slope / 4

		local is_land = DATA.tile_get_is_land(t)
		local has_marsh = DATA.tile_get_has_marsh(t)
		local ice = DATA.tile_get_ice(t)

		local sand = DATA.tile_get_sand(t)
		local clay = DATA.tile_get_clay(t)
		local silt = DATA.tile_get_silt(t)

		local grass = DATA.tile_get_grass(t)
		local shrub = DATA.tile_get_shrub(t)
		local broadleaf = DATA.tile_get_broadleaf(t)
		local conifer = DATA.tile_get_conifer(t)

		for _, b_id in pairs(RAWS_MANAGER.biomes_load_order) do
			local b = DATA.fatten_biome(b_id)

			if slope < b.minimum_slope or slope > b.maximum_slope then
				goto continue
			end

			if b.aquatic == is_land then
				goto continue
			end
			if b.marsh ~= has_marsh then
				goto continue
			end
			if b.icy ~= (ice > 0.001) then
				goto continue
			end
			if elevation < b.minimum_elevation or elevation > b.maximum_elevation then
				goto continue
			end
			-- climate checks
			local t_ja = DATA.tile_get_january_temperature(t)
			local t_ju = DATA.tile_get_july_temperature(t)
			local r_ja = DATA.tile_get_january_rain(t)
			local r_ju = DATA.tile_get_july_rain(t)

			local rain = (r_ja + r_ju) / 2
			if rain < b.minimum_rain or rain > b.maximum_rain then
				goto continue
			end
			--local tile_perm =
			local tile_perm = tile.soil_permeability(t)
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
			local soil_depth = tile.soil_depth(t)
			if soil_depth < b.minimum_soil_depth or soil_depth > b.maximum_soil_depth then
				goto continue
			end
			local richness = DATA.tile_get_soil_minerals(t)
			if richness < b.minimum_soil_richness or richness > b.maximum_soil_richness then
				goto continue
			end
			if sand < b.minimum_sand or sand > b.maximum_sand then
				goto continue
			end
			if clay < b.minimum_clay or clay > b.maximum_clay then
				goto continue
			end
			if silt < b.minimum_silt or silt > b.maximum_silt then
				goto continue
			end
			-- vegetation based checks
			local trees = broadleaf + conifer
			local dead_land = 1 - broadleaf - conifer - shrub - grass
			local conifer_frac = 0.5
			if trees > 0 then
				conifer_frac = conifer / trees
			end
			if shrub < b.minimum_shrubs or shrub > b.maximum_shrubs then
				goto continue
			end
			if grass < b.minimum_grass or grass > b.maximum_grass then
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
			DATA.tile_set_biome(t, b_id)

			::continue::
		end
	end)
end

return re
