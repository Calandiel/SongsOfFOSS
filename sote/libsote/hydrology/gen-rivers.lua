local rivers = {}

local world

local waterbody = require "libsote.hydrology.waterbody"

local enable_debug = false
-- local logger = require("libsote.debug-loggers").get_rivers_logger("d:/temp")

local prof = require "libsote.profiling-helper"
local prof_prefix = "[gen-rivers]"
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

-- local function set_waterbodies_to_debug(channel)
-- 	world:for_each_waterbody(function(wb)
-- 		wb:for_each_tile(function(ti)
-- 			if wb.type == wb.TYPES.river then
-- 				world:set_debug_rgba(channel, ti, 173, 216, 230, 255)
-- 			elseif wb.type == wb.TYPES.freshwater_lake then
-- 				world:set_debug_rgba(channel, ti, 0, 255, 0, 255)
-- 			elseif wb.type == wb.TYPES.saltwater_lake then
-- 				world:set_debug_rgba(channel, ti, 0, 255, 255, 255)
-- 			elseif wb.type == wb.TYPES.ocean then
-- 				world:set_debug_rgba(channel, ti, 0, 0, 255, 255)
-- 			end
-- 		end)
-- 	end)
-- end

local function construct_start_locations()
	--* Here we are iterating along the coast of each endoreic lake and ocean to find the start tile of rivers
	world:for_each_waterbody(function(wb)
		if wb:is_lake_or_ocean() then
			for ti, _ in pairs(wb.perimeter) do
				if world.water_movement[ti] >= 6000 then
					table.insert(initial_candidates, ti)
				end
			end
		end

		--* Setting all tiles inside of a waterbody to 0 watermovement since they are now submerged
		for _, ti in ipairs(wb.tiles) do
			world.water_movement[ti] = 0
		end
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
			local true_elev = world.true_elevation[ti]

			for i = 0, world:neighbors_count(ti) - 1 do
				local nti = world.neighbors[ti * 6 + i]
				local nwb = world:get_waterbody_by_tile(nti)

				if not world:is_tile_waterbody_valid(nti) then
					if world.water_movement[nti] > 2000 and world.true_elevation[nti] > true_elev then
						world:add_tile_to_waterbody(nti, wb)
						table.insert(new_layer, nti)
					end
				elseif nwb.id ~= wb.id and nwb.type == nwb.TYPES.freshwater_lake then --* Freshwater lakes get tiles IDs, but don't get added to the list of tiles in the drainage basin
					stored_bodies[nti] = nwb
					world:reassign_tile_to_waterbody(nti, wb)
					nwb.basin = wb
					table.insert(new_layer, nti)
				else
					--* ?????
				end
			end
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

local function find_path_using_waterbodies(ti, wb)
	local true_elev = world.true_elevation[ti]
	local lowest_elev = 100000
	local lowest_nti = -1

	for i = 0, world:neighbors_count(ti) - 1 do --* Here we count candidates and determine who has the lowest elevation
		local nti = world.neighbors[ti * 6 + i]
		local nwb = world:get_waterbody_by_tile(nti)
		if not nwb or not nwb:is_valid() then goto cont_loop1 end

		local actual_neigh_elev = world.true_elevation[nti]

		local is_freshwater_lake_with_standing_water = false
		local swb = stored_bodies[nti]
		if swb and swb.water_level > 0 then --* we need to consider the level of the standing water body if we happen to bump into it
			is_freshwater_lake_with_standing_water = true
			actual_neigh_elev = swb.water_level
		end

		if actual_neigh_elev >= true_elev then goto cont_loop1 end

		if is_freshwater_lake_with_standing_water and swb.lowest_shore_tile ~= ti then
			lowest_nti = swb.lowest_shore_tile
		elseif nwb.id == wb.id and world.water_movement[nti] >= 2000 and lowest_elev > actual_neigh_elev then
			lowest_elev = actual_neigh_elev
			lowest_nti = nti
		end

		::cont_loop1::
	end

	return lowest_nti ~= -1, lowest_nti
end

local function tag_and_prep_all_tributaries()
	initial_candidates = {}
	sorted_candidates = {}

	world:for_each_tile(function(ti)
		if world.water_movement[ti] < 6000 or world.ice[ti] > 0 then return end

		local wb = world:get_waterbody_by_tile(ti)
		if not wb or not wb:is_valid() then return end

		local ellibigle_candidate = true
		for i = 0, world:neighbors_count(ti) - 1 do --* Determine elligible candidates for headwaters
			local nti = world.neighbors[ti * 6 + i]
			local nwb = world:get_waterbody_by_tile(nti)
			if not nwb or not nwb:is_valid() then goto cont_loop2 end

			if nwb.id == wb.id and world.water_movement[nti] >= 6000 and world.true_elevation[nti] > world.true_elevation[ti] then
				ellibigle_candidate = false
			end

			::cont_loop2::
		end

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
	sorted_candidates = require("libsote.heap-sort").heap_sort_indices_with_lambdas2(
		function(i) return world.true_elevation[initial_candidates[i + 1]] end,
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
			found_path, ti = find_path_using_waterbodies(ti, wb)
		end

		::continue1::
	end
end

local function kill_old_basins()
	world:for_each_waterbody(function(wb) --* Kill old drainage basin rivers and convert their members to a logic variable
		if wb.type == wb.TYPES.river then --* Kill old rivers
			for _, ti in ipairs(wb.tiles) do
				watershed[ti] = wb
			end
			world:kill_waterbody(wb)
		elseif wb.type == wb.TYPES.ocean or wb.type == wb.TYPES.saltwater_lake then --* Prep standing water body variables for next phase
			for _, ti in ipairs(wb.tiles) do
				fork_count[ti] = 1000000
				true_river[ti] = true
			end
		else
			--* ???
		end
	end)
end

local function find_path_using_watershed(ti, wb)
	local true_elev = world.true_elevation[ti]
	local lowest_elevation = 100000
	local lowest_nti = -1

	for i = 0, world:neighbors_count(ti) - 1 do --* Here we count candidates and determine who has the lowest elevation. Lowest elevation neighbor will be next tile in the path
		local nti = world.neighbors[ti * 6 + i]

		local actual_neigh_elev = world.true_elevation[nti] --* Will function as either the elevation of the tile or the water level of the tile (if it is a lake)

		local is_freshwater_lake_with_standing_water = false
		local swb = stored_bodies[nti]
		if swb and swb.water_level > 0 then --* Then we've bumped into a lake and we need to push the water to the drain tile of the lake
			is_freshwater_lake_with_standing_water = true
			actual_neigh_elev = swb.water_level
		end

		if actual_neigh_elev >= true_elev then goto cont_loop3 end

		local nwb = swb or watershed[nti] or world:get_waterbody_by_tile(nti)
		if not nwb then goto cont_loop3 end

		if is_freshwater_lake_with_standing_water and swb.lowest_shore_tile ~= ti then
			--* We need to terminate expansion and start the next tributary on the drain tile
			lowest_nti = swb.lowest_shore_tile
		elseif nwb.type == nwb.TYPES.saltwater_lake or nwb.type == nwb.TYPES.ocean then -- found river end
			lowest_elevation = actual_neigh_elev
			lowest_nti = nti
		elseif nwb.id == wb.id and world.water_movement[nti] >= 2000 and lowest_elevation > actual_neigh_elev then
			lowest_elevation = actual_neigh_elev
			lowest_nti = nti
		end

		::cont_loop3::
	end

	return lowest_nti
end

local function process_tributary(ti, wb, members)
	true_river[ti] = true --* Set as true river so it can never be counted again as a waterbody member
	table.insert(members, ti)

	local lowest_nti = find_path_using_watershed(ti, wb)
	if lowest_nti == -1 then return false, -1 end

	--* If greater than -1, it implies we actually have a lower neighbor, so therefore we need to check if it is a true river

	--* We also need to check to see if it is part of the same tributary as well.
	if fork_count[lowest_nti] == fork_count[ti] then return true, lowest_nti end

	--* We need to terminate expansion for this tributary, and construct a waterbody for the tributary using the list we created earlier
	local new_tributary_wb = world:create_waterbody(waterbody.TYPES.river)
	new_tributary_wb.tmp_float_1 = 0
	new_tributary_wb.water_level = 0
	for _, trib_ti in ipairs(members) do
		world:add_tile_to_waterbody(trib_ti, new_tributary_wb)
	end
	while #members > 0 do table.remove(members) end

	if true_river[lowest_nti] then return false, -1 end

	return true, lowest_nti
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

local function reassign_proper_tile_waterbody_to_lakes()
	world:for_each_waterbody(function(wb)
		if wb.type == wb.TYPES.freshwater_lake then
			for _, ti in ipairs(wb.tiles) do
				world:reassign_tile_to_waterbody(ti, wb)
				watershed[ti] = wb
			end
		end

		if wb.type == wb.TYPES.river then
			local members_under_ice = 0
			local total_members = wb:size()
			for _, ti in ipairs(wb.tiles) do
				local ice = world.ice[ti]
				if ice == 0 then goto cont_loop1 end

				if ice > 1000 then members_under_ice = members_under_ice + 2
				elseif ice > 500 then members_under_ice = members_under_ice + 1.75
				elseif ice > 200 then members_under_ice = members_under_ice + 1.5
				elseif ice > 100 then members_under_ice = members_under_ice + 1.25
				elseif ice > 50 then members_under_ice = members_under_ice + 1
				elseif ice > 25 then members_under_ice = members_under_ice + 0.75
				else members_under_ice = members_under_ice + 0.51
				end

				::cont_loop1::
			end
			if members_under_ice / total_members > 0.5 then
				world:kill_waterbody(wb)
			end
		end
	end)
end

local function connect_all_waterbodies()
	world:for_each_waterbody(function(wb)
		if wb.type == wb.TYPES.river then
			--* Check first tile first to determine whether there are waterbody sources feeding into the current waterbody
			local first_ti = wb.tiles[1]
			local first_tile_elev = world.true_elevation[first_ti]
			for i = 0, world:neighbors_count(first_ti) - 1 do
				local nti = world.neighbors[first_ti * 6 + i]
				local nwb = world:get_waterbody_by_tile(nti)
				if not nwb or not nwb:is_valid() then goto cont_loop4 end

				if world.true_elevation[nti] > first_tile_elev then
					wb:add_source(nwb)
				end

				::cont_loop4::
			end
			wb.lake_open = #wb.source > 0 and true or false --* Open means we're getting water from another waterbody and not just the ambient environment

			--* Check last tile to determine the waterbodies that are being fed by the current waterbody. EVERY river should feed somewhere
			local lowest_elevation = 100000
			local lowest_wb = nil
			local last_ti = wb.tiles[#wb.tiles]
			for i = 0, world:neighbors_count(last_ti) - 1 do
				local nti = world.neighbors[last_ti * 6 + i]
				local nwb = world:get_waterbody_by_tile(nti)
				if not nwb or not nwb:is_valid() then goto cont_loop5 end

				local elev_to_check = world.true_elevation[nti]

				if nwb:is_lake_or_ocean() then
					elev_to_check = nwb.water_level
				end

				if elev_to_check < lowest_elevation then
					lowest_elevation = elev_to_check
					lowest_wb = nwb
				end

				::cont_loop5::
			end
			if lowest_wb == nil then error("River " .. wb.id .. " does not feed into a waterbody") end
			wb.drain = lowest_wb

			if wb.drain.type == wb.TYPES.freshwater_lake then
				local lowest_shore_tile_wb = world:get_waterbody_by_tile(wb.drain.lowest_shore_tile)
				if lowest_shore_tile_wb and lowest_shore_tile_wb:is_valid() then
					wb.drain = lowest_shore_tile_wb
				end
			end
		end

		if wb:is_lake_or_ocean() then
			--* Receive water from sources
			for ti, _ in pairs(wb.perimeter) do
				--* Check for higher elevation than waterlevel... check for waterbody ID to make sure it is not zero and not different.
				if world.true_elevation[ti] <= wb.water_level then goto cont_loop2 end

				--* If criteria is met, add as source
				local nwb = world:get_waterbody_by_tile(ti)
				if not nwb or not nwb:is_valid() then goto cont_loop2 end

				wb:add_source(nwb)

				::cont_loop2::
			end
		end

		if wb.type == wb.TYPES.freshwater_lake then
			local lowest_shore_tile_wb = world:get_waterbody_by_tile(wb.lowest_shore_tile)
			if lowest_shore_tile_wb and lowest_shore_tile_wb:is_valid() then --* If the drain tile is a waterbody...
				wb.drain = lowest_shore_tile_wb
				lowest_shore_tile_wb:add_source(wb)
			else
				wb.lake_open = false
				wb.drain = nil
			end

			if lowest_shore_tile_wb and lowest_shore_tile_wb.id == wb.id then
				wb.lake_open = false
				wb.drain = nil
			end
		end

		-- logger:log(wb.id .. ", " .. wb.type .. ", " .. tostring(wb.lake_open) .. ": " .. (wb.drain and wb.drain.id or "nil"))
	end)
end

local function assigning_drainage_basin_value_to_rivers()
	world:for_each_waterbody(function(wb)
		if wb.type ~= wb.TYPES.river then return end
		wb.basin = watershed[wb.tiles[1]]
	end)
end

local function construct_wetlands()
	world:fill_ffi_array(true_river, false)

	--* Identify Wetlands
	world:for_each_tile(function(ti)
		local wb = world:get_waterbody_by_tile(ti)
		if wb and wb:is_valid() then return end

		if world.water_movement[ti] <= 2000 then return end

		local points_to_check = 0
		for i = 0, world:neighbors_count(ti) - 1 do
			local nti = world.neighbors[ti * 6 + i]
			local nwb = world:get_waterbody_by_tile(nti)
			if nwb and nwb:is_valid() or world.water_movement[nti] > 2000 then
				points_to_check = points_to_check + 1
			end
		end

		if points_to_check >= 3 then
			true_river[ti] = true
		end
	end)

	--* Construct wetlands as actual waterbodies
	world:for_each_tile(function(ti)
		if not true_river[ti] or world.ice[ti] > 0 then return end

		local wb = world:get_waterbody_by_tile(ti)
		if wb and wb:is_valid() then return end

		--* If elligible wetland but not already assigned to a waterbody
		wb = world:create_waterbody_from_tile(ti, waterbody.TYPES.wetland)
		wb.lake_open = true

		local old_layer = {}
		local new_layer = {}

		table.insert(old_layer, ti)
		local tiles_to_check = 1

		while tiles_to_check > 0 do
			for _, expansion_ti in ipairs(old_layer) do
				for i = 0, world:neighbors_count(expansion_ti) - 1 do
					local nti = world.neighbors[expansion_ti * 6 + i]

					if not true_river[nti] or world.ice[nti] > 0 then goto cont_loop6 end

					local nwb = world:get_waterbody_by_tile(nti)
					if nwb and nwb:is_valid() then goto cont_loop6 end

					world:add_tile_to_waterbody(nti, wb)
					table.insert(new_layer, nti)

					::cont_loop6::
				end
			end

			old_layer = {}
			for _, new_ti in ipairs(new_layer) do
				table.insert(old_layer, new_ti)
			end
			new_layer = {}
			tiles_to_check = #old_layer
		end
	end)
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

	run_with_profiling(function() world:update_true_elevation_for_waterflow() end, "update_true_elevation_for_waterflow")
	run_with_profiling(function() construct_start_locations() end, "construct_start_locations")
	run_with_profiling(function()
		sorted_candidates = require("libsote.heap-sort").heap_sort_indices_with_lambdas2(
			function(i) return world.true_elevation[initial_candidates[i + 1]] end,
			nil,
			#initial_candidates,
			false
		)
	end, "sort_lowest_elevation_to_highest")
	run_with_profiling(function() construct_drainage_basins() end, "construct_drainage_basins")
	run_with_profiling(function() tag_and_prep_all_tributaries() end, "tag_and_prep_all_tributaries")
	run_with_profiling(function() kill_old_basins() end, "kill_old_basins")
	run_with_profiling(function() split_river_up_into_tributaries() end, "split_river_up_into_tributaries")
	run_with_profiling(function() reassign_proper_tile_waterbody_to_lakes() end, "reassign_proper_tile_waterbody_to_lakes")
	run_with_profiling(function() connect_all_waterbodies() end, "connect_all_waterbodies")
	run_with_profiling(function() assigning_drainage_basin_value_to_rivers() end, "assigning_drainage_basin_value_to_rivers")
	run_with_profiling(function() construct_wetlands() end, "construct_wetlands")
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
