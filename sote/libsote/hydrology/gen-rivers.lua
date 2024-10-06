local rivers = {}

local world

local waterbody = require "libsote.hydrology.waterbody"
-- local open_issues = require "libsote.hydrology.open-issues"

local enable_debug = true
local logger = require("libsote.debug-loggers").get_rivers_logger("d:/temp")

local prof = require "libsote.profiling-helper"
local prof_prefix = "[gen-dynamic-lakes]"
local function run_with_profiling(func, log_txt)
	prof.run_with_profiling(func, prof_prefix, log_txt)
end

local initial_candidates = {}
local sorted_candidates = {}

local stored_bodies = {} -- key: tile index, value: freshwater lake waterbody
local watershed = {} -- key: tile index, value: river waterbody
local true_lake
local true_river
local fork_count

local function set_waterbodies_to_debug(channel)
	world:for_each_waterbody(function(wb)
		wb:for_each_tile(function(ti)
			if wb.type == wb.TYPES.river then
				world:set_debug_rgba(channel, ti, 173, 216, 230, 255)
			elseif wb.type == wb.TYPES.freshwater_lake then
				world:set_debug_rgba(channel, ti, 0, 255, 0, 255)
			elseif wb.type == wb.TYPES.saltwater_lake then
				world:set_debug_rgba(channel, ti, 0, 255, 255, 255)
			elseif wb.type == wb.TYPES.ocean then
				world:set_debug_rgba(channel, ti, 0, 0, 255, 255)
			end
		end)
	end)
end

