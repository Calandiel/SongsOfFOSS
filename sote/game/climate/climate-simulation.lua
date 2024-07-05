local sim = {}

-- Some model constants
local BASE_TEMPERATURE_DEVIATION = 0.0
local BASE_RAINFALL_DEVIATION = 0.0
local AXIAL_TILT_TEMPERATURE_DEVIATION = 0.0
local HADLEY_CONTINENTALITY_DIVISOR = 0.05
local HADLEY_TEMPERATURE_IMPACT = 6.0
local OROGRAPHIC_LIFT_MULTIPLIER = 1.0
local ITCZ_RAINFALL_IMPACT = 200.0
local SEASONALITY_TEMPERATURE_BASE = 400.0 -- 100
local SEASONALITY_RAINFALL_BASE = 200.0
local AXIAL_TILT_SUMMER_TEMPERATURE_DIVISOR = 30.0
local AXIAL_TILT_WINTER_TEMPERATURE_DIVISOR = 1.0
local AXIAL_TILT_SUMMER_RAINFALL_DIVISOR = 10.0
local AXIAL_TILT_WINTER_RAINFALL_DIVISOR = 40.0
local MEDITERRANEAN_SUBTRACTION_CONSTANT = 0.05
local MEDITERRANEAN_COAST_IMPACT_MULTIPLIER = 1.0

local HUMIDITY_DISTANCE_TO_SEA_DIVISOR = 25.0
local HUMIDITY_DISTANCE_TO_SEA_FACTOR = 0.25
local HUMIDITY_RAINFALL_DIVISOR = 350.0
local HUMIDITY_TEMPERATURE_DIVISOR = 50.0

