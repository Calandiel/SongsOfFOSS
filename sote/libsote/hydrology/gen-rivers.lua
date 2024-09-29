local rivers = {}

local world

local open_issues = require "libsote.hydrology.open-issues"

local logger = require("libsote.debug-loggers").get_rivers_logger("d:/temp")

local prof = require "libsote.profiling-helper"
local prof_prefix = "[gen-dynamic-lakes]"
local function run_with_profiling(func, log_txt)
	prof.run_with_profiling(func, prof_prefix, log_txt)
end

local initial_candidates = {}
local sorted_candidates = {}

local stored_bodies = {}

local function construct_start_locations()
	--* Here we are iterating along the coast of each endoreic lake and ocean to find the start tile of rivers
	world:for_each_waterbody(function(wb)
		if not wb:is_valid() then return end

		if wb.type == wb.TYPES.ocean or wb.type == wb.TYPES.saltwater_lake or wb.type == wb.TYPES.freshwater_lake then
			wb:for_each_tile_in_perimeter(function(ti)
				if world.water_movement[ti] >= 6000 then
					table.insert(initial_candidates, ti)
					-- logger:log(ti .. " - " .. wb.id .. ": " .. world.water_movement[ti])
				end
			end)
		end

		--* Setting all tiles inside of a waterbody to 0 watermovement since they are now submerged
		wb:for_each_tile(function(ti)
			world.water_movement[ti] = 0
		end)
	end)
end

local function process_drainage_basins(coast_ti)
	if world:is_tile_waterbody_valid(coast_ti) then return end

	local wb = world:create_new_waterbody_from_tile(coast_ti)
	wb.type = wb.TYPES.river

	local old_layer = {}
	local new_layer = {}
	table.insert(old_layer, coast_ti)
	local num_tiles = #old_layer

	while num_tiles > 0 do
		--* At some point we will need to run a check which evaluated whether we have run into a freshwater lake
		for _, ti in ipairs(old_layer) do
			world:for_each_neighbor(ti, function(nti)
				local nwb = world:get_waterbody_by_tile(nti)

				if not world:is_tile_waterbody_valid(nti) then
					if world.water_movement[nti] > 2000 and world:true_elevation_for_waterflow(nti) > world:true_elevation_for_waterflow(ti) then
						world:add_tile_to_waterbody(wb, nti)
						table.insert(new_layer, nti)
					end
				elseif nwb.id ~= wb.id and nwb.type == wb.TYPES.freshwater_lake then --* Freshwater lakes get tiles IDs, but don't get added to the list of tiles in the drainage basin
					stored_bodies[nti] = nwb.id
					world:reassign_tile_to_waterbody(nti, wb)
					nwb.basin_id = wb.id
					table.insert(new_layer, nti)
				else
					--* ?????
				end
			end)
		end

		old_layer = {}
		for _, ti in ipairs(new_layer) do
			table.insert(old_layer, ti)
		end
		new_layer = {}
		num_tiles = #old_layer
	end
end

local function construct_drainage_basins()
	for i = 0, #initial_candidates - 1 do
		local coast_ti = initial_candidates[sorted_candidates[i] + 1]
		logger:log(coast_ti .. ": " .. world:true_elevation_for_waterflow(coast_ti))
		process_drainage_basins(coast_ti)
	end
end

local function tag_and_prep_all_tributaries()
	initial_candidates = {}
	sorted_candidates = {}
end

function rivers.run(world_obj)
	world = world_obj

	run_with_profiling(function() construct_start_locations() end, "construct_start_locations")
	run_with_profiling(function()
		sorted_candidates = require("libsote.heap-sort").heap_sort_indices(
			function(i) return world:true_elevation_for_waterflow(initial_candidates[i + 1]) end,
			nil,
			#initial_candidates,
			false
		)
	end, "sort_lowest_elevation_to_highest")
	run_with_profiling(function() construct_drainage_basins() end, "construct_drainage_basins")
	run_with_profiling(function() tag_and_prep_all_tributaries() end, "tag_and_prep_all_tributaries")
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
