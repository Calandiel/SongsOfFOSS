local sa = {}

---Applies a single variable
---@param center number
---@param thickness number
---@param saldo_influence number
---@param mirror boolean
---@param apply_func function
local function apply_saldo_based_variable(center, thickness, saldo_influence, mirror, apply_func)
	local ut = require "game.climate.utils"
	local cells_per_degree = WORLD.climate_grid_size / 180.0

	for i, cell in pairs(WORLD.climate_cells) do
		local cont = cell.saldo_north - cell.saldo_south
		cont = math.min(0.22, math.max(-0.22, cont))
		cont = cont / 0.22

		local dist = cont * cells_per_degree * saldo_influence

		-- Calculate centers of the zones.
		-- We need to do this, because the center gets skewed by distribution of land within the world.
		local new_center = WORLD.climate_grid_size / 2 + center * cells_per_degree + dist
		local mirr_center = WORLD.climate_grid_size / 2 - center * cells_per_degree + dist

		local _, y = ut.get_x_y(i)
		y = y + 0.5

		if y > new_center - thickness and y < new_center + thickness then
			local influence = 1 - math.abs(new_center - y) / thickness
			apply_func(cell, influence)
		end
		if mirror then
			if y > mirr_center - thickness and y < mirr_center + thickness then
				local influence = 1 - math.abs(mirr_center - y) / thickness
				apply_func(cell, influence)
			end
		end
	end
end

function sa.run()
	-- HADLEY
	apply_saldo_based_variable(24, 10, 6, true, function(c, inf)
		c.hadley_influence = inf
	end)
	-- ITCZ
	apply_saldo_based_variable(-8, 15, 3, false, function(c, inf)
		c.itcz_january = inf
	end)
	apply_saldo_based_variable(8, 15, -3, false, function(c, inf)
		c.itcz_july = inf
	end)
	for _, cell in pairs(WORLD.climate_cells) do
		local dist_factor = math.min(WORLD.climate_grid_size, cell.distance_to_sea / 0.1) / WORLD.climate_grid_size
		cell.itcz_january = cell.itcz_january * (1 - dist_factor)
		cell.itcz_july = cell.itcz_july * (1 - dist_factor)
	end
	-- MED
	apply_saldo_based_variable(32, 8, 4, true, function(c, inf)
		c.med_influence = inf
	end)
	for _, cell in pairs(WORLD.climate_cells) do
		local dist_factor = math.min(WORLD.climate_grid_size, cell.distance_to_sea / 0.05) / WORLD.climate_grid_size
		cell.med_influence = cell.med_influence * (1 - dist_factor)
	end
end

return sa
