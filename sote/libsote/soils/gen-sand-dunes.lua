local gsd = {}

local wgu = require "libsote.world-gen-utils"
local ROCK_TYPES = require "libsote.rock-type".TYPES
local rq = require "libsote.rock-qualities"

local enable_debug = false
-- local logger = require("libsote.debug-loggers").get_soils_logger("d:/temp")

local world
local rng
local true_dune
local potential_dune
local dune_terminated
local true_water
local silt_stash
local mineral_stash
local tag_num
local slope_retention_factor

local DUNE_DEATH_SIZE = 8 --* The size at which we terminate a dune
local SUPER_DUNE_THRESHOLD = 100 --* The size that the dune needs to be to disperse "full range" of 100 tiles. Also, dunes under threshold only have 1 point source
local DUNE_SILT_TUNER = 1

local function trimmed_dune(dune)
	local remaining_dune_tiles = #dune

	local tiles_trimmed = true
	while tiles_trimmed do
		tiles_trimmed = false

		for _, ti in ipairs(dune) do
			if dune_terminated[ti] then goto continue1 end

			local dune_neighbors = 0

			world:for_each_neighbor(ti, function(nti)
				if true_dune[nti] then
					dune_neighbors = dune_neighbors + 1
				end
			end)

			if dune_neighbors < 2 then --* If only 1 neighbor, you get chopped off the dune
				dune_terminated[ti] = true
				true_dune[ti] = false
				potential_dune[ti] = false
				remaining_dune_tiles = remaining_dune_tiles - 1
				tiles_trimmed = true
			end

			::continue1::
		end
	end

	--* Second line of defense to remove dunes
	if remaining_dune_tiles < DUNE_DEATH_SIZE then
		for _, ti in ipairs(dune) do
			dune_terminated[ti] = true
			true_dune[ti] = false
			potential_dune[ti] = false
		end
		return {}
	end

	local final_dune = {}
	for _, ti in ipairs(dune) do
		if not dune_terminated[ti] then
			table.insert(final_dune, ti)
		end
	end
	return final_dune
end

local function calculate_dune_mineral_value(dune)
	local average_rainfall = 0 --* used to determine influence of chemical weathering on nutrient value

	local sand_stone_dune_percent = 0
	local lime_stone_dune_percent = 0
	local silt_stone_dune_percent = 0
	local mud_stone_dune_percent = 0
	local acid_volcanic_dune_percent = 0
	local mixed_volcanic_dune_percent = 0
	local basic_volcanic_dune_percent = 0
	local acid_plutonic_dune_percent = 0
	local mixed_plutonic_dune_percent = 0
	local basic_plutonic_dune_percent = 0
	local other_dune_percent = 0

	--* average mineral nutrient value for each sand dune
	for _, ti in ipairs(dune) do
		average_rainfall = average_rainfall + world.jan_rainfall[ti] + world.jul_rainfall[ti]

		local rock_type = world.rock_type[ti]

		if rock_type == ROCK_TYPES.sandstone then
			sand_stone_dune_percent = sand_stone_dune_percent + 1
		elseif rock_type == ROCK_TYPES.limestone then
			lime_stone_dune_percent = lime_stone_dune_percent + 1
		elseif rock_type == ROCK_TYPES.siltstone then
			silt_stone_dune_percent = silt_stone_dune_percent + 1
		elseif rock_type == ROCK_TYPES.mudstone then
			mud_stone_dune_percent = mud_stone_dune_percent + 1
		elseif rock_type == ROCK_TYPES.acid_volcanics then
			acid_volcanic_dune_percent = acid_volcanic_dune_percent + 1
		elseif rock_type == ROCK_TYPES.mixed_volcanics then
			mixed_volcanic_dune_percent = mixed_volcanic_dune_percent + 1
		elseif rock_type == ROCK_TYPES.basic_volcanics then
			basic_volcanic_dune_percent = basic_volcanic_dune_percent + 1
		elseif rock_type == ROCK_TYPES.acid_plutonics then
			acid_plutonic_dune_percent = acid_plutonic_dune_percent + 1
		elseif rock_type == ROCK_TYPES.mixed_plutonics then
			mixed_plutonic_dune_percent = mixed_plutonic_dune_percent + 1
		elseif rock_type == ROCK_TYPES.basic_plutonics then
			basic_plutonic_dune_percent = basic_plutonic_dune_percent + 1
		else
			other_dune_percent = other_dune_percent + 1
		end

		-- set biome to sand_dune here
	end

	average_rainfall = average_rainfall / #dune

	sand_stone_dune_percent = sand_stone_dune_percent / #dune
	lime_stone_dune_percent = lime_stone_dune_percent / #dune
	silt_stone_dune_percent = silt_stone_dune_percent / #dune
	mud_stone_dune_percent = mud_stone_dune_percent / #dune
	acid_volcanic_dune_percent = acid_volcanic_dune_percent / #dune
	mixed_volcanic_dune_percent = mixed_volcanic_dune_percent / #dune
	basic_volcanic_dune_percent = basic_volcanic_dune_percent / #dune
	acid_plutonic_dune_percent = acid_plutonic_dune_percent / #dune
	mixed_plutonic_dune_percent = mixed_plutonic_dune_percent / #dune
	basic_plutonic_dune_percent = basic_plutonic_dune_percent / #dune
	other_dune_percent = other_dune_percent / #dune

	local sand_stone_mineral = sand_stone_dune_percent * rq.mineral_nutrients(ROCK_TYPES.sandstone)
	local lime_stone_mineral = lime_stone_dune_percent * rq.mineral_nutrients(ROCK_TYPES.limestone)
	local silt_stone_mineral = silt_stone_dune_percent * rq.mineral_nutrients(ROCK_TYPES.siltstone)
	local mud_stone_mineral = mud_stone_dune_percent * rq.mineral_nutrients(ROCK_TYPES.mudstone)
	local acid_volcanic_mineral = acid_volcanic_dune_percent * rq.mineral_nutrients(ROCK_TYPES.acid_volcanics)
	local mixed_volcanic_mineral = mixed_volcanic_dune_percent * rq.mineral_nutrients(ROCK_TYPES.mixed_volcanics)
	local basic_volcanic_mineral = basic_volcanic_dune_percent * rq.mineral_nutrients(ROCK_TYPES.basic_volcanics)
	local acid_plutonic_mineral = acid_plutonic_dune_percent * rq.mineral_nutrients(ROCK_TYPES.acid_plutonics)
	local mixed_plutonic_mineral = mixed_plutonic_dune_percent * rq.mineral_nutrients(ROCK_TYPES.mixed_plutonics)
	local basic_plutonic_mineral = basic_plutonic_dune_percent * rq.mineral_nutrients(ROCK_TYPES.basic_plutonics)
	local other_mineral = other_dune_percent * 0.4

	local chemical_weathering = math.max(1, average_rainfall / 40)

	return (
		sand_stone_mineral +
		lime_stone_mineral +
		silt_stone_mineral +
		mud_stone_mineral +
		acid_volcanic_mineral +
		mixed_volcanic_mineral +
		basic_volcanic_mineral +
		acid_plutonic_mineral +
		mixed_plutonic_mineral +
		basic_plutonic_mineral +
		other_mineral) / 100 / chemical_weathering
