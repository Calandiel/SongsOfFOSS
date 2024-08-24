local pro = {}

-- After provinces are created, we also need to create the neighborhoods and travel time costs
---@param t tile_id
local single_tile_cost = function(t)
	if DATA.tile_get_is_land(t) then
		local elevation = DATA.tile_get_elevation(t)
		local grass = DATA.tile_get_grass(t)
		local shrub = DATA.tile_get_shrub(t)
		local conifer = DATA.tile_get_shrub(t)
		local broadleaf = DATA.tile_get_shrub(t)

		local elevation_cost = math.max(elevation, 0) / 1000.0
		local plant_cost = 0.01 * grass + 0.1 * shrub + 1 * conifer + 2 * broadleaf
		local ice_cost = 0
		if DATA.tile_get_ice(t) > 0 then
			ice_cost = 10
		end
		return elevation_cost + plant_cost + ice_cost
	else
		if DATA.tile_get_ice(t) > 0 then
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
