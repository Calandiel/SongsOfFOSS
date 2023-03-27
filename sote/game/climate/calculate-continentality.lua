local cc = {}
local ut = require "game.climate.utils"

function cc.run()
	local one_over_gs = 1.0 / WORLD.climate_grid_size

	local CONTINENTALITY_INCREASE = 0.5
	local MAX_INC_ELE = 10000.0 -- the amount of elevation needed to block 100% of rain
	local RAIN_SHADOW_DECREASE_RATE = 30.0
	local RAIN_SHADOW_BASE_DECAY = 6.0


	for lua_y = 1, WORLD.climate_grid_size do
		local y = lua_y - 1
		-- Find the starting location for this row...
		local function do_one(starting_x, ending_x, next_x_closure, set_cont, set_rs)
			local found_water = false

			while not found_water and starting_x ~= ending_x do
				local i = ut.get_id(starting_x, y)
				if WORLD.climate_cells[i].water_fraction > 0 then
					found_water = true
				else
					starting_x = next_x_closure(starting_x, 1)
				end
			end

			if found_water then
				local starting_id = ut.get_id(starting_x, y)
				local current_rain_shadow = 0
				local current_cont = 0
				local previous_ele = math.max(0, WORLD.climate_cells[starting_id].elevation)

				for lua_x = 1, WORLD.climate_grid_size do
					local x = lua_x - 1
					local true_x = next_x_closure(starting_x, x) % WORLD.climate_grid_size
					local id = ut.get_id(true_x, y)
					local cell = WORLD.climate_cells[id]
					local ele = math.max(0, cell.elevation)

					if cell.water_fraction > 0 then
						current_cont = math.max(0, current_cont - one_over_gs * CONTINENTALITY_INCREASE * 4)
						current_rain_shadow = math.max(0,
							current_rain_shadow - cell.water_fraction * one_over_gs * RAIN_SHADOW_DECREASE_RATE)

						if cell.water_fraction == 0 then
							set_cont(cell, current_cont)
							set_rs(cell, current_rain_shadow)
						else
							set_cont(cell, 0)
							set_rs(cell, 0)
						end
					else
						set_cont(cell, current_cont)
						set_rs(cell, current_rain_shadow)
						current_cont = math.min(1, current_cont + one_over_gs * CONTINENTALITY_INCREASE)
					end

					local delta_ele = math.max(0, ele - previous_ele)
					current_rain_shadow = current_rain_shadow + delta_ele / MAX_INC_ELE
					current_rain_shadow = math.min(1, current_rain_shadow)
					current_rain_shadow = math.max(0, current_rain_shadow - one_over_gs * RAIN_SHADOW_BASE_DECAY)
					previous_ele = ele
				end
			else
				for lua_j = 1, WORLD.climate_grid_size do
					local j = lua_j - 1
					local i = ut.get_id(j, y)
					local cell = WORLD.climate_cells[i]

					if cell.water_fraction > 0 then
						set_cont(cell, 0)
						set_rs(cell, 0)
					else
						set_cont(cell, 1)
						set_rs(cell, 0)
					end
				end
			end
		end

		-- LEFT TO RIGHT
		do_one(0, WORLD.climate_grid_size, function(x, d)
			return x + d
		end, function(cell, v)
			cell.left_to_right_continentality = v
		end, function(cell, v)
			cell.left_to_right_rain_shadow = v
		end)
		-- RIGHT TO LEFT
		do_one(WORLD.climate_grid_size - 1, -1, function(x, d)
			return x - d
		end, function(cell, v)
			cell.right_to_left_continentality = v
		end, function(cell, v)
			cell.right_to_left_rain_shadow = v
		end)
		-- After we've calculated east to west and west to east values, calculate the final value by lerping the other two based on latitude!
		-- This will replicate some effects of prevailing winds in a very computationally cheap way.
		for lua_x = 1, WORLD.climate_grid_size do
			local x = lua_x - 1
			local id = ut.get_id(x, y)
			local cell = WORLD.climate_cells[id]

			local scaled_lat = 6 * ut.latitude_degrees(y) / 90
			local left_to_right = math.pow(ut.sigmoid(scaled_lat), 6) + math.pow(ut.sigmoid(-scaled_lat), 6)
			local right_to_left = 1 - left_to_right

			cell.true_rain_shadow = cell.left_to_right_rain_shadow * left_to_right +
				cell.right_to_left_rain_shadow * right_to_left
			cell.true_continentality = cell.left_to_right_continentality * left_to_right +
				cell.right_to_left_continentality * right_to_left
			cell.true_continentality = cell.true_continentality * 2 / 3 -- don't ask me why
		end
	end
end

return cc