local function construct_start_locations()
	--* Here we are iterating along the coast of each endoreic lake and ocean to find the start tile of rivers
	world:for_each_waterbody(function(wb)
		if wb.type == wb.TYPES.ocean or wb.type == wb.TYPES.saltwater_lake or wb.type == wb.TYPES.freshwater_lake then
			wb:for_each_tile_in_perimeter(function(ti)
				if world.water_movement[ti] >= 6000 then
					table.insert(initial_candidates, ti)
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

	local wb = world:create_waterbody_from_tile(coast_ti, waterbody.TYPES.river)

	local old_layer = {}
	local new_layer = {}

	table.insert(old_layer, coast_ti)
	local num_tiles = 1

	while num_tiles > 0 do
		--* At some point we will need to run a check which evaluated whether we have run into a freshwater lake
		for _, ti in ipairs(old_layer) do
			local true_elev = world:true_elevation_for_waterflow(ti)

			world:for_each_neighbor(ti, function(nti)
				local nwb = world:get_waterbody_by_tile(nti)

				if not world:is_tile_waterbody_valid(nti) then
					if world.water_movement[nti] > 2000 and world:true_elevation_for_waterflow(nti) > true_elev then
						world:add_tile_to_waterbody(wb, nti)
						table.insert(new_layer, nti)
					end
				elseif nwb.id ~= wb.id and nwb.type == nwb.TYPES.freshwater_lake then --* Freshwater lakes get tiles IDs, but don't get added to the list of tiles in the drainage basin
					stored_bodies[nti] = nwb
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
		process_drainage_basins(coast_ti)
	end
end

local function build_path_using_waterbodies(ti, wb)
	local true_elev = world:true_elevation_for_waterflow(ti)
	local lowest_elevation = 100000
	local lowest_elevation_id = -1

	world:for_each_neighbor(ti, function(nti) --* Here we count candidates and determine who has the lowest elevation
		local nwb = world:get_waterbody_by_tile(nti)
		if not nwb or not nwb:is_valid() then return end

		local actual_neigh_elev = world:true_elevation_for_waterflow(nti)

		local is_freshwater_lake_with_standing_water = false
		local swb = stored_bodies[nti]
		if swb and swb.water_level > 0 then --* we need to consider the level of the standing water body if we happen to bump into it
			is_freshwater_lake_with_standing_water = true
			actual_neigh_elev = swb.water_level
		end

		if actual_neigh_elev >= true_elev then return end

		if is_freshwater_lake_with_standing_water then
			lowest_elevation_id = swb.lowest_shore_tile
		elseif nwb.id == wb.id and world.water_movement[nti] >= 2000 and lowest_elevation > actual_neigh_elev then
			lowest_elevation = actual_neigh_elev
			lowest_elevation_id = nti
		end
	end)

	return lowest_elevation_id
end

local function tag_and_prep_all_tributaries()
	initial_candidates = {}
	sorted_candidates = {}

	world:for_each_tile(function(ti)
		if world.water_movement[ti] < 6000 or world.ice[ti] > 0 then return end

		local wb = world:get_waterbody_by_tile(ti)
		if not wb or not wb:is_valid() then return end

		local ellibigle_candidate = true
		world:for_each_neighbor(ti, function(nti) --* Determine elligible candidates for headwaters
			local nwb = world:get_waterbody_by_tile(nti)
			if not nwb or not nwb:is_valid() then return end

			if nwb.id == wb.id and world.water_movement[nti] >= 6000 and world:true_elevation_for_waterflow(nti) > world:true_elevation_for_waterflow(ti) then
				ellibigle_candidate = false
			end
		end)

		if ellibigle_candidate then
			table.insert(initial_candidates, ti)
		end
	end)

	--* Now we can just have a second loop which goes through all freshwater lakes with a drain tile and we just add that drain tile to the candidate list
	--* and allow it to flow toward the ocean like all the others. That should rectify all of our downstream fork counts on all tributaries.

	world:for_each_waterbody(function(wb)
		if wb.type ~= wb.TYPES.freshwater_lake then return end

		local drain_ti = wb.lowest_shore_tile
		table.insert(initial_candidates, drain_ti)
		true_lake[drain_ti] = true
	end)

	--* Sort candidates by elevation
	sorted_candidates = require("libsote.heap-sort").heap_sort_indices(
		function(i) return world:true_elevation_for_waterflow(initial_candidates[i + 1]) end,
		nil,
		#initial_candidates,
		true
	)

	--* Now we construct a path down from each headwater tributary and we mark every tile as we go down. This method will be used to differentiate different tributaries from one another.
	for i = 0, #initial_candidates - 1 do
		local ti = initial_candidates[sorted_candidates[i] + 1]

		local wb = world:get_waterbody_by_tile(ti)
		if not wb or not wb:is_valid() then goto continue1 end

		--* We need lake drain tiles to be checked as candidates and not over-written
		if fork_count[ti] > 0 and not true_lake[ti] then goto continue1 end

		local found_path = true

		while found_path do
			fork_count[ti] = fork_count[ti] + 1

			local lowest_elevation_id = build_path_using_waterbodies(ti, wb)
			if lowest_elevation_id == -1 then
				found_path = false
			else
				ti = lowest_elevation_id
			end
		end

		::continue1::
	end
end

local function kill_old_basins()
	world:for_each_waterbody(function(wb) --* Kill old drainage basin rivers and convert their members to a logic variable
		if wb.type == wb.TYPES.river then --* Kill old rivers
			wb:for_each_tile(function(ti)
				watershed[ti] = wb
			end)
			world:kill_waterbody(wb)
		elseif wb.type == wb.TYPES.ocean or wb.type == wb.TYPES.saltwater_lake then --* Prep standing water body variables for next phase
			wb:for_each_tile(function(ti)
				fork_count[ti] = 1000000
				true_river[ti] = true
			end)
		else
			--* ???
		end
	end)
end

local function build_path_using_watershed(ti, wb)
	local true_elev = world:true_elevation_for_waterflow(ti)
	local lowest_elevation = 100000
	local lowest_elevation_id = -1

	world:for_each_neighbor(ti, function(nti) --* Here we count candidates and determine who has the lowest elevation. Lowest elevation neighbor will be next tile in the path
		local actual_neigh_elev = world:true_elevation_for_waterflow(nti) --* Will function as either the elevation of the tile or the water level of the tile (if it is a lake)

		local is_freshwater_lake_with_standing_water = false
		local swb = stored_bodies[nti]
		if swb and swb.water_level > 0 then --* Then we've bumped into a lake and we need to push the water to the drain tile of the lake
			is_freshwater_lake_with_standing_water = true
			actual_neigh_elev = swb.water_level
		end

		if actual_neigh_elev >= true_elev then return end

		local nwb = swb or watershed[nti] or world:get_waterbody_by_tile(nti)
		if not nwb then return end

		if is_freshwater_lake_with_standing_water then
			--* We need to terminate expansion and start the next tributary on the drain tile
			lowest_elevation_id = swb.lowest_shore_tile
		elseif nwb.type == nwb.TYPES.saltwater_lake or nwb.type == nwb.TYPES.ocean then -- found river end
			lowest_elevation = actual_neigh_elev
			lowest_elevation_id = nti
		elseif nwb.id == wb.id and world.water_movement[nti] >= 2000 and lowest_elevation > actual_neigh_elev then
			lowest_elevation = actual_neigh_elev
			lowest_elevation_id = nti
		end
	end)

	return lowest_elevation_id
end

local function process_tributary(ti, wb, members)
	true_river[ti] = true --* Set as true river so it can never be counted again as a waterbody member
	table.insert(members, ti)

	local lowest_elevation_id = build_path_using_watershed(ti, wb)
	if lowest_elevation_id == -1 then return false, -1 end

	--* If greater than -1, it implies we actually have a lower neighbor, so therefore we need to check if it is a true river

	--* We also need to check to see if it is part of the same tributary as well.
	if fork_count[lowest_elevation_id] == fork_count[ti] then return true, lowest_elevation_id end

	--* We need to terminate expansion for this tributary, and construct a waterbody for the tributary using the list we created earlier
	local new_tributary_wb = world:create_waterbody(waterbody.TYPES.river)
	new_tributary_wb.tmp_float_1 = 0
	new_tributary_wb.water_level = 0
	for _, trib_ti in ipairs(members) do
		world:add_tile_to_waterbody(new_tributary_wb, trib_ti)
	end
	while #members > 0 do table.remove(members) end

	if true_river[lowest_elevation_id] then return false, -1 end

	return true, lowest_elevation_id
end

local function split_river_up_into_tributaries()
	--* I need to connect all my rivers, lakes, and oceans now...

	for i = 0, #initial_candidates - 1 do
		local ti = initial_candidates[sorted_candidates[i] + 1]

		 --* If the tile has been already turned into a true river, don't bother continuing.
		if true_river[ti] then goto continue2 end

		local wb = watershed[ti]
		if not wb then goto continue2 end

		local tributary_members = {} --* This list will be turned into the members of the river tributary.
		local found_path = true

		while found_path do --* Continue to the ocean or until we hit a tile which has already been turned into a true river
			found_path, ti = process_tributary(ti, wb, tributary_members)
		end

		::continue2::
	end
end

function rivers.run(world_obj)
	world = world_obj
	true_lake = world.tmp_bool_1
	true_river = world.tmp_bool_2
	fork_count = world.tmp_int_1

	world:fill_ffi_array(true_lake, false)
	world:fill_ffi_array(true_river, false)
	world:fill_ffi_array(fork_count, 0)

	if enable_debug then
		world:adjust_debug_channels(1)
		world:reset_debug_all()
	end

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
	run_with_profiling(function() kill_old_basins() end, "kill_old_basins")
	run_with_profiling(function() split_river_up_into_tributaries() end, "split_river_up_into_tributaries")
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
