local wg = {}

---@enum world_gen_state
wg.states = {
	idle               = 0,
	init               = 1,

	phase_01           = 10,
	cleanup            = 11,
	post_tectonic      = 12,
	phase_02           = 13,

	constraints_failed = 99,
	error              = 999,

	completed          = 1000
}

wg.state = wg.states.idle
wg.message = ""
wg.world = nil

local debug = require "libsote.debug-control-panel"

local prof = require "libsote.profiling-helper"
local prof_prefix = "[worldgen profiling]"

local function run_with_profiling(func, log_text)
	prof.run_with_profiling(func, prof_prefix, log_text)
end

local function profile_and_get(func, log_text, depth)
	return prof.profile_and_get(func, prof_prefix, log_text, depth)
end

local function log_profiling_data(prof_data, log_text)
	prof.log_profiling_data(prof_data, prof_prefix, log_text)
end

local fu = require "game.file-utils"

local function override_climate_data()
	local generator = fu.csv_rows("d:\\temp\\sote\\" .. wg.world.seed .. "\\sote_climate_data.csv")

	wg.world:for_each_tile(function(ti, _)
		local row = generator()
		if row == nil then
			error("Not enough rows in climate data")
		end

		wg.world.jan_temperature[ti] = tonumber(row[3])
		wg.world.jul_temperature[ti] = tonumber(row[4])
		wg.world.jan_rainfall[ti] = tonumber(row[5])
		wg.world.jul_rainfall[ti] = tonumber(row[6])
		wg.world.jan_humidity[ti] = tonumber(row[7])
		wg.world.jul_humidity[ti] = tonumber(row[8])
		wg.world.jan_wind_speed[ti] = tonumber(row[9])
		wg.world.jul_wind_speed[ti] = tonumber(row[10])
	end)
end

local function override_water_movement_data()
	local generator = fu.csv_rows("d:\\temp\\sote\\" .. wg.world.seed .. "\\sote_climate_data.csv")

	wg.world:for_each_tile(function(ti, _)
		local row = generator()
		if row == nil then
			error("Not enough rows in climate data")
		end

		wg.world.water_movement[ti] = tonumber(row[12])
	end)
end

local function override_glacial_data()
	local generator = fu.csv_rows("d:\\temp\\sote\\" .. wg.world.seed .. "\\sote_glacial_data.csv")

	wg.world:for_each_tile(function(ti, _)
		local row = generator()
		if row == nil then
			error("Not enough rows in climate data")
		end

		wg.world.ice[ti] = tonumber(row[2])
		wg.world.ice_age_ice[ti] = tonumber(row[3])
	end)
end

local function override_soils_data()
	-- local generator = fu.csv_rows("d:\\temp\\sote\\" .. wg.world.seed .. "\\sote_soils_data_after_ThinningSilts.csv")
	-- local generator = fu.csv_rows("d:\\temp\\sote\\" .. wg.world.seed .. "\\sote_soils_data_after_GenBedrockBuffer.csv")
	local generator = fu.csv_rows("d:\\temp\\sote\\" .. wg.world.seed .. "\\sote_soils_data_after_LoadWaterbodies.csv")

	wg.world:for_each_tile(function(ti, _)
		local row = generator()
		if row == nil then
			error("Not enough rows in soils data")
		end

		wg.world.sand[ti] = tonumber(row[1])
		wg.world.silt[ti] = tonumber(row[2])
		wg.world.clay[ti] = tonumber(row[3])
		wg.world.mineral_richness[ti] = tonumber(row[4])
		wg.world.soil_organics[ti] = tonumber(row[5])
		wg.world.is_land[ti] = tonumber(row[6]) == 1
	end)
end

local function post_tectonic()
	run_with_profiling(function() require "libsote.post-tectonic".run(wg.world) end, "post-tectonic")
end

local function check_constraints()
	return true
end

local function fill_ffi_array(array, value)
	wg.world:fill_ffi_array(array, value)
end

local function set_soils_texture(sand, silt, clay)
	fill_ffi_array(wg.world.sand, sand)
	fill_ffi_array(wg.world.silt, silt)
	fill_ffi_array(wg.world.clay, clay)
end

local function initial_waterbodies()
	local prof_output = {}

	table.insert(prof_output, { profile_and_get(function() require "libsote.hydrology.gen-initial-waterbodies".run(wg.world) end, "gen-initial-waterbodies", 1) })
	table.insert(prof_output, { profile_and_get(function() require "libsote.hydrology.def-prelim-waterbodies".run(wg.world) end, "def-prelim-waterbodies", 1) })

	log_profiling_data(prof_output, "initial_waterbodies")
end

local waterflow = require "libsote.hydrology.calculate-waterflow"

local function initial_waterflow()
	local prof_output = {}

	table.insert(prof_output, { profile_and_get(function() set_soils_texture(333, 334, 333) end, "intial_soils_texture", 1) })
	table.insert(prof_output, { profile_and_get(function() wg.world:create_elevation_list() end, "create_elevation_list", 1) })
	table.insert(prof_output, { profile_and_get(function() waterflow.run(wg.world, waterflow.TYPES.world_gen) end, "calculate-waterflow", 1) }) -- #1 true_elev
	table.insert(prof_output, { profile_and_get(function() set_soils_texture(0, 0, 0) end, "clear_soils", 1) })

	log_profiling_data(prof_output, "initial_waterflow")
