local gf = {}

-- NOTE 2024.07.06: The comments are close to the original, but may have been edited for clarity and relevance to the current state.
-- In order to distinguish between the original comments and the new ones, the original ones are marked with "--*"

---@enum age_types
local AGE_TYPES = {
	ice_age  = 0,
	game_age = 1
}

local open_issues = require "libsote.glaciation.open-issues"
local rock_qualities = require "libsote.rock-qualities"
local rock_types = require "libsote.rock-type".TYPES

-- local logger = require("libsote.debug-loggers").get_glacial_logger("d:/temp")
local prof = require "libsote.profiling-helper"
local prof_prefix = "[glacial-formation]"

local function run_with_profiling(func, log_txt)
	prof.run_with_profiling(func, prof_prefix, log_txt)
end

local use_original = true
local align_rng = false
local enable_debug = false

local world
local glacial_seed
local already_added
local ice_flow
local ice_moved
local texture_material
local material_richness
local distance_from_edge
local invasion_ticker
local silt_storage
local mineral_storage

local rng

local old_layer = {}
local new_layer = {}
local sorted_glacial_seeds = {}
local melt_tiles = {}
local tiles_influenced = {}

local max_distance = 0
local max_ice = 0
local max_ice_moved = 0

local function set_debug(channel, ti, r, g, b, a)
	world:set_debug_rgba(channel, ti, r, g, b, a or 255)
end

local function create_glacial_start_locations(is_ice_age)
	local ice_age_factor = 5
	if is_ice_age then ice_age_factor = -10 end --* Makes world colder for ice age

	local seed_threshold = -15 --* -15 for non-Ice Age
	if is_ice_age then seed_threshold = 0 end

	world:for_each_tile(function(ti)
		local waterbody_size = world:get_waterbody_size(ti)

		local jan_rainfall = world.jan_rainfall[ti]
		local jan_temperature = world.jan_temperature[ti]
		local jul_rainfall = world.jul_rainfall[ti]
		local jul_temperature = world.jul_temperature[ti]

		local average_temp = open_issues.avg_temp(jan_temperature, jul_temperature) + ice_age_factor
		if average_temp >= seed_threshold or waterbody_size >= 20000 then return end

		local ice_depth = average_temp * -0.25 * open_issues.rainfall_contrib_to_ice_depth(jan_rainfall, jul_rainfall)
		if ice_depth > 0 then
			glacial_seed[ti] = true
			ice_flow[ti] = ice_depth
		end
	end)

	-- world:for_each_tile(function(ti)
	-- 	if not glacial_seed[ti] then return end
	-- 	logger:log(ti)
	-- end)
end

local function find_glacial_perimeter()
	old_layer = {}

	world:for_each_tile(function(ti)
		if glacial_seed[ti] then return end

		local has_seed_neighbour = false
		world:for_each_neighbor(ti, function(nti)
			if not glacial_seed[nti] then return end
			has_seed_neighbour = true
		end)

		if has_seed_neighbour then
			table.insert(old_layer, ti)
			distance_from_edge[ti] = 1
		end
	end)

	-- for _, ti in ipairs(old_layer) do
	-- 	logger:log(ti)
	-- end
end

