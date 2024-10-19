local gsd = {}

local wgu = require "libsote.world-gen-utils"
-- local ROCK_TYPES = require "libsote.rock-type".TYPES
-- local rq = require "libsote.rock-qualities"

local enable_debug = true
local logger = require("libsote.debug-loggers").get_soils_logger("d:/temp")

local world
local rng
local potential_dune
local true_water
local permeability

local function process_dune_tile(dti)
end

function gsd.run(world_obj)
	world = world_obj
	potential_dune = world.tmp_bool_2
	true_water = world.tmp_float_2
	permeability = world.tmp_float_3

	rng = world.rng
	local align_rng = require("libsote.debug-control-panel").soils.align_rng
	local preserved_state = nil
	if align_rng then
		preserved_state = rng:get_state()
		rng:set_seed(world.seed + 19832)
	end

	world:fill_ffi_array(potential_dune, false)
	world:fill_ffi_array(true_water, 0)
	world:fill_ffi_array(permeability, 0)

	if enable_debug then
		world:adjust_debug_channels(1)
		world:reset_debug_all()
	end

	--* Let's construct sanddunes in scope, then we can trim and fashion them, then have them disperse their silt. There's no need to
	--* create objects or anything like that out of them since it'll all be temporary

	local dune_start_tiles = {}
	world:for_each_tile(function(ti)
		if not world.is_land[ti] then return end

		--* Calculate "true water"
		--* Have minimum sand standard? May not need this...
		--* We'll set a sanddune threshold and light it up to see what we get, then we can evaluate from there on where to go next
		--* We'll want to evaluate the slope as well to make sure its on relatively flattish land

		local water_movement_contribution = math.max(0, math.sqrt(world.water_movement[ti]) - 10)
		local true_water_calc = world.jan_rainfall[ti] + world.jul_rainfall[ti] + water_movement_contribution
		local wind_factor = world.jan_wind_speed[ti] --*+ world.jul_wind_speed[ti]
		wind_factor = math.min(25, wind_factor)
		wind_factor = ((1 - wind_factor / 25) * 0.65) + 0.35
		permeability[ti] = wgu.permiation_calc_dune(world.sand[ti], world.silt[ti], world.clay[ti])
		true_water[ti] = true_water_calc * permeability[ti] * wind_factor

		if true_water[ti] > 40 then return end

		--* calculate composite
		local average_slope = 0
		local elev = world.elevation[ti]
		world:for_each_neighbor(ti, function(nti) --* Get average slope. Is used to exclude sand dune locations
			local elev_diff = math.abs(elev - world.elevation[nti])
			average_slope = average_slope + elev_diff
		end)
		average_slope = average_slope / world:neighbors_count(ti)

		local sand_dune_composite = true_water[ti] + 30
		local sand_percent = (world.sand[ti] * 100) / (world.sand[ti] + world.silt[ti] + world.clay[ti]) --* Calculate percentage of sand as soil texture
		local sand_factor = 1
		if sand_percent > 55 then sand_factor = sand_factor * 0.5 end
		if sand_percent > 70 then sand_factor = sand_factor * 0.5 end
		if sand_percent > 90 then sand_factor = sand_factor * 0.5 end
		sand_dune_composite = sand_dune_composite * sand_factor

		if sand_dune_composite <= 9 and average_slope < 25 then
			potential_dune[ti] = true
			table.insert(dune_start_tiles, ti)
			world:set_debug_rgba(1, ti, 255, 255, 0, 255)
		end
	end)

	--* Generate "final" dunes which will contribute to silt. We may want to create non-silt producing dunes in areas with sufficient land cover and
	--* rainfall so that we have the kind of grassland dunes that exist in Kansas and the Pannonian Basin

	for _, ti in ipairs(dune_start_tiles) do
		process_dune_tile(ti)
	end

	if align_rng then
		rng:set_state(preserved_state)
	end
end

return gsd