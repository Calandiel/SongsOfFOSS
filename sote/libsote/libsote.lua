local libsote = {}

local ffi = require("ffi")
local kernel32 = require("utils.win32api")

ffi.cdef [[
int LIBSOTE_Init(char* err_msg, const char* log_file);
int LIBSOTE_StartTask(char* err_msg, int task, unsigned int num, char* fname);
int LIBSOTE_WaitEndTask(char* err_msg);
int LIBSOTE_SetVar(char* err_msg, int dlen, unsigned int* desc, void* val);
int LIBSOTE_GetVar(char* err_msg, int dlen, unsigned int* desc, void* val);
int LIBSOTE_IsRunning();
int LIBSOTE_GetLoadMessage(char* err_msg, char* msg);
]]

local sote_params = {
	{ name = "randomSeed",                       index = 0,  ctype = "unsigned int",   value = 51804               },
	{ name = "WorldSize",                        index = 1,  ctype = "unsigned short", value = 183                 },
	{ name = "SuperOceans",                      index = 2,  ctype = "short",          value = 2                   },
	{ name = "SuperContinents",                  index = 3,  ctype = "short",          value = 1                   },
	{ name = "MajorPlates",                      index = 4,  ctype = "short",          value = 4                   },
	{ name = "MinorPlates",                      index = 5,  ctype = "short",          value = 11                  },
	{ name = "MajorHotspots",                    index = 6,  ctype = "short",          value = 4                   },
	{ name = "ModerateHotspots",                 index = 7,  ctype = "short",          value = 6                   },
	{ name = "MinorHotspots",                    index = 8,  ctype = "short",          value = 15                  },
	{ name = "HotspotWidth",                     index = 9,  ctype = "double",         value = 1.0                 },
	{ name = "majPlateExpansion",                index = 10, ctype = "short",          value = 4                   },
	{ name = "minPlateExpansion",                index = 11, ctype = "short",          value = 3                   },
	{ name = "plateRandomness",                  index = 12, ctype = "short",          value = 50                  },
	{ name = "totalPlatesUsed",                  index = 13, ctype = "short",          value = 1                   },
	{ name = "PlateSpeed",                       index = 14, ctype = "double",         value = 1.0                 },
	{ name = "PercentCrust",                     index = 15, ctype = "short",          value = 40                  },
	{ name = "OldMountains",                     index = 16, ctype = "double",         value = 1.0                 },
	{ name = "OldHills",                         index = 17, ctype = "double",         value = 1.0                 },
	{ name = "AncientMountains",                 index = 18, ctype = "double",         value = 1.0                 },
	{ name = "MountainPasses",                   index = 19, ctype = "double",         value = 1.0                 },
	{ name = "MountainWidth",                    index = 20, ctype = "double",         value = 1.0                 },
	{ name = "BeltLength",                       index = 21, ctype = "double",         value = 1.0                 },
	{ name = "BeltFrequency",                    index = 22, ctype = "double",         value = 1.0                 },
	{ name = "MinorOceanPlates",                 index = 23, ctype = "short",          value = 8                   },
	{ name = "LargeIslandArcs",                  index = 24, ctype = "double",         value = 2.0                 },
	{ name = "SunkenContinents",                 index = 25, ctype = "double",         value = 0.0                 },
	{ name = "ContinentalShelves",               index = 26, ctype = "double",         value = 1.0                 },
	{ name = "ContinentalSlopes",                index = 27, ctype = "double",         value = 1.0                 },
	{ name = "AbyssalPlains",                    index = 28, ctype = "double",         value = 1.0                 },
	{ name = "evaporationConstant",              index = 29, ctype = "double",         value = 5000.0              },
	{ name = "rainfallMultiplier",               index = 30, ctype = "double",         value = 1.0                 },
	{ name = "vapourAbsorptionFactor",           index = 31, ctype = "double",         value = 0.00175             },
	{ name = "backgroundGreenhouseEffectFactor", index = 32, ctype = "double",         value = 0.21                },
	{ name = "rainfallThreshold",                index = 33, ctype = "double",         value = 0.99                },
	{ name = "diffusionUpdatesPerClimateUpdate", index = 34, ctype = "int",            value = 3                   },
	{ name = "diffusionStrength",                index = 35, ctype = "double",         value = 1.0 / 80.0          },
	{ name = "passiveRainCoefficient",           index = 36, ctype = "double",         value = 0.1                 },
	{ name = "advectionStrength",                index = 37, ctype = "float",          value = 0.4000000059604645  },
	{ name = "iceCapCorrection",                 index = 38, ctype = "double",         value = 0.09                },
	{ name = "hadleyDrynessFactor",              index = 39, ctype = "double",         value = 0.75                },
	{ name = "hadleyTemperatureImpact",          index = 40, ctype = "double",         value = 0.75                },
	{ name = "hadleyTargetTemperature",          index = 41, ctype = "double",         value = 306.15              },
	{ name = "hadleyMinLat",                     index = 42, ctype = "double",         value = 0.34906600000000004 },
	{ name = "hadleyMaxLat",                     index = 43, ctype = "double",         value = 0.61086550000000006 },
	{ name = "worldScaling",                     index = 44, ctype = "double",         value = 1.0                 },
	{ name = "numOfPlates",                      index = 45, ctype = "int",            value = 10                  },
	{ name = "numOfBoundaries",                  index = 46, ctype = "int",            value = 1                   },
	{ name = "numWaterBodies",                   index = 47, ctype = "int",            value = 1                   },
	{ name = "initialClimateTicks",              index = 48, ctype = "",               value = nil                 }, -- SKIPPED
	{ name = "iceAgeSeverity",                   index = 49, ctype = "float",          value = 1.0                 }
}