local function find_distance_of_each_glacier_tile_from_edge()
	local elevation_factor = 500
	local base_expansion = 100
	local expansion_threshold = 300

	new_layer = {}

	local expansion_ticker = 1 --* Keeps track of how many loops we've done.
	local num_tiles = #old_layer

	while num_tiles > 0 do
		expansion_ticker = expansion_ticker + 1 -- probably ok to increment here; expansion_ticker is used to calculate distance_from_edge, which the tiles on the glacier perimeter have it already initialized with 1

		--* Expanding layer
		for _, ti in ipairs(old_layer) do
			local attacked_neighbor = false

			world:for_each_neighbor(ti, function(nti)
				if not glacial_seed[nti] or distance_from_edge[nti] > 0 then return end

				attacked_neighbor = true

				local invasion_modifier = open_issues.true_elevation(world, nti)
				invasion_modifier = math.max(500, invasion_modifier)
				invasion_modifier = invasion_modifier / elevation_factor

				invasion_ticker[nti] = invasion_ticker[nti] + math.floor(base_expansion / invasion_modifier)
				if invasion_ticker[nti] > expansion_threshold then
					table.insert(new_layer, nti)
					distance_from_edge[nti] = expansion_ticker
				end
			end)

			if attacked_neighbor then
				table.insert(new_layer, ti)
			end
		end

		--* The tiles we added this round get checked next round in the "old layer". The new becomes the old
		old_layer = {}
		for _, ti in ipairs(new_layer) do
			table.insert(old_layer, ti)
		end
		new_layer = {}

		num_tiles = #old_layer
	end

	max_distance = expansion_ticker

	-- world:for_each_tile(function(ti)
	-- 	if not glacial_seed[ti] then return end
	-- 	logger:log(ti .. ": " .. distance_from_edge[ti])
	-- end)
end

local function calculate_initial_ice_depth()
	world:for_each_tile(function(ti)
		if not glacial_seed[ti] then return end

		open_issues.calculate_initial_ice_depth(ti, ice_flow, distance_from_edge)
	end)
end

local function sort_glacial_seeds()
	-- world:for_each_tile(function(ti)
	-- 	if not glacial_seed[ti] then return end
	-- 	table.insert(sorted_glacial_seeds, ti)
	-- end)

	-- table.sort(sorted_glacial_seeds, function(a, b)
	-- 	return distance_from_edge[a] > distance_from_edge[b]
	-- end)

	local glacial_seeds_table = {}

	world:for_each_tile(function(ti)
		if not glacial_seed[ti] then return end
		table.insert(glacial_seeds_table, ti)
	end)

	local expansion_ticker = max_distance
	while expansion_ticker > 0 do
		for _, ti in ipairs(glacial_seeds_table) do
			if distance_from_edge[ti] == expansion_ticker then
				table.insert(sorted_glacial_seeds, ti)
			end
		end
		expansion_ticker = expansion_ticker - 1
	end

	-- for _, ti in ipairs(sorted_glacial_seeds) do
	-- 	logger:log(ti .. ": " .. distance_from_edge[ti])
	-- end
end

