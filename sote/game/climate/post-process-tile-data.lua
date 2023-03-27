local p = {}
local ut = require "game.climate.utils"

function p.run()
	local function apply_from_closure(get_closure, set_closure)
		for _, cell in pairs(WORLD.climate_cells) do
			local x, y = ut.get_x_y(cell.cell_id)
			local l = ut.get_x(x - 1)
			local r = ut.get_x(x + 1)
			local u = ut.get_y(y + 1)
			local d = ut.get_y(y - 1)

			cell.cache[1] = (
				get_closure(WORLD.climate_cells[ut.get_id(l, y)]) +
					get_closure(WORLD.climate_cells[ut.get_id(r, y)]) +
					get_closure(WORLD.climate_cells[ut.get_id(x, u)]) +
					get_closure(WORLD.climate_cells[ut.get_id(x, d)]) +
					get_closure(WORLD.climate_cells[ut.get_id(x, y)])
				) / 5.0
		end
		for _, cell in pairs(WORLD.climate_cells) do
			set_closure(cell, cell.cache[1])
		end
	end

	-- Smooth most factors...
	for _ = 1, 6 do
		apply_from_closure(function(cell)
			return cell.true_continentality
		end, function(cell, value)
			cell.true_continentality = value
		end)
		apply_from_closure(function(cell)
			return cell.true_rain_shadow
		end, function(cell, value)
			cell.true_rain_shadow = value
		end)
		apply_from_closure(function(cell)
			return cell.med_influence
		end, function(cell, value)
			cell.med_influence = value
		end)
	end

	-- Adjust Hadley for continentality...
	-- Smooth hadley
	for _, cell in pairs(WORLD.climate_cells) do
		local cont = cell.left_to_right_continentality
		local had = cell.hadley_influence

		had = had * (1 - math.min(1, math.max(0, cont / 0.025)))
		had = math.sqrt(had)

		cell.hadley_influence = had
	end
	for _ = 1, 6 do
		apply_from_closure(function(cell)
			return cell.hadley_influence
		end, function(cell, value)
			cell.hadley_influence = value
		end)
	end
end

return p
