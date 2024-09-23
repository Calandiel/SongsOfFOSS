local cwf = {}

---@enum flow_type
cwf.TYPES = {
	january   = 1,
	july      = 2,
	current   = 3,
	world_gen = 4
}

local open_issues = require "libsote.hydrology.open-issues"

local function clear_temporary_data(world)
	world:fill_ffi_array(world.tmp_float_1, 0)
	world:fill_ffi_array(world.tmp_float_2, 0)
	world:fill_ffi_array(world.tmp_float_3, 0)
	world:fill_ffi_array(world.tmp_bool_1, true)
end

local function clear_current_elevation_on_lakes(world)
	world:for_each_waterbody(function(wb)
		if not wb:is_valid() then return end

		if wb.type == wb.TYPES.freshwater_lake or wb.type == wb.TYPES.saltwater_lake then
			wb.tmp_float_1 = 0
		end
	end)
end

local month_of_first_melt = 3
local soil_moisture_multiplier = 4 -- We'll use this to moderate the extent to which soil moisture = water on the surface 

-- local logger = require("libsote.debug-loggers").get_waterflow_logger("d:/temp")
-- local p1_p1 = 0
-- local p1_p2 = 0
-- local p1_p3 = 0
-- local p1_p4 = 0
-- local p2_p1 = 0
-- local p2_p2 = 0
-- local p2_p3 = 0
-- local p2_p4 = 0
-- local p2_p5 = 0

