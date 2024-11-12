local wat = {}

local wb_types = require("libsote.hydrology.waterbody").TYPES

-- local logger = require("libsote.debug-loggers").get_soils_logger("d:/temp")

local world

local function prep_waterbodies()
	world:for_each_waterbody(function(wb)
		wb.tmp_float_1 = 0

		if wb.type ~= wb_types.river then return end

		--* If river, go through members and determine the "slope of the river." This will inform the rate at which material is broken down, as well as navigatibility

		local beginning_elev = world.elevation[wb.tiles[1]]
		local end_elev = world.elevation[wb.tiles[#wb.tiles]]
		local total_diff = beginning_elev - end_elev
		wb.river_slope = (total_diff / #wb.tiles) / 10

		--* Determine annual water volume for rivers
		local total_tile_movement = 0
		for _, ti in ipairs(wb.tiles) do
			total_tile_movement = total_tile_movement + world.water_movement[ti]
		end
		wb.water_level = total_tile_movement / #wb.tiles --* Sets total volume moving through river
	end)

	--* Populating each waterbody with number corresponding to how many waterbodies contribute
	world:for_each_waterbody(function(wb)
		if (wb.type ~= wb_types.freshwater_lake or not wb.lake_open) and wb.type ~= wb_types.river then return end

		--* We want to be sure that we start on either a lake that drains or a river

		local hit_ocean = false
		local current_wb = wb
		local terminal_ticker = 0

		--* we begin the drainage process here

		while not hit_ocean and terminal_ticker < 1000 do
			terminal_ticker = terminal_ticker + 1
			current_wb.tmp_float_1 = current_wb.tmp_float_1 + 1

			if current_wb.type == wb_types.ocean or current_wb.type == wb_types.saltwater_lake or (current_wb.type == wb_types.freshwater_lake and not current_wb.lake_open) then
				hit_ocean = true
			end

			local drain_target_wb = current_wb.drain
			if drain_target_wb and drain_target_wb:is_valid() then
				current_wb = drain_target_wb
			elseif hit_ocean then
				terminal_ticker = 1000
			else
				error("Drainage error: " .. current_wb.id)
			end
		end
	end)
end

local BASE_SILTATION_TUNER = 700 --* The value that we divide the siltation amount be

local function process_waterbody_drainage_and_degradation(waterbody_count)
	world:for_each_waterbody(function(wb)
		if wb.tmp_float_1 ~= waterbody_count then return end

		--* We want to be sure that we start on either a lake that drains or a river
		if (wb.type ~= wb_types.freshwater_lake or not wb.lake_open) and wb.type ~= wb_types.river then return end

		if wb.type == wb_types.river then
			local temp_sand = wb.sand_load --* Need to use a float so we don't chop off the decimal after each tile member is checked
			local extra_silt = 0 --* Silt that gets converted. Add to total silt in the waterbody at the end
			-- local weathering_value = wb.river_slope * wb:size() --* The total sand weathering value of the river

			--* Each tile gets its turn to weather down the sand
			for _, ti in ipairs(wb.tiles) do
				local sand_friction = temp_sand / wb.water_level --* Determines amount of weathering due to load of sand
				local sand_converted = (temp_sand * sand_friction * wb.river_slope) / BASE_SILTATION_TUNER
				temp_sand = temp_sand - sand_converted
				extra_silt = extra_silt + sand_converted
			end

			wb.silt_load = wb.silt_load + math.floor(extra_silt)
			wb.sand_load = math.floor(temp_sand)
		end

		wb.drain.sand_load = wb.drain.sand_load + wb.sand_load
		wb.drain.silt_load = wb.drain.silt_load + wb.silt_load
		wb.drain.clay_load = wb.drain.clay_load + wb.clay_load
		wb.drain.mineral_load = wb.drain.mineral_load + wb.mineral_load
		wb.drain.organic_load = wb.drain.organic_load + wb.organic_load
	end)
end

function wat.run(world_obj)
	world = world_obj

	prep_waterbodies()

	local most_tributaries = 0 --* Represents how many times we want to loop through the drain cycle. Corresponds to the river section with the most contributors
	world:for_each_waterbody(function(wb)
		if wb.type ~= wb_types.river then return end
		most_tributaries = math.max(most_tributaries, wb.tmp_float_1)
	end)

	--* REVISION FOR Friday!
	--* Use the waterbodyDebug value we generated as a means of draining our tributaries.
	--* We start with individuals of value 1, iterate up one by one and drain each waterbody by rank. So every value "1" waterbody needs to
	--* drain first, then every rank 2.... all the way up to X, where X = the total contributing members of the indendent tributary with the
	--* most contributing members.
	--* We would more or less use the same exact code internally that we used before, the only difference is that we are reordering the waterbodies
	--* so that headwaters ALWAYS go first, and stuff toward the end of a watershed goes last.

	local waterbody_count = 0
	while waterbody_count < most_tributaries do
		waterbody_count = waterbody_count + 1
		process_waterbody_drainage_and_degradation(waterbody_count)
	end

	-- world:for_each_waterbody(function(wb)
	-- 	logger:log(wb.id .. ": " .. wb.sand_load .. " " .. wb.silt_load .. " " .. wb.clay_load .. " " .. wb.mineral_load .. " " .. wb.organic_load)
	-- end)
end

--* Phase two of process: we need to create a new job in which we move water from "end points" in waterbodies to low points.
--* The main issue we have here is we need larger grained material to break down as we go down stream.
--* So the first order of business is to give our rivers characteristics in terms of their "speed."  Rivers with greater "slope" will
--* produce more silt from sand, and more clay from silt.
--* Then we iterate through every waterbody in the world except for wetlands and we drain them to the ocean, moving the sediment load and running
--* the pertinent "break down" calculations. This will involve lots of redundancy but it may have a trivial influence on gen time, we'll just have to see.
--* If that fails we always attempt to pre-sort them so that there is less redundancy, but that involves more developer time.

--* We're probably going to want to keep a separate list of everything that ever went through each waterbody, then translate it over in the end.

return wat