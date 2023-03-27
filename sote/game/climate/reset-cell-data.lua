local r = {}

function r.run()
	local cc = require "game.entities.climate-cell"
	local ut = require "game.climate.utils"
	for id, _ in pairs(WORLD.climate_cells) do
		WORLD.climate_cells[id] = cc.ClimateCell:new(id)
	end
	for _, tile in pairs(WORLD.tiles) do
		ut.set_climate_cell(tile)
	end
end

return r