-- We want to make a check, to see if water is allowed to move at all through ice tiles.
-- If it is ice and is the warm season, move the water. If it is ice and is the cold season, move water for BOTH seasons.
---@param ti number
---@param flow_type flow_type
---@param month number
---@param year number
local function process_tile_waterflow(ti, world, flow_type, month, year)
	world.tmp_bool_1[ti] = false

	local is_land = world.is_land[ti]
	local jan_rainfall = world.jan_rainfall[ti]
	local jan_temperature = world.jan_temperature[ti]
	local jul_rainfall = world.jul_rainfall[ti]
	local jul_temperature = world.jul_temperature[ti]
	local seasonal_rainfall = world:get_rainfall_for(ti, month)
	local seasonal_temperature = world:get_temperature_for(ti, month)
	local seasonal_humidity = open_issues.seasonal_humidity(world, ti, month)

	local sand = world.sand[ti]
	local silt = world.silt[ti]
	local clay = world.clay[ti]
	local total_soil = sand + silt + clay
	local sand_percent = sand / total_soil
	local silt_percent = silt / total_soil
	local clay_percent = clay / total_soil

	-- local log_str =  ""
	-- log_str = log_str .. world.colatitude[ti] .. "," .. world.minus_longitude[ti] .. "; te: " .. world:true_elevation(ti) .. "; "
	-- if is_land then
	-- 	log_str = log_str .. "land\n"
	-- else
	-- 	log_str = log_str .. "water\n"
	-- end
	-- log_str = log_str .. "\tjanr: " .. world.jan_rainfall[ti] .. ", julr: " .. world.jul_rainfall[ti] .. ", m: " .. month .. " --> sr: " .. seasonal_rainfall .. "\n"
	-- log_str = log_str .. "\tjant: " .. world.jan_temperature[ti] .. ", jult: " .. world.jul_temperature[ti] .. ", m: " .. month .. " --> st: " .. seasonal_temperature .. "\n"
	-- log_str = log_str .. "\th: " .. seasonal_humidity .. "\n"

	-- local is_p1_p1 = false
	-- local is_p1_p2 = false
	-- local is_p1_p3 = false
	-- local is_p1_p4 = false

	-- For the case of snow, we can simply check the seasonal temperature to determine whether snow accumulation or melt occurs.
	-- However, once snow starts occurring, we also need to shut off plant growth as well.
	if world.ice[ti] > 0 then -- If there is ice on tile, only release water during the warm season
		-- is_p1_p1 = true
		-- p1_p1 = p1_p1 + 1
		if flow_type == cwf.TYPES.january then -- If January temperature is greater than July, move ice along.
			if jan_temperature > jul_temperature then
				world.tmp_float_2[ti] = jul_rainfall + jan_rainfall -- We add July as well, since July was frozen when the ice accumulated.
			end

		elseif flow_type == cwf.TYPES.july then
			if jul_temperature > jan_temperature then
				world.tmp_float_2[ti] = jan_rainfall + jul_rainfall
			end

		elseif flow_type == cwf.TYPES.world_gen then
			world.tmp_float_2[ti] = (jan_rainfall + jul_rainfall) / 2

		elseif flow_type == cwf.TYPES.current then
			local x = world:is_in_northern_hemisphere(ti) and month or (month + 5) % 12;
			if x >= month_of_first_melt and x < month_of_first_melt + 6 then
				world.tmp_float_2[ti] = (250 + math.pow(x, 3)) * 6 * (jan_rainfall + jul_rainfall) * (math.sin(math.pi * (x - month_of_first_melt + 1) / 7) / 946)
			end
		end

	elseif seasonal_temperature <= 0 then
		if is_land then
			-- is_p1_p2 = true
			-- p1_p2 = p1_p2 + 1
			local temp_mult = seasonal_temperature / -10
			if temp_mult > 1 then temp_mult = 1 end
			local water_to_snow = seasonal_rainfall * temp_mult
			local water_to_flow = seasonal_rainfall - water_to_snow
			world.snow[ti] = water_to_snow
			world.tmp_float_2[ti] = water_to_flow

		else
			-- is_p1_p3 = true
			-- p1_p3 = p1_p3 + 1
			open_issues.add_sea_ice(world, ti)
		end

	else -- If no ice is involved and temp is above 0, release water in all seasons
		-- is_p1_p4 = true
		-- p1_p4 = p1_p4 + 1
		if flow_type == cwf.TYPES.january then
			world.tmp_float_2[ti] = jan_rainfall

		elseif flow_type == cwf.TYPES.july then
			world.tmp_float_2[ti] = jul_rainfall

		elseif flow_type == cwf.TYPES.world_gen then
			world.tmp_float_2[ti] = (jan_rainfall + jul_rainfall) / 2

		else
			world.tmp_float_2[ti] = seasonal_rainfall

			if world.snow[ti] > 0 then -- if there is snow but temperatures are not freezing, start melting snow
				local soil_depth_factor = total_soil
				if total_soil < 1000 then
					soil_depth_factor = 0.75 * (soil_depth_factor / 1000) + 0.25
				end

				local melt_mult = (sand_percent * 0.65 + silt_percent * 0.85 + clay_percent * 1) / 3;
				local melt_qty = (seasonal_temperature * 15 + seasonal_temperature * 1 * world.snow[ti] * melt_mult) * soil_depth_factor;

				if melt_qty >= world.snow[ti] then melt_qty = world.snow[ti] end
				world.snow[ti] = world.snow[ti] - melt_qty
				world.tmp_float_2[ti] = world.tmp_float_2[ti] + melt_qty
			end
		end
	end

	-- local case_str = ""
	-- if is_p1_p1 then case_str = "p1_p1" end
	-- if is_p1_p2 then case_str = "p1_p2" end
	-- if is_p1_p3 then case_str = "p1_p3" end
	-- if is_p1_p4 then case_str = "p1_p4" end

	-- log_str = log_str .. "\t" .. case_str .. ", " .. "f2: " .. world.tmp_float_2[ti] .. ", snow: " .. world.snow[ti] .. "\n"

	------------------------------------------------------------------------------------------------------------------------------------------

	-- local is_p2_p1 = false
	-- local is_p2_p2 = false
	-- local is_p2_p3 = false
	-- local is_p2_p4 = false
	-- local is_p2_p5 = false

	if not is_land then -- if water tile, check to see if it's a lake. If it is, shunt water to outlet tile
		local body = world:get_waterbody_by_tile(ti)

		if body and body.lake_open then -- If it is a non-endhoric waterbody, then pass the water on.
			-- is_p2_p1 = true
			-- p2_p1 = p2_p1 + 1
			local body_outlet_ti = body.lowest_shore_tile

			world.tmp_float_1[body_outlet_ti] = world.tmp_float_1[body_outlet_ti] + world.tmp_float_1[ti] + world.tmp_float_2[ti]
			body.tmp_float_1 = body.tmp_float_1 + world.tmp_float_1[ti] + world.tmp_float_2[ti] -- Body temp float represents how much water moved through this body.

		elseif body and body.type == body.TYPES.saltwater_lake or body.type == body.TYPES.freshwater_lake then
			-- is_p2_p2 = true
			-- p2_p2 = p2_p2 + 1
			body.tmp_float_1 = body.tmp_float_1 + world.tmp_float_1[ti] + world.tmp_float_2[ti]
		else
			-- is_p2_p3 = true
			-- p2_p3 = p2_p3 + 1
		end

	else -- otherwise... the tile is land and we pass the water to all neighboring tiles which are lower in elevation based on elevation differences
		-- Apply Water Infiltration
		-- We only want water infiltration to the soil and evaporation if the tile is not covered in ice

		if world.ice[ti] <= 0 then
			-- is_p2_p4 = true
			-- p2_p4 = p2_p4 + 1
			local capacity = 1
			local soil_depth_factor = world:soil_depth_raw(ti) -- Less soil depth should mean faster penetration of water into aquifer and out of soil.
			soil_depth_factor = math.min(soil_depth_factor, 1000)
			soil_depth_factor = soil_depth_factor / 1000
			capacity = ((sand_percent * 0.25) + (silt_percent * 0.75) + (clay_percent * 1)) * soil_depth_factor -- Long term, we want to revise so that too much clay = compaction
			capacity = capacity * 5000
			world.tmp_float_3[ti] = capacity

			local organic_factor = math.pow((world.soil_organics[ti] / 1000), 0.5) + 1 -- Test factor so far to see the effects of organics on water retention.

			-- Do we just want to look at temperature at the specific time of month and prevent water loss at that time?
			-- Or do we want to consider the total range of temperature throughout the year?
			local winter_depression_factor_result = require("libsote.world-gen-utils").winter_depression_factor(jan_temperature, jul_temperature)
			local permafrost_factor = 1
			if seasonal_temperature - winter_depression_factor_result < -10 then -- Less than 0 implies net temperature of tile over year being less than 0, hence presence of some permafrost
				permafrost_factor = seasonal_temperature - winter_depression_factor_result + 10;
				if permafrost_factor < 0 then
					permafrost_factor = math.max(permafrost_factor, -10)
					permafrost_factor = 1 - (permafrost_factor / -10)
				else
					permafrost_factor = 1
				end
			end

			local sand_factor = sand_percent * (1 - (1 - 0.15) / (organic_factor * 12));
			local silt_factor = silt_percent * (1 - (1 - 0.75) / (organic_factor * 6));
			local clay_factor = clay_percent * (1 - (1 - 0.90) / (organic_factor * 6));
			local water_loss = world.soil_moisture[ti] * (1 - (soil_depth_factor * ((sand_factor + silt_factor + clay_factor))));
			water_loss = water_loss * permafrost_factor
			water_loss = math.min(water_loss, world.soil_moisture[ti])
			world.soil_moisture[ti] = world.soil_moisture[ti] - water_loss;

			local current_saturation = open_issues.current_saturation(world, ti, capacity)
			local infiltration = (sand_percent * 0.9 + silt_percent * 0.75 + clay_percent * 0.1) * (1 - current_saturation) -- Base infiltration multiplier
			local rain_in = (world.tmp_float_2[ti] * infiltration) * soil_moisture_multiplier
			local moving_water_in = 0
			if world.tmp_float_1[ti] > 0 then
				moving_water_in = (math.pow(world.tmp_float_1[ti], 0.6) / 4) * infiltration * soil_moisture_multiplier;
			end
			local total_water_added = rain_in + moving_water_in;

			if total_water_added + world.soil_moisture[ti] < capacity then  -- If capacity not met, fill 'er on up
				world.soil_moisture[ti] = world.soil_moisture[ti] + (rain_in + moving_water_in) -- Soil moisture is effectively increased by soilMoistureMultiplier
				world.tmp_float_1[ti] = world.tmp_float_1[ti] + world.tmp_float_2[ti] - (rain_in + moving_water_in) / soil_moisture_multiplier;
			else -- If capacity not met, fill to capacity and then send remaining water on its way
				world.soil_moisture[ti] = capacity
				world.tmp_float_1[ti] = world.tmp_float_1[ti] + world.tmp_float_2[ti] + (total_water_added - (capacity - world.soil_moisture[ti])) / soil_moisture_multiplier;
			end

		else -- If ice, just add rain without any infiltration into the soil
			-- is_p2_p5 = true
			-- p2_p5 = p2_p5 + 1
			world.tmp_float_1[ti] = world.tmp_float_1[ti] + world.tmp_float_2[ti]
		end
		world.tmp_float_1[ti] = math.max(0, world.tmp_float_1[ti])

		-- Apply Evaporation
		local evaporation_volume = 0
		if world.tmp_float_1[ti] > 0 then
			if world.tmp_float_1[ti] < 6000 then -- Don't evaporate big rivers -- we don't want to kill our Niles!
				if seasonal_temperature > 0 then -- Don't evaporate in winters, we already have barely any water movement left during those seasons!
					evaporation_volume = math.sqrt(world.tmp_float_1[ti]) / seasonal_humidity
				end
			end
		end
		if evaporation_volume > world.tmp_float_1[ti] then
			world.tmp_float_1[ti] = 0
		else
			world.tmp_float_1[ti] = world.tmp_float_1[ti] - evaporation_volume
		end

		local total_elevation_difference = 0
		world:for_each_neighbor(ti, function(nti)
			if world.tmp_bool_1[nti] then
				local elev_diff = world:true_elevation(ti) - world:true_elevation(nti)
				total_elevation_difference = total_elevation_difference + elev_diff
			end
		end)
		world:for_each_neighbor(ti, function(nti)
			if world.tmp_bool_1[nti] then
				if total_elevation_difference == 0 then error("Total elevation difference is 0!") end

				local elev_diff = world:true_elevation(ti) - world:true_elevation(nti)
				world.tmp_float_1[nti] = world.tmp_float_1[nti] + (elev_diff / total_elevation_difference) * world.tmp_float_1[ti]
			end
		end)
	end

	-- case_str = ""
	-- if is_p2_p1 then case_str = "p2_p1" end
	-- if is_p2_p2 then case_str = "p2_p2" end
	-- if is_p2_p3 then case_str = "p2_p3" end
	-- if is_p2_p4 then case_str = "p2_p4" end
	-- if is_p2_p5 then case_str = "p2_p5" end
	-- local c1 = is_p1_p1 and is_p2_p5
	-- local c2 = is_p1_p2 and is_p2_p4
	-- local c3 = is_p1_p3 and is_p2_p1
	-- local c4 = is_p1_p3 and is_p2_p2
	-- local c5 = is_p1_p3 and is_p2_p3
	-- local c6 = is_p1_p4 and is_p2_p1
	-- local c7 = is_p1_p4 and is_p2_p2
	-- local c8 = is_p1_p4 and is_p2_p3
	-- local c9 = is_p1_p4 and is_p2_p4
	-- if c1 then case_str = case_str .. ", c1" end
	-- if c2 then case_str = case_str .. ", c2" end
	-- if c3 then case_str = case_str .. ", c3" end
	-- if c4 then case_str = case_str .. ", c4" end
	-- if c5 then case_str = case_str .. ", c5" end
	-- if c6 then case_str = case_str .. ", c6" end
	-- if c7 then case_str = case_str .. ", c7" end
	-- if c8 then case_str = case_str .. ", c8" end
	-- if c9 then case_str = case_str .. ", c9" end
	-- if not c1 and not c2 and not c3 and not c4 and not c5 and not c6 and not c7 and not c8 and not c9 then
	-- 	case_str = case_str .. ", ERROR"
	-- end

	-- if c3 or c4 or c5 or c6 or c7 or c8 then
	-- 	log_str = log_str .. "\t" .. case_str .. ", " .. "wb.f1: " .. world:get_waterbody_by_tile(ti).tmp_float_1
	-- else
	-- 	log_str = log_str .. "\t" .. case_str .. ", " .. "f1: " .. world.tmp_float_1[ti] .. ", moisture: " .. world.soil_moisture[ti]
	-- end

	-- logger:log(log_str)