local function simulate_climate()
	--print("A")
	local ut = require "game.climate.utils"

	for i, cell in pairs(WORLD.climate_cells) do
		local _, y = ut.get_x_y(i);
		-- 1:
		-- HADLEY CELL DECREASES RAINFALL AND INCREASES TEMPERATURE
		-- MORE SO IF WE ARE IN HIGHLY CONTINENTAL AREAS
		-- 2:
		-- ITCZ INCREASES RAINFALL IN THEIR RESPECTIVE MONTHS
		-- 3:
		-- HIGH CONTINENTALITY MAKES WINTERS COLDER AND SUMMER HOTTER
		-- 4:
		-- LOW CONTINENTALITY AND BEING CLOSE TO A COAST ADDS MORE RAINFALL
		-- 5:
		-- HIGH DISTANCE FROM COASTS INCREASES VARIATION IN RAINFALL
		-- 6:
		-- BASE TEMPERATURES AND RAINFALLS VARY WITH LATITUDE
		-- 7:
		-- RA IN SHADOWS ARE LESS IMPACTFUL NEARBY COASTS
		-- 8:
		-- RAIN SHADOWS CUT DOWN RAINFALL AND *INCREASE* TEMPERATURE
		-- 9:
		-- EXTRA DEPOSITS INCREASE RAINFALL AND *DECREASE* TEMPERATURE
		-- 10:
		-- ELEVATION DECREASES TEMPERATURE (APPLIED WHEN CLIMATE DATA IS WRITTEN TO TILES)
		--print("B")
		local jan_temp_base -- C
		local jul_temp_base -- C
		local jan_rain_base -- mm
		local jul_rain_base -- m
		local lat = ut.latitude_degrees(y) -- degrees
		local lat_rad = ut.latitude(y)
		local hadley_influence = cell.hadley_influence -- 0 - 1
		hadley_influence = math.sqrt(math.sqrt(hadley_influence))
		local med_influence = cell.med_influence --  0 - 1
		local land_in_cell = 1 - cell.water_fraction
		local extra_deposit = 0.0
		local rain_shadow_drying_impact_multiplier = math.max(0.0, 1.0 - cell.true_rain_shadow)
		local itcz_jan_influence = cell.itcz_january * rain_shadow_drying_impact_multiplier -- 0 - 1
		local itcz_jul_influence = cell.itcz_july * rain_shadow_drying_impact_multiplier --  0 - 1

		-- Initialize rain and temperature
		local lower
		local higher
		local latabs = math.abs(lat)
		if latabs > 80.0 then
			lower = -20.0 - (latabs - 80.0) * 10.0
			higher = 0.0 - (latabs - 80.0) * 10.0
		elseif latabs > 68.5 then
			lower = -10.0 - (latabs - 68.5) / (80.0 - 68.5) * 10.0 -- -10 to -20
			higher = 10.0 - (latabs - 68.5) / (80.0 - 68.5) * 10.0 -- 10 to 0
		elseif latabs > 59.5 then
			lower = -3.0 - (latabs - 59.5) / (68.5 - 59.5) * 7.0 -- -3 to -10
			higher = 18.0 - (latabs - 59.5) / (68.5 - 59.5) * 8.0 -- 18 to 10
		elseif latabs > 43.1 then
			lower = 6.0 - (latabs - 43.1) / (59.5 - 43.1) * 9.0 -- 6 to -3
			higher = 22.0 - (latabs - 43.1) / (59.5 - 43.1) * 4.0 -- 22 to 18
		elseif latabs > 21.0 then
			lower = 30.0 - (latabs - 21.0) / (43.1 - 21.0) * 24.0 -- 30 to 6
			higher = 32.0 - (latabs - 21.0) / (43.1 - 21.0) * 10.0 -- 32 to 22
		elseif latabs > 5.0 then
			lower = 29.0 + (latabs - 5.0) / (21.0 - 5.0) * 1.0 -- 29 to 30
			higher = 30.0 + (latabs - 5.0) / (21.0 - 5.0) * 2.0 -- 30 to 32
		else
			lower = 28.0 + latabs / 5.0 * 1.0 -- 28 to 29
			higher = 28.0 + latabs / 5.0 * 2.0 -- 28 to 30
		end
		if lat > 0.0 then
			jan_temp_base = BASE_TEMPERATURE_DEVIATION + lower
				- AXIAL_TILT_TEMPERATURE_DEVIATION * math.abs(lat / 90.0)
			jul_temp_base = BASE_TEMPERATURE_DEVIATION
				+ higher + AXIAL_TILT_TEMPERATURE_DEVIATION * math.abs(lat / 90.0)
		else
			jan_temp_base = BASE_TEMPERATURE_DEVIATION
				+ higher + AXIAL_TILT_TEMPERATURE_DEVIATION * math.abs(lat / 90.0)
			jul_temp_base = BASE_TEMPERATURE_DEVIATION + lower
				- AXIAL_TILT_TEMPERATURE_DEVIATION * math.abs(lat / 90.0)
		end

		--print("C")
		jan_rain_base = math.max(0.0, BASE_RAINFALL_DEVIATION + 70.0) --25.0f + 90.1f * sigmoid(- 8 * lat_rad / math.PI) --  - 0.65f)
		jul_rain_base = math.max(0.0, BASE_RAINFALL_DEVIATION + 70.0) --25.0f + 90.1f * sigmoid(8 * lat_rad / math.PI) --  - 0.65f)
		---- Add some rain for lower latitudes to prevent large semi arid areas from happening
		--if math.abs(lat) < 22.0 then
		--	jan_rain_base = jan_rain_base + (math.abs(lat) / 20.0) * 10.0
		--	jul_rain_base = jul_rain_base + (math.abs(lat) / 20.0) * 10.0
		--end
		--print("C1")
		-- ITCZ
		---[[
		jul_rain_base = jul_rain_base + itcz_jul_influence * ITCZ_RAINFALL_IMPACT
		jan_rain_base = jan_rain_base + itcz_jan_influence * ITCZ_RAINFALL_IMPACT
		--]]
		--print("C2")
		-- CONTINENTALITY
		---[[
		-- Vary temperature based on continentality and distance to sea
		local f = cell.true_continentality
		local is_tropics = 1.0 - (math.pow(ut.sigmoid(7.0 * lat_rad), 6.0) + math.pow(ut.sigmoid(-7.0 * lat_rad), 6.0))
		local is_temperate = 1.0 - is_tropics
		f = 16.0 * f * f
		-- manipulate the effect in certain latitudes
		if latabs < 30.0 then
			-- tropical zone
			f = f * latabs / 30.0
		end
		if latabs > 75.0 then
			-- polar vortex zone
			local mulp = math.abs(latabs - 90.0) / 15.0
			f = f * mulp * mulp * mulp
		end
		--print("C3")
		-- Vary temperature and rain
		local temp_diff = f * SEASONALITY_TEMPERATURE_BASE * is_temperate -- scale by how temperate the climate is
		local rain_diff = f * SEASONALITY_RAINFALL_BASE * is_temperate
		--print("C3a")
		temp_diff = math.max(0, temp_diff)
		temp_diff = math.min(40, temp_diff)
		temp_diff = temp_diff * (1.0 - hadley_influence) -- multiply by hadley influence to "disable" the cooling in hadley affected areas!
		--print("C3b")
		if lat > 0.0 then
			jan_temp_base = jan_temp_base - temp_diff / AXIAL_TILT_WINTER_TEMPERATURE_DIVISOR
			jul_temp_base = jul_temp_base - temp_diff / AXIAL_TILT_SUMMER_TEMPERATURE_DIVISOR
			jan_rain_base = jan_rain_base - rain_diff / AXIAL_TILT_WINTER_RAINFALL_DIVISOR
			jul_rain_base = jul_rain_base - rain_diff / AXIAL_TILT_SUMMER_RAINFALL_DIVISOR
		else
			jan_temp_base = jan_temp_base - temp_diff / AXIAL_TILT_SUMMER_TEMPERATURE_DIVISOR
			jul_temp_base = jul_temp_base - temp_diff / AXIAL_TILT_WINTER_TEMPERATURE_DIVISOR
			jan_rain_base = jan_rain_base - rain_diff / AXIAL_TILT_SUMMER_RAINFALL_DIVISOR
			jul_rain_base = jul_rain_base - rain_diff / AXIAL_TILT_WINTER_RAINFALL_DIVISOR
		end
		--print("C4")
		jan_rain_base = math.max(0, jan_rain_base)
		jul_rain_base = math.max(0, jul_rain_base)
		--janTempBase += is_tropics * 1000;
		--julTempBase += is_temperate * 1000;
		-- Add extra dryness inside continents
		--print("C5")
		local cont_dryness = math.sqrt(cell.true_continentality)
		--print("C6")
		jan_rain_base = jan_rain_base * (1.0 - math.min(0.9, cont_dryness))
		jul_rain_base = jul_rain_base * (1.0 - math.min(0.9, cont_dryness))
		--print("C7")
		-- For drying out areas based only on distance to sea
		jan_rain_base = jan_rain_base * (1.0 - math.min(0.9, math.max(0, (cell.distance_to_sea - 10.0) / 75.0)))
		jul_rain_base = jul_rain_base * (1.0 - math.min(0.9, math.max(0, (cell.distance_to_sea - 10.0) / 75.0)))
		--print("C8")
		--]]
		--print("D")
		-- MED
		---[[
		-- Med climates have moist winters and cold summer
		local val = math.max(0.0, med_influence - MEDITERRANEAN_SUBTRACTION_CONSTANT)
		local q = cell.left_to_right_continentality * 30.0
		local we_val = val
		we_val = we_val * (1.0 - q)
		we_val = math.max(0.0, we_val)
		local ew_val = 0.0
		if we_val < 0.1 then
			ew_val = val
			ew_val = ew_val * math.max(0, ew_val)
			ew_val = ew_val * math.min(1, ew_val)
		end
		if lat > 0.0 then
			jan_rain_base = jan_rain_base * (1.0 + (we_val - ew_val) * MEDITERRANEAN_COAST_IMPACT_MULTIPLIER)
			jul_rain_base = jul_rain_base * (1.0 - (we_val - ew_val) * MEDITERRANEAN_COAST_IMPACT_MULTIPLIER)
		else
			jan_rain_base = jan_rain_base * (1.0 - (we_val - ew_val) * MEDITERRANEAN_COAST_IMPACT_MULTIPLIER)
			jul_rain_base = jul_rain_base * (1.0 + (we_val - ew_val) * MEDITERRANEAN_COAST_IMPACT_MULTIPLIER)
		end
		--]]
		--print("E")
		-- Hadley
		---[[
		local cont_hadley_factor = math.min(1.0, cell.true_continentality / HADLEY_CONTINENTALITY_DIVISOR)
		hadley_influence = hadley_influence * land_in_cell * (1.0 - math.max(0.0, itcz_jan_influence + itcz_jul_influence))
		hadley_influence = hadley_influence * cont_hadley_factor
		jan_temp_base = jan_temp_base + (hadley_influence * HADLEY_TEMPERATURE_IMPACT)
		jul_temp_base = jul_temp_base + (hadley_influence * HADLEY_TEMPERATURE_IMPACT)
		jan_rain_base = jan_rain_base * (1.0 - math.sqrt(math.sqrt(hadley_influence)))
		jul_rain_base = jul_rain_base * (1.0 - math.sqrt(math.sqrt(hadley_influence)))
		--]]

		-- Rain shadows
		---[[
		jul_rain_base = jul_rain_base * rain_shadow_drying_impact_multiplier
		jan_rain_base = jan_rain_base * rain_shadow_drying_impact_multiplier
		jul_rain_base = jul_rain_base * rain_shadow_drying_impact_multiplier
		jan_rain_base = jan_rain_base * rain_shadow_drying_impact_multiplier
		-- Orographics lift
		jul_rain_base = jul_rain_base + extra_deposit * OROGRAPHIC_LIFT_MULTIPLIER
		jan_rain_base = jan_rain_base + extra_deposit * OROGRAPHIC_LIFT_MULTIPLIER
		--]]

		--print("F")
		-- Write data!
		--print(y, jan_rain_base, jan_temp_base, jul_rain_base, jul_temp_base)
		cell.january_rainfall = math.max(0, math.min(350, jan_rain_base))
		cell.july_rainfall = math.max(0, math.min(350, jul_rain_base))
		cell.january_temperature = jan_temp_base
		cell.july_temperature = jul_temp_base
		--print("G")

		local dist_factor = 1.0 - math.min(cell.distance_to_sea / HUMIDITY_DISTANCE_TO_SEA_DIVISOR, 1.0)
		local fff = HUMIDITY_DISTANCE_TO_SEA_FACTOR

		cell.january_humidity = fff * dist_factor + (1.0 - fff) * math.max(cell.january_rainfall / HUMIDITY_RAINFALL_DIVISOR, math.min(1.0, 1.0 - cell.january_temperature / HUMIDITY_TEMPERATURE_DIVISOR))
		cell.july_humidity = fff * dist_factor + (1.0 - fff) * math.max(cell.july_rainfall / HUMIDITY_RAINFALL_DIVISOR, math.min(1.0, 1.0 - cell.july_temperature / HUMIDITY_TEMPERATURE_DIVISOR))
	end
end

function sim.run()
	require "game.climate.buffer-tile-data".run()
	simulate_climate()
end

function sim.run_hex(world)
	require "game.climate.buffer-tile-data".run_hex(world)
	simulate_climate()
end

return sim
