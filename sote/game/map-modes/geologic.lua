local geo = {}

local ut = require "game.map-modes.utils"
local tile = require "game.entities.tile"

function geo.resources()
	DATA.for_each_tile(function (tile_id)
		local res = DATA.tile_get_resource(tile_id)
		if res ~= INVALID_ID then
			local fat_res = DATA.fatten_resource(res)
			local r, g, b = fat_res.r, fat_res.g, fat_res.b
			tile.set_real_color(tile_id, r, g, b)
		else
			ut.set_default_color(tile_id)
		end
	end)
end

function geo.plates()
	DATA.for_each_tile(function (tile_id)
		local local_plate = tile.plate(tile_id)

		if local_plate ~= INVALID_ID then
			tile.set_real_color(tile_id, DATA.plate_get_r(local_plate), DATA.plate_get_g(local_plate), DATA.plate_get_b(local_plate))
		else
			tile.set_real_color(tile_id, 0.1, 0.1, 0.1)
		end
	end)
end

function geo.rocks()
	DATA.for_each_tile(function (tile_id)
		local local_bedrock = DATA.tile_get_bedrock(tile_id)
		if local_bedrock ~= INVALID_ID then
			local r = DATA.bedrock_get_r(local_bedrock)
			local g = DATA.bedrock_get_g(local_bedrock)
			local b = DATA.bedrock_get_b(local_bedrock)
			tile.set_real_color(tile_id, r, g, b)
		else
			tile.set_real_color(tile_id, 0.1, 0.1, 0.1)
		end
	end)
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

	DATA.for_each_tile(function (tile_id)
		if DATA.tile_get_ice(tile_id) > 0 then
			tile.set_real_color(tile_id, 0.95, 0.95, 1)
		end
	end)
end

return geo
