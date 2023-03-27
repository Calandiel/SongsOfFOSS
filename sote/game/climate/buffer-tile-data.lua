local buf = {}

function buf.run()
	require "game.climate.reset-cell-data".run()
	require "game.climate.calculate-grid-elevation".run()
	require "game.climate.calculate-distance-to-sea".run()
	require "game.climate.calculate-saldo".run()
	require "game.climate.calculate-saldo-based-zones".run()
	require "game.climate.calculate-continentality".run()
	require "game.climate.post-process-tile-data".run()
end

return buf
