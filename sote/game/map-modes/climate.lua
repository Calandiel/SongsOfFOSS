local cli = {}

local ut = require "game.map-modes.utils"
local kopp = require "game.climate.koppen"
local tile = require "game.entities.tile"

function cli.itcz()
	for tile_id, cell in pairs(WORLD.tile_to_climate_cell) do

		tile.set_real_color(
			tile_id,
			cell.itcz_july,
			0,
			cell.itcz_january
		)
	end
end

function cli.koppen()
	for _, tile_id in pairs(WORLD.tiles) do
		local r_ja, t_ja, r_ju, t_ju = tile.get_climate_data(tile_id)
		local k = kopp.get_koppen(t_ja, t_ju, r_ja, r_ju, DATA.tile_get_is_land(tile_id))
		local col = kopp.KOPPEN_COLORS[k]
		if col == nil then
			ut.set_default_color(tile_id)
		else
			tile.set_real_color(tile_id, col[1] / 255, col[2] / 255, col[3] / 255)
		end
	end
end

local flow_map_mode_exponent = 0.5
function cli.jan_flow()
	ut.simple_hue_map_mode(function(tile_id)
		---@type tile_id
		local tt = tile_id
		return math.pow(DATA.tile_get_january_waterflow(tt), flow_map_mode_exponent) / math.pow(30000.0, flow_map_mode_exponent)
	end)
end

function cli.jul_flow()
	ut.simple_hue_map_mode(function(tile_id)
		---@type tile_id
		local tt = tile_id
		return math.pow(DATA.tile_get_july_waterflow(tt), flow_map_mode_exponent) / math.pow(30000.0, flow_map_mode_exponent)
	end)
end

function cli.jan_rain()
	ut.simple_hue_map_mode(function(tile_id)
		local r_ja, t_ja, r_ju, t_ju = tile.get_climate_data(tile_id)
		return 1 - math.min(1, r_ja / 250.0)
	end)
end

function cli.jul_rain()
	ut.simple_hue_map_mode(function(tile_id)
		local r_ja, t_ja, r_ju, t_ju = tile.get_climate_data(tile_id)
		return 1 - math.min(1, r_ju / 250.0)
	end)
end

function cli.jan_temp()
	ut.simple_hue_map_mode(function(tile_id)
		local r_ja, t_ja, r_ju, t_ju = tile.get_climate_data(tile_id)
		return 1 - math.max(0, math.min(1, 0.5 + 0.5 * t_ja / 40.0))
	end)
end

function cli.jul_temp()
	ut.simple_hue_map_mode(function(tile_id)
		local r_ja, t_ja, r_ju, t_ju = tile.get_climate_data(tile_id)
		return 1 - math.max(0, math.min(1, 0.5 + 0.5 * t_ju / 40.0))
	end)
end

return cli
