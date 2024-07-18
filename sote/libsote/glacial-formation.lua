local gm = {}

-- NOTE 2024.07.06: The comments are close to the original, but may have been edited for clarity and relevance to the current state.
-- In order to distinguish between the original comments and the new ones, the original ones are marked with "--*"

---@enum age_types
local AGE_TYPES = {
	ice_age  = 0,
	game_age = 1
}

local logger = require("libsote.debug-loggers").get_glacial_logger("d:/temp")
local open_issues = require "libsote.glacial-open-issues"

local glacial_seed = nil
local ice_flow = nil
local ice_moved = nil
local distance_from_edge = nil

local function create_glacial_start_locations(world, is_ice_age)
	local ice_age_factor = 5
	if is_ice_age then ice_age_factor = -10 end --* Makes world colder for ice age

	local seed_threshold = -15 --* -15 for non-Ice Age
	if is_ice_age then seed_threshold = 0 end

	world:for_each_tile(function(ti)
	-- world:for_each_tile_by_elevation_for_waterflow(function(ti, _)
		-- local log_str = "gs: " .. world.colatitude[ti] .. "," .. world.minus_longitude[ti] .. "; " .. world:true_elevation_for_waterflow(ti) .. "\n"

		local wb = world:get_waterbody_by_tile(ti)
		local waterbody_size = (wb == nil) and 0 or #wb.tiles

		local jan_rainfall = world.jan_rainfall[ti]
		local jan_temperature = world.jan_temperature[ti]
		local jul_rainfall = world.jul_rainfall[ti]
		local jul_temperature = world.jul_temperature[ti]

		local average_temp = open_issues.avg_temp(jan_temperature, jul_temperature) + ice_age_factor
		-- log_str = log_str .. "\tavgt: " .. average_temp .. ", wbs: " .. waterbody_size .. "\n"
		if average_temp >= seed_threshold or waterbody_size >= 20000 then
			-- log_str = log_str .. "\tnot seeded"
			-- logger:log(log_str)
			return
		end
		-- log_str = log_str .. "\tis seeded"

		local ice_depth = average_temp * -0.25 * open_issues.rainfall_contrib_to_ice_depth(jan_rainfall, jul_rainfall)
		if ice_depth > 0 then
			glacial_seed[ti] = true
			ice_flow[ti] = ice_depth
		else
			glacial_seed[ti] = false
		end
		-- logger:log(log_str)
	end)
end

---@param world World
---@param age_type age_types
local function process_age(world, age_type)
	local is_ice_age = age_type == AGE_TYPES.ice_age

	create_glacial_start_locations(world, is_ice_age)
end

function gm.run(world)
	--* Before we even set seeds, we need to construct temp waterbodies to determine which ones are large, and which ones are small. Ocean waterbodies 
	--* of a sufficient volume will have heat exchanging capacity and act as hard barriers for glacial expansion. Smaller waterbodies can simply 
	--* be elligible to be seeds but have "stricter threshold."
	--* Need boolean to see if part of waterbody. Need logic variable integer to represent "size of waterbody."

	-- 2024.07.07: Above comment might not be relevant. Waterbodies are already defined by gen-initial-waterbodies and we will attempt to use them here instead of re-generating them.

	glacial_seed = world.tmp_bool_1
	ice_flow = world.tmp_float_2
	ice_moved = world.tmp_float_3
	distance_from_edge = world.tmp_int_1

	world:fill_ffi_array(glacial_seed, false)
	world:fill_ffi_array(ice_flow, 0)
	world:fill_ffi_array(ice_moved, 0)

	process_age(world, AGE_TYPES.ice_age)
	process_age(world, AGE_TYPES.game_age)
end

return gm