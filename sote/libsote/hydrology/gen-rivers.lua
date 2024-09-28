local rivers = {}

local world

local logger = require("libsote.debug-loggers").get_rivers_logger("d:/temp")

local prof = require "libsote.profiling-helper"
local prof_prefix = "[gen-dynamic-lakes]"
local function run_with_profiling(func, log_txt)
	prof.run_with_profiling(func, prof_prefix, log_txt)
end

local intitial_candidates = {}

local function construct_start_locations()
	--* Here we are iterating along the coast of each endoreic lake and ocean to find the start tile of rivers
	world:for_each_waterbody(function(wb)
		if not wb:is_valid() then return end

		if wb.type == wb.TYPES.ocean or wb.type == wb.TYPES.saltwater_lake or wb.type == wb.TYPES.freshwater_lake then
			wb:for_each_tile_in_perimeter(function(ti)
				if world.water_movement[ti] >= 6000 then
					table.insert(intitial_candidates, ti)
				end
			end)
		end

		--* Setting all tiles inside of a waterbody to 0 watermovement since they are now submerged
		wb:for_each_tile(function(ti)
			world.water_movement[ti] = 0
		end)
	end)

	logger:log("Start locations: " .. #intitial_candidates)
end

function rivers.run(world_obj)
	world = world_obj

	run_with_profiling(function() construct_start_locations() end, "construct_start_locations")
end

return rivers

--* Make wetlands or create variables for rivers *--
--*
--* Major types of wetlands we need to represent:
--*  Riverine
--*  Coastal
--*  Lake skirt



--*  Nominal Plan? *--
--* Okay, so we may want to generate basic soil data from bedrock weathering. We'll need a bit of global random variation layers for each sediment grain size.
--* Sand, Silt, Clay... we may want to generate them first from the bedrock based on weathering rates, then transport them by water and *possibly* wind?
--* Need weathering sources... need glacial and wind blown sources (particularly with silt), and need alluvial sources.
--* 
--* Theoretically we can generate the values of both of the first two in either order and aggregate them both... but the alluvial source should pull soil from upstream and
--* deposit it down stream so we need the first two done.
--*
--* Generating soil texture material from bedrock is going to depend on local weathering conditions, but also the age of the rock. We'll also need a variability matrix similar
--* to our randQuality matrix, but possibly for each type of texture? We can have a clay / sand slider variable and then a silt abundance variable. Then we use our last
--* 3 logic variables for the purpose of transporting texture.
--* We'll need to transport organics and mineral nutrients in a later job so that we're not juggling too many variables in the same job.
--*
--* Step 1: Generating variability matrix. Go back to C++ code for some inspiration.
