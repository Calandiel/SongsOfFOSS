local sa = {}

---This function loops through all columns of the world.
---Then, it calculates how "skewed" the distribution of elevation in the world is
---Lastly, it writes that distribution to cells data.
---We need this because we want to "skew" some climate related variables south or north depending on where the landmasses are
---For example, the ITCZ
function sa.run()
	local ut = require "game.climate.utils"
	for lua_x = 1, WORLD.climate_grid_size do
		local x = lua_x - 1
		local local_saldo_north = 0
		local local_saldo_south = 0

		for lua_y = 1, WORLD.climate_grid_size do
			local y = lua_y - 1
			local l = -ut.latitude(y)
			local cell = WORLD.climate_cells[ut.get_id(x, y)]

			local val = (1 - cell.water_fraction) * math.abs(math.sin(l)) / WORLD.climate_grid_size
			if l > 0 then
				local_saldo_north = local_saldo_north + val
			else
				local_saldo_south = local_saldo_south + val
			end
		end
		for lua_y = 1, WORLD.climate_grid_size do
			local y = lua_y - 1
			WORLD.climate_cells[ut.get_id(x, y)].saldo_north = local_saldo_north
			WORLD.climate_cells[ut.get_id(x, y)].saldo_south = local_saldo_south
		end
	end
end

return sa
