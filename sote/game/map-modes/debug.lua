local dbg = {}

function dbg.coastlines()
	for _, tile in pairs(WORLD.tiles) do
		if tile.is_land then
			if tile:is_coast() then
				tile:set_real_color(1, 1, 1)
			else
				tile:set_real_color(0, 0, 0)
			end
		else
			tile:set_real_color(0, 0, 1)
		end
	end
end

function dbg.yellow()
	for _, tile in pairs(WORLD.tiles) do
		tile:set_real_color(1, 1, 0)
	end
end

function dbg.selected_tile(clicked_tile_id)
	for _, tile in pairs(WORLD.tiles) do
		tile:set_real_color(0.2, 0.2, 0.2)
	end

	local clicked = WORLD.tiles[clicked_tile_id]
	if clicked then
		local clicked_province = clicked:province()
		if clicked_province then
			for _, t in pairs(clicked_province.tiles) do
				for n in t:iter_neighbors() do
					local neighbour_province = n:province()

					if neighbour_province ~= clicked_province then
						n:set_real_color(1, 1, 0)

						if clicked_province.neighbors[neighbour_province] == nil then
							print("???? A neighboring province wasn't assigned correctly")
						end
					end
				end
			end
			for _, owo in pairs(clicked_province.neighbors) do
				for _, t in pairs(owo.tiles) do
					t:set_real_color(0, 0, 0.5)
				end
			end
			for _, t in pairs(clicked_province.tiles) do
				t:set_real_color(0, 0, 1)
			end
		end
		clicked:set_real_color(1, 1, 1)
		for n in clicked:iter_neighbors() do n:set_real_color(0.5, 0.5, 0.5) end
		for t in clicked:line_iterator(1, 5) do t:set_real_color(1.0, 0, 0) end
	end
end

function dbg.debug_color()
	for _, tile in pairs(WORLD.tiles) do
		-- tile:set_real_color(tile.debug_r, tile.debug_g, tile.debug_b)
		if tile:province().on_a_river then
			tile:set_real_color(1, 1, 1)
		else
			tile:set_real_color(0, 0, 0)
		end
	end
end

return dbg
