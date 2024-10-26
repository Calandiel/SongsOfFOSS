local gvc = {}

local ROCK_TYPES = require "libsote.rock-type".TYPES
local rq = require "libsote.rock-qualities"

local enable_debug = false

local world
local rng
local already_checked
local distance_factor
local slope_retention_factor

local MAX_ITERATIONS = 35
local VOLCANO_SPLOOGE_TUNER = 50 --* How much ash volcanos splooge

local function expand_from_tile(vti, silt_qty, mineral_qty)
	local old_layer = {}
	local new_layer = {}
	local all_influenced = {}

	table.insert(old_layer, vti)
	table.insert(all_influenced, vti)

	local expansion_iterations = MAX_ITERATIONS

	--* Phase where we expand outward and calculate all influenced tiles
	while expansion_iterations > 0 do
		expansion_iterations = expansion_iterations - 1

		for _, ti in ipairs(old_layer) do
			world:for_each_neighbor(ti, function(nti)
				if already_checked[nti] then return end

				if rng:random_int_max(100) >= 50 then
					table.insert(new_layer, ti)
					return
				end

				table.insert(new_layer, nti)
				table.insert(all_influenced, nti)
				already_checked[nti] = true
				distance_factor[nti] = expansion_iterations
			end)
		end

		old_layer = {}
		for _, ti in ipairs(new_layer) do
			table.insert(old_layer, ti)
		end
		new_layer = {}
	end

	--* At end of loop, loop through all effected tiles and apply silt
	for _, ti in ipairs(all_influenced) do
		already_checked[ti] = false

		if not world.is_land[ti] then goto continue end

		local distance_multiplier = 100 * distance_factor[ti] / 35
		distance_factor[ti] = 0

		local local_silt_produced = (silt_qty * VOLCANO_SPLOOGE_TUNER * distance_multiplier * slope_retention_factor[ti]) / 100; --* Actual silt produced here. Will also be used to inform volume of mineral nutrient

		world.silt[ti] = world.silt[ti] + math.floor(local_silt_produced)
		world.mineral_richness[ti] = world.mineral_richness[ti] + math.floor(mineral_qty * local_silt_produced)

		-- world:set_debug_rgba(1, ti, 255, 255, 0, 255)

		::continue::
	end
end

local function gen_volcanic_silt(volcano_tiles, silt_qty, mineral_qty)
	--* Iterate through every volcanic tile, and splode
	for _, ti in ipairs(volcano_tiles) do
		expand_from_tile(ti, silt_qty, mineral_qty)
	end
end

function gvc.run(world_obj)
	world = world_obj
	rng = world.rng
	already_checked = world.tmp_bool_1
	distance_factor = world.tmp_int_1
	slope_retention_factor = world.carry_float_1

	if require("libsote.debug-control-panel").soils.align_rng then
		rng = require("libsote.randomness"):new(world.seed + 19832)
	end

	world:fill_ffi_array(already_checked, false)
	world:fill_ffi_array(distance_factor, 0)

	if enable_debug then
		world:adjust_debug_channels(1)
		world:reset_debug_all()
	end

	local mixed_volcano_tiles = {}
	local basic_volcano_tiles = {}

	--* Generating lists for both types of volcanoes that will participate
	world:for_each_tile(function(ti)
		local rock_type = world.rock_type[ti]

		if rock_type == ROCK_TYPES.mixed_volcanics then
			if rng:random_int_max(100) < 1 then table.insert(mixed_volcano_tiles, ti) end
		elseif rock_type == ROCK_TYPES.basic_volcanics then
			if rng:random_int_max(100) < 1 then table.insert(basic_volcano_tiles, ti) end
		end
	end)

	gen_volcanic_silt(mixed_volcano_tiles, 2, rq.mineral_nutrients(ROCK_TYPES.mixed_volcanics) / 100)
	gen_volcanic_silt(basic_volcano_tiles, 1, rq.mineral_nutrients(ROCK_TYPES.basic_volcanics) / 100)
end

return gvc