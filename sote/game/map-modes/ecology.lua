local ut = require "game.map-modes.utils"

local ec = {}

function ec.carrying_capacity()
	ut.simple_hue_map_mode(function(tile)
		---@type Tile
		local t = tile
		return (t.province.foragers_limit - 5) / 50
	end)
end

function ec.tile_carrying_capacity()
	local cc = require "game.ecology.carrying-capacity".get_tile_carrying_capacity
	ut.simple_hue_map_mode(function(tile)
		---@type Tile
		local t = tile
		return cc(t) / 0.7
	end)
end

function ec.plants()
	for _, tile in pairs(WORLD.tiles) do
		if tile.is_land then
			tile:set_real_color(tile.shrub, tile.grass, tile.conifer + tile.broadleaf)
		else
			ut.set_default_color(tile)
		end
	end
end

function ec.biomes()
	for _, tile in pairs(WORLD.tiles) do
		if tile.biome ~= nil then
			tile:set_real_color(tile.biome.r, tile.biome.g, tile.biome.b)
		else
			ut.set_default_color(tile)
		end
	end
end

return ec
