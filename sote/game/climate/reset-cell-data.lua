local r = {}

local tile= require "game.entities.tile"

local function reset_climate_cells()
	local cc = require "game.entities.climate-cell"
	for id, _ in pairs(WORLD.climate_cells) do
		WORLD.climate_cells[id] = cc.ClimateCell:new(id)
	end
end

local ut = require "game.climate.utils"

function r.run()
	reset_climate_cells()

	DATA.for_each_tile(function (tile_id)
		WORLD.tile_to_climate_cell[tile_id] = ut.get_climate_cell(tile.latlon(tile_id))
	end)
end

function r.run_hex(world)
	reset_climate_cells()

	world:for_each_tile(function(i, _)
		local lat, lon = world:get_latlon_by_tile(i)
		world.climate_cells[i + 1] = ut.get_climate_cell(lat, lon)
	end)
end

return r
