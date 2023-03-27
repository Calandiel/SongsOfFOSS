local gen = {}
local sun = require "game.climate.sun"

--[[
SHRUB_COUNT = {}
GRASS_COUNT = {}
CONIFER_COUNT = {}
BROADLEAF_COUNT = {}

SUNLIGHT_VALUES = {}
WATER_IN_TILE_VALUES = {}
RAINFALL_IN_TILE = {}
PERMEABILITY_OF_TILE = {}
REAL_NUTRIENT_IN_TILE = {}
WATER_MULTIPLIER = {}
NUTRIENT_MULTIPLIER = {}
LIGHT_MULTIPLIER = {}
BROADLEAF_TEMP_MULTIPLIER = {}
SOIL_AERATION = {}
SOIL_ORGANICS = {}
AERATION_LOSS = {}

DEBUG_1 = {}
DEBUG_2 = {}
DEBUG_3 = {}
DEBUG_4 = {}

BASE_GROWTH = {} --grass_base_growth
WATER_MULTIPLIER = {} --grass_water_multiplier
NUTRIENT_MULTIPLIER = {} --grass_nutrient_multiplier
LIGHT_MULTIPLIER = {} --grass_light_multiplier
SOILDEPTH_MULTIPLIER = {} --grass_soildepth_multiplier
TEMP_MULTIPLIER = {} --grass_temp_multiplier
KILL = {} --grass_kill

--]]

