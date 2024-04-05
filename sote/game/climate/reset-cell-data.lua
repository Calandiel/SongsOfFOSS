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

	for i = 1, world.tile_count do
		world.climate_cells[i] = ut.get_climate_cell(world:get_latlon_by_index(i))
	end
end

return r
