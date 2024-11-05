local climate = {}

function climate.run(world)
	require "game.climate.climate-simulation".run_hex(world)
	world:cache_climate_data()
end

return climate