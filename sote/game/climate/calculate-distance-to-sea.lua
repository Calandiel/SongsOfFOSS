local cd = {}

function cd.run()
	local ut = require "game.climate.utils"
	local position_queue = require "engine.queue":new()
	local marked = {}

	-- First, we enqueue the coastlines.
	for lua_y = 1, WORLD.climate_grid_size do
		local y = lua_y - 1
		for lua_x = 1, WORLD.climate_grid_size do
			local x = lua_x - 1
			local i = ut.get_id(x, y)
			local cell = WORLD.climate_cells[i]
			if cell.water_fraction > 0 then
				marked[cell] = true

				local left = ut.get_x(x - 1)
				local right = ut.get_x(x + 1)
				local down = y - 1
				local up = y + 1

				-- Enqueue neighbors
				position_queue:enqueue(WORLD.climate_cells[ut.get_id(left, y)])
				position_queue:enqueue(WORLD.climate_cells[ut.get_id(right, y)])

				local up_in_bounds = ut.in_bounds(up)
				local down_in_bounds = ut.in_bounds(down)

				if up_in_bounds then
					position_queue:enqueue(WORLD.climate_cells[ut.get_id(x, up)])
				end
				if down_in_bounds then
					position_queue:enqueue(WORLD.climate_cells[ut.get_id(x, down)])
				end
				if up_in_bounds then
					position_queue:enqueue(WORLD.climate_cells[ut.get_id(left, up)])
					position_queue:enqueue(WORLD.climate_cells[ut.get_id(right, up)])
				end
				if down_in_bounds then
					position_queue:enqueue(WORLD.climate_cells[ut.get_id(left, down)])
					position_queue:enqueue(WORLD.climate_cells[ut.get_id(right, down)])
				end
			end
		end
	end

	-- After that, loop until thw queue is empty
	-- (flood fill)
	while position_queue:length() > 0 do
		---@type ClimateCell
		local n = position_queue:dequeue()
		local x, y = ut.get_x_y(n.cell_id)

		if marked[n] then
			-- the cell is already marked! nothing to do!
		else
			local min_dist = 9999999.0
			marked[n] = true

			local left = ut.get_x(x - 1)
			local right = ut.get_x(x + 1)
			local down = y - 1
			local up = y + 1

			---Handles one cell
			---@param cell_to_handle ClimateCell
			local function handle(cell_to_handle)
				if marked[cell_to_handle] then
					min_dist = math.min(min_dist, cell_to_handle.distance_to_sea + 1)
				else
					position_queue:enqueue(cell_to_handle)
				end
			end

			local left_cell = WORLD.climate_cells[ut.get_id(left, y)]
			local right_cell = WORLD.climate_cells[ut.get_id(right, y)]
			handle(left_cell)
			handle(right_cell)

			if ut.in_bounds(up) then
				local top_left_cell = WORLD.climate_cells[ut.get_id(left, up)]
				local top_right_cell = WORLD.climate_cells[ut.get_id(right, up)]
				local top_cell = WORLD.climate_cells[ut.get_id(right, up)]
				handle(top_left_cell)
				handle(top_right_cell)
				handle(top_cell)
			end
			if ut.in_bounds(down) then
				local bottom_left_cell = WORLD.climate_cells[ut.get_id(left, down)]
				local bottom_right_cell = WORLD.climate_cells[ut.get_id(right, down)]
				local bottom_cell = WORLD.climate_cells[ut.get_id(right, down)]
				handle(bottom_left_cell)
				handle(bottom_right_cell)
				handle(bottom_cell)
			end
			n.distance_to_sea = min_dist
		end
	end
end

return cd
