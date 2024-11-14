local tile = require "game.entities.tile"

local dbg = {}


function dbg.coastlines()
	DATA.for_each_tile(function (tile_id)
		if DATA.tile_get_is_land(tile_id) then
			if tile.is_coast(tile_id) then
				tile.set_real_color(tile_id,1, 1, 1)
			else
				tile.set_real_color(tile_id,0, 0, 0)
			end
		else
			tile.set_real_color(tile_id,0, 0, 1)
		end
	end)
end

function dbg.yellow()
	DATA.for_each_tile(function (tile_id)
		tile.set_real_color(tile_id,1, 1, 0)
	end)
end

function dbg.selected_tile(clicked_tile_id)
	DATA.for_each_tile(function (tile_id)
		tile.set_real_color(tile_id,0.2, 0.2, 0.2)
	end)

	local clicked = clicked_tile_id
	if clicked then
		local clicked_province = tile.province(clicked)
		if clicked_province ~= INVALID_ID then
			for _, t in pairs(clicked_province.tiles) do
				for n in tile.iter_neighbors(t) do
					local neighbour_province = tile.province(n)

					if neighbour_province ~= clicked_province then
						tile.set_real_color(n, 1, 1, 0)

						if clicked_province.neighbors[neighbour_province] == nil then
							print("???? A neighboring province wasn't assigned correctly")
						end
					end
				end
			end
			for _, owo in pairs(clicked_province.neighbors) do
				for _, t in pairs(owo.tiles) do
					tile.set_real_color(t, 0, 0, 0.5)
				end
			end
			for _, t in pairs(clicked_province.tiles) do
				tile.set_real_color(t, 0, 0, 1)
			end
		end
		tile.set_real_color(clicked, 1, 1, 1)
		for n in tile.iter_neighbors(clicked) do tile.set_real_color(n, 0.5, 0.5, 0.5) end
		for t in tile.line_iterator(clicked, 1, 5) do tile.set_real_color(t, 1.0, 0, 0) end
	end
end

function dbg.debug_color()
	DATA.for_each_tile(function (tile_id)
		-- tile.set_real_color(tile_id,tile.debug_r, tile.debug_g, tile.debug_b)
		if DATA.tile_get_is_border(tile_id) then
			tile.set_real_color(tile_id, 1, 1, 1)
		else
			tile.set_real_color(tile_id, 0, 0, 0)
		end
		-- local prov = tile.province(tile_id)
		-- if DATA.province_get_on_a_river(prov) then
		-- 	tile.set_real_color(tile_id,1, 1, 1)
		-- else
		-- 	tile.set_real_color(tile_id,0, 0, 0)
		-- end
	end)
end

return dbg
