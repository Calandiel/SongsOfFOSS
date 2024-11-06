local lw = {}

local waterbody = require "libsote.hydrology.waterbody"
local wgu = require "libsote.world-gen-utils"
local sun = require "game.climate.sun"
local open_issues = require "libsote.soils.open-issues"

-- local logger = require("libsote.debug-loggers").get_soils_logger("d:/temp")

local world
local already_added
local moving_sand
local moving_silt
local moving_clay
local moving_minerals
local moving_organics
local sand_stash
local silt_stash
local clay_stash
local mineral_stash

local water_flow_now = {}
local water_flow_later = {}

local BASE_ORGANIC_PRODUCTION = 100
local MATERIAL_SLOPE = 100

local function calculate_organics()
	--* Before we move material we want to assign waterspeed characteristics to our rivers, that way we know how intensively sand is broken down.
	--* After this, we will add in a little function to break up sand and silt as we move material downstream... Then we're good.

	--* standard tile formula: baseproduction * Water * (mineral nutrient* tempfactor) * sunlight = subsidy available material, have alternative formula for wetlands and riparian ecosystems
	--* wetland formula:
	--* river formula:
	--* freshwater lake formula:
	--* Create a base amount of organic production independant of soil depth. Don't worry about proportions ever of organics to other materials.
	--* When we finally calculate soil depth informed by slope, we will reduce soil depth in places like mountains, but we will leave organics
	--* alone. This will create the "organic dense" soils of mountains that we encounter.

	world:for_each_tile(function(ti)
		local true_water_calc = math.min(wgu.true_water_for_tile(world, ti), 300)

		local total_material = world.sand[ti] + world.silt[ti] + world.clay[ti]
		local percent_mineral_nutrient = world.mineral_richness[ti] / total_material
		local temp_factor = wgu.temperature_factor_for_tile(world, ti)
		local modified_mineral_factor = (percent_mineral_nutrient / 0.6) ^ 0.5 * temp_factor

		local wetland_modifier = 1
		local wb = world:get_waterbody_by_tile(ti)
		if wb and wb:is_valid() then
			if wb.type == waterbody.TYPES.wetland or wb.type == waterbody.TYPES.river then
				if world.water_movement[ti] > 1000000 then
					wetland_modifier = wetland_modifier * 3
				elseif world.water_movement[ti] > 100000 then
					wetland_modifier = wetland_modifier * 2
				elseif world.water_movement[ti] > 15000 then
					wetland_modifier = wetland_modifier * 1.5
				elseif world.water_movement[ti] > open_issues.lowest_wetland_thresh() then
					wetland_modifier = wetland_modifier * 1.25
				end
			end
		end

		world.soil_organics[ti] = math.floor(BASE_ORGANIC_PRODUCTION * (true_water_calc / 50) * modified_mineral_factor * sun.yearly_irradiance_from_colat(world.colatitude[ti]) * wetland_modifier)
		-- logger:log(ti .. ": " .. world.soil_organics[ti])
	end)
end

local function calculate_material_to_move()
	--* calculate how much material in the tile will need to be moved

	world:for_each_tile(function(ti)
		if not world.is_land[ti] then goto cont_loop1 end

		--* Calculate material in tile, done by amount of water moving into tile times slope
		local true_elev = world:true_elevation_for_waterflow(ti)

		local total_elevation_difference = 0
		local steepest_face = 0
		for i = 0, world:neighbors_count(ti) - 1 do
			local nti = world.neighbors[ti * 6 + i]

			local elev_diff = true_elev - world:true_elevation_for_waterflow(nti)

			--* If tile under scrutiny is higher, we know material is transported
			if elev_diff > 0 then
				total_elevation_difference = total_elevation_difference + elev_diff
				steepest_face = math.max(steepest_face, elev_diff)
			end
		end

		local gross_material_to_grab = 0
		for i = 0, world:neighbors_count(ti) - 1 do
			local nti = world.neighbors[ti * 6 + i]

			local elev_diff = true_elev - world:true_elevation_for_waterflow(nti)

			--* If tile under scrutiny is higher, we know material is transported
			if elev_diff > 0 then
				local water_flow_share = world.water_movement[ti] * (elev_diff / total_elevation_difference)
				gross_material_to_grab = gross_material_to_grab + water_flow_share * (elev_diff / MATERIAL_SLOPE)
			end
		end
		-- local log_str = ti .. ": " .. gross_material_to_grab

		if gross_material_to_grab <= 0 then
			-- logger:log(log_str)
			goto cont_loop1
		end

		local slope_weathering = math.max((steepest_face / 100) ^ 0.5, 0.75)
		-- log_str = log_str .. " " .. steepest_face .. " " .. slope_weathering
		local total_material = world.sand[ti] + world.silt[ti] + world.clay[ti]

		--* More base material in tile should = more grabbed
		gross_material_to_grab = gross_material_to_grab * slope_weathering * (total_material / gross_material_to_grab) ^ 0.5
		-- log_str = log_str .. " " .. gross_material_to_grab

		moving_sand[ti] = gross_material_to_grab * (world.sand[ti] / total_material)
		moving_silt[ti] = gross_material_to_grab * (world.silt[ti] / total_material)
		moving_clay[ti] = gross_material_to_grab * (world.clay[ti] / total_material)
		moving_minerals[ti] = world.mineral_richness[ti] * ((moving_sand[ti] + moving_silt[ti] + moving_clay[ti]) / total_material)
		moving_organics[ti] = gross_material_to_grab * (world.soil_organics[ti] / gross_material_to_grab) ^ 0.5

		-- logger:log(ti .. ": " .. moving_sand[ti] .. " " .. moving_silt[ti] .. " " .. moving_clay[ti] .. " " .. moving_minerals[ti] .. " " .. moving_organics[ti])
		-- logger:log(log_str)

		::cont_loop1::
	end)
