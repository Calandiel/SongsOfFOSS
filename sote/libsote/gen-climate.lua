local climate = {}

function climate.run(world)
    require "game.climate.climate-simulation".run_hex(world)
end

return climate