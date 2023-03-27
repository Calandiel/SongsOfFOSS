local hydr = {}

function hydr.run()
	-- Recalculate hydration!
	for _, pr in pairs(WORLD.provinces) do
		---@type Province
		local pro = pr
		local support = 5
		if pro.center.is_land then
			for _, tile in pairs(pro.tiles) do
				local jan_rain, jul_rain, _, _ = tile:get_climate_data()
				support = support + (jan_rain + jul_rain) * 0.5 / 2 / 30
			end
		end
		pro.hydration = support
	end
end

return hydr