end

local function identify_start_location()
	world:for_each_tile(function(ti)
		local true_elev = world:true_elevation_for_waterflow(ti)
		if true_elev <= 0 then goto cont_loop2 end

		--* This section locates all of our starting tiles for waterflow

		local has_higher_neigh = false
		for i = 0, world:neighbors_count(ti) - 1 do
			local nti = world.neighbors[ti * 6 + i]

			if world:true_elevation_for_waterflow(nti) > true_elev then
				has_higher_neigh = true
			end
		end
		if not has_higher_neigh then
			table.insert(water_flow_now, ti)
		end

		::cont_loop2::
	end)
end

local function drain_tile(ti)
	local giving_tile_body = world:get_waterbody_by_tile(ti)
	if giving_tile_body and giving_tile_body.type ~= waterbody.TYPES.wetland then return end

	--* If waterbody ID is 0, it means we're on land and we want to keep transferring material

	local true_elev = world:true_elevation_for_waterflow(ti)
	local num_neighs = world:neighbors_count(ti)

	--* Here we sum the elevation difference of all neighbor tiles
	local total_elevation_difference = 0
	for ni = 0, num_neighs - 1 do
		local nti = world.neighbors[ti * 6 + ni]
		local elevation_to_check = world:true_elevation_for_waterflow(nti)
		local wb = world:get_waterbody_by_tile(nti)

		--* If there is water at the location, check the waterlevel instead of the elevation since waterlevel will be higher
		if wb and wb.type ~= waterbody.TYPES.river and wb.type ~= waterbody.TYPES.wetland then
			elevation_to_check = wb.water_level
		end

		if elevation_to_check < true_elev then
			total_elevation_difference = total_elevation_difference + (true_elev - elevation_to_check)
		end
	end

	--* Now we decide share value to be distributed based on elevation disparities
	for ni = 0, num_neighs - 1 do
		local nti = world.neighbors[ti * 6 + ni]
		local elevation_to_check = world:true_elevation_for_waterflow(nti)
		local wb = world:get_waterbody_by_tile(nti)

		--* If there is water at the location, check the waterlevel instead of the elevation since waterlevel will be higher
		if wb and wb.type ~= waterbody.TYPES.river and wb.type ~= waterbody.TYPES.wetland then
			elevation_to_check = wb.water_level
		end

		if elevation_to_check < true_elev then
			local material_share = (true_elev - elevation_to_check) / total_elevation_difference

			moving_sand[nti] = moving_sand[nti] + material_share * moving_sand[ti]
			moving_silt[nti] = moving_silt[nti] + material_share * moving_silt[ti]
			moving_clay[nti] = moving_clay[nti] + material_share * moving_clay[ti]
			moving_minerals[nti] = moving_minerals[nti] + material_share * moving_minerals[ti]

			if not already_added[nti] then
				table.insert(water_flow_later, nti)
				already_added[nti] = true
			end
		end
	end

	if world.ice[ti] == 0 then
		sand_stash[ti] = sand_stash[ti] + math.floor(moving_sand[ti] * 0.05)
		silt_stash[ti] = silt_stash[ti] + math.floor(moving_silt[ti] * 0.05)
		clay_stash[ti] = clay_stash[ti] + math.floor(moving_clay[ti] * 0.05)
		mineral_stash[ti] = mineral_stash[ti] + math.floor(moving_minerals[ti] * 0.05)
	end

	moving_sand[ti] = 0
	moving_silt[ti] = 0
	moving_clay[ti] = 0
	moving_minerals[ti] = 0
end

