local dl = {}

local world

local open_issues = require "libsote.hydrology.open-issues"

-- local logger = require("libsote.debug-loggers").get_lakes_logger("d:/temp")
local prof = require "libsote.profiling-helper"
local prof_prefix = "[gen-dynamic-lakes]"

local function run_with_profiling(func, log_txt)
	prof.run_with_profiling(func, prof_prefix, log_txt)
end

local water_flow_now = {}
local water_flow_later = {}

local function find_start_tiles()
	world:for_each_tile(function(ti)
		--* Unmoved water
		world.tmp_float_2[ti] = world.jan_rainfall[ti] + world.jul_rainfall[ti] --* Our total rainfall annually in tile
		if world.tmp_float_2[ti] < 15 then --* If below value, reduce moveable water without reducing rainfall (below a certain value, we assume a desert)
			world.tmp_float_2[ti] = world.tmp_float_2[ti] * 0.75
		end

		open_issues.set_water_movement_for_lakes(world, ti)

		if world:true_elevation_for_waterflow(ti) < 0 then return end

		--* This section locates all of our starting tiles for waterflow
		local has_higher_neighbor = false
		world:for_each_neighbor(ti, function(nti)
			if world:true_elevation_for_waterflow(nti) > world:true_elevation_for_waterflow(ti) then
				has_higher_neighbor = true
				return
			end
		end)

		if not has_higher_neighbor then
			table.insert(water_flow_now, ti)
		end
	end)
end

local function water_flow_from_tile_to_tile()
	for i = 1, #water_flow_now do
		local ti = water_flow_now[i]

		local water_movement = world.water_movement[ti]

		local modified_evaporation_factor = 0
		if water_movement < 25 then --* This section helps to simulate evaporation in desert environments
			modified_evaporation_factor = modified_evaporation_factor + 1
		end
		if water_movement < 20 then
			modified_evaporation_factor = modified_evaporation_factor + 2
		end
		if water_movement < 10 then
			modified_evaporation_factor = modified_evaporation_factor + 3
		end

		local water_to_give = world.tmp_float_2[ti] - modified_evaporation_factor * (world.jan_humidity[ti] + world.jul_humidity[ti]) / 2
		if water_to_give < 0 then
			water_to_give = 0
		end
		world.tmp_float_2[ti] = 0

		local true_elevation_for_waterflow = world:true_elevation_for_waterflow(ti)

		if water_to_give <= 0.1 or true_elevation_for_waterflow < 0 then goto continue1 end

		local total_elevation_difference = 0
		world:for_each_neighbor(ti, function(nti) --* Here we sum the elevation difference of all neighbor tiles
			local elevation_to_check = world:true_elevation_for_waterflow(nti)
			local wb = world:get_waterbody_by_tile(nti)
			if wb then elevation_to_check = wb.water_level end --* If there is water at the location, check the waterlevel instead of the elevation since waterlevel will be higher

			if elevation_to_check < true_elevation_for_waterflow then
				total_elevation_difference = total_elevation_difference + (true_elevation_for_waterflow - elevation_to_check)
			end
		end)

		if total_elevation_difference > 0 then --* Now we actually distribute water if the tile has at least 1 lower neighbor
			world:for_each_neighbor(ti, function(nti)
				local elevation_to_check = world:true_elevation_for_waterflow(nti)
				local nwb = world:get_waterbody_by_tile(nti)
				if nwb then --* If there is water at the location, check the waterlevel instead of the elevation since waterlevel will be higher
					elevation_to_check = nwb.water_level
				end

				if elevation_to_check >= true_elevation_for_waterflow then return end

				--* Neighbor needs to be lower in elevation to get water
				local water_to_neighbor = (true_elevation_for_waterflow - elevation_to_check) / total_elevation_difference * water_to_give

				if nwb then --* If there is a waterbody in tile, add water to that waterbody as opposed to the tile.
					nwb.tmp_float_1 = nwb.tmp_float_1 + water_to_neighbor
				else
					world.tmp_float_3[nti] = world.tmp_float_3[nti] + water_to_neighbor --* Water to add is the water that will run next round

					--* We only add into this list once per "round" if tile is elligible for water movement
					if world.tmp_bool_1[nti] then return end

					table.insert(water_flow_later, nti)
					world.tmp_bool_1[nti] = true
				end
			end)

			goto continue1
		end

		if world:get_waterbody_by_tile(ti) then goto continue1 end

		--* If elevation difference is 0, it can be inferred that we have no tiles lower than the target tile, therefore it should construct a lake.
		local new_wb = world:create_new_waterbody_from_tile(ti)

		--* Mark the tile as water
		world.is_land[ti] = false

		--* Now we build the shoreline
		world:for_each_neighbor(ti, function(nti)
			new_wb:add_to_perimeter(nti)
		end)

		new_wb:set_lowest_shore_tile(world)
		new_wb.tmp_float_1 = new_wb.tmp_float_1 + water_to_give
		new_wb.water_level = true_elevation_for_waterflow
		new_wb.type = new_wb.TYPES.saltwater_lake

		-- logger:log("\tlake " .. new_wb.id .. " created at " .. ti)

		::continue1::
	end
