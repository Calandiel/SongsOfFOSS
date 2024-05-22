local cwf = {}

---@enum flow_type
cwf.types = {
	january   = 1,
	july      = 2,
	current   = 3,
	world_gen = 4
}

local function clear_temporary_data(world)
	world:fill_ffi_array(world.tmp_float_1, 0)
	world:fill_ffi_array(world.tmp_float_2, 0)
	world:fill_ffi_array(world.tmp_float_3, 0)
	world:fill_ffi_array(world.tmp_bool_1, true)
end

local function clear_current_elevation_on_lakes(world)
	world:for_each_waterbody(function(waterbody)
		if not waterbody:is_valid() then return end

		if waterbody.type == waterbody.types.freshwater_lake or waterbody.type == waterbody.types.saltwater_lake then
			waterbody.tmp_float_1 = 0
		end
	end)
end

local month_of_first_melt = 3
local soil_moisture_multiplier = 4 -- We'll use this to moderate the extent to which soil moisture = water on the surface 

-- We want to make a check, to see if water is allowed to move at all through ice tiles.
-- If it is ice and is the warm season, move the water. If it is ice and is the cold season, move water for BOTH seasons.
---@param ti number
---@param flow_type flow_type
---@param month number
---@param year number
local function process_tile_waterflow(ti, world, flow_type, month, year)
	local is_land = world.is_land[ti]
	local jan_rainfall = world.jan_rainfall[ti]
	local jan_temperature = world.jan_temperature[ti]
	local jul_rainfall = world.jul_rainfall[ti]
	local jul_temperature = world.jul_temperature[ti]
	local seasonal_rainfall = world:get_rainfall_for(ti, month)
	local seasonal_temperature = world:get_temperature_for(ti, month)
	local seasonal_humidity = 0.3 -- hardcoded for now

	local sand = world.sand[ti]
	local silt = world.silt[ti]
	local clay = world.clay[ti]
	local total_soil = sand + silt + clay
	local sand_percent = sand / total_soil
	local silt_percent = silt / total_soil
	local clay_percent = clay / total_soil

	-- For the case of snow, we can simply check the seasonal temperature to determine whether snow accumulation or melt occurs.
	-- However, once snow starts occurring, we also need to shut off plant growth as well.
	if world.ice[ti] > 0 then -- If there is ice on tile, only release water during the warm season
		if flow_type == cwf.types.january then -- If January temperature is greater than July, move ice along.
			if jan_temperature > jul_temperature then
				world.tmp_float_2[ti] = jul_rainfall + jan_rainfall -- We add July as well, since July was frozen when the ice accumulated.
			end

		elseif flow_type == cwf.types.july then
			if jul_temperature > jan_temperature then
				world.tmp_float_2[ti] = jan_rainfall + jul_rainfall
			end

		elseif flow_type == cwf.types.world_gen then
			world.tmp_float_2[ti] = (jan_rainfall + jul_rainfall) / 2

		elseif flow_type == cwf.types.current then
			local x = world:is_in_northern_hemisphere(ti) and month or (month + 5) % 12;
			if x >= month_of_first_melt and x < month_of_first_melt + 6 then
				world.tmp_float_2[ti] = (250 + math.pow(x, 3)) * 6 * (jan_rainfall + jul_rainfall) * (math.sin(math.pi * (x - month_of_first_melt + 1) / 7) / 946)
			end
		end

	elseif seasonal_temperature <= 0 then
		if is_land then
			local temp_mult = seasonal_temperature / -10
			if temp_mult > 1 then temp_mult = 1 end
			local water_to_snow = seasonal_rainfall * temp_mult
			local water_to_flow = seasonal_rainfall - water_to_snow
			world.snow[ti] = water_to_snow
			world.tmp_float_2[ti] = water_to_flow

		else
			world.snow[ti] = 0 -- TODO: Add in sea ice here later
		end

	else -- If no ice is involved and temp is above 0, release water in all seasons
		if flow_type == cwf.types.january then
			world.tmp_float_2[ti] = jan_rainfall

		elseif flow_type == cwf.types.july then
			world.tmp_float_2[ti] = jul_rainfall

		elseif flow_type == cwf.types.world_gen then
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

	if not is_land then -- if water tile, check to see if it's a lake. If it is, shunt water to outlet tile
		local body = world:get_waterbody_by_tile(ti)

		if body.lake_open then -- If it is a non-endhoric waterbody, then pass the water on.
			local body_outlet_ti = body.lowest_shore_tile

			world.tmp_float_1[body_outlet_ti] = world.tmp_float_1[body_outlet_ti] + world.tmp_float_1[ti] + world.tmp_float_2[ti]
			body.tmp_float_1 = body.tmp_float_1 + world.tmp_float_1[ti] + world.tmp_float_2[ti] -- Body temp float represents how much water moved through this body.

		elseif body.type == body.types.saltwater_lake or body.type == body.types.freshwater_lake then
			body.tmp_float_1 = body.tmp_float_1 + world.tmp_float_1[ti] + world.tmp_float_2[ti]
		end

	else -- otherwise... the tile is land and we pass the water to all neighboring tiles which are lower in elevation based on elevation differences
		-- Apply Water Infiltration
		-- We only want water infiltration to the soil and evaporation if the tile is not covered in ice

		if world.ice[ti] <= 0 then
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

			local current_saturation = world.soil_moisture[ti] / capacity
			current_saturation = 0 -- :(
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

		if flow_type == cwf.types.january then
			world.jan_water_movement[ti] = world.tmp_float_1[ti]

		elseif flow_type == cwf.types.july then
			world.jul_water_movement[ti] = world.tmp_float_1[ti]

		else
			world.water_movement[ti] = world.tmp_float_1[ti]
		end
	end)
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

	-- Run soil moisture calculations iff flowType is current.
	-- Otherwise, we'd run it an odd number of times, because world gen calls this function for july and january.
	if flow_type == cwf.types.current then
		-- TODO: Port soil moisture calculations here
	end
end

return cwf