function gen.run()
	print("Running plant generation...")
	-- Loop over all land tiles (there's also iter_all and iter_water)
	for _, tile in pairs(WORLD.tiles) do
		-- Do cool things here!

		-- "iter" refers to the ID of the tile, retrieved from the iterator over all land tiles
		-- Showing how to pull local data:
		local shrub_kill = 1
		local grass_kill = 1
		local conifer_kill = 1
		local broadleaf_kill = 1

		local permafrost_threshold = -20
		local soil_depth_tuner = 0.5 --- higher = higher soil depth penalty for thin soils

		local latitude, _ = tile:latlon()
		latitude = latitude / math.pi * 180
		--local waterflow = tile:average_waterflow()
		--local elevation = tile.elevation
		local ice = tile.ice

		local soil_depth = tile:soil_depth()
		local sand = tile.sand
		local clay = tile.clay
		local silt = tile.silt
		if soil_depth > 0 then
			sand = sand / soil_depth
			clay = clay / soil_depth
			silt = silt / soil_depth
		end
		--local organics = tile.soil_organics
		local minerals = tile.soil_minerals

		local jan_rain, jan_temp, jul_rain, jul_temp = tile:get_climate_data()
		--print(tostring(jan_temp) .. " , " .. tostring(jul_temp))
		local annual_average_temp = (jan_temp + jul_temp) / 2
		local adjusted_annual_temperature = annual_average_temp - permafrost_threshold
		local annual_rainfall = jan_rain + jul_rain
		local high_rain = 0
		local low_rain = 0
		if jan_rain > jul_rain then
			high_rain = jan_rain
			low_rain = jul_rain
		else
			high_rain = jul_rain
			low_rain = jan_rain
		end
		local seasonal_rain_extreme_factor = (low_rain / high_rain) ^ 1.75

		--- Any Ice on a Tile should kill plants ---
		if ice > 0 then
			shrub_kill = 0
			grass_kill = 0
			conifer_kill = 0
			broadleaf_kill = 0
		end


		--- Our objectives today:

		--- We want to calculate basesline organics that should be in tile based on specific variables.
		--- have seasonal water extremes influence broad leaf trees (and conifers to some extent?)

		--	if jan_rain >= jul_rain then


		local seasonal_water_shock = math.abs(jan_rain - jul_rain)

		local sunlight = sun.yearly_irradiance(latitude)

		local temperature_soil_factor = annual_average_temp
		if temperature_soil_factor > 30 then
			temperature_soil_factor = 30
		end
		if temperature_soil_factor <= permafrost_threshold then
			temperature_soil_factor = -20
		end
		temperature_soil_factor = temperature_soil_factor - permafrost_threshold
		--temperature_soil_factor = 1 / (1.5 ^ ((math.abs(temperature_soil_factor - 40) / 40)))
		temperature_soil_factor = temperature_soil_factor / 50
		local tilePerm = 2.5 -- Maximum water retained per unit
		if sand > 0.15 then
			tilePerm = tilePerm - (((sand - 0.15) / (1 - 0.15)) * 2)
		end
		if silt > 0.85 then
			tilePerm = tilePerm - (((silt - 0.85) / (1 - 0.85)) * 0.25)
		end
		if clay > 0.2 then
			tilePerm = tilePerm - (((clay - 0.2) / (1 - 0.2)) * 1.25)
		end
		tilePerm = tilePerm / 2.5

		local available_water = annual_rainfall * tilePerm

		local sand_max_loss = 2.0 --0.5
		local silt_max_loss = 0.5 --0.75
		local clay_max_loss = 2.0 --1

		local sand_max = 0.50
		local silt_max = 0.50
		local clay_max = 0.30

		local ideal_sand = 0.40
		local ideal_silt = 0.40
		local ideal_clay = 0.20

		local sand_aeration_loss = 0
		local silt_aeration_loss = 0
		local clay_aeration_loss = 0

		if sand >= sand_max then
			sand_aeration_loss = ((sand - sand_max) / sand_max) * sand_max_loss
		end
		if silt >= silt_max then
			silt_aeration_loss = ((silt - silt_max) / silt_max) * silt_max_loss
		end
		if sand >= sand_max then
			clay_aeration_loss = ((clay - clay_max) / clay_max) * clay_max_loss
		end

		local soil_organic_aeration_factor = 2 - sand_aeration_loss - silt_aeration_loss - clay_aeration_loss


		local soil_organic_water_factor = available_water / 60
		local soil_organic_sunlight_factor = sunlight - 2
		if soil_organic_sunlight_factor < 0 then
			soil_organic_sunlight_factor = 0
		else
			soil_organic_sunlight_factor = soil_organic_sunlight_factor / 0.75
		end


		local soil_organic_depth_factor = (soil_depth / 3) ^ 0.75


		local soil_organics = 0.015 * soil_organic_aeration_factor * soil_organic_sunlight_factor * soil_organic_water_factor *
			temperature_soil_factor * soil_organic_depth_factor

		local real_nutrient_factor = (minerals * temperature_soil_factor) + soil_organics

		local color = real_nutrient_factor * 500
		if color > 250 then
			color = 250
		end
		--SOIL_ORGANICS[tile] = soil_organics
		tile.grass = 0
		tile.shrub = 0
		tile.conifer = 0
		tile.broadleaf = 0

		--- Shrub Defines ---
		local shrub_base_growth = 30000
		local shrub_water_floor = 30
		local shrub_water_ceiling = 60

		local shrub_nutrient_floor = 0.15
		local shrub_nutrient_ceiling = 0.3

		local shrub_light_floor = 3.5
		local shrub_light_ceiling = 4.0

		local shrub_soildepth_ceiling = 3
		local shrub_soildepth_floor = 1

		local shrub_water_multiplier = 1
		local shrub_nutrient_multiplier = 1
		local shrub_light_multiplier = 1


		---- Water factor for shrubs ----
		if available_water <= shrub_water_ceiling then
			shrub_water_multiplier = shrub_water_multiplier * (available_water / shrub_water_floor)
		else
			shrub_water_multiplier = ((shrub_water_ceiling / shrub_water_floor) * (shrub_water_ceiling / available_water))
		end

		---- Nutrient factor for shrubs ----
		if real_nutrient_factor <= shrub_nutrient_ceiling then
			shrub_nutrient_multiplier = shrub_nutrient_multiplier * (real_nutrient_factor / shrub_nutrient_floor)
		else
			shrub_nutrient_multiplier = (
				(shrub_nutrient_ceiling / shrub_nutrient_floor) * (shrub_nutrient_ceiling / real_nutrient_factor))
		end

		--- Light Factor for Shrubs ---
		shrub_light_multiplier = sunlight / shrub_light_floor

		--- Soil Depth Factor for Shrubs ---

		if soil_depth <= shrub_soildepth_floor then
			shrub_soildepth_floor = (soil_depth / shrub_soildepth_floor) ^ (1.5 + soil_depth_tuner)
		end

		local shrubs = shrub_base_growth * shrub_water_multiplier * shrub_nutrient_multiplier * shrub_light_multiplier *
			shrub_soildepth_floor * shrub_kill

		-----------------------------------------------------------------------------

		--- Grass Defines ---
		local grass_base_growth = 40000
		local grass_water_floor = 40
		local grass_water_ceiling = 80

		local grass_nutrient_floor = 0.15
		local grass_nutrient_ceiling = 0.3

		local grass_light_floor = 3.0
		local grass_light_ceiling = 4.0

		local grass_soildepth_ceiling = 3
		local grass_soildepth_floor = 2

		local grass_preferred_temp = 10

		local grass_water_multiplier = 1
		local grass_nutrient_multiplier = 1
		local grass_light_multiplier = 1
		local grass_soildepth_multiplier = 1
		local grass_temp_multiplier = 1
		local grass_temp_multiplier = 2 ^ ((10 - math.abs(annual_average_temp - grass_preferred_temp)) / 10)


		---- Water factor for Grass ----
		if available_water <= grass_water_ceiling and available_water >= grass_water_floor then
			grass_water_multiplier = (available_water / grass_water_floor)
		elseif available_water >= grass_water_ceiling then
			grass_water_multiplier = (grass_water_ceiling / grass_water_floor) * ((available_water / grass_water_ceiling) ^ 0.5)
		else
			grass_water_multiplier = (available_water / grass_water_floor) ^ 1.5
		end

		---- Nutrient factor for Grass ----
		if real_nutrient_factor <= grass_nutrient_ceiling and real_nutrient_factor >= grass_nutrient_floor then
			grass_nutrient_multiplier = (real_nutrient_factor / grass_nutrient_floor)
		elseif real_nutrient_factor >= grass_nutrient_ceiling then
			grass_nutrient_multiplier = (grass_nutrient_ceiling / grass_nutrient_floor) *
				((real_nutrient_factor / grass_nutrient_ceiling) ^ 0.5)
		else
			grass_nutrient_multiplier = (real_nutrient_factor / grass_nutrient_floor) ^ 2
		end

		---- Light factor for Grass ----
		grass_light_multiplier = sunlight / grass_light_floor

		--- Grass Prefers Deep Soils ---
		if soil_depth >= 3 then
			grass_soildepth_multiplier = (soil_depth / grass_soildepth_ceiling)
		elseif soil_depth <= grass_soildepth_floor then
			grass_soildepth_multiplier = (soil_depth / grass_soildepth_floor) ^ (1.5 + soil_depth_tuner)
		end
		local grasses = grass_base_growth * grass_water_multiplier * grass_nutrient_multiplier * grass_light_multiplier *
			grass_soildepth_multiplier * grass_temp_multiplier * grass_kill


		--------------------------------------------------------------------------------------------

		--- Conifer Defines ---
		local conifer_base_growth = 30000
		local conifer_water_floor = 50
		local conifer_water_ceiling = 100

		local conifer_nutrient_floor = 0.05
		local conifer_nutrient_ceiling = 0.10

		local conifer_light_floor = 2.0
		local conifer_light_ceiling = 3.5

		local conifer_soildepth_ceiling = 3
		local conifer_soildepth_floor = 1

		local conifer_preferred_temp_floor = 0
		local conifer_preferred_temp_ceiling = 15
		local conifer_temp_terminal = 30

		local conifer_water_multiplier = 1
		local conifer_nutrient_multiplier = 1
		local conifer_light_multiplier = 1
		local conifer_temperature_multiplier = 1

		---- Water factor for Conifers ----
		if available_water <= conifer_water_ceiling then
			conifer_water_multiplier = conifer_water_multiplier * (available_water / conifer_water_floor)
		else
			conifer_water_multiplier = (
				(conifer_water_ceiling / conifer_water_floor) * (conifer_water_ceiling / available_water))
		end

		---- Nutrient factor for Conifers ----
		if real_nutrient_factor <= conifer_nutrient_ceiling then
			conifer_nutrient_multiplier = conifer_nutrient_multiplier * (real_nutrient_factor / conifer_nutrient_floor)
		else
			conifer_nutrient_multiplier = (
				(conifer_nutrient_ceiling / conifer_nutrient_floor) * (conifer_nutrient_ceiling / real_nutrient_factor))
		end

		---- Light factor for Conifers ----
		if sunlight <= conifer_light_ceiling then
			conifer_light_multiplier = sunlight / conifer_light_floor
		else
			conifer_light_multiplier = conifer_light_ceiling / conifer_light_floor * ((conifer_light_ceiling / sunlight) ^ 2)
		end

		--- Soils Depth for Conifers ---
		if soil_depth <= conifer_soildepth_floor then
			conifer_soildepth_floor = (soil_depth / conifer_soildepth_floor) ^ (1.5 + soil_depth_tuner)
		end

		---- Temperature Factor for Conifers ----
		-- Wilt under the heat.  Prefer coldish.

		local adjusted_conifer_preferred_temp_floor = conifer_preferred_temp_floor - permafrost_threshold
		local adjusted_conifer_preferred_temp_ceiling = conifer_preferred_temp_ceiling - permafrost_threshold
		local adjusted_conifer_temp_terminal = conifer_temp_terminal - permafrost_threshold -- point where no conifer can grow

		if adjusted_annual_temperature >= adjusted_conifer_preferred_temp_ceiling and
			adjusted_annual_temperature <= adjusted_conifer_temp_terminal then
			conifer_temperature_multiplier = (
				(adjusted_conifer_temp_terminal - adjusted_annual_temperature) /
					(adjusted_conifer_temp_terminal - adjusted_conifer_preferred_temp_ceiling)) ^ 2
		elseif adjusted_annual_temperature > adjusted_conifer_preferred_temp_ceiling then
			conifer_temperature_multiplier = 0
			--- Add threshold from 0 - -20 which diminishes abundance
		elseif adjusted_annual_temperature < adjusted_conifer_preferred_temp_floor then
			conifer_temperature_multiplier = (adjusted_annual_temperature / -permafrost_threshold) ^ 2
		end
		local conifers = conifer_base_growth * conifer_water_multiplier * conifer_nutrient_multiplier *
			conifer_light_multiplier * conifer_temperature_multiplier * conifer_soildepth_floor * seasonal_rain_extreme_factor *
			conifer_kill

		--------------------------------------------------------------------------------------------

		--- Broadleaf Defines ---
		local broadleaf_base_growth = 50000
		local broadleaf_water_floor = 70
		local broadleaf_water_ceiling = 140

		local broadleaf_nutrient_floor = 0.1
		local broadleaf_nutrient_ceiling = 0.2

		local broadleaf_light_floor = 3.5
		local broadleaf_light_ceiling = 4.0

		local broadleaf_soildepth_ceiling = 4
		local broadleaf_soildepth_floor = 2

		local broadleaf_temp_terminal = -20
		local broadleaf_preferred_temp_floor = 5
		local broadleaf_preferred_temp_ceiling = 30


		local broadleaf_water_multiplier = 1
		local broadleaf_nutrient_multiplier = 1
		local broadleaf_light_multiplier = 1
		local broadleaf_soildepth_multiplier = 1
		local broadleaf_temperature_multiplier = 1

		---- Water factor for Broad Leaves ----
		if available_water <= broadleaf_water_ceiling and available_water >= broadleaf_water_floor then
			broadleaf_water_multiplier = ((available_water / broadleaf_water_floor) ^ 2)
		elseif available_water >= broadleaf_water_ceiling then
			broadleaf_water_multiplier = (
				((broadleaf_water_ceiling / broadleaf_water_floor) ^ 2) * (broadleaf_water_ceiling / available_water))
		else
			broadleaf_water_multiplier = ((available_water / broadleaf_water_floor) ^ 3)
		end

		---- Nutrient factor for Broad Leaves ----
		if real_nutrient_factor <= broadleaf_nutrient_ceiling and real_nutrient_factor >= broadleaf_nutrient_floor then
			broadleaf_nutrient_multiplier = (real_nutrient_factor / broadleaf_nutrient_floor)
		elseif real_nutrient_factor >= broadleaf_nutrient_ceiling then
			broadleaf_nutrient_multiplier = (broadleaf_nutrient_ceiling / broadleaf_nutrient_floor) *
				((real_nutrient_factor / broadleaf_nutrient_ceiling) ^ 0.75)
		else
			broadleaf_nutrient_multiplier = (real_nutrient_factor / broadleaf_nutrient_floor) ^ 2
		end

		--- Broadleaf Sunlight ---
		broadleaf_light_multiplier = (sunlight / broadleaf_light_floor) ^ 5

		--- Soils Depth for Broadleaf ---
		if soil_depth <= broadleaf_soildepth_floor then
			broadleaf_soildepth_multiplier = (soil_depth / broadleaf_soildepth_floor) ^ (2 + soil_depth_tuner)
		end

		local adjusted_broadleaf_preferred_temp_floor = broadleaf_preferred_temp_floor - permafrost_threshold
		local adjusted_broadleaf_preferred_temp_ceiling = broadleaf_preferred_temp_ceiling - permafrost_threshold
		local adjusted_broadleaf_temp_terminal = broadleaf_temp_terminal - permafrost_threshold -- point where no conifer can grow


		if adjusted_annual_temperature >= adjusted_broadleaf_preferred_temp_floor and
			adjusted_annual_temperature <= adjusted_broadleaf_preferred_temp_ceiling then
			broadleaf_temperature_multiplier = adjusted_annual_temperature / adjusted_broadleaf_preferred_temp_floor
		elseif adjusted_annual_temperature >= adjusted_broadleaf_preferred_temp_ceiling then
			broadleaf_temperature_multiplier = (
				adjusted_broadleaf_preferred_temp_ceiling / adjusted_broadleaf_preferred_temp_floor) *
				((adjusted_annual_temperature / adjusted_broadleaf_preferred_temp_ceiling) ^ 0.5)
		elseif adjusted_annual_temperature >= adjusted_broadleaf_temp_terminal and
			adjusted_annual_temperature <= adjusted_broadleaf_preferred_temp_floor then
			broadleaf_temperature_multiplier = adjusted_annual_temperature / adjusted_broadleaf_preferred_temp_floor
		else
			broadleaf_temperature_multiplier = 0
		end

		--- Broad Leaf Floor = -10

		local broad_leaves = broadleaf_base_growth * broadleaf_water_multiplier * broadleaf_nutrient_multiplier *
			broadleaf_light_multiplier * broadleaf_soildepth_multiplier * broadleaf_temperature_multiplier *
			seasonal_rain_extreme_factor * broadleaf_kill
		local total_biomass = shrubs + grasses + conifers + broad_leaves

		--	local grass_percent_pre = grasses / total_biomass
		--	local grass_aggression = 0
		--	if grass_percent_pre > 0.50 then
		--		grass_aggression = (grass_percent_pre - 0.5) + 1
		--		grasses = grasses^grass_aggression
		--	end

		local shrub_excess = 0
		local grass_excess = 0
		local conifer_excess = 0
		local broadleaf_excess = 0

		--- create factor for amount over


		if total_biomass > 60000 then
			--- Calculate the value of each vegetation type in excess of total land cover to determine competition extent
			if shrubs >= 60000 then
				shrub_excess = shrubs - 60000
				shrubs = shrubs + shrub_excess ^ ((((shrub_excess / 60000) * 0.025) + 1) ^ 0.5)
				--shrubs = shrubs + shrub_excess ^ 1.05
			end
			if grasses >= 60000 then
				grass_excess = grasses - 60000
				grasses = grasses + grass_excess ^ ((((grass_excess / 60000) * 0.025) + 1) ^ 0.5)
				--grasses = grasses + grass_excess ^ 1.05
			end
			if conifers >= 60000 then
				conifer_excess = conifers - 60000
				conifers = conifers + conifer_excess ^ ((((conifer_excess / 60000) * 0.025) + 1) ^ 0.5)
				--conifers = conifers + conifer_excess ^ 1.05
			end
			if broad_leaves >= 60000 then
				broadleaf_excess = broad_leaves - 60000
				broad_leaves = broad_leaves + broadleaf_excess ^ ((((broadleaf_excess / 60000) * 0.025) + 1) ^ 0.5)
				--broad_leaves = broad_leaves + broadleaf_excess ^ 1.05
			end
		end
		--	local total_excess = shrub_excess + grass_excess + conifer_excess + broadleaf_excess

		--	local shrub_excess_proportion = shrub_excess / total_excess
		--	local grass_excess_proportion = grass_excess / total_excess
		--	local conifer_excess_proportion = conifer_excess / total_excess
		--	local broadleaf_excess_proportion = broadleaf_excess / total_excess

		local grass_percent = 0
		local shrub_percent = 0
		local conifer_percent = 0
		local broadleaf_percent = 0

		if total_biomass < 60000 then
			grass_percent = grasses / 60000
			shrub_percent = shrubs / 60000
			conifer_percent = conifers / 60000
			broadleaf_percent = broad_leaves / 60000
		else
			shrub_percent = shrubs / total_biomass
			grass_percent = grasses / total_biomass
			conifer_percent = conifers / total_biomass
			broadleaf_percent = broad_leaves / total_biomass
		end

		local is_nan = require "game.math-utils".is_nan
		if is_nan(broadleaf_percent) then
			print("!!!\n!!!\n TREE ERROR \n!!!\n!!!")
		end




		grass_percent = math.max(0, grass_percent)
		shrub_percent = math.max(0, shrub_percent)
		conifer_percent = math.max(0, conifer_percent)
		broadleaf_percent = math.max(0, broadleaf_percent)
		local total_plants = grass_percent + shrub_percent + conifer_percent + broadleaf_percent
		if total_plants > 1 then
			tile.grass = grass_percent / total_plants
			tile.shrub = shrub_percent / total_plants
			tile.conifer = conifer_percent / total_plants
			tile.broadleaf = broadleaf_percent / total_plants
		else
			tile.grass = grass_percent
			tile.shrub = shrub_percent
			tile.conifer = conifer_percent
			tile.broadleaf = broadleaf_percent
		end

		--[[
		SHRUB_COUNT[tile] = shrubs
		GRASS_COUNT[tile] = grasses
		CONIFER_COUNT[tile] = conifers
		BROADLEAF_COUNT[tile] = broad_leaves

		REAL_NUTRIENT_IN_TILE[tile] = real_nutrient_factor
		WATER_IN_TILE_VALUES[tile] = available_water
		RAINFALL_IN_TILE[tile] = annual_rainfall
		PERMEABILITY_OF_TILE[tile] = tilePerm
		SUNLIGHT_VALUES[tile] = sunlight
		SHRUB_COUNT[tile] = shrub_percent
		WATER_MULTIPLIER[tile] = conifer_water_multiplier
		NUTRIENT_MULTIPLIER[tile] = conifer_nutrient_multiplier
		LIGHT_MULTIPLIER[tile] = conifer_light_multiplier
		BROADLEAF_TEMP_MULTIPLIER[tile] = broadleaf_temperature_multiplier

		DEBUG_1[tile] = adjusted_conifer_preferred_temp_floor
		DEBUG_2[tile] = adjusted_conifer_preferred_temp_ceiling
		DEBUG_3[tile] = adjusted_conifer_temp_terminal
		DEBUG_4[tile] = adjusted_annual_temperature

		BASE_GROWTH[tile] = broadleaf_base_growth
		WATER_MULTIPLIER[tile] = broadleaf_water_multiplier
		NUTRIENT_MULTIPLIER[tile] = broadleaf_nutrient_multiplier
		LIGHT_MULTIPLIER[tile] = broadleaf_light_multiplier
		SOILDEPTH_MULTIPLIER[tile] = broadleaf_soildepth_multiplier
		TEMP_MULTIPLIER[tile] = broadleaf_temperature_multiplier
		KILL[tile] = broadleaf_kill

		AERATION_LOSS[tile] = 2 - sand_aeration_loss - silt_aeration_loss - clay_aeration_loss
		SOIL_AERATION[tile] = soil_organic_aeration_factor
		--]]
	end
end

return gen
