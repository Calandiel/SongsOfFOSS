return function ()
	--require "sote.simple-tests.queue"

	require "sote.codegen.output.generated".test_save_load_0()
	-- require "sote.codegen.output.generated".test_save_load_1()
	-- require "sote.codegen.output.generated".test_save_load_2()

	require "sote.codegen.output.generated".test_set_get_0()
	-- require "sote.codegen.output.generated".test_set_get_1()
	-- require "sote.codegen.output.generated".test_set_get_2()

	-- fat id performance test

	-- local tile = DATA.create_province()

	-- local now = love.timer.getTime()
	-- for i = 1, 100000000 do
	-- 	DATA.tile_set_real_r(tile, math.random())
	-- end
	-- print(love.timer.getTime() - now)

	-- now = love.timer.getTime()
	-- for i = 1, 100000000 do
	-- 	local fat_tile = DATA.fatten_tile(tile)
	-- 	fat_tile.real_r = math.random()
	-- end
	-- print(love.timer.getTime() - now)
end