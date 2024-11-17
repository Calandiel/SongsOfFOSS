local gas = {}

local wgu = require "libsote.world-gen-utils"
local wb_types = require("libsote.hydrology.waterbody").TYPES

local enable_debug = true
-- local logger = require("libsote.debug-loggers").get_soils_logger("d:/temp")

local world
local rng
local added_to_list
local finalized
local deposited_sand
local deposited_silt
local deposited_clay
local deposited_minerals
local tile_penetration
local temp_penetration

local function thin_soils()
	world:for_each_tile(function(ti)
		local _, steepest_face = wgu.elev_diff_and_steepest_face(world, ti)
		local erosion_factor = math.min(1, 50 / steepest_face)

		local new_sand = world.sand[ti] * erosion_factor
		local new_silt = world.silt[ti] * erosion_factor
		local new_clay = world.clay[ti] * erosion_factor
		local percent_remaining = (new_sand + new_silt + new_clay) / (world.sand[ti] + world.silt[ti] + world.clay[ti])

		world.mineral_richness[ti] = math.floor(world.mineral_richness[ti] * percent_remaining)
		world.sand[ti] = math.floor(new_sand)
		world.silt[ti] = math.floor(new_silt)
		world.clay[ti] = math.floor(new_clay)
	end)
end

local old_layer = {}
local new_layer = {}
local all_influenced = {}

local function process_ring_tile(ti, water_height, ring_num)
	local penetration = tile_penetration[ti]
	local raiseable_water = water_height - penetration
	local true_elev = world:true_elevation_for_waterflow(ti)

	for ni = 0, world:neighbors_count(ti) - 1 do
		local nti = world.neighbors[ti * 6 + ni]
		if not world.is_land[nti] then goto cont_loop1 end

		local elev_diff = math.max(0, world:true_elevation_for_waterflow(nti) - true_elev)

		local wb = world:get_waterbody_by_tile(nti)
		local is_wetland_or_river = wb and (wb.type == wb_types.river or wb.type == wb_types.wetland)

		if raiseable_water <= elev_diff and not is_wetland_or_river then goto cont_loop1 end

		if raiseable_water > 0 and not finalized[nti] then
			local standard_modifier = math.floor(elev_diff * 0.5 * ring_num) + ring_num * 20
			standard_modifier = ring_num < 2 and standard_modifier * 0.5 or standard_modifier

			if is_wetland_or_river then
				local wetland_river_modifier = 2 --* Scales up slower than non-wetland river modifier
				wetland_river_modifier = ring_num > 2 and wetland_river_modifier + standard_modifier * 0.5 or wetland_river_modifier

				temp_penetration[nti] = math.min(temp_penetration[nti], penetration + wetland_river_modifier)
			else
				local variation = rng:random_int_min_max(4, 15)
				temp_penetration[nti] = math.min(temp_penetration[nti], math.floor(elev_diff) + penetration + standard_modifier + variation)
			end
		end

		if not added_to_list[nti] and temp_penetration[nti] <= water_height then
			table.insert(new_layer, nti)
			added_to_list[nti] = true
			table.insert(all_influenced, nti)
		end

		::cont_loop1::
	end
end

