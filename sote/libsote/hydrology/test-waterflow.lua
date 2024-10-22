local tw = {}

local fu = require "game.float-utils"

local world_allocator = require "libsote.world-allocator"
local world = world_allocator.allocate(3, 12177)
local waterflow_calc = require "libsote.hydrology.calculate-waterflow"

local error_margin = 1e-5

local function assert_eq(a, b, msg)
	msg = msg .. ": expected " .. b .. ", got " .. a
	assert_true(fu.eq(a, b, error_margin), msg)
end

local function clear_data()
	world.tmp_float_2[0] = 0
	world.snow[0] = 0
	world.tmp_float_1[0] = 0
	world.soil_moisture[0] = 0
end

-- c1 code path is not yet reachable
local function test_c1(flow_type)
	clear_data()
end

local function test_c2(flow_type)
	clear_data()

	local month = 0
	local year = 0

	world.ice[0] = 0
	world.is_land[0] = 1
	world.jan_rainfall[0] = 18.3124
	world.jul_rainfall[0] = 8.616516
	world.jan_temperature[0] = -7.025959
	world.jul_temperature[0] = -0.7689381
	world.sand[0] = 333
	world.silt[0] = 334
	world.clay[0] = 333

	waterflow_calc.test_tile(0, world, flow_type, month, 0)

	local msg = "c2 "
	assert_eq(world.tmp_float_2[0], 5.446182, msg .. "float_2")
	assert_eq(world.snow[0], 12.86621, msg .. "snow")
	assert_eq(world.tmp_float_1[0], 2.268335, msg .. "float_1")
	assert_eq(world.soil_moisture[0], 12.71139, msg .. "soil_moisture")
end

-- c3 code path is not yet reachable; seems to depend on neighboring tiles
local function test_c3(flow_type)
	clear_data()
end

-- c4 seems to depend on neighboring tiles; it is also fairly trivial
local function test_c4(flow_type)
	clear_data()

	local month = 0
	local year = 0

	world.ice[0] = 0
	world.is_land[0] = 0
	world.jan_rainfall[0] = 64.49884
	world.jul_rainfall[0] = 64.51164
	world.jan_temperature[0] = -6.457015
	world.jul_temperature[0] = 14.22404
	world.sand[0] = 333
	world.silt[0] = 334
	world.clay[0] = 333

	local wb = world:create_new_waterbody()
	wb.type = wb.types.freshwater_lake
	world.waterbody_id_by_tile[0] = wb.id

	waterflow_calc.test_tile(0, world, flow_type, month, year)

	local msg = "c4 "
	assert_eq(world.tmp_float_2[0], 0, msg .. "float_2")
	assert_eq(world.snow[0], 0, msg .. "snow")
	assert_eq(world.tmp_float_1[0], 0, msg .. "float_1")
	assert_eq(world.soil_moisture[0], 0, msg .. "soil_moisture")
	assert_eq(wb.tmp_float_1, 797.2018, msg .. "waterbody float_1")
end

-- c3 code path is not yet reachable; seems to depend on neighboring tiles
local function test_c6(flow_type)
	clear_data()
end

-- c9 seems to depend on neighboring tiles
local function test_c9(flow_type)
	clear_data()

	local month = 0
	local year = 0

	world.ice[0] = 0
	world.is_land[0] = 1
	world.jan_rainfall[0] = 9.390036
	world.jul_rainfall[0] = 6.280334
	world.jan_temperature[0] = 1857414
	world.jul_temperature[0] = 5.260559
	world.sand[0] = 333
	world.silt[0] = 334
	world.clay[0] = 333

	waterflow_calc.test_tile(0, world, flow_type, month, 0)

	local msg = "c9 "
	assert_eq(world.tmp_float_2[0], 7.835185, msg .. "float_2")
	assert_eq(world.snow[0], 0, msg .. "snow")
	assert_eq(world.tmp_float_1[0], 1.598903, msg .. "float_1")
	assert_eq(world.soil_moisture[0], 19.30493, msg .. "soil_moisture")
end

function tw.test_worldgen_waterflow()
	-- test_c1(waterflow_calc.TYPES.world_gen) -- not yet reachable
	test_c2(waterflow_calc.TYPES.world_gen)
	-- test_c3(waterflow_calc.TYPES.world_gen) -- not yet reachable
	-- c4 seems to depend on neighboring tiles; it is also fairly trivial
	-- c5 is a dead end path
	-- test_c6(waterflow_calc.TYPES.world_gen) -- not yet reachable
	-- c7 seems to depend on neighboring tiles; it is also fairly trivial
	-- c8 is a dead end path
	-- test_c9(waterflow_calc.TYPES.world_gen)
end

return tw