end

---@param flow_type flow_type
---@param month number
---@param year number
local function process_waterflow(world, flow_type, month, year)
	world:for_each_tile_by_elevation(function(ti, _)
		process_tile_waterflow(ti, world, flow_type, month, year)
	end)
end

---@param flow_type flow_type
local function apply_waterflow(world, flow_type)
	world:for_each_tile(function(ti)
		if world.tmp_bool_1[ti] then return end

		if flow_type == cwf.TYPES.january then
			world.jan_water_movement[ti] = world.tmp_float_1[ti]

		elseif flow_type == cwf.TYPES.july then
			world.jul_water_movement[ti] = world.tmp_float_1[ti]

		else
			world.water_movement[ti] = world.tmp_float_1[ti]
		end
	end)
end

function cwf.test_tile(ti, world, flow_type, month, year)
	process_tile_waterflow(ti, world, flow_type, month, year)
end

---@param flow_type flow_type
---@param month? number
---@param year? number
function cwf.run(world, flow_type, month, year)
	if year == nil then year = 0 end
	if month == nil then month = 0 end

	clear_temporary_data(world)
	clear_current_elevation_on_lakes(world)

	process_waterflow(world, flow_type, month, year)

	apply_waterflow(world, flow_type)

	-- print("p1_p1: " .. p1_p1)
	-- print("p1_p2: " .. p1_p2)
	-- print("p1_p3: " .. p1_p3)
	-- print("p1_p4: " .. p1_p4)
	-- print("p2_p1: " .. p2_p1)
	-- print("p2_p2: " .. p2_p2)
	-- print("p2_p3: " .. p2_p3)
	-- print("p2_p4: " .. p2_p4)
	-- print("p2_p5: " .. p2_p5)

	-- Run soil moisture calculations if flowType is current.
	-- Otherwise, we'd run it an odd number of times, because world gen calls this function for july and january.
	if flow_type == cwf.TYPES.current then
		-- TODO: Port soil moisture calculations here
	end
end

return cwf