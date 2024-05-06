local r = {}

local function reset_climate_cells()
	local cc = require "game.entities.climate-cell"
	for id, _ in pairs(WORLD.climate_cells) do
		WORLD.climate_cells[id] = cc.ClimateCell:new(id)
	end
end

local ut = require "game.climate.utils"

function r.run()
	reset_climate_cells()

	for _, tile in pairs(WORLD.tiles) do
		tile.climate_cell = ut.get_climate_cell(tile:latlon())
	end
end

function r.run_hex(world)
	reset_climate_cells()

	for i = 0, world.tile_count - 1 do
		local lat, lon = world:get_latlon_by_tile(i)
		world.climate_cells[i + 1] = ut.get_climate_cell(lat, lon)
	end
end

return r
