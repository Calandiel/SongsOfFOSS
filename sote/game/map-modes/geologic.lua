local geo = {}

local ut = require "game.map-modes.utils"

function geo.resources()
	for _, tile in pairs(WORLD.tiles) do
		if tile.resource then
			local r, g, b = tile.resource.r, tile.resource.g, tile.resource.b
			tile:set_real_color(r, g, b)
		else
			ut.set_default_color(tile)
		end
	end
end

function geo.plates()
	for _, tile in pairs(WORLD.tiles) do
		local local_plate = tile:plate()

		if local_plate then
			local r, g, b = local_plate.r, local_plate.g, local_plate.b
			tile:set_real_color(r, g, b)
		else
			tile:set_real_color(0.1, 0.1, 0.1)
		end
	end
end

function geo.rocks()
	for _, tile in pairs(WORLD.tiles) do
		if tile.bedrock then
			local r, g, b = tile.bedrock.r, tile.bedrock.g, tile.bedrock.b
			tile:set_real_color(r, g, b)
		else
			tile:set_real_color(0.1, 0.1, 0.1)
		end
	end
end

function geo.elevation()
	ut.simple_map_mode(
		function(tile)
			if tile.is_land then
				return math.max(0, tile.elevation)
			else
				return math.min(0, tile.elevation)
			end
		end, ut.elevation_threshold)

	for _, tile in pairs(WORLD.tiles) do
		if tile.ice > 0 then
			tile:set_real_color(0.95, 0.95, 1)
		end
	end
end

return geo