local function apply_dropped_material()
	world:for_each_tile(function(ti)
		--* 10,000, anything over is scaled down.
		--* if at 30,000, scale down more

		local sand_sum = sand_stash[ti] + world.sand[ti]
		local silt_sum = silt_stash[ti] + world.silt[ti]
		local clay_sum = clay_stash[ti] + world.clay[ti]

		if sand_sum > 20000 then
			world.sand[ti] = math.floor(20000 + (sand_sum - 20000) ^ 0.8)
		end
		if silt_sum > 20000 then
			world.silt[ti] = math.floor(20000 + (silt_sum - 20000) ^ 0.8)
		end
		if clay_sum > 20000 then
			world.clay[ti] = math.floor(20000 + (clay_sum - 20000) ^ 0.8)
		end

		world.mineral_richness[ti] = math.floor(((world.sand[ti] + world.silt[ti] + world.clay[ti]) / (sand_sum + silt_sum + clay_sum)) * (mineral_stash[ti] + world.mineral_richness[ti]))

		-- logger:log(ti .. ": " .. world.sand[ti] .. " " .. world.silt[ti] .. " " .. world.clay[ti] .. " " .. world.mineral_richness[ti])
	end)
end

function lw.run(world_obj)
	world = world_obj

	already_added = world.tmp_bool_1
	moving_sand = world.tmp_float_1
	moving_silt = world.tmp_float_2
	moving_clay = world.tmp_float_3
	moving_minerals = world.tmp_float_4
	moving_organics = world.tmp_float_5
	sand_stash = world.tmp_int_1
	silt_stash = world.tmp_int_2
	clay_stash = world.tmp_int_3
	mineral_stash = world.tmp_int_4

	world:fill_ffi_array(already_added, false)
	world:fill_ffi_array(moving_sand, 0)
	world:fill_ffi_array(moving_silt, 0)
	world:fill_ffi_array(moving_clay, 0)
	world:fill_ffi_array(moving_minerals, 0)
	world:fill_ffi_array(moving_organics, 0)
	world:fill_ffi_array(sand_stash, 0)
	world:fill_ffi_array(silt_stash, 0)
	world:fill_ffi_array(clay_stash, 0)
	world:fill_ffi_array(mineral_stash, 0)

	--* Prep all surviving waterbodies for material load
	world:for_each_waterbody(function(wb)
		wb.sand_load = 0
		wb.silt_load = 0
		wb.clay_load = 0
		wb.mineral_load = 0
		wb.organic_load = 0
	end)

	calculate_organics()
	calculate_material_to_move()
	identify_start_location()

	while #water_flow_now > 0 do
		for _, ti in ipairs(water_flow_now) do
			drain_tile(ti)
		end

		world:fill_ffi_array(already_added, false)

		water_flow_now = {}
		for _, ti in ipairs(water_flow_later) do
			table.insert(water_flow_now, ti)
		end
		water_flow_later = {}
	end

	apply_dropped_material()

	world:for_each_waterbody(function(wb)
		for _, ti in ipairs(wb.tiles) do
			wb.sand_load = math.floor(wb.sand_load + moving_sand[ti])
			wb.silt_load = math.floor(wb.silt_load + moving_silt[ti])
			wb.clay_load = math.floor(wb.clay_load + moving_clay[ti])
			wb.mineral_load = math.floor(wb.mineral_load + moving_minerals[ti])
			wb.organic_load = math.floor(wb.organic_load + moving_organics[ti])
			-- logger:log(ti .. ": " .. wb.sand_load .. " " .. wb.silt_load .. " " .. wb.clay_load .. " " .. wb.mineral_load .. " " .. wb.organic_load)
		end
	end)
end

--* Plan for Alluvial soils. We want to move soil texture via water to determine the sediment load characteristics of rivers
--* At the moment I'm partial to a simpler plan in which we move material downstream based on pre-existing waterflow data. This way we don't need to use
--* up any of our logic variables on where water needs to flow. The only tricky part is determining how much material gets picked up by the water, because we may
--* have tiles checked multiple times.
--*
--* Presuming the simpler plan... We determine how transportable material is produced at all land locations based on waterflow.
--* Find all tiles in the world with no higher neighbors. Start process, move material "downstream" by checking all neighbors that are lower in elevation,
--* distribute material based on locations of highest water flow. Higher waterflow = more material given
--*
--* Then we always take a percentage that is passing through tile and deposit into the tile's material
--* As soon as we hit a waterbody, all material is placed directly into the waterbody.

--* Phase 2 will then iterate through all end points of our waterbodies and then transport material "downstream" until we reach the ocean.
--* As a side note, we'll be able to build deltas depending on the sediment load.
--* As sediment is transported though, we want to convert some of the larger grain sediment into smaller grain sediment so that sand turns to silt which
--* turns to clay. The longer the river and more rugged, the more material gets broken down into silty and claysize grains.

--* Phase 3 will involve "flooding" the banks of our rivers so that we finally produce alluvial soils based on the sediment load of that particular river
--* tributary.

return lw