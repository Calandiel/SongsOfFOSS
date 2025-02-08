local cwf = {}

---@enum flow_type
cwf.TYPES = {
	january   = 1,
	july      = 2,
	current   = 3,
	world_gen = 4
}

local open_issues = require "libsote.hydrology.open-issues"
local wgu = require "libsote.world-gen-utils"
local wb_types = require("libsote.hydrology.waterbody").TYPES

local function clear_temporary_data(world)
	world:fill_ffi_array(world.tmp_float_1, 0)
	world:fill_ffi_array(world.tmp_float_2, 0)
	world:fill_ffi_array(world.tmp_float_3, 0)
	world:fill_ffi_array(world.tmp_float_4, 0)
	world:fill_ffi_array(world.tmp_bool_1, true)
end

local function clear_current_elevation_on_lakes(world)
	world:for_each_waterbody(function(wb)
		if wb.type == wb_types.freshwater_lake or wb.type == wb_types.saltwater_lake then
			wb.tmp_float_1 = 0
		end
	end)
end

local MONTH_OF_FIRST_MELT = 3
local SOIL_MOISTURE_MULTIPLIER = 4 -- We'll use this to moderate the extent to which soil moisture = water on the surface 

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
	-- log_str = log_str .. ti .. ": " .. world.colatitude[ti] .. "," .. world.minus_longitude[ti] .. "; te: " .. world:get_true_elevation(ti) .. "; "
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
			if x >= MONTH_OF_FIRST_MELT and x < MONTH_OF_FIRST_MELT + 6 then
				world.tmp_float_2[ti] = (250 + x ^ 3) * 6 * (jan_rainfall + jul_rainfall) * (math.sin(math.pi * (x - MONTH_OF_FIRST_MELT + 1) / 7) / 946)
				-- logger:log(ti .. " - p1_p1: " .. world.tmp_float_2[ti])
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
			world.snow[ti] = world.snow[ti] + water_to_snow
			world.tmp_float_2[ti] = world.tmp_float_2[ti] + water_to_flow
			-- if flow_type == cwf.TYPES.current then
			-- 	logger:log(ti .. " - p1_p2: " .. world.snow[ti] .. ", " .. world.tmp_float_2[ti])
			-- 	logger:log("\t" .. seasonal_rainfall .. ", " .. temp_mult)
			-- end

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
				-- if flow_type == cwf.TYPES.current then logger:log(ti .. " p1_p4: " .. world.snow[ti] .. ", " .. world.tmp_float_2[ti]) end
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
			-- if flow_type == cwf.TYPES.current then
			-- 	logger:log(ti .. " p2_p1: " .. world.tmp_float_1[ti] .. ", " .. body.tmp_float_1)
			-- end

		elseif body and body.type == wb_types.saltwater_lake or body.type == wb_types.freshwater_lake then
			-- is_p2_p2 = true
			-- p2_p2 = p2_p2 + 1
			body.tmp_float_1 = body.tmp_float_1 + world.tmp_float_1[ti] + world.tmp_float_2[ti]
			-- if flow_type == cwf.TYPES.current then
			-- 	logger:log(ti .. " p2_p2: " .. body.tmp_float_1)
			-- end
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

			local organic_factor = open_issues.calc_organic_factor(world.soil_organics[ti]) -- Test factor so far to see the effects of organics on water retention.

			-- Do we just want to look at temperature at the specific time of month and prevent water loss at that time?
			-- Or do we want to consider the total range of temperature throughout the year?
			local winter_depression_factor_result = wgu.winter_depression_factor(jan_temperature, jul_temperature)
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
			-- if flow_type == cwf.TYPES.current then
			-- 	logger:log(ti .. " p2_p4 - 2: " .. world.soil_moisture[ti] .. ", " .. world.soil_organics[ti])
			-- end
			-- if flow_type == cwf.TYPES.world_gen then
			-- 	logger:log(ti .. " p2_p4 - 1: " .. world.soil_moisture[ti] .. ", " .. world.soil_organics[ti])
			-- end
			world.soil_moisture[ti] = world.soil_moisture[ti] - water_loss;
			-- if flow_type == cwf.TYPES.current or flow_type == cwf.TYPES.world_gen then
			-- 	logger:log("\t" .. world.soil_moisture[ti] .. ": " .. soil_depth_factor .. ", " .. organic_factor .. ", " .. permafrost_factor .. ", " .. sand_factor .. ", " .. silt_factor .. ", " .. clay_factor .. ", " .. water_loss)
			-- end

			local current_saturation = open_issues.current_saturation(world, ti, capacity)
			local infiltration = (sand_percent * 0.9 + silt_percent * 0.75 + clay_percent * 0.1) * (1 - current_saturation) -- Base infiltration multiplier
			local rain_in = (world.tmp_float_2[ti] * infiltration) * SOIL_MOISTURE_MULTIPLIER
			local moving_water_in = 0
			if world.tmp_float_1[ti] > 0 then
				moving_water_in = (world.tmp_float_1[ti] ^ 0.6 / 4) * infiltration * SOIL_MOISTURE_MULTIPLIER;
			end
			local total_water_added = rain_in + moving_water_in;
			-- if flow_type == cwf.TYPES.current or flow_type == cwf.TYPES.world_gen then
			-- 	logger:log("\t" .. current_saturation .. ", " .. infiltration .. ", " .. rain_in .. ", " .. moving_water_in .. ", " .. total_water_added .. ", " .. world.tmp_float_1[ti])
			-- end

			if total_water_added + world.soil_moisture[ti] < capacity then  -- If capacity not met, fill 'er on up
				world.soil_moisture[ti] = world.soil_moisture[ti] + (rain_in + moving_water_in) -- Soil moisture is effectively increased by soilMoistureMultiplier
				world.tmp_float_1[ti] = world.tmp_float_1[ti] + world.tmp_float_2[ti] - (rain_in + moving_water_in) / SOIL_MOISTURE_MULTIPLIER;
			else -- If capacity not met, fill to capacity and then send remaining water on its way
				world.tmp_float_1[ti] = world.tmp_float_1[ti] + world.tmp_float_2[ti] + (total_water_added - (capacity - world.soil_moisture[ti])) / SOIL_MOISTURE_MULTIPLIER;
				world.soil_moisture[ti] = capacity
			end
			-- if flow_type == cwf.TYPES.current or flow_type == cwf.TYPES.world_gen then
			-- 	logger:log("\t" .. world.soil_moisture[ti] .. ", " .. world.tmp_float_1[ti])
			-- end

		else -- If ice, just add rain without any infiltration into the soil
			-- is_p2_p5 = true
			-- p2_p5 = p2_p5 + 1
			world.tmp_float_1[ti] = world.tmp_float_1[ti] + world.tmp_float_2[ti]
			-- if flow_type == cwf.TYPES.current then
			-- 	logger:log(ti .. " p2_p5: " .. world.tmp_float_1[ti])
			-- end
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

		local tile_elev = world.true_elevation[ti]
		local num_neighs = world:neighbors_count(ti)

		local total_elevation_diff = 0
		for i = 0, num_neighs - 1 do
			local nti = world.neighbors[ti * 6 + i]

			if world.tmp_bool_1[nti] then
				local elev_diff = tile_elev - world.true_elevation[nti]
				total_elevation_diff = total_elevation_diff + elev_diff
			end
		end
		for i = 0, num_neighs - 1 do
			local nti = world.neighbors[ti * 6 + i]

			if world.tmp_bool_1[nti] then
				if total_elevation_diff == 0 then error("Total elevation difference is 0!") end

				local elev_diff = tile_elev - world.true_elevation[nti]
				world.tmp_float_1[nti] = world.tmp_float_1[nti] + (elev_diff / total_elevation_diff) * world.tmp_float_1[ti]
			end
		end
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

	-- if flow_type == cwf.TYPES.current then
	-- 	logger:log(log_str)
	-- end