end

local function process_dune_source(dune, expansion_iterations)
	local old_layer = {}
	local new_layer = {}
	local all_influenced = {}

	-- local eruption_rand = rng:random()
	-- local etid = dune[math.floor(eruption_rand * #dune) + 1]
	local eruption_rand = rng:random_int_max(#dune) + 1
	local etid = dune[eruption_rand]
	table.insert(old_layer, etid)
	table.insert(all_influenced, etid)
	tag_num[etid] = expansion_iterations

	while expansion_iterations > 0 do
		expansion_iterations = expansion_iterations - 1

		for _, ti in ipairs(old_layer) do
			world:for_each_neighbor(ti, function(nti)
				if tag_num[nti] > 0 then return end

				if rng:random() >= 0.5 then
					table.insert(new_layer, ti)
					return
				end

				table.insert(new_layer, nti)
				table.insert(all_influenced, nti)
				tag_num[nti] = expansion_iterations
			end)
		end

		old_layer = {}
		for _, ti in ipairs(new_layer) do
			table.insert(old_layer, ti)
		end
		new_layer = {}
	end

	return all_influenced
end

local function process_dune_tile(dti)
	if true_dune[dti] or dune_terminated[dti] or not potential_dune[dti] then return end

	--* If threshold not met, don't use as start point, but may be "expanded into"
	if true_water[dti] > 20 then return end

	local old_layer = {}
	local new_layer = {}
	local temp_dune = {}

	table.insert(old_layer, dti)
	table.insert(temp_dune, dti)
	true_dune[dti] = true

	--* Continue to "build" the dune for as long as it takes to run out of elligible tiles
	while #old_layer > 0 do
		for _, ti in ipairs(old_layer) do
			world:for_each_neighbor(ti, function(nti)
				if true_dune[nti] or not potential_dune[nti] then return end

				table.insert(new_layer, nti)
				table.insert(temp_dune, nti)
				true_dune[nti] = true
			end)
		end

		old_layer = {}
		for _, ti in ipairs(new_layer) do
			table.insert(old_layer, ti)
		end
		new_layer = {}
	end

	local final_dune = {}

	if #temp_dune >= DUNE_DEATH_SIZE then
		final_dune = trimmed_dune(temp_dune)
	else
		--* Kill dunes that don't make the cut
		for _, ti in ipairs(temp_dune) do
			dune_terminated[ti] = true
			potential_dune[ti] = false
			true_dune[ti] = false
		end
	end

	if #final_dune < DUNE_DEATH_SIZE then return end

	--* If dune is big enough, do duney stuff like turn tiles bare and generate silt criteria

	local num_sources = math.max(1, math.floor(#final_dune / SUPER_DUNE_THRESHOLD))
	local silt_produced = DUNE_SILT_TUNER * #final_dune / num_sources --* How much silt is produced by the desert
	local silt_dispersal_range = math.floor(math.sqrt(#final_dune >= SUPER_DUNE_THRESHOLD and SUPER_DUNE_THRESHOLD or #final_dune)) * 12 + 15 --* The number of tiles silt can expand outward from point source
	local dune_mineral_value = calculate_dune_mineral_value(final_dune)

	while num_sources > 0 do
		num_sources = num_sources - 1

		--* Phase where we expand outward and calculate all influenced tiles
		local all_influenced = process_dune_source(final_dune, silt_dispersal_range)

		for _, ti in ipairs(all_influenced) do
			if not world.is_land[ti] then goto continue2 end

			local settled_silt = (silt_produced * tag_num[ti] * slope_retention_factor[ti]) / silt_dispersal_range

			silt_stash[ti] = silt_stash[ti] + settled_silt
			mineral_stash[ti] = mineral_stash[ti] + settled_silt * dune_mineral_value

			tag_num[ti] = 0

			::continue2::
		end
	end
end

function gsd.run(world_obj)
	world = world_obj
	rng = world.rng
	true_dune = world.tmp_bool_1
	potential_dune = world.tmp_bool_2
	dune_terminated = world.tmp_bool_3
	true_water = world.tmp_float_2
	silt_stash = world.tmp_float_4
	mineral_stash = world.tmp_float_5
	tag_num = world.tmp_int_1
	slope_retention_factor = world.carry_float_1

	if require("libsote.debug-control-panel").soils.align_rng then
		rng = require("libsote.randomness"):new(world.seed + 19832)
	end

	world:fill_ffi_array(true_dune, false)
	world:fill_ffi_array(potential_dune, false)
	world:fill_ffi_array(dune_terminated, false)
	world:fill_ffi_array(true_water, 0)
	world:fill_ffi_array(silt_stash, 0)
	world:fill_ffi_array(mineral_stash, 0)
	world:fill_ffi_array(tag_num, 0)

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
		wind_factor = (1 - wind_factor / 25) * 0.65 + 0.35
		local permeability = wgu.permiation_calc_dune(world.sand[ti], world.silt[ti], world.clay[ti])
		true_water[ti] = true_water_calc * permeability * wind_factor

		if true_water[ti] > 40 then return end

		--* calculate composite
		local average_slope = 0
		local elev = world.elevation[ti]
		world:for_each_neighbor(ti, function(nti) --* Get average slope. Is used to exclude sand dune locations
			local elev_diff = math.abs(elev - world.elevation[nti])
			average_slope = average_slope + elev_diff
		end)
		average_slope = average_slope / world:neighbors_count(ti)

		local sand_percent = (world.sand[ti] * 100) / (world.sand[ti] + world.silt[ti] + world.clay[ti]) --* Calculate percentage of sand as soil texture
		local sand_factor = 1
		if sand_percent > 55 then sand_factor = sand_factor * 0.5 end
		if sand_percent > 70 then sand_factor = sand_factor * 0.5 end
		if sand_percent > 90 then sand_factor = sand_factor * 0.5 end
		local sand_dune_composite = (true_water[ti] + 30) * sand_factor

		if sand_dune_composite <= 9 and average_slope < 25 then
			potential_dune[ti] = true
			table.insert(dune_start_tiles, ti)
		end
	end)

	--* Generate "final" dunes which will contribute to silt. We may want to create non-silt producing dunes in areas with sufficient land cover and
	--* rainfall so that we have the kind of grassland dunes that exist in Kansas and the Pannonian Basin

	for _, ti in ipairs(dune_start_tiles) do
		process_dune_tile(ti)
	end

	--* Iterate through all pertinent tiles and add silt and minerals
	world:for_each_tile(function(ti)
		if not world.is_land[ti] then return end

		world.silt[ti] = world.silt[ti] + math.floor(silt_stash[ti])
		world.mineral_richness[ti] = world.mineral_richness[ti] + math.floor(mineral_stash[ti])
		-- logger:log(ti .. ": " .. world.silt[ti] .. " " .. world.mineral_richness[ti])
	end)
end

return gsd