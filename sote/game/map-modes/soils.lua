local so = {}

local ut = require "game.map-modes.utils"


function so.texture()
	for _, tile in pairs(WORLD.tiles) do
		ut.set_default_color(tile)

		local d = tile:soil_depth()

		tile:set_real_color(
			tile.sand / d,
			tile.silt / d,
			tile.clay / d
		)
	end
end

function so.depth()
	ut.simple_hue_map_mode(function(tile)
		return math.min(1, tile:soil_depth() / 25)
	end)
end

function so.organics()
	ut.simple_hue_map_mode(function(tile)
		return math.min(1, tile.soil_organics)
	end)
end

function so.minerals()
	ut.simple_hue_map_mode(function(tile)
		return math.min(1, tile.soil_minerals)
	end)
end

return so