end

---@param flow_type flow_type
---@param month number
---@param year number
local function process_waterflow(world, flow_type, month, year)
	world:for_each_tile_by_elevation(function(ti)
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

local function initialize_soil_moisture(world)
	world:for_each_waterbody(function(wb)
		local is_lake = false
		local pow = 1

		if wb.type == wb_types.freshwater_lake then
			is_lake = true
			pow = 0.6
		elseif wb.type == wb_types.saltwater_lake then
			is_lake = true
			pow = 0.55
		end

		if not is_lake then return end

		for _, ti in ipairs(wb.tiles) do
			world.soil_moisture[ti] = wb.tmp_float_1 ^ pow
			-- logger:log(ti .. ": " .. wb.tmp_float_1 .. ": " .. world.soil_moisture[ti])
			world.tmp_float_3[ti] = 3000
		end
	end)
end

--* We want 3 kinds of water flow. Surficial, soil, and subsoil (in the bedrock).
--* ---Surficial is the most complicated probably and the fastest.
--* ---Soil is going to be somewhat slow. In this case, we're passing through a porous medium, thus flow is slowed down. While this flow is still
--* sensitive to gravity, it's less gravity contingent than surficial waterflow. Soil water flow is also highly influenced by soil composition and 
--* relative saturation of the soil. We may want water flowing in the soil to rejoin rivers in some cases?  We'll see.
--* ---Bedrock/aquifer water flow is even slower than all the others, perhaps even calculated at a 1 year interval instead of monthly. However...
--* we want to know where natural springs arise.
local function soil_waterflow(world)
	--* NOTE: Why does this not take "flow type" into account?
	--* It feels like it's asking for someone to make a mistake
	--* All other jobs use flow type in their evaluation (see: top of this source file)
	--* Cala ~ 02/01/2021

	world:for_each_tile_by_elevation(function(ti)
		--* Let tiles go over capacity?? Always give fraction of water, just figure out which direction it needs to go in. Only give to less pressure tiles
		local tile_with_soil_waterflow = world.ice[ti] <= 0 and world.is_land[ti]
		local wb = world:get_waterbody_by_tile(ti)
		tile_with_soil_waterflow = tile_with_soil_waterflow or (wb and wb.type == wb_types.freshwater_lake)

		if not tile_with_soil_waterflow then return end

		local tile_soil_moisture = world.soil_moisture[ti]
		local tile_capacity = world.tmp_float_3[ti]
		local tile_moisture_capacity_ratio = tile_soil_moisture / tile_capacity
		local num_neighs = world:neighbors_count(ti)

		local total_capacity = 0
		local total_soil_moisture = 0
		local total_deficit = 0.001
		-- local total_elevation_difference = 0

		for i = 0, num_neighs - 1 do
			local nti = world.neighbors[ti * 6 + i]

			if tile_moisture_capacity_ratio > world.soil_moisture[nti] / world.tmp_float_3[nti] then
				total_capacity = total_capacity + world.tmp_float_3[nti]
				total_soil_moisture = total_soil_moisture + world.soil_moisture[nti]
				total_deficit = total_deficit + math.max(0, (world.tmp_float_3[nti] - world.soil_moisture[nti]) / world.tmp_float_3[nti])
				-- total_elevation_difference = total_elevation_difference + world.true_elevation[ti] - world.true_elevation[nti]
			end
		end
		-- logger:log(ti .. ": " .. total_capacity .. ", " .. total_soil_moisture .. ", " .. total_deficit)

		if total_soil_moisture > 0 and total_capacity > 0 then
			local deficit_difference = tile_moisture_capacity_ratio - total_soil_moisture / total_capacity
			local water_up_for_grabs = deficit_difference * tile_soil_moisture / 2

			for i = 0, num_neighs - 1 do
				local nti = world.neighbors[ti * 6 + i]

				if tile_moisture_capacity_ratio > world.soil_moisture[nti] / world.tmp_float_3[nti] then
					local elev_diff = world.true_elevation[nti] - world.true_elevation[ti]
					local elevation_mult = elev_diff > 0 and 0.75^(elev_diff / 50) or 1
					local amount_transferred = water_up_for_grabs * elevation_mult * (((world.tmp_float_3[nti] - world.soil_moisture[nti]) / world.tmp_float_3[nti]) / total_deficit)
					world.tmp_float_4[nti] = world.tmp_float_4[nti] + amount_transferred
					world.tmp_float_4[ti] = world.tmp_float_4[ti] - amount_transferred
				end
			end
		end
	end)
end

local function apply_soil_moisture(world)
	world:for_each_tile(function(ti)
		-- logger:log(ti .. ": " .. world.soil_moisture[ti] .. ", " .. world.tmp_float_4[ti])
		world.soil_moisture[ti] = world.soil_moisture[ti] + world.tmp_float_4[ti]
	end)
end

-- precondition: update_true_elevation (fullfilled by create_elevation_list)
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
		initialize_soil_moisture(world)
		soil_waterflow(world)
		apply_soil_moisture(world)
	end
end

function cwf.test_tile(ti, world, flow_type, month, year)
	process_tile_waterflow(ti, world, flow_type, month, year)
end

return cwf