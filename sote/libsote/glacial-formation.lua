local gm = {}

-- NOTE 2024.07.06: The comments are close to the original, but may have been edited for clarity and relevance to the current state.
-- In order to distinguish between the original comments and the new ones, the original ones are marked with "--*"

---@enum age_types
local AGE_TYPES = {
	ice_age  = 0,
	game_age = 1
}

-- local logger = require("libsote.debug-loggers").get_glacial_logger("d:/temp")
local open_issues = require "libsote.glacial-open-issues"

local glacial_seed
local ice_flow
local ice_moved
local distance_from_edge
local invasion_ticker

local old_layer = {}
local new_layer = {}
local glacial_seed_table = {}

local function length(t)
	local count = 0
	for _ in pairs(t) do count = count + 1 end
	return count
end

local function set_debug(world, ti, r, g, b)
	world.debug_r[ti] = r
	world.debug_g[ti] = g
	world.debug_b[ti] = b
end

local function create_glacial_start_locations(world, is_ice_age)
	local ice_age_factor = 5
	if is_ice_age then ice_age_factor = -10 end --* Makes world colder for ice age

	local seed_threshold = -15 --* -15 for non-Ice Age
	if is_ice_age then seed_threshold = 0 end

	local start = love.timer.getTime()

	world:for_each_tile(function(ti)
	-- world:for_each_tile_by_elevation_for_waterflow(function(ti, _)
		-- local log_str = "gs: " .. world.colatitude[ti] .. "," .. world.minus_longitude[ti] .. "; " .. world:true_elevation_for_waterflow(ti) .. "; " .. ti .. "\n"

		local wb = world:get_waterbody_by_tile(ti)
		local waterbody_size = (wb == nil) and 0 or #wb.tiles

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
			-- log_str = log_str .. "\tis seeded"
			-- glacial_seed[ti] = true
			glacial_seed_table[ti] = true
			ice_flow[ti] = ice_depth

			set_debug(world, ti, 0, 0, 255)
		-- else
			-- log_str = log_str .. "\tnot seeded, no ice"
			-- glacial_seed[ti] = false
		end
		-- logger:log(log_str)
	end)

	local duration = love.timer.getTime() - start
	print("[glacial-formation] create_glacial_start_locations: " .. tostring(duration * 1000) .. "ms")

	-- local count = 0
	-- world:for_each_tile(function(ti)
	-- 	if glacial_seed[ti] then
	-- 		count = count + 1
	-- 	end
	-- end)
	print("Glacial Seeds: " .. length(glacial_seed_table))
end

local function find_glacial_perimeter(world)
	old_layer = {}

	local start = love.timer.getTime()

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
	for ti, _ in pairs(glacial_seed_table) do
		world:for_each_neighbor(ti, function(nti)
			if glacial_seed_table[nti] ~= nil then return end
			old_layer[nti] = true
			distance_from_edge[nti] = 1

			set_debug(world, nti, 255, 0, 0)
		end)
	end
	-- world:for_each_tile(function(ti)
	-- 	if glacial_seed_table[ti] ~= nil then return end

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

	local duration = love.timer.getTime() - start
	print("[glacial-formation] find_glacial_perimeter: " .. tostring(duration * 1000) .. "ms")

	print("Old Layer: " .. length(old_layer))
end

local function find_distance_of_each_glacier_tile_from_edge(world)
	local elevation_factor = 500
	local base_expansion = 100
	local expansion_threshold = 300

	local start = love.timer.getTime()

	new_layer = {}

	local expansion_ticker = 1 --* Keeps track of how many loops we've done.
	local num_tiles = length(old_layer)

	while num_tiles > 0 do
		expansion_ticker = expansion_ticker + 1

		--* Expanding layer
		for oti in pairs(old_layer) do
			--* We want each tile in oldLayer to "attack" unoccupied tiles, and add some base value * depression factor which = elevation
			--* Once threshold is met we add the tile to newLayer

			local attacked_neighbor = false

			world:for_each_neighbor(oti, function(nti)
				if glacial_seed_table[nti] == nil or distance_from_edge[nti] > 0 then return end

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
		for key, _ in pairs(new_layer) do
			old_layer[key] = true
		end
		new_layer = {}

		num_tiles = length(old_layer)
	end

	local duration = love.timer.getTime() - start
	print("[glacial-formation] find_distance_of_each_glacier_tile_from_edge: " .. tostring(duration * 1000) .. "ms")
	print("Expansion Ticker: " .. expansion_ticker)

	world:for_each_tile(function(ti)
		if distance_from_edge[ti] == 0 then return end
		local fraction = distance_from_edge[ti] / expansion_ticker
		local red = fraction * 255
		local blue = (1 - fraction) * 255
		set_debug(world, ti, red, 0, blue)
	end)
end

local function reset_variables(world)
	world:fill_ffi_array(glacial_seed, false)
	glacial_seed_table = {}
	world:fill_ffi_array(ice_flow, 0)
	world:fill_ffi_array(ice_moved, 0)
	world:fill_ffi_array(distance_from_edge, 0)
	world:fill_ffi_array(invasion_ticker, 0)
end

---@param world World
---@param age_type age_types
local function process_age(world, age_type)
	world:fill_ffi_array(world.debug_r, 0)
	world:fill_ffi_array(world.debug_g, 0)
	world:fill_ffi_array(world.debug_b, 0)

	local is_ice_age = age_type == AGE_TYPES.ice_age

	create_glacial_start_locations(world, is_ice_age)
	find_glacial_perimeter(world)
	find_distance_of_each_glacier_tile_from_edge(world)

	reset_variables(world)
end

function gm.run(world)
	--* Before we even set seeds, we need to construct temp waterbodies to determine which ones are large, and which ones are small. Ocean waterbodies 
	--* of a sufficient volume will have heat exchanging capacity and act as hard barriers for glacial expansion. Smaller waterbodies can simply 
	--* be elligible to be seeds but have "stricter threshold."
	--* Need boolean to see if part of waterbody. Need logic variable integer to represent "size of waterbody."

	-- 2024.07.07: Above comment might not be relevant. Waterbodies are already defined by gen-initial-waterbodies and we will attempt to use them here instead of re-generating them.

	glacial_seed = world.tmp_bool_1
	ice_flow = world.tmp_float_2
	ice_moved = world.tmp_float_3
	distance_from_edge = world.tmp_int_1
	invasion_ticker = world.tmp_int_2

	world:fill_ffi_array(glacial_seed, false)
	world:fill_ffi_array(ice_flow, 0)
	world:fill_ffi_array(ice_moved, 0)
	world:fill_ffi_array(distance_from_edge, 0)
	world:fill_ffi_array(invasion_ticker, 0)

	process_age(world, AGE_TYPES.ice_age)
	process_age(world, AGE_TYPES.game_age)
end

return gm