local function process_ice_expansion(ti, boost_ice)
	local can_flow_to_neighbors =
		ice_flow[ti] >= 25 and world.is_land[ti] or
		not world.is_land[ti] and ice_flow[ti] > -world.elevation[ti]

	if not can_flow_to_neighbors then return end

	local ultimate_elevation = open_issues.true_elevation(world, ti) + ice_flow[ti]

	-- local rn = rng:random_int_max(world:neighbors_count(ti))
	-- world:for_each_neighbor_starting_at(ti, rn, function(nti)
	world:for_each_neighbor_random_start(ti, function(nti)
		local neigh_ultimate_elev = open_issues.true_elevation(world, nti) + ice_flow[nti]
		if ultimate_elevation <= neigh_ultimate_elev then return end

		local elevation_diff = ultimate_elevation - neigh_ultimate_elev
		local ice_available = ice_flow[ti] / 3
		local max_to_give = elevation_diff / 2
		local ice_to_give = math.min(max_to_give, ice_available)

		if distance_from_edge[ti] > distance_from_edge[nti] then
			if (boost_ice) then
				ice_to_give = ice_to_give + ice_flow[ti] / 40
			end
		else
			ice_to_give = ice_to_give / 3
		end

		ice_flow[nti] = ice_flow[nti] + ice_to_give
		ice_flow[ti] = ice_flow[ti] - ice_to_give
		ice_moved[nti] = ice_moved[nti] + ice_to_give

		-- max_ice = math.max(ice_flow[nti], max_ice)

		if glacial_seed[nti] then return end

		glacial_seed[nti] = true

		-- this is a bit odd, because:
		--   1. we are adding to the table we are iterating over (is it safe or not?)
		--   2. the table is sorted by distance, so we are changing the order of the table
		table.insert(sorted_glacial_seeds, nti) -- is it safe or not? seems fine, I have verified that the added elements are processed
	end)
end

local function ice_expansion_loops(is_ice_age)
	-- max_ice = 0

	local num_interations = is_ice_age and 10 or 25 --* Ice ages have fewer iterations, since they take longer and need less precision
	local boost_iterations = math.floor(num_interations / 10)

	while num_interations > 0 do
		num_interations = num_interations - 1
		boost_iterations = boost_iterations - 1

		for _, ti in ipairs(sorted_glacial_seeds) do
			process_ice_expansion(ti, boost_iterations > 0)
		end
	end

	-- world:for_each_tile(function(ti)
	-- 	if not glacial_seed[ti] then return end
	-- 	logger:log(ti .. ": " .. ice_flow[ti] .. ", " .. ice_moved[ti])
	-- end)
end

local function set_permanent_ice_variables(is_ice_age)
	max_ice = 0
	max_ice_moved = 0

	world:for_each_tile(function(ti)
		if glacial_seed[ti] then
			max_ice = math.max(ice_flow[ti], max_ice)
			max_ice_moved = math.max(ice_moved[ti], max_ice_moved)

			if is_ice_age then
				local converted_ice_height = ice_flow[ti] / 100
				converted_ice_height = math.min(math.max(1, converted_ice_height), 250)
				world.ice_age_ice[ti] = converted_ice_height
			else
				world.ice[ti] = ice_flow[ti]
			end
		end

		if is_ice_age and world.is_land[ti] and world.ice_age_ice[ti] <= 50 then --* Apply bedrock weathering to all tiles that are not underneath Ice Age Ice
			--* Scale ice age ice influence on chemical weathering between 1 - 50.  Everything above 50 = 0 influence
			local chemical_weathering = math.max(1, (world.jan_rainfall[ti] + world.jul_rainfall[ti]) / 40)

			local volcanic_modifier = 1 --* If volcanic, recent eruptions mean material is refreshed and "resistant" to chemical weathering
			local rock_type = world.rock_type[ti]
			if rock_type == rock_types.basic_volcanics then
				volcanic_modifier = 0.3
			elseif rock_type == rock_types.mixed_volcanics then
				volcanic_modifier = 0.5
			elseif rock_type == rock_types.acid_volcanics then
				volcanic_modifier = 0.65
			end
			chemical_weathering = 1 + (chemical_weathering - 1) * volcanic_modifier

			local ice_age_inhibitor = 1 - (world.ice_age_ice[ti] / 50) --* More ice age ice height means ice sheet shielded from chemical weathering for longer
			local material_removed = world.mineral_richness[ti] * (1 - 1 / chemical_weathering) * ice_age_inhibitor

			world.mineral_richness[ti] = math.floor(world.mineral_richness[ti] - material_removed)
		end
	end)

	-- world:for_each_tile(function(ti)
	-- 	if not glacial_seed[ti] then return end
	-- 	logger:log(ti .. ": " .. world.ice_age_ice[ti] .. ", " .. world.ice[ti])
	-- end)
end

------------------------------------------------------------------------------------------------------------------------------------------------------

local function creating_material_from_glacial_action()
	old_layer = {}

	world:for_each_tile(function(ti)
		if not glacial_seed[ti] then return end

		table.insert(old_layer, ti)

		--* Calculate material that is generated from ice movement
		local _, _, _, mineral_richness, rock_mass_conversion, rock_weathering_rate = rock_qualities.get_characteristics_for_rock(world.rock_type[ti], 0, 0, 0, 0, 0, 0) --* mineral_richness acts as multiplier based on bedrock

		texture_material[ti] = ice_moved[ti] * rock_mass_conversion * rock_weathering_rate / 100
		material_richness[ti] = texture_material[ti] * mineral_richness / 100 / 2 --* Reducing mineral richness of glacial silt by / 2
	end)
end

local function push_material_to_the_melt_zones()
	local iterate_down = max_distance

	while iterate_down > 0 do
		for _, ti in ipairs(old_layer) do
			if distance_from_edge[ti] ~= iterate_down then goto continue1 end -- "or distance_from_edge[ti] <= 0" seems to be redundant, since iterate_down is always > 0

			open_issues.move_material(world, ti, distance_from_edge, ice_moved, texture_material, material_richness, already_added, use_original)

			::continue1::
		end

		iterate_down = iterate_down - 1
	end

	-- world:for_each_tile(function(ti)
	-- 	if not glacial_seed[ti] then return end
	-- 	logger:log(ti .. ": " .. texture_material[ti] .. ", " .. material_richness[ti])
	-- end)
end

local function remove_ineligible_ocean_ice_tiles(is_ice_age)
	--* Purge all tiles that discharge into the ocean. Only using periglacial melt tiles
	world:for_each_tile(function(ti)
		if not glacial_seed[ti] then return end

		local wbs = world:get_waterbody_size(ti)

		local is_eligible_melt_tile =
			texture_material[ti] > 0 and
			wbs < 20000 and
			((not is_ice_age and world.ice[ti] > 0) or (is_ice_age and world.ice_age_ice[ti] > 0))

		if is_eligible_melt_tile then
			table.insert(melt_tiles, ti)
		else
			glacial_seed[ti] = false
			texture_material[ti] = 0
			material_richness[ti] = 0
		end

		open_issues.remove_already_added(ti, already_added, is_eligible_melt_tile, use_original)
	end)
end

local function create_melt_province(ti)
	--* If not already a part of a melt province, then we make one out of it, and the surrounding tiles
	local melt_province = {}

	old_layer = {}
	new_layer = {}

	table.insert(old_layer, ti)
	table.insert(melt_province, ti) --* Used to store province tiles

	local default_province_size = 50
	local tiles_up = #old_layer

	--* Here we expand out the province until we either have no tiles to add or we run out of "turns"
	while default_province_size > 0 and tiles_up > 0 do
		for _, expand_ti in ipairs(old_layer) do
			world:for_each_neighbor(expand_ti, function(nti)
				if already_added[nti] or not glacial_seed[nti] then return end

				--* If not already a province, then add

				table.insert(new_layer, nti)
				already_added[nti] = true
			end)
		end

		default_province_size = default_province_size - 1

		old_layer = {}
		for _, new_ti in ipairs(new_layer) do
			table.insert(old_layer, new_ti)
			table.insert(melt_province, new_ti)
		end
		new_layer = {}
		tiles_up = #old_layer
	end

	return melt_province
end

local function identify_edge_tiles_and_update_province_status(melt_province, is_ice_age)
	local perimeter_size = 0
	local kill_province = true
	old_layer = {}

	for _, ti in ipairs(melt_province) do
		local on_edge = false

		world:for_each_neighbor(ti, function(nti)
			local is_ice_free = is_ice_age and world.ice_age_ice[nti] == 0 or not is_ice_age and world.ice[nti] == 0
			if is_ice_free then
				kill_province = false
				table.insert(old_layer, nti)
				table.insert(tiles_influenced, nti)
			end

			if not glacial_seed[nti] then
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

	for _, ti in ipairs(old_layer) do
		world:for_each_neighbor(ti, function(nti)
			-- original code has some dead code that seems to want to use the ice to decide whether to skip or not
			if already_added[nti] then return end

			local rn = rng:random_int_max(100)
			local neighbor_contributes = false
			if is_ice_age and world.ice_age_ice[nti] > 0 then
				if rn < 20 then neighbor_contributes = true end
			elseif rn < 50 then neighbor_contributes = true end

			if neighbor_contributes then
				already_added[nti] = true
				table.insert(new_layer, nti)
				invasion_ticker[nti] = expansion_tick
			else
				table.insert(new_layer, ti)
			end
		end)
	end

	old_layer = {}
	for _, new_ti in ipairs(new_layer) do
		table.insert(old_layer, new_ti)
		table.insert(tiles_influenced, new_ti)
	end
end

local function construct_glacial_melt_provinces_and_disperse_silt(is_ice_age)
	-- local max_silt_storage = 0

	world:fill_ffi_array(invasion_ticker, 0)

	--* Iterate through all melt tiles. Construct glacial melt provinces as we go
	for _, ti in ipairs(melt_tiles) do
		if already_added[ti] then goto continue2 end
		already_added[ti] = true

		local melt_province = create_melt_province(ti)
		if melt_province == nil then goto continue2 end

		tiles_influenced = {}

		local perimeter_size, kill_province = identify_edge_tiles_and_update_province_status(melt_province, is_ice_age)

		if kill_province then goto continue2 end

		local total_material = 0
		local total_richness = 0
		local max_material = 0
		local max_richness = 0
		for _, mp_ti in ipairs(melt_province) do
			total_material = total_material + texture_material[mp_ti]
			total_richness = total_richness + material_richness[mp_ti]
			max_material = math.max(texture_material[mp_ti], max_material)
			max_richness = math.max(material_richness[mp_ti], max_richness)
		end

		total_material = open_issues.adjust_material_for_province_size_before(total_material, is_ice_age, #melt_province, use_original)

		local base_expansion = 5
		local sample_expansion = math.floor(math.pow(total_material, 0.25)) + base_expansion
		if sample_expansion > 75 then
			sample_expansion = 75 + math.floor(math.sqrt(sample_expansion - 75))
		end

		total_material = open_issues.adjust_material_for_province_size_after(total_material, is_ice_age, #melt_province, use_original)

		while sample_expansion > 0 do
			-- in the original code, the 'sample_expansion' is decremented at the begging of the loop, but its value is then used by the loop logic
			sample_expansion = sample_expansion - 1

			expand_melt_province(is_ice_age, sample_expansion)
		end

		local total_points = 0
		for _, i_ti in ipairs(tiles_influenced) do
			total_points = total_points + invasion_ticker[i_ti]
		end

		for _, i_ti in ipairs(tiles_influenced) do
			local share_of_silt = total_material * invasion_ticker[i_ti] / total_points
			local share_of_mineral = total_richness * invasion_ticker[i_ti] / total_points

			silt_storage[i_ti] = silt_storage[i_ti] + math.floor(share_of_silt)
			mineral_storage[i_ti] = mineral_storage[i_ti] + math.floor(share_of_mineral)

			invasion_ticker[i_ti] = 0
			already_added[i_ti] = false

			-- max_silt_storage = math.max(math.log(silt_storage[i_ti] + 1), max_silt_storage)
		end

		::continue2::
	end

	-- world:for_each_tile(function(ti)
	-- 	if silt_storage[ti] == 0 and mineral_storage[ti] == 0 then return end
	-- 	logger:log(ti .. ": " .. silt_storage[ti] .. ", " .. mineral_storage[ti])
	-- end)

	-- world:for_each_tile(function(ti)
	-- 	local fraction = math.log(silt_storage[ti] + 1) / max_silt_storage
	-- 	local red = fraction * 255
	-- 	set_debug(1, ti, red, 0, 0, 255)
	-- end)
end

local function reset_variables()
	sorted_glacial_seeds = {}
	melt_tiles = {}
	tiles_influenced = {}
	world:fill_ffi_array(glacial_seed, false)
	world:fill_ffi_array(already_added, false)
	world:fill_ffi_array(ice_flow, 0)
	world:fill_ffi_array(ice_moved, 0)
	world:fill_ffi_array(texture_material, 0)
	world:fill_ffi_array(material_richness, 0)
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

	reset_variables()                                                                                                                                       -- #14
end

local function cull_back_silt_based_on_moisture_and_slope()
	local silt_rank_one = 50 --* Retention will vary depending on the base amount of silt remaining
	local silt_rank_two = 200
	local silt_rank_three = 1000
	local silt_rank_four = 5000

	local wind_adjustment_slope = 0.65
	local wind_adjustment_base = 0.35
	local max_wind_factor = 25.0
	local max_normalized_wind = 1
	local water_normalization_factor = 60

	local silt_limit = 10000
	local silt_exponent = 0.8

	-- local max_silt = 0
	-- local max_mineral = 0

	world:for_each_tile(function(ti)
		if silt_storage[ti] <= 0 then return end

		local temp_sand, temp_silt, temp_clay, _, _, _ = rock_qualities.get_characteristics_for_rock(world.rock_type[ti], 0, 0, 0, 0, 0, 0)

		local true_water_calc = 0
		if world.is_land[ti] then
			local wind_factor = wind_adjustment_base + wind_adjustment_slope * (1 - math.min(world.jan_wind_speed[ti] / max_wind_factor, max_normalized_wind))
			local permeability = require("libsote.world-gen-utils").permiation_calc(temp_sand, temp_silt, temp_clay)

			true_water_calc = (world.jan_rainfall[ti] + world.jul_rainfall[ti]) * wind_factor * permeability
		end

		local steepest_face = 0
		world:for_each_neighbor(ti, function(nti)
			local elev_diff = open_issues.true_elevation(world, ti) - open_issues.true_elevation(world, nti)
			if elev_diff <= 0 then return end
			steepest_face = math.max(steepest_face, elev_diff)
		end)

		-- original code happily divides by zero if it chances on a flat piece of terrain, so I decided to set the slope_retention_factor to 1 in that case
		local slope_retention_factor = steepest_face > 0 and math.min(math.pow((10 / steepest_face), 2), 1) or 1
		local temp_factor = open_issues.calculate_temp_factor_for_retention_mult(world.jan_temperature[ti], world.jul_temperature[ti])
		local retention_multiplier = math.min(math.pow((true_water_calc / water_normalization_factor), 2) * slope_retention_factor * temp_factor, 1)

		local new_silt = silt_storage[ti]
		local altered_silt = 0

		if new_silt > silt_rank_four then
			altered_silt = altered_silt + (new_silt - silt_rank_four) * math.pow(retention_multiplier, 2.0)
			altered_silt = altered_silt + (new_silt - silt_rank_three) * retention_multiplier -- suspicious, as it does not follow the pattern, but Demian seems to remember it was on purpose, to "skew toward a specific outcome for silt"
			altered_silt = altered_silt + (silt_rank_three - silt_rank_two) * math.pow(retention_multiplier, 0.75)
			altered_silt = altered_silt + (silt_rank_two - silt_rank_one) * math.pow(retention_multiplier, 0.25)
			altered_silt = altered_silt + silt_rank_one
		elseif new_silt > silt_rank_three then
			altered_silt = altered_silt + (new_silt - silt_rank_three) * retention_multiplier
			altered_silt = altered_silt + (silt_rank_three - silt_rank_two) * math.pow(retention_multiplier, 0.75)
			altered_silt = altered_silt + (silt_rank_two - silt_rank_one) * math.pow(retention_multiplier, 0.25)
			altered_silt = altered_silt + silt_rank_one
		elseif new_silt > silt_rank_two then
			altered_silt = altered_silt + (new_silt - silt_rank_two) * math.pow(retention_multiplier, 0.75)
			altered_silt = altered_silt + (silt_rank_two - silt_rank_one) * math.pow(retention_multiplier, 0.25)
			altered_silt = altered_silt + silt_rank_one
		elseif new_silt > silt_rank_one then
			altered_silt = altered_silt + (new_silt - silt_rank_one) * math.pow(retention_multiplier, 0.25)
			altered_silt = altered_silt + silt_rank_one
		else
			altered_silt = new_silt
		end

		if altered_silt > silt_limit then
			altered_silt = math.pow((altered_silt - silt_limit), silt_exponent) + silt_limit
		end

		local original_silt_ratio = altered_silt / silt_storage[ti]

		silt_storage[ti] = math.floor(altered_silt)
		mineral_storage[ti] = math.floor(mineral_storage[ti] * original_silt_ratio)

		-- max_silt = math.max(math.log(silt_storage[ti] + 1), max_silt)
		-- max_mineral = math.max(math.log(mineral_storage[ti] + 1), max_mineral)
	end)

	-- world:for_each_tile(function(ti)
	-- 	if not world.is_land[ti] then
	-- 		set_debug(1, ti, 0, 0, 0, 255)
	-- 		set_debug(2, ti, 0, 0, 0, 255)
	-- 		return
	-- 	end

	-- 	local fraction = math.log(silt_storage[ti] + 1) / max_silt
	-- 	local blue = fraction * 255
	-- 	set_debug(1, ti, 0, 0, blue, 255)

	-- 	fraction = math.log(mineral_storage[ti] + 1) / max_mineral
	-- 	local red = fraction * 255
	-- 	set_debug(2, ti, red, 0, 0, 255)
	-- end)
end

local function assign_ice_biomes_and_set_variables()
	world:for_each_tile(function(ti)
		if world.ice[ti] > 0 then
			-- set biome here
		else
			world.silt[ti] = world.silt[ti] + silt_storage[ti]
			world.mineral_richness[ti] = world.mineral_richness[ti] + mineral_storage[ti]
		end
	end)
end

function gf.run(world_obj)
	--* Before we even set seeds, we need to construct temp waterbodies to determine which ones are large, and which ones are small. Ocean waterbodies 
	--* of a sufficient volume will have heat exchanging capacity and act as hard barriers for glacial expansion. Smaller waterbodies can simply 
	--* be elligible to be seeds but have "stricter threshold."
	--* Need boolean to see if part of waterbody. Need logic variable integer to represent "size of waterbody."

	-- 2024.07.07: Above comment might not be relevant. Waterbodies are already defined by gen-initial-waterbodies and we will attempt to use them here instead of re-generating them.

	world = world_obj
	glacial_seed = world.tmp_bool_1
	already_added = world.tmp_bool_2
	ice_flow = world.tmp_float_2
	ice_moved = world.tmp_float_3
	texture_material = world.tmp_float_4
	material_richness = world.tmp_float_5
	distance_from_edge = world.tmp_int_1
	invasion_ticker = world.tmp_int_2
	silt_storage = world.tmp_int_3
	mineral_storage = world.tmp_int_4

	rng = world.rng
	local preserved_state = nil
	if align_rng then
		preserved_state = rng:get_state()
		rng:set_seed(world.seed + 19832)
	end

	if enable_debug then
		world:adjust_debug_channels(2)
	end

	world:fill_ffi_array(glacial_seed, false)
	world:fill_ffi_array(already_added, false)
	world:fill_ffi_array(ice_flow, 0)
	world:fill_ffi_array(ice_moved, 0)
	world:fill_ffi_array(texture_material, 0)
	world:fill_ffi_array(material_richness, 0)
	world:fill_ffi_array(distance_from_edge, 0)
	world:fill_ffi_array(invasion_ticker, 0)
	world:fill_ffi_array(silt_storage, 0)
	world:fill_ffi_array(mineral_storage, 0)

	process_age(AGE_TYPES.ice_age)

	if enable_debug then
		world:reset_debug_all()
	end

	process_age(AGE_TYPES.game_age)

	run_with_profiling(function() cull_back_silt_based_on_moisture_and_slope() end, "cull_back_silt_based_on_moisture_and_slope")                           -- #15
	--* Dispose of Lists                                                                                                                                    -- #16
	run_with_profiling(function() assign_ice_biomes_and_set_variables() end, "assign_ice_biomes_and_set_variables")                                         -- #17

	if align_rng then
		rng:set_state(preserved_state)
	end
end

return gf