end

local lake_divisor = 20 --* divides the value of the water going into waterbodies

local function add_lowest_shore_tile_to_waterbody(wb, lsti)
	wb.tmp_float_1 = wb.tmp_float_1 + world.tmp_float_2[lsti] / lake_divisor --* If a tile gets eaten by a lake, we automatically move any water that was in the tile to the lake
	world.tmp_float_2[lsti] = 0

	world:add_tile_to_waterbody(wb, lsti)

	local true_elevation_for_waterflow = world:true_elevation_for_waterflow(lsti)
	world:for_each_neighbor(lsti, function(nti)
		if true_elevation_for_waterflow >= world:true_elevation_for_waterflow(nti) then return end

		local nwb = world:get_waterbody_by_tile(nti)
		if nwb and nwb.id == wb.id then return end

		wb:add_to_perimeter(nti)
	end)

	wb:remove_from_perimeter(lsti)
	wb:set_lowest_shore_tile(world)
end

local function manage_expansion_and_drainage(wb, water_to_disburse)
	local lowest_shore_ti = wb.lowest_shore_tile
	local true_elevation_for_waterflow = world:true_elevation_for_waterflow(lowest_shore_ti)
	local volume_to_fill = (true_elevation_for_waterflow - wb.water_level) * wb:size()
	-- logger:log("\t\tlake " .. wb.id .. " (" .. wb:size() .. ", " .. wb.water_level .. ", " .. lowest_shore_ti .. ", " .. world:true_elevation_for_waterflow(wb.lowest_shore_tile) .. ") has volume to fill: " .. volume_to_fill .. " and water to disburse: " .. water_to_disburse)

	--* If true, simply add water to watervolume
	if water_to_disburse < volume_to_fill then
		wb.water_level = wb.water_level + water_to_disburse / wb:size()
		-- logger:log("\t\tlake " .. wb.id .. " filled to " .. wb.water_level .. " with 0 water left")
		return 0
	end

	--* Otherwise, we need to determine whether the shore tile is added to the waterbody or drains
	water_to_disburse = water_to_disburse - volume_to_fill --* Subtract volume that it takes to fill up lake to lowest shore tile
	wb.water_level = true_elevation_for_waterflow --* Raise water level to the lowest tile

	-- logger:log("\t\tlake " .. wb.id .. " filled to " .. wb.water_level .. " with " .. water_to_disburse .. " water left")

	local body_to_kill = nil
	local has_lower_neigh = false --* This will inform us as to whether we need to add the tile to the lake or drain into this tile

	world:for_each_neighbor(lowest_shore_ti, function(nti)
		local nwb = world:get_waterbody_by_tile(nti)
		if nwb and nwb.id == wb.id then return end --* Excluding tiles which belong to the current water body being checked.

		local elevation_to_check = world:true_elevation_for_waterflow(nti)

		if nwb and nwb.id > 0 then
			--* If there is water at the location, check the waterlevel instead of the elevation since waterlevel will be higher
			elevation_to_check = nwb.water_level

			if wb.water_level == nwb.water_level then --* If water levels of both bodies are the same
				body_to_kill = nwb
			end
		end

		if true_elevation_for_waterflow > elevation_to_check then
			has_lower_neigh = true
		end
	end)

	--* Kill neighbor waterbody and combine it with current waterbody
	if body_to_kill then
		-- logger:log("\t\t\tlake " .. wb.id .. " combining with lake " .. body_to_kill.id)
		wb.tmp_float_1 = wb.tmp_float_1 + body_to_kill.tmp_float_1

		world:merge_waterbodies(wb, body_to_kill)
		add_lowest_shore_tile_to_waterbody(wb, lowest_shore_ti)

		return water_to_disburse
	end

	--* Drain lake into shore tile with low neighbor that is not the same waterbody
	if has_lower_neigh then
		-- local log_str = "\t\t\tlake " .. wb.id .. " draining into tile " .. lowest_shore_ti
		local lsti_wb = world:get_waterbody_by_tile(lowest_shore_ti)
		if lsti_wb then
			-- logger:log(log_str .. " which belongs to lake " .. lsti_wb.id)
		-- else
		-- 	logger:log(log_str)
		end

		wb.lake_open = true
		wb.type = wb.TYPES.freshwater_lake
		world.tmp_float_2[lowest_shore_ti] = world.tmp_float_2[lowest_shore_ti] + water_to_disburse * lake_divisor --* Convert back to centimeters
		world.water_movement[lowest_shore_ti] = world.water_movement[lowest_shore_ti] + water_to_disburse * lake_divisor --* Convert back to centimeters
		if not world.tmp_bool_1[lowest_shore_ti] then
			table.insert(water_flow_later, lowest_shore_ti)
			world.tmp_bool_1[lowest_shore_ti] = true
		end

		return 0
	end

	--* if false, add tile to lake
	add_lowest_shore_tile_to_waterbody(wb, lowest_shore_ti)
	-- logger:log("\t\t\tlake " .. wb.id .. " added tile " .. lowest_shore_ti .. ": " .. world:true_elevation_for_waterflow(wb.lowest_shore_tile))

	return water_to_disburse