---@enum sote_tasks
local sote_tasks = {
	init_world = 1,
	clean_up   = 6
}

---@enum sote_vals
local sote_vals = {
	latitude          = 40, -- Colatitude
	longitude         = 41, -- MinusLongitude
	elevation         =  1, -- Elevation
	-- water_movement    = 20, -- skipped?
	rugosity          = 43, -- Hilliness
	rock_type         = 35, -- RockType (needs some translation)
	volcanic_activity =  5, -- VolcanicActivity
	-- IsLand: computed from elevation
	plate             = 15,
}

local function log_info(msg)
	print("[libsote] " .. msg)
end

local function log_sote(sote_msg)
	print("[libSOTE.dll] " .. ffi.string(sote_msg))
end

libsote.message = nil

local function log_and_set_msg(msg)
	log_info(msg)
	libsote.message = msg
end

local function remap_coords_from_sote(world)
	world.coord = {}

	for row in require("game.file-utils").csv_rows("d:\\temp\\sote_tilettes.csv") do
		local face = tonumber(row[1])
		local q = tonumber(row[2])
		local r = tonumber(row[3])
		local ti = tonumber(row[4])

		world:_remap_tile(q, r, face + 1, ti)
	end

	for row in require("game.file-utils").csv_rows("d:\\temp\\sote_world_coord.csv") do
		local tile_id = tonumber(row[1])
		local neighbor_indices = { tonumber(row[5]), tonumber(row[6]), tonumber(row[7]), tonumber(row[8]), tonumber(row[9]), tonumber(row[10]) }

		world:_remap_neighbors(tile_id, neighbor_indices)
	end
end

libsote.allocated_memory = nil

local function init_mem_reserve()
	kernel32 = ffi.load("kernel32")

	local addr = ffi.cast("LPVOID", 0x8000000000)
	local alloc_size = 0x5000002000
	local allocation_success = false

	libsote.allocated_memory = kernel32.VirtualAlloc(addr, alloc_size, ffi.C.MEM_RESERVE, ffi.C.PAGE_EXECUTE_READWRITE)

	if libsote.allocated_memory == nil then
		log_info("memory allocation failed with error code: " .. tostring(ffi.C.GetLastError()))
	elseif libsote.allocated_memory ~= addr then
		log_info("allocated memory, but not at expected address")
		kernel32.VirtualFree(libsote.allocated_memory, 0, ffi.C.MEM_RELEASE)
	else
		allocation_success = true
		log_info("libSOTE memory reserved")
	end

	if not allocation_success then
		log_and_set_msg("Memory allocation failed")
		return false
	end

	ffi.gc(libsote.allocated_memory, function(address) kernel32.VirtualFree(address, 0, ffi.C.MEM_RELEASE) end)

	return true
