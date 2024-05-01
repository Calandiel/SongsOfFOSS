local buf = {}

local function run_common()
	require "game.climate.calculate-distance-to-sea".run()
	require "game.climate.calculate-saldo".run()
	require "game.climate.calculate-saldo-based-zones".run()
	require "game.climate.calculate-continentality".run()
	require "game.climate.post-process-tile-data".run()
end

function buf.run()
	require "game.climate.reset-cell-data".run()
	require "game.climate.calculate-grid-elevation".run()
	run_common()
end

function buf.run_hex(world)
	require "game.climate.reset-cell-data".run_hex(world)
	require "game.climate.calculate-grid-elevation".run_hex(world)
	run_common()
end

return buf
