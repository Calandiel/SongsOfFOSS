local cl = {}

function cl.run()
	--print("A")
	for _, tile in pairs(WORLD.tiles) do
		local cell = tile.climate_cell

		cell.elevation = tile.elevation

		if tile.is_land then
			cell.land_tiles = cell.land_tiles + 1
		else
			cell.water_tiles = cell.water_tiles + 1
		end
	end
	--print("B")
	for _, cell in pairs(WORLD.climate_cells) do
		--print("1")
		local tt = cell.land_tiles + cell.water_tiles
		--print("2")
		if tt > 0 then
			--print("2a")
			cell.elevation = cell.elevation / tt
			cell.water_fraction = cell.water_tiles / tt
			--print("3a")
		else
			--print("2b")
			cell.elevation = 0
			cell.water_tiles = 1
			cell.water_fraction = 1
			--print("3b")
		end
	end
end

return cl