end

local lib_sote_instance = nil

function libsote.init()
	if ffi.os ~= "Windows" then
		log_and_set_msg("libSOTE only supported on Windows for now")
		return false
	end

	if not init_mem_reserve() then return false end

	local bins_dir = love.filesystem.getSourceBaseDirectory() .. "/sote/engine/bins/win/"
	lib_sote_instance = ffi.load(bins_dir .. "libSOTE.dll")
	if not lib_sote_instance then
		log_and_set_msg("Failed to load libSOTE.dll")
		return false
	end

	local err_msg = ffi.new("char[256]")

	local ret_code = lib_sote_instance.LIBSOTE_Init(err_msg,
		love.filesystem.getSourceBaseDirectory() .. "/sote/logs/libSOTE/log.txt")
	if ret_code ~= 0 then
		log_sote(err_msg)
		log_and_set_msg("Failed to init libSOTE")
		libsote.message = libsote.message .. ": " .. ffi.string(err_msg)
		return false
	end

	log_info("initialized libSOTE")

	return true
end

local function int_to_uint(n)
	local bit = require("bit")
	if n < 0 then
		n = bit.bnot(math.abs(n)) + 1
	end
	if n < 0 then
		n = n + 2 ^ 32
	end
	return n
end

local bit = require("bit")
local bnot_big_number = bit.bnot(int_to_uint(4294959104))
local min_int = -2 ^ 31

local function hex_coord_to_hex_number(face, q, r)
	face = int_to_uint(face)
	q = int_to_uint(q)
	r = int_to_uint(r)

	local shift_face = bit.lshift(face, 26)
	local r_and_bnbn = bit.band(r, bnot_big_number)
	local shift_r_and_bnbn = bit.lshift(r_and_bnbn, 13)
	local q_and_bnbn = bit.band(q, bnot_big_number)

	return int_to_uint(bit.bor(min_int, shift_face, shift_r_and_bnbn, q_and_bnbn))
end

local function get_val(desc, err_msg, val)
	if not lib_sote_instance then
		error('libSOTE not initialized')
	end
	local ret_code = lib_sote_instance.LIBSOTE_GetVar(err_msg, 3, desc, ffi.cast("void*", val))
	if ret_code ~= 0 then
		log_sote(err_msg)
		error("failed to get val")
	end
end

local function set_sote_params(seed)
	if not lib_sote_instance then
		log_and_set_msg("libSOTE not initialized")
		return
	end

	local err_msg = ffi.new("char[256]")

	local desc = ffi.new("unsigned int[3]", { 1, 0, 0 })
	for _, v in ipairs(sote_params) do
		if v.ctype == "" then goto continue end

		local value = v.value
		if seed and v.name == "randomSeed" then
			value = seed
		end

		desc[2] = v.index
		--- [Cala, 30 Mar 2024] This is fine, sumneko is just a bit iffy with LuaJIT's ffi
		---@diagnostic disable-next-line: param-type-mismatch
		local cval = ffi.new(v.ctype .. "[1]", value)
		_ = lib_sote_instance.LIBSOTE_SetVar(err_msg, 3, desc, ffi.cast("void*", cval))

		::continue::
	end
end

local function is_running()
	if not lib_sote_instance then
		log_and_set_msg("libSOTE not initialized")
		return false
	end

	return lib_sote_instance.LIBSOTE_IsRunning() == 1
end

local function start_worldgen_task()
	if not lib_sote_instance then
		log_and_set_msg("libSOTE not initialized")
		return
	end

	local err_msg = ffi.new("char[256]")
	local ret_code = 0

	ret_code = lib_sote_instance.LIBSOTE_StartTask(err_msg, sote_tasks.init_world, 0, nil)
	if ret_code ~= 0 then
		log_sote(err_msg)
		error("failed to start init_world task")
	end

	log_info("started task init_world")
end