end

local function glaciers()
	local prof_output = {}

	table.insert(prof_output, { profile_and_get(function() require "libsote.soils.gen-bias-matrix".run(wg.world) end, "gen-bias-matrix", 1) })
	table.insert(prof_output, { profile_and_get(function() require "libsote.soils.gen-parent-material".run(wg.world) end, "gen-parent-material", 1) })
	table.insert(prof_output, { profile_and_get(function() require "libsote.glaciation.glacial-formation".run(wg.world) end, "glacial-formation", 1) }) -- #2 true_elev_for_glaciation

	log_profiling_data(prof_output, "glaciers")
end

local function gen_phase_02()
	run_with_profiling(function() require "libsote.gen-rocks".run(wg.world) end, "gen-rocks")
	run_with_profiling(function() require "libsote.gen-climate".run(wg.world) end, "gen-climate")
	if debug.use_sote_climate_data then
		run_with_profiling(function() override_climate_data() end, "override_climate_data")
	end
	initial_waterbodies()
	initial_waterflow()
	glaciers()
	if debug.use_sote_water_movement then
		run_with_profiling(function() override_water_movement_data() end, "override_waterflow_data")
	end
	run_with_profiling(function() require "libsote.hydrology.gen-dynamic-lakes".run(wg.world) end, "gen-dynamic-lakes") -- #3 true_elev_for_waterflow, can be pre-computed until is_land is changed

	run_with_profiling(function() require "libsote.hydrology.gen-rivers".run(wg.world) end, "gen-rivers") -- #4 true_elev_for_waterflow, must be pre-computed because lakes change is_land
	local ocean_count = 0
	local freshwater_lake_count = 0
	local saltwater_lake_count = 0
	local river_count = 0
	local wetland_count = 0
	wg.world:for_each_waterbody(function(wb)
		if wb.type == wb.TYPES.ocean then
			ocean_count = ocean_count + 1
		elseif wb.type == wb.TYPES.freshwater_lake then
			freshwater_lake_count = freshwater_lake_count + 1
		elseif wb.type == wb.TYPES.saltwater_lake then
			saltwater_lake_count = saltwater_lake_count + 1
		elseif wb.type == wb.TYPES.river then
			river_count = river_count + 1
		elseif wb.type == wb.TYPES.wetland then
			wetland_count = wetland_count + 1
		end
	end)
	print("\tOcean count: " .. ocean_count)
	print("\tFreshwater lake count: " .. freshwater_lake_count)
	print("\tSaltwater lake count: " .. saltwater_lake_count)
	print("\tRiver count: " .. river_count)
	print("\tWetland count: " .. wetland_count)

	run_with_profiling(function() require "libsote.soils.gen-volcanic-silt".run(wg.world) end, "gen-volcanic-silt")
	run_with_profiling(function() require "libsote.soils.gen-sand-dunes".run(wg.world) end, "gen-sand-dunes")
	run_with_profiling(function() require "libsote.soils.thinning-silts".run(wg.world) end, "thinning_silts")
	run_with_profiling(function() require "libsote.soils.gen-bedrock-buffer".run(wg.world) end, "gen-bedrock-buffer")
	if debug.use_sote_soils_data then
		run_with_profiling(function() override_soils_data() end, "override_soils_data")
	end
	run_with_profiling(function() require "libsote.soils.gen-sediment-load".run(wg.world) end, "gen-sediment-load") -- #5 true_elev_for_waterflow
	run_with_profiling(function() require "libsote.soils.weather_alluvial_texture".run(wg.world) end, "weather_alluvial_texture")
	run_with_profiling(function() require "libsote.soils.gen-alluvial-soils".run(wg.world) end, "gen-alluvial-soils") -- #6 true_elev_for_waterflow
end

local libsote_cpp = require "libsote.libsote"

function wg.init()
	wg.state = wg.states.init
	wg.message = nil

	if not libsote_cpp.init() then
		wg.state = wg.states.error
		wg.message = libsote_cpp.message
		return false
	end

	return true
end

function wg.get_gen_coro(seed)
	wg.state = wg.states.phase_01
	coroutine.yield()

	local phase01_coro = coroutine.create(libsote_cpp.worldgen_phase01_coro)
	while coroutine.status(phase01_coro) ~= "dead" do
		coroutine.resume(phase01_coro, seed)
		coroutine.yield()
	end

	wg.message = libsote_cpp.message
	coroutine.yield()

	wg.world = libsote_cpp.generate_world(seed)
	wg.message = libsote_cpp.message
	if not wg.world then
		wg.state = wg.states.error
		return
	end

	wg.state = wg.states.cleanup
	coroutine.yield()

	local cleanup_coro = coroutine.create(libsote_cpp.clean_up_coro)
	while coroutine.status(cleanup_coro) ~= "dead" do
		coroutine.resume(cleanup_coro)
		coroutine.yield()
	end

	wg.message = libsote_cpp.message

	wg.state = wg.states.post_tectonic
	coroutine.yield()

	post_tectonic();

	local constraints_met = check_constraints()
	if not constraints_met then
		wg.state = wg.states.constraints_failed
		wg.message = "Constraints not met"
		return
	end

	-- libsote.dll/phase01 done ------------------------------------------

	wg.state = wg.states.phase_02
	coroutine.yield()

	gen_phase_02()
end

return wg