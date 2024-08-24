local geo = {}

local ut = require "game.map-modes.utils"
local tile = require "game.entities.tile"

function geo.resources()
	for _, tile_id in pairs(WORLD.tiles) do
		local res = DATA.tile_get_resource(tile_id)
		if res then
			local r, g, b = res.r, res.g, res.b
			tile.set_real_color(tile_id, r, g, b)
		else
			ut.set_default_color(tile_id)
		end
	end
end

function geo.plates()
	for _, tile_id in pairs(WORLD.tiles) do
		local local_plate = tile.plate(tile_id)

		if local_plate then
			local r, g, b = local_plate.r, local_plate.g, local_plate.b
			tile.set_real_color(tile_id,r, g, b)
		else
			tile.set_real_color(tile_id,0.1, 0.1, 0.1)
		end
	end
end

function geo.rocks()
	for _, tile_id in pairs(WORLD.tiles) do
		local local_bedrock = DATA.tile_get_bedrock(tile_id)
		if local_bedrock then
			local r, g, b = local_bedrock.r, local_bedrock.g, local_bedrock.b
			tile.set_real_color(tile_id, r, g, b)
		else
			tile.set_real_color(tile_id, 0.1, 0.1, 0.1)
		end
	end
end

local function elevation_wrapper(tile_id)
	local elevation = DATA.tile_get_elevation(tile_id)
	if DATA.tile_get_is_land(tile_id) then
		return math.max(0, elevation)
	else
		return math.min(0, elevation)
	end
end

function geo.elevation()
	ut.simple_map_mode(
		elevation_wrapper,
		ut.elevation_threshold
	)

	for _, tile_id in ipairs(WORLD.tiles) do
		if DATA.tile_get_ice(tile_id) > 0 then
			tile.set_real_color(tile_id, 0.95, 0.95, 1)
		end
	end
end

return geo
