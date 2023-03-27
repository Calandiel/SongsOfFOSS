local cli = {}

local ut = require "game.map-modes.utils"
local kopp = require "game.climate.koppen"

function cli.itcz()
	for _, tile in pairs(WORLD.tiles) do
		tile:set_real_color(
			tile.climate_cell.itcz_july,
			0,
			tile.climate_cell.itcz_january
		)
	end
end

function cli.koppen()
	for _, tile in pairs(WORLD.tiles) do
		local r_ja, t_ja, r_ju, t_ju = tile:get_climate_data()
		local k = kopp.get_koppen(t_ja, t_ju, r_ja, r_ju, tile.is_land)
		local col = kopp.KOPPEN_COLORS[k]
		if col == nil then
			ut.set_default_color(tile)
		else
			tile:set_real_color(col[1] / 255, col[2] / 255, col[3] / 255)
		end
	end
end

local flow_map_mode_exponent = 0.5
function cli.jan_flow()
	ut.simple_hue_map_mode(function(tile)
		---@type Tile
		local tt = tile
		return math.pow(tt.january_waterflow, flow_map_mode_exponent) / math.pow(30000.0, flow_map_mode_exponent)
	end)
end

function cli.jul_flow()
	ut.simple_hue_map_mode(function(tile)
		---@type Tile
		local tt = tile
		return math.pow(tt.january_waterflow, flow_map_mode_exponent) / math.pow(30000.0, flow_map_mode_exponent)
	end)
end

function cli.jan_rain()
	ut.simple_hue_map_mode(function(tile)
		local r_ja, t_ja, r_ju, t_ju = tile:get_climate_data()
		return 1 - math.min(1, r_ja / 250.0)
	end)
end

function cli.jul_rain()
	ut.simple_hue_map_mode(function(tile)
		local r_ja, t_ja, r_ju, t_ju = tile:get_climate_data()
		return 1 - math.min(1, r_ju / 250.0)
	end)
end

function cli.jan_temp()
	ut.simple_hue_map_mode(function(tile)
		local r_ja, t_ja, r_ju, t_ju = tile:get_climate_data()
		return 1 - math.max(0, math.min(1, 0.5 + 0.5 * t_ja / 40.0))
	end)
end

function cli.jul_temp()
	ut.simple_hue_map_mode(function(tile)
		local r_ja, t_ja, r_ju, t_ju = tile:get_climate_data()
		return 1 - math.max(0, math.min(1, 0.5 + 0.5 * t_ju / 40.0))
	end)
end

return cli
