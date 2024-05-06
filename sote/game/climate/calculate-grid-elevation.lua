local cl = {}

local function update_climate_cells()
	for _, cell in pairs(WORLD.climate_cells) do
		local tt = cell.land_tiles + cell.water_tiles
		if tt > 0 then
			cell.elevation = cell.elevation / tt
			cell.water_fraction = cell.water_tiles / tt
		else
			cell.elevation = 0
			cell.water_tiles = 1
			cell.water_fraction = 1
		end
	end
end

function cl.run()
	for _, tile in pairs(WORLD.tiles) do
		local cell = tile.climate_cell

		cell.elevation = tile.elevation

		if tile.is_land then
			cell.land_tiles = cell.land_tiles + 1
		else
			cell.water_tiles = cell.water_tiles + 1
		end
	end

	update_climate_cells()
end

function cl.run_hex(world)
	for i = 0, world.tile_count - 1 do
		local cell = world.climate_cells[i + 1]

		cell.elevation = world.elevation[i]

		local is_land = world.is_land[i]
		if is_land then
			cell.land_tiles = cell.land_tiles + 1
		else
			cell.water_tiles = cell.water_tiles + 1
		end
	end

	update_climate_cells()
end

return cl
