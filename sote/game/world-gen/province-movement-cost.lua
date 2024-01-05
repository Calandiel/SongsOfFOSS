local pro = {}

-- After provinces are created, we also need to create the neighborhoods and travel time costs
local single_tile_cost = function(tile)
	---@type Tile
	local t = tile
	if t.is_land then
		local elevation_cost = math.max(t.elevation, 0) / 1000.0
		local plant_cost = 0.01 * t.grass + 0.1 * t.shrub + 1 * t.conifer + 2 * t.broadleaf
		local ice_cost = 0
		if t.ice > 0 then
			ice_cost = 10
		end
		return elevation_cost + plant_cost + ice_cost
	else
		if t.ice > 0 then
			return 50
		else
			return 1
		end
	end
end

function pro.run()
	for _, province in pairs(WORLD.provinces) do
		province.movement_cost = 0
		for _, tile in pairs(province.tiles) do
			province.movement_cost = province.movement_cost + single_tile_cost(tile)
		end
	end
end

return pro