local function get_tile_data(desc, err_msg, float_val, short_val, uint_val)
	local tile_data = {}

	desc[2] = sote_vals.latitude
	get_val(desc, err_msg, float_val)
	tile_data.latitude = float_val[0]

	desc[2] = sote_vals.longitude
	get_val(desc, err_msg, float_val)
	tile_data.longitude = float_val[0]

	desc[2] = sote_vals.elevation
	get_val(desc, err_msg, float_val)
	tile_data.elevation = float_val[0]

	desc[2] = sote_vals.rugosity
	get_val(desc, err_msg, float_val)
	tile_data.rugosity = float_val[0]

	desc[2] = sote_vals.rock_type
	get_val(desc, err_msg, short_val)
	tile_data.rock_type = short_val[0]

	desc[2] = sote_vals.volcanic_activity
	get_val(desc, err_msg, short_val)
	tile_data.volcanic_activity = short_val[0]

	tile_data.is_land = tile_data.elevation > 0

	desc[2] = sote_vals.plate
	get_val(desc, err_msg, uint_val)
	tile_data.plate = uint_val[0]

	return tile_data
end

local current_msg = ""

function libsote.worldgen_phase01_coro(seed)
	set_sote_params(seed)

	local start = love.timer.getTime()

	start_worldgen_task()

	coroutine.yield()

	local err_msg = ffi.new("char[256]")
	local msg = ffi.new("char[256]")

	current_msg = ""
	while is_running() do
		_ = lib_sote_instance.LIBSOTE_GetLoadMessage(err_msg, msg)

		local new_msg = ffi.string(msg)
		if new_msg ~= current_msg then
			current_msg = new_msg
			log_sote(current_msg)
		end

		coroutine.yield()
	end

	local ret_code = lib_sote_instance.LIBSOTE_WaitEndTask(err_msg);
	if ret_code ~= 0 then
		log_sote(err_msg)
		error("failed to wait init_world task")
	end

	local duration = love.timer.getTime() - start
	print("[worldgen_task]: " .. string.format("%.2f", duration * 1000) .. "ms --------------------------------------")

	log_and_set_msg("World generation finished")
end

function libsote.generate_world(seed)
	local world_size = sote_params[2].value
	-- local world_size = 4

	local start = love.timer.getTime()
	local world = require("libsote.world-allocator").allocate(world_size, seed)
	local duration = love.timer.getTime() - start
	print("[worldgen profiling] allocated Goldberg polyhedron world: " .. string.format("%.2f", duration * 1000) .. "ms")

	if not world then
		log_and_set_msg("World allocation failed")
		return nil
	end

	if require("libsote.debug-control-panel").align_to_sote_coords then remap_coords_from_sote(world) end

	local err_msg = ffi.new("char[256]")
	local float_val = ffi.new("float[1]")
	local short_val = ffi.new("int16_t[1]")
	local uint_val = ffi.new("uint32_t[1]")

	local get_desc = ffi.new("unsigned int[3]", { 0, 0, 0 })

	for q = -world_size, world_size do
		for r = -world_size, world_size do
			if not world:is_valid(q, r) then goto continue end

			for face = 1, 20 do
				get_desc[1] = hex_coord_to_hex_number(face - 1, q, r)
				local tile_data = get_tile_data(get_desc, err_msg, float_val, short_val, uint_val)
				world:set_tile_data(-r, -q, face, tile_data)
			end

			::continue::
		end
	end

	log_and_set_msg("World data loaded")

	return world
end

function libsote.clean_up_coro()
	local err_msg = ffi.new("char[256]")
	local ret_code = 0

	ret_code = lib_sote_instance.LIBSOTE_StartTask(err_msg, sote_tasks.clean_up, 0, nil)
	if ret_code ~= 0 then
		log_sote(err_msg)
		error("failed to start clean_up task")
	end

	while is_running() do
		coroutine.yield()
	end

	ret_code = lib_sote_instance.LIBSOTE_WaitEndTask(err_msg);
	if ret_code ~= 0 then
		log_sote(err_msg)
		error("failed to wait clean_up task")
	end

	log_and_set_msg("Finished task clean_up")
end

return libsote