local function flood_from_tile(wb, ti, water_height)
	old_layer = {}
	new_layer = {}
	all_influenced = {}

	table.insert(old_layer, ti)
	table.insert(all_influenced, ti)

	added_to_list[ti] = true
	finalized[ti] = true

	local ring_num = 0
	while #old_layer > 0 and ring_num < 20 do
		for _, rti in ipairs(old_layer) do
			process_ring_tile(rti, water_height, ring_num)
		end

		old_layer = {}
		for _, nlti in ipairs(new_layer) do
			finalized[nlti] = true --* This allows us to prevent older tiles being reset in reverse
			tile_penetration[nlti] = tile_penetration[nlti] + temp_penetration[nlti]
			temp_penetration[nlti] = tile_penetration[nlti]

			table.insert(old_layer, nlti)
		end
		new_layer = {}

		ring_num = ring_num + 1
	end

	local total_body_material = wb.sand_load + wb.silt_load + wb.clay_load
	local base_dispersed_material = total_body_material ^ 0.5
	local base_dispersed_sand = base_dispersed_material * (wb.sand_load / total_body_material)
	local base_dispersed_silt = base_dispersed_material * (wb.silt_load / total_body_material)
	local base_dispersed_clay = base_dispersed_material * (wb.clay_load / total_body_material)
	local base_dispersed_minerals = wb.mineral_load * (base_dispersed_material / total_body_material)

	-- logger:log(ti .. ": " .. water_height .. "; " .. #all_influenced)
	for _, iti in ipairs(all_influenced) do
		-- logger:log("\t" .. iti .. ": " .. tile_penetration[iti])
		added_to_list[iti] = false
		finalized[iti] = false
		temp_penetration[iti] = 10000

		local scaled_contribution = 1 - math.min(tile_penetration[iti], water_height) / water_height --* How high the water had to go has an inverse influence on the amount of material deposited
		deposited_sand[iti] = deposited_sand[iti] + scaled_contribution * base_dispersed_sand
		deposited_silt[iti] = deposited_silt[iti] + scaled_contribution * base_dispersed_silt
		deposited_clay[iti] = deposited_clay[iti] + scaled_contribution * base_dispersed_clay
		deposited_minerals[iti] = deposited_minerals[iti] + scaled_contribution * base_dispersed_minerals

		tile_penetration[iti] = 0
	end
end

local function flood_banks()
	world:for_each_waterbody(function(wb)
		if wb.type ~= wb_types.river and wb.type ~= wb_types.freshwater_lake and wb.type ~= wb_types.saltwater_lake then return end

		local total_body_material = wb.sand_load + wb.silt_load + wb.clay_load
		local water_height = wb.type == wb_types.river and math.floor((wb.water_level / 100) ^ 0.5) or math.floor((total_body_material / 200) ^ 0.5)

		if wb.type == wb_types.river then
			for _, ti in ipairs(wb.tiles) do
				flood_from_tile(wb, ti, water_height)
				-- logger:log("river tile; " .. ti .. " " .. water_height)
			end
		else
			for ti, _ in pairs(wb.perimeter) do
				flood_from_tile(wb, ti, water_height)
				-- logger:log("lakep tile; " .. ti .. " " .. water_height)
			end
		end
	end)
end

local SCALING_THRESHOLD = 30000

local function scale_and_set_soils()
	local max_sand = 0
	local max_silt = 0
	local max_clay = 0
	local max_mineral = 0

	world:for_each_tile(function(ti)
		if not world.is_land[ti] then return end

		local total_texture_added = deposited_sand[ti] + deposited_silt[ti] + deposited_clay[ti]
		if total_texture_added > SCALING_THRESHOLD then
			local revised_material = (total_texture_added - SCALING_THRESHOLD) ^ 0.8 --* The material that gets trimmed off the top and then scaled down
			local base_sand_added = SCALING_THRESHOLD * (deposited_sand[ti] / total_texture_added)
			local base_silt_added = SCALING_THRESHOLD * (deposited_silt[ti] / total_texture_added)
			local base_clay_added = SCALING_THRESHOLD * (deposited_clay[ti] / total_texture_added)

			deposited_sand[ti] = (deposited_sand[ti] / total_texture_added) * (revised_material / (total_texture_added - SCALING_THRESHOLD)) + base_sand_added
			deposited_silt[ti] = (deposited_silt[ti] / total_texture_added) * (revised_material / (total_texture_added - SCALING_THRESHOLD)) + base_silt_added
			deposited_clay[ti] = (deposited_clay[ti] / total_texture_added) * (revised_material / (total_texture_added - SCALING_THRESHOLD)) + base_clay_added

			local revised_total_material = deposited_sand[ti] + deposited_silt[ti] + deposited_clay[ti]
			local old_mineral_percent = deposited_minerals[ti] / total_texture_added
			deposited_minerals[ti] = revised_total_material * old_mineral_percent
		end

		if enable_debug then
			max_sand = math.max(max_sand, math.log(1 + deposited_sand[ti]))
			max_silt = math.max(max_silt, math.log(1 + deposited_silt[ti]))
			max_clay = math.max(max_clay, math.log(1 + deposited_clay[ti]))
			max_mineral = math.max(max_mineral, math.log(1 + deposited_minerals[ti]))
		end

		world.sand[ti] = world.sand[ti] + math.floor(deposited_sand[ti])
		world.silt[ti] = world.silt[ti] + math.floor(deposited_silt[ti])
		world.clay[ti] = world.clay[ti] + math.floor(deposited_clay[ti])
		world.mineral_richness[ti] = world.mineral_richness[ti] + math.floor(deposited_minerals[ti])
		-- logger:log(ti .. ": " .. world.sand[ti] .. " " .. world.silt[ti] .. " " .. world.clay[ti] .. " " .. world.mineral_richness[ti])
	end)

	if enable_debug then
		world:for_each_tile(function(ti)
			local fraction = math.log(deposited_sand[ti] + 1) / max_sand
			-- local fraction = math.log(deposited_silt[ti] + 1) / max_silt
			-- local fraction = math.log(deposited_clay[ti] + 1) / max_clay
			-- local fraction = math.log(deposited_minerals[ti] + 1) / max_mineral
			local color = math.floor(fraction * 255)
			world:set_debug_rgba(1, ti, color, 0, 0, 255)
		end)
	end
end

--* New plan: Expand on each tile. Each tile expands X rings. However, each tile has a ticker variable depending on how many expansions they are permitted.
--* As each tile attempts to "invade" a new tile, it must spend ticker points based on the elevation its trying to expand.
--* How much we deposit can be based on how much elevation penetration remains.

function gas.run(world_obj)
	world = world_obj
	rng = world.rng

	added_to_list = world.tmp_bool_1
	finalized = world.tmp_bool_2
	deposited_sand = world.tmp_float_1
	deposited_silt = world.tmp_float_2
	deposited_clay = world.tmp_float_3
	deposited_minerals = world.tmp_float_4
	tile_penetration = world.tmp_int_1
	temp_penetration = world.tmp_int_2

	if require("libsote.debug-control-panel").soils.align_rng then
		rng = require("libsote.randomness"):new(world.seed + 19832)
	end

	world:fill_ffi_array(added_to_list, false)
	world:fill_ffi_array(finalized, false)
	world:fill_ffi_array(deposited_sand, 0)
	world:fill_ffi_array(deposited_silt, 0)
	world:fill_ffi_array(deposited_clay, 0)
	world:fill_ffi_array(deposited_minerals, 0)
	world:fill_ffi_array(tile_penetration, 0)
	world:fill_ffi_array(temp_penetration, 10000)

	if enable_debug then
		world:adjust_debug_channels(1)
		world:reset_debug_all()
	end

	--* First we want to thin our soils based on slope... then we can use that to inform a soil depth factor for favorability of farming lands
	thin_soils()
	--* Flood banks to generate alluvial soils
	flood_banks()
	scale_and_set_soils()
end

--* FINALLY! We will create alluvial soils based on a mix of sediment load + water volume moved by a given river tributary. We may want to use
--* this opportunity as well to determine watertables around a given waterbody, as this is especially important in arid regions in which 
--* alluvial soils will simply blow away if too dry.
--* MY initial impulse is to just iterate through all pertinent waterbodies and run an expansion algorithm... but we could have some unusual
--* outcomes in which two different tributaries of the same watershed happen to overlap. So we may need a more generalized model that is similar to
--* how we generated elevation and oceanography.

--* The two approaches:
--* Approach 1: Iterate through EACH waterbody singularly. Build out layers from said waterbody. Have change in elevation influence rate
--* of expansion. Eventually expanding layer slows down as it loses inertia. With this approach, the watervolume of a given river is "pushing"
--* against the elevation change as we move up hill, until eventually we come into equilibrium at the frontiers of the alluvial soils.
--* Approach 2: We iterate through all waterbodies and plunk down sediment value, waterflow, etc in each tile. Push tiles into general list
--* After iterating through all pertinent tiles, we then run a separate algorithm on the general list that we've created and we generate generalized
--* rules of behavior within a tile. All of these tiles then "compete" and we use a kind of "diffusion" model. I'm more partial to this approach,
--* but need to think about it a bit more.

return gas