end

local function resize_lakes()
	--* Loop through all waterbodies. Check for active, and check for tempWater.

	world:for_each_waterbody(function(wb)
		-- if not wb:is_valid() then return end -- do we really need this check?

		if wb.tmp_float_1 <= 0 or wb.type == wb.TYPES.ocean then return end
		--* Only resize lakes and seas

		local water_to_disburse = wb.tmp_float_1 / lake_divisor
		wb.tmp_float_1 = 0

		-- logger:log("\tlake " .. wb.id .. " (" .. wb:size() .. ", " .. wb.water_level .. ", " .. world:true_elevation_for_waterflow(wb.lowest_shore_tile) .. ") has water to disburse: " .. water_to_disburse)

		--* Continue to grow lake until all water is used up
		while water_to_disburse > 0 do
			water_to_disburse = manage_expansion_and_drainage(wb, water_to_disburse)
		end
	end)
end

local function prep_for_next_round()
	--* Insuring we clear out bool on new tiles
	for _, ti in ipairs(water_flow_later) do
		world.tmp_bool_1[ti] = false
		world.tmp_float_2[ti] = world.tmp_float_2[ti] + world.tmp_float_3[ti]
		world.water_movement[ti] = world.water_movement[ti] + world.tmp_float_3[ti]
		world.tmp_float_3[ti] = 0
	end

	--* Insuring we clear our bool on old tiles
	for _, ti in ipairs(water_flow_now) do
		world.tmp_float_3[ti] = 0
		world.tmp_bool_1[ti] = false
	end

	water_flow_now = {}
	for i = 1, #water_flow_later do
		table.insert(water_flow_now, water_flow_later[i])
	end
	water_flow_later = {}
end

local function water_flow_phase()
	water_flow_later = {}

	local iter = 0

	while #water_flow_now > 0 do
		-- logger:log("iter: " .. iter .. "; water_flow_now: " .. #water_flow_now)

		water_flow_from_tile_to_tile()

		--* Each round has a lake resize phase based on whether we have any temp water inside of the lake. We check to see whether the lowest tile's elevation
		--* is exceeded. If so, we want to expand the lake. Otherwise, we simply want to raise the water level based on the total tiles and current water level.
		resize_lakes()

		prep_for_next_round()

		iter = iter + 1
	end
end

function dl.run(world_obj)
	world = world_obj

	world:fill_ffi_array(world.tmp_bool_1, false)

	world:for_each_tile(function(ti)
		if world.elevation[ti] == 0 then
			world.elevation[ti] = world.elevation[ti] + 0.1
		end
	end)

	run_with_profiling(function() find_start_tiles() end, "find_start_tiles")

	--* ---Now we want to generate a new rivergen model that doesn't actively generate erosion but which still determines sediment load. Variables that need to 
	--* be included in that sediment load are mineral fertility, sand load, clay load, silt load and organics... we should be able to infer organics from climate for now.
	--* Need rainfall in every tile. No longer need to worry about erosion.

	--* ---Tentative plan: We have an initial rainfall and river gen algorithm during world gen which determines the mineral fertility load, sand load, clay load, etc for
	--* all of the tributaries. We then save that data in the tributaries to determine the alluvial soil of floodplains. We can also theoretically infer the
	--* seasonality of rivers as well as whether they reliably flood every year as per the case of the Nile. What we do is run the algorithm two times for the rainfall
	--* values of each season, and then have their sizes resized each season based on the disparity. THEN, each "tick" in game all we need to do is
	--* calculate waterflow which is only a very small fraction of the cost of the original algorithm. If tributaries then swell to a certain threshold, that's when
	--* when we have targetted flood events and things of that nature. Alluvial soils however can be relatively fixed unless there is a major change to the river
	--* river in general (because of Beavers and stuff).
	--* --- So... first step is we just need to make a simple waterflow algorithm. Construct it with nothing other than the waterflow variable and elevation. This should
	--* be stupidly simple because erosion isn't going to be reshaping the land and mucking everything up, so we don't need all of the conditional checks to makes sure
	--* water is going backwards, blah blah blah.
	--* ---Wonderfully, we should only need 1 eon of rainfall now which should be a snap, possibly 2 later on for different seasons. We should time how long this
	--* preliminary phase takes because it'll give us and understanding of whether this model will work in our regular climate tick phase.

	run_with_profiling(function() water_flow_phase() end, "water_flow_phase")

	world:for_each_waterbody(function(wb)
		if not wb:is_valid() then return end
		-- logger:log("lake " .. wb.id .. " (" .. wb:size() .. ", " .. wb.water_level .. ")")
		for _, ti in ipairs(wb.tiles) do
			world.is_land[ti] = false
		end
	end)
end

--* River Plan ///
--* Possibly generate wetlands first, so that when rivers flow through them, they can then have an "out tile" similar to a lake. The difference is that you don't
--* have "standing water" like a lake. Instead, its more like a broad, slow moving, shallow river.

--* For rivers, we iterate through all enhoric lakes and oceans, check their coasts. When we come upon a tile which has a specific watermovement threshold
--* (I suppose the "yellow" threshold). We then assign all of those tiles with a specific waterbody ID. This will light them all up in the mapmode for us to see,
--* and then we can pick all of the "Extremity" tiles where the furthest branches start, and then we can calculate the most direct river paths. We can then use
--* the "leftover" sections which were not direct paths and ascertain whether they are "wetlands" or "rivers."

--* As an aside, we can have an list of integers for each waterbody which represent all of the direct "children" which feed into that waterbody.

--* As far as wetlands are concerned, qualifying a tile as a wetland will involve evaluating the change in elevation vs the water flowing through a tile. So a 
--* small elevation change and small waterflow could still generate a wetland because that smaller amount of water is there longer. Conversely, a tile with a large slope
--* can only be a wetland if there is a lot of water flowing through the tile

--* Check all endoric waterbodies, including oceans, seas, and saltwater lakes
--* Check shoreline of those waterbodies and check for tiles with watermovement reaching a particular threshold.
--* Build a list and follow the waterflow backward from low elevation to high. Stop once the river forks.

return dl