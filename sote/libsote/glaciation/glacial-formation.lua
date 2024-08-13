local gm = {}

-- NOTE 2024.07.06: The comments are close to the original, but may have been edited for clarity and relevance to the current state.
-- In order to distinguish between the original comments and the new ones, the original ones are marked with "--*"

---@enum age_types
local AGE_TYPES = {
	ice_age  = 0,
	game_age = 1
}

-- local logger = require("libsote.debug-loggers").get_glacial_logger("d:/temp")
local open_issues = require "libsote.glaciation.open-issues"
local rock_qualities = require "libsote.rock-qualities"

local prof = require "libsote.profiling-helper"
local prof_prefix = "[glacial-formation]"

local function run_with_profiling(func, log_txt)
	prof.run_with_profiling(func, prof_prefix, log_txt)
end

local world
-- local glacial_seed
local ice_flow
local ice_moved
local texture_material
local material_richness
local distance_from_edge
local invasion_ticker

local old_layer = {}
local new_layer = {}

local glacial_seeds_table = {}
local sorted_glacial_seeds = {}

local already_added = {}
local melt_tiles = {}
local tiles_influenced = {}

local max_distance = 0
local max_ice = 0
local max_ice_moved = 0

local function length(t)
	local count = 0
	for _ in pairs(t) do count = count + 1 end
	return count
end

local function set_debug(channel, ti, r, g, b, a)
	world:set_debug_rgba(channel, ti, r, g, b, a or 255)
end

local function for_each_glacial_seed(callback)
	for ti in pairs(glacial_seeds_table) do
		callback(ti)
	end
end

local function create_glacial_start_locations(is_ice_age)
	local ice_age_factor = 5
	if is_ice_age then ice_age_factor = -10 end --* Makes world colder for ice age

	local seed_threshold = -15 --* -15 for non-Ice Age
	if is_ice_age then seed_threshold = 0 end

	world:for_each_tile(function(ti)
	-- world:for_each_tile_by_elevation_for_waterflow(function(ti, _)
		-- local log_str = "gs: " .. world.colatitude[ti] .. "," .. world.minus_longitude[ti] .. "; " .. world:true_elevation_for_waterflow(ti) .. "; " .. ti .. "\n"

		local waterbody_size = world:get_waterbody_size(ti)

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

		local ice_depth = average_temp * -0.25 * open_issues.rainfall_contrib_to_ice_depth(jan_rainfall, jul_rainfall)
		if ice_depth > 0 then
			-- log_str = log_str .. "\tis seeded\n"
			-- glacial_seed[ti] = true
			glacial_seeds_table[ti] = true
			ice_flow[ti] = ice_depth
			-- log_str = log_str .. "\t" .. average_temp .. ", " .. jan_rainfall .. ", " .. jul_rainfall .. " ---> " .. ice_depth

			-- set_debug(world, ti, 0, 0, 255)
		-- else
		-- 	log_str = log_str .. "\tnot seeded, no ice"
		-- 	glacial_seed[ti] = false
		end
		-- logger:log(log_str)
	end)

	-- local count = 0
	-- world:for_each_tile(function(ti)
	-- 	if glacial_seed[ti] then
	-- 		count = count + 1
	-- 	end
	-- end)
	-- print("Glacial Seeds: " .. length(glacial_seeds_table))
end

local function find_glacial_perimeter()
	old_layer = {}

	-- world:for_each_tile(function(ti)
	-- 	if not glacial_seed[ti] then return end

	-- 	local has_seed_neighbour = false
	-- 	world:for_each_neighbor(ti, function(nti)
	-- 		if glacial_seed[nti] then return end
	-- 		has_seed_neighbour = true
	-- 	end)

	-- 	if has_seed_neighbour then
	-- 		old_layer[ti] = true
	-- 		distance_from_edge[ti] = 1
	-- 	end
	-- end)
	for ti in pairs(glacial_seeds_table) do
		world:for_each_neighbor(ti, function(nti)
			if glacial_seeds_table[nti] then return end

			old_layer[nti] = true
			distance_from_edge[nti] = 1

			-- set_debug(world, nti, 255, 0, 0)
		end)
	end
	-- world:for_each_tile(function(ti)
	-- 	if glacial_seed_table[ti] then return end

	-- 	local has_seed_neighbour = false
	-- 	world:for_each_neighbor(ti, function(nti)
	-- 		if glacial_seed_table[nti] == nil then return end
	-- 		has_seed_neighbour = true
	-- 	end)

	-- 	if has_seed_neighbour then
	-- 		old_layer[ti] = true
	-- 		distance_from_edge[ti] = 1
	-- 		set_debug(world, ti, 255, 0, 0)
	-- 	end
	-- end)
end

local function find_distance_of_each_glacier_tile_from_edge()
	local elevation_factor = 500
	local base_expansion = 100
	local expansion_threshold = 300

	new_layer = {}

	local expansion_ticker = 1 --* Keeps track of how many loops we've done.
	local num_tiles = length(old_layer)

	while num_tiles > 0 do
		-- is it ok to increment this here? or should it be at the end of the loop?
		expansion_ticker = expansion_ticker + 1

		--* Expanding layer
		for oti in pairs(old_layer) do
			--* We want each tile in oldLayer to "attack" unoccupied tiles, and add some base value * depression factor which = elevation
			--* Once threshold is met we add the tile to newLayer

			local attacked_neighbor = false

			world:for_each_neighbor(oti, function(nti)
				if glacial_seeds_table[nti] == nil or distance_from_edge[nti] > 0 then return end

				attacked_neighbor = true

				local invasion_modifier = open_issues.true_elevation(world, nti)
				invasion_modifier = math.max(invasion_modifier, 500)
				invasion_modifier = invasion_modifier / elevation_factor

				invasion_ticker[nti] = invasion_ticker[nti] + math.floor(base_expansion / invasion_modifier)
				if invasion_ticker[nti] > expansion_threshold then
					new_layer[nti] = true
					distance_from_edge[nti] = expansion_ticker
					-- set_debug(world, nti, 255, 255, 0)
				end
			end)

			if attacked_neighbor then
				new_layer[oti] = true
				-- set_debug(world, oti, 255, 255, 0)
			end
		end

		--* The tiles we added this round get checked next round in the "old layer". The new becomes the old
		old_layer = {}
		for key in pairs(new_layer) do
			old_layer[key] = true
		end
		new_layer = {}

		num_tiles = length(old_layer)
	end

	max_distance = expansion_ticker

	-- print("Expansion Ticker: " .. expansion_ticker)
	-- world:for_each_tile(function(ti)
	-- 	if distance_from_edge[ti] == 0 then return end
	-- 	local fraction = distance_from_edge[ti] / max_distance
	-- 	local red = fraction * 255
	-- 	local blue = (1 - fraction) * 255
	-- 	set_debug(world, ti, red, 0, blue)
	-- end)
end

local function calculate_initial_ice_depth()
	-- local max_ice = 0
	world:for_each_tile(function(ti)
	-- world:for_each_tile_by_elevation_for_waterflow(function(ti, _)
		if glacial_seeds_table[ti] == nil then return end

		-- local log_str = "gs: " .. world.colatitude[ti] .. "," .. world.minus_longitude[ti] .. "; " .. world:true_elevation_for_waterflow(ti) .. "; " .. ti .. "\n"
		-- log_str = log_str .. "\tice_flow: " .. ice_flow[ti] .. "; distance_from_edge: " .. distance_from_edge[ti]

		open_issues.calculate_initial_ice_depth(world, ti)

		-- log_str = log_str .. " ---> " .. ice_flow[ti]
		-- logger:log(log_str)
		-- max_ice = math.max(max_ice, ice_flow[ti])
	end)

	-- world:for_each_tile(function(ti)
	-- 	set_debug(world, ti, 0, 0, 0)
	-- 	if ice_flow[ti] == 0 then return end
	-- 	local fraction = ice_flow[ti] / max_ice
	-- 	local red = fraction * 255
	-- 	local blue = (1 - fraction) * 255
	-- 	set_debug(world, ti, red, 0, blue)
	-- end)
end

local function sort_glacial_seeds()
	for ti in pairs(glacial_seeds_table) do
		table.insert(sorted_glacial_seeds, ti)
	end

	table.sort(sorted_glacial_seeds, function(a, b)
		return distance_from_edge[a] > distance_from_edge[b]
	end)
end

local function process_ice_expansion(ice_ti, boost_ice)
	-- local log_str = "" .. world.colatitude[ice_ti] .. "," .. world.minus_longitude[ice_ti] .. "; " --.. world:true_elevation_for_waterflow(ice_ti)
	-- log_str = log_str .. "(" .. world.elevation[ice_ti] .. ", " .. world.ice[ice_ti] .. "); " .. ice_ti .. " ---> " .. ice_flow[ice_ti] .. ", " .. distance_from_edge[ice_ti] .. "\n"

	local can_flow_to_neighbors =
		ice_flow[ice_ti] >= 25 and world.is_land[ice_ti] or
		not world.is_land[ice_ti] and ice_flow[ice_ti] > -world.elevation[ice_ti]

	-- log_str = log_str .. "\t" .. tostring(can_flow_to_neighbors) .. "\n"
	-- if not can_flow_to_neighbors then logger:log(log_str) end

	if not can_flow_to_neighbors then return end

	local ultimate_elevation = open_issues.true_elevation(world, ice_ti) + ice_flow[ice_ti]
	-- log_str = log_str .. "\t" .. ultimate_elevation .. "\n"

	world:for_each_neighbor_random_start(ice_ti, function(nti)
	-- world:for_each_neighbor(ice_ti, function(nti)
		local neigh_ultimate_elev = open_issues.true_elevation(world, nti) + ice_flow[nti]
		if ultimate_elevation <= neigh_ultimate_elev then return end

		local elevation_diff = ultimate_elevation - neigh_ultimate_elev
		local ice_available = ice_flow[ice_ti] / 3
		local max_to_give = elevation_diff / 2
		local ice_to_give = math.min(max_to_give, ice_available)

		if distance_from_edge[ice_ti] > distance_from_edge[nti] then
			if (boost_ice) then
				ice_to_give = ice_to_give + ice_flow[ice_ti] / 40
			end
		else
			ice_to_give = ice_to_give / 3
		end

		ice_flow[nti] = ice_flow[nti] + ice_to_give
		ice_flow[ice_ti] = ice_flow[ice_ti] - ice_to_give
		ice_moved[nti] = ice_moved[nti] + ice_to_give

		-- max_ice = math.max(max_ice, ice_flow[nti])

		if glacial_seeds_table[nti] then return end

		glacial_seeds_table[nti] = true

		-- this is a bit odd, because:
		--   1. we are adding to the table we are iterating over (is it safe or not?)
		--   2. the table is sorted by distance, so we are changing the order of the table
		table.insert(sorted_glacial_seeds, nti) -- is it safe or not?!
	end)

	-- logger:log(log_str)
end

local function ice_expansion_loops(is_ice_age)
	-- world:for_each_tile_by_elevation_for_waterflow(function(ti, _)
	-- 	local log_str = "gs: " .. world.colatitude[ti] .. "," .. world.minus_longitude[ti] .. "; " .. world:true_elevation_for_waterflow(ti) .. "; " .. ti .. " ---> " .. ice_flow[ti] .. ", " .. distance_from_edge[ti]
	-- 	logger:log(log_str)
	-- end)

	-- max_ice = 0

	local num_interations = is_ice_age and 10 or 25 --* Ice ages have fewer iterations, since they take longer and need less precision
	local boost_iterations = num_interations / 10

	while num_interations > 0 do
		num_interations = num_interations - 1
		boost_iterations = boost_iterations - 1

		for _, ice_ti in ipairs(sorted_glacial_seeds) do
			process_ice_expansion(ice_ti, boost_iterations > 0)
		end
	end

	-- world:for_each_tile(function(ti)
	-- 	set_debug(world, ti, 0, 0, 0)
	-- 	if ice_flow[ti] == 0 then return end
	-- 	local fraction = ice_flow[ti] / max_ice
	-- 	local red = fraction * 255
	-- 	local blue = (1 - fraction) * 255
	-- 	set_debug(world, ti, red, 0, blue)
	-- end)

	-- world:for_each_tile_by_elevation_for_waterflow(function(ti, _)
	-- 	local log_str = "gs: " .. world.colatitude[ti] .. "," .. world.minus_longitude[ti] .. "; " .. world:true_elevation_for_waterflow(ti) .. "; " .. ti .. " ---> " .. ice_flow[ti] .. ", " .. distance_from_edge[ti]
	-- 	logger:log(log_str)
	-- end)
end

local function set_permanent_ice_variables(is_ice_age)
	for ti in pairs(glacial_seeds_table) do
		max_ice = math.max(max_ice, ice_flow[ti])
		max_ice_moved = math.max(max_ice_moved, ice_moved[ti])

		if is_ice_age then
			local converted_Ice_height = ice_flow[ti] / 100
			converted_Ice_height = math.min(math.max(converted_Ice_height, 1), 250)
			world.ice_age_ice[ti] = converted_Ice_height
		else
			world.ice[ti] = ice_flow[ti]
		end
	end
end

local function creating_material_from_glacial_action()
	for ti in pairs(glacial_seeds_table) do
		--* Calculate material that is generated from ice movement
		local _, _, _, mineral_richness, rock_mass_conversion, rock_weathering_rate = rock_qualities.get_characteristics_for_rock(world.rock_type[ti], 0, 0, 0, 0, 0, 0) --* mineral_richness acts as multiplier based on bedrock

		texture_material[ti] = ice_moved[ti] * rock_mass_conversion * rock_weathering_rate / 100
		material_richness[ti] = texture_material[ti] * mineral_richness / 100 / 2 --* Reducing mineral richness of glacial silt by / 2
	end
end

local function push_material_to_the_melt_zones()
	local iterate_down = max_distance
	while iterate_down > 0 do
		for ti in pairs(glacial_seeds_table) do
			if distance_from_edge[ti] ~= iterate_down then goto continue1 end -- "or distance_from_edge[ti] <= 0" seems to be redundant, since iterate_down is always > 0

			open_issues.move_material(world, ti, distance_from_edge, ice_moved, texture_material, material_richness, already_added)

			::continue1::
		end

		iterate_down = iterate_down - 1
	end
end

local function remove_ineligible_ocean_ice_tiles(is_ice_age)
	 --* Purge all tiles that discharge into the ocean. Only using periglacial melt tiles
	world:for_each_tile(function(ti)
		if glacial_seeds_table[ti] == nil then return end
		set_debug(1, ti, 224, 247, 250, 255)

		local wbs = world:get_waterbody_size(ti)

		local is_eligible_melt_tile =
			texture_material[ti] > 0 and
			wbs < 20000 and
			((not is_ice_age and world.ice[ti] > 0) or (is_ice_age and world.ice_age_ice[ti] > 0))

		if is_eligible_melt_tile then
			melt_tiles[ti] = true
		else
			glacial_seeds_table[ti] = nil
			texture_material[ti] = 0
			material_richness[ti] = 0
		end

		-- On a second thought, since 'already_added' primary usage is in the code that builds melt provinces, I'd rather leave the table empty
		-- open_issues.remove_already_added(ti, already_added, is_eligible_melt_tile)
	end)
end

local function create_melt_province(ti)
	if already_added[ti] then return nil end

	already_added[ti] = true

	--* If not already a part of a melt province, then we make one out of it, and the surrounding tiles
	local melt_province = {}

	old_layer = {}
	new_layer = {}

	old_layer[ti] = true
	melt_province[ti] = true --* Used to store province tiles
	set_debug(2, ti, 178, 235, 242, 180)

	local default_province_size = 50
	local tiles_up = length(old_layer)

	--* Here we expand out the province until we either have no tiles to add or we run out of "turns"
	while default_province_size > 0 and tiles_up > 0 do
		for expand_ti in pairs(old_layer) do
			world:for_each_neighbor(expand_ti, function(nti)
				if already_added[nti] or glacial_seeds_table[nti] == nil then return end

				--* If not already aprovince, then add

				new_layer[nti] = true
				already_added[nti] = true
			end)
		end

		default_province_size = default_province_size - 1

		old_layer = {}
		for new_ti in pairs(new_layer) do
			old_layer[new_ti] = true
			melt_province[new_ti] = true
			set_debug(2, new_ti, 178, 235, 242, 180)
		end
		new_layer = {}
		tiles_up = length(old_layer)
	end

	return melt_province
end

local function identify_edge_tiles_and_update_province_status(melt_province, is_ice_age)
	local perimeter_size = 0
	local kill_province = true
	old_layer = {}

	for ti in pairs(melt_province) do
		local on_edge = false

		world:for_each_neighbor(ti, function(nti)
			local is_ice_free = is_ice_age and world.ice_age_ice[nti] == 0 or not is_ice_age and world.ice[nti] == 0
			if is_ice_free then
				kill_province = false
				old_layer[nti] = true
				tiles_influenced[nti] = true
				set_debug(3, nti, 128, 203, 196, 120)
			end

			if glacial_seeds_table[nti] == nil then
				on_edge = true
			end
		end)

		if on_edge then
			perimeter_size = perimeter_size + 1
		end
	end

	return perimeter_size, kill_province
end

local function expand_melt_province(is_ice_age, expansion_tick)
	new_layer = {}

	for ti in pairs(old_layer) do
		world:for_each_neighbor(ti, function(nti)
			-- original code has some dead code that seems to want to use the ice to decide whether to skip or not
			if already_added[nti] then return end

			local rn = world.rng:random_int_max(100)
			local neighbor_contributes = (is_ice_age and world.ice_age_ice[nti] > 0) and rn < 20 or rn < 50

			if neighbor_contributes then
				already_added[nti] = true
				new_layer[nti] = true
				invasion_ticker[nti] = expansion_tick
				set_debug(4, nti, 255, 204, 128, 100)
			else
				new_layer[ti] = true
			end
		end)
	end

	old_layer = {}
	for new_ti in pairs(new_layer) do
		old_layer[new_ti] = true
		tiles_influenced[new_ti] = true
	end
end

local function construct_glacial_melt_provinces_and_disperse_silt(is_ice_age)
	world:fill_ffi_array(invasion_ticker, 0)

	--* Iterate through all melt tiles. Construct glacial melt provinces as we go
	for ti in pairs(melt_tiles) do
		local melt_province = create_melt_province(ti)
		if melt_province == nil then goto continue2 end

		local perimeter_size, kill_province = identify_edge_tiles_and_update_province_status(melt_province, is_ice_age)

		if kill_province then goto continue2 end

		local total_material = 0
		local total_richness = 0
		for mp_ti in pairs(melt_province) do
			total_material = total_material + texture_material[mp_ti]
			total_richness = total_richness + material_richness[mp_ti]
		end

		total_material = open_issues.adjust_material_for_province_size_before(total_material, is_ice_age, perimeter_size)

		local base_expansion = 5
		local sample_expansion = math.floor(math.pow(total_material, 0.25)) + base_expansion
		if sample_expansion > 75 then
			sample_expansion = 75 + math.floor(math.sqrt(sample_expansion - 75))
		end

		total_material = open_issues.adjust_material_for_province_size_after(total_material, is_ice_age, perimeter_size)

		while sample_expansion > 0 do
			expand_melt_province(is_ice_age, sample_expansion)

			-- in the original code, the 'sample_expansion' is decremented at the begging of the loop, but its value is then used by the loop logic
			-- so, I have decided to move the decrement to the end of the loop
			sample_expansion = sample_expansion - 1
		end

		::continue2::
	end
end

local function reset_variables()
	glacial_seeds_table = {}
	sorted_glacial_seeds = {}
	already_added = {}
	melt_tiles = {}
	tiles_influenced = {}
	world:fill_ffi_array(ice_flow, 0)
	world:fill_ffi_array(ice_moved, 0)
	world:fill_ffi_array(distance_from_edge, 0)
	world:fill_ffi_array(invasion_ticker, 0)
end

---@param age_type age_types
local function process_age(age_type)
	local is_ice_age = age_type == AGE_TYPES.ice_age

	run_with_profiling(function() create_glacial_start_locations(is_ice_age) end, "create_glacial_start_locations")                                         -- #1
	run_with_profiling(function() find_glacial_perimeter() end, "find_glacial_perimeter")                                                                   -- #2
	run_with_profiling(function() find_distance_of_each_glacier_tile_from_edge() end, "find_distance_of_each_glacier_tile_from_edge")                       -- #3
	run_with_profiling(function() calculate_initial_ice_depth() end, "calculate_initial_ice_depth")                                                         -- #4
	run_with_profiling(function() sort_glacial_seeds() end, "sort_glacial_seeds")                                                                           -- #5
	run_with_profiling(function() ice_expansion_loops(is_ice_age) end, "ice_expansion_loops")                                                               -- #6
	run_with_profiling(function() set_permanent_ice_variables(is_ice_age) end, "set_permanent_ice_variables")                                               -- #7
	--* DIAGNOSTIC: EXPRESS ICE DEPTH                                                                                                                       -- #8
	--* Clear Variables for Next Phase                                                                                                                      -- #9
	run_with_profiling(function() creating_material_from_glacial_action() end, "creating_material_from_glacial_action")                                     -- #10
	run_with_profiling(function() push_material_to_the_melt_zones() end, "push_material_to_the_melt_zones")                                                 -- #11
	run_with_profiling(function() remove_ineligible_ocean_ice_tiles(is_ice_age) end, "remove_ineligible_ocean_ice_tiles")                                   -- #12
	run_with_profiling(function() construct_glacial_melt_provinces_and_disperse_silt(is_ice_age) end, "construct_glacial_melt_provinces_and_disperse_silt") -- #13

	reset_variables()
end

function gm.run(world_obj)
	--* Before we even set seeds, we need to construct temp waterbodies to determine which ones are large, and which ones are small. Ocean waterbodies 
	--* of a sufficient volume will have heat exchanging capacity and act as hard barriers for glacial expansion. Smaller waterbodies can simply 
	--* be elligible to be seeds but have "stricter threshold."
	--* Need boolean to see if part of waterbody. Need logic variable integer to represent "size of waterbody."

	-- 2024.07.07: Above comment might not be relevant. Waterbodies are already defined by gen-initial-waterbodies and we will attempt to use them here instead of re-generating them.

	world = world_obj
	ice_flow = world.tmp_float_2
	ice_moved = world.tmp_float_3
	texture_material = world.tmp_float_4
	material_richness = world.tmp_float_5
	distance_from_edge = world.tmp_int_1
	invasion_ticker = world.tmp_int_2

	world:adjust_debug_channels(4)

	world:fill_ffi_array(ice_flow, 0)
	world:fill_ffi_array(ice_moved, 0)
	world:fill_ffi_array(distance_from_edge, 0)
	world:fill_ffi_array(invasion_ticker, 0)

	process_age(AGE_TYPES.ice_age)
	world:reset_debug_all()
	process_age(AGE_TYPES.game_age)
end

return gm