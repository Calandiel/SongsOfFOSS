local ut = require "game.map-modes.utils"
local tile = require "game.entities.tile"

local ec = {}

function ec.carrying_capacity()
	ut.provincial_hue_map_mode(function(prov)
		return (prov.foragers_limit - 5) / 50
	end)
end

function ec.tile_carrying_capacity()
	local cc = require "game.ecology.carrying-capacity".get_tile_carrying_capacity
	ut.simple_hue_map_mode(function(tile_id)
		return cc(tile_id) / 0.7
	end)
end

function ec.plants()
	for _, tile_id in pairs(WORLD.tiles) do
		if DATA.tile_get_is_land(tile_id) then
			tile.set_real_color(tile_id, tile.shrub, tile.grass, tile.conifer + tile.broadleaf)
		else
			ut.set_default_color(tile_id)
		end
	end
end

function ec.biomes()
	for _, tile_id in pairs(WORLD.tiles) do
		local biome = DATA.tile_get_biome(tile_id)
		if biome ~= nil then
			tile.set_real_color(tile_id, biome.r, biome.g, biome.b)
		else
			ut.set_default_color(tile_id)
		end
	end
end

return ec
