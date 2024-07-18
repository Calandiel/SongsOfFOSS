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
	local climate_generator = fu.csv_rows("d:\\temp\\sote\\12177\\sote_climate_data_by_elev.csv")
	-- local logger = require("libsote.debug-loggers").get_climate_logger("d:/temp")

	wg.world:for_each_tile_by_elevation_for_waterflow(function(ti, _)
		local row = climate_generator()
		if row == nil then
			error("Not enough rows in climate data")
		end

		wg.world.jan_temperature[ti] = tonumber(row[3])
		wg.world.jul_temperature[ti] = tonumber(row[4])
		wg.world.jan_rainfall[ti] = tonumber(row[5])
		wg.world.jul_rainfall[ti] = tonumber(row[6])
		wg.world.jan_humidity[ti] = tonumber(row[7])
		wg.world.jul_humidity[ti] = tonumber(row[8])

		-- local log_str = row[1] .. "," .. row[2] .. " --- " .. wg.world.colatitude[ti] .. "," .. wg.world.minus_longitude[ti] .. " --- " .. wg.world:true_elevation_for_waterflow(ti) .. " <-> " .. tonumber(row[11])
		-- logger:log(log_str)
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

	table.insert(prof_output, { profile_and_get(override_climate_data, "override_climate_data", 1) })

	table.insert(prof_output, { profile_and_get(function() waterflow.run(wg.world, waterflow.TYPES.world_gen) end, "calculate-waterflow", 1) })
	table.insert(prof_output, { profile_and_get(function() set_soils_texture(0, 0, 0) end, "clear_soils", 1) })

	log_profiling_data(prof_output, "initial_waterflow")
end

local function glaciers()
	local prof_output = {}

	table.insert(prof_output, { profile_and_get(function() require "libsote.soils.gen-bias-matrix".run(wg.world) end, "gen-bias-matrix", 1) })
	table.insert(prof_output, { profile_and_get(function() require "libsote.soils.gen-parent-material".run(wg.world) end, "gen-parent-material", 1) })
	table.insert(prof_output, { profile_and_get(function() require "libsote.glacial-formation".run(wg.world) end, "glacial-formation", 1) })

	log_profiling_data(prof_output, "glaciers")
end

local function gen_phase_02()
	run_with_profiling(function() wg.world:sort_by_elevation_for_waterflow() end, "sort_by_elevation_for_waterflow")

	run_with_profiling(function() require "libsote.gen-rocks".run(wg.world) end, "gen-rocks")
	run_with_profiling(function() require "libsote.gen-climate".run(wg.world) end, "gen-climate")
	initial_waterbodies()
	initial_waterflow()
	glaciers()
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