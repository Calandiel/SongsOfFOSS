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
	local month_rainfall = world:get_rainfall_for(ti, month)
	local month_temperature = world:get_temperature_for(ti, month)
	local month_humidity = 0.3 -- hardcoded for now

	local sand = world.sand[ti]
	local silt = world.silt[ti]
	local clay = world.clay[ti]

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

	elseif month_temperature <= 0 then
		if is_land then
			local temp_mult = month_temperature / -10
			if temp_mult > 1 then temp_mult = 1 end
			local water_to_snow = month_rainfall * temp_mult
			local water_to_flow = month_rainfall - water_to_snow
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
			world.tmp_float_2[ti] = month_rainfall

			if world.snow[ti] > 0 then -- if there is snow but temperatures are not freezing, start melting snow
				local total_soil = sand + silt + clay
				local sand_percent = sand / total_soil
				local silt_percent = silt / total_soil
				local clay_percent = clay / total_soil

				local soil_depth_factor = total_soil
				if total_soil < 1000 then
					soil_depth_factor = 0.75 * (soil_depth_factor / 1000) + 0.25
				end

				local melt_mult = (sand_percent * 0.65 + silt_percent * 0.85 + clay_percent * 1) / 3;
				local melt_qty = (month_temperature * 15 + month_temperature * 1 * world.snow[ti] * melt_mult) * soil_depth_factor;

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

		else -- If ice, just add rain without any infiltration into the soil
			world.tmp_float_1[ti] = world.tmp_float_1[ti] + world.tmp_float_2[ti]
		end
		world.tmp_float_1[ti] = math.max(0, world.tmp_float_1[ti])

		-- Apply Evaporation
		local evaporation_volume = 0
		if world.tmp_float_1[ti] > 0 then
			if world.tmp_float_1[ti] < 6000 then -- Don't evaporate big rivers -- we don't want to kill our Niles!
				if month_temperature > 0 then -- Don't evaporate in winters, we already have barely any water movement left during those seasons!
					evaporation_volume = math.sqrt(world.tmp_float_1[ti]) / month_humidity
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