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

	-- For the case of snow, we can simply check the seasonal temperature to determine whether snow accumulation or melt occurs.
	-- However, once snow starts occurring, we also need to shut off plant growth as well.
	if world.ice[ti] > 0 then -- If there is ice on tile, only release water during the warm season
		if flow_type == cwf.types.january then
		elseif flow_type == cwf.types.july then
		elseif flow_type == cwf.types.world_gen then
		elseif flow_type == cwf.types.current then
		end
	elseif world:get_temperature(ti, month) <= 0 then
	else -- If no ice is involved and temp is above 0, release water in all seasons
		if flow_type == cwf.types.january then
		elseif flow_type == cwf.types.july then
		elseif flow_type == cwf.types.world_gen then
		else
		end
	end

	if not is_land then -- if water tile, check to see if it's a lake. If it is, shunt water to outlet tile
	else -- otherwise... the tile is land and we pass the water to all neighboring tiles which are lower in elevation based on elevation differences
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
---@param month? number
---@param year? number
function cwf.run(world, flow_type, month, year)
	if year == nil then year = 0 end
	if month == nil then month = 0 end

	clear_temporary_data(world)
	clear_current_elevation_on_lakes(world)

	process_waterflow(world, flow_type, month, year)
end

return cwf