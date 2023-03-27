local kopp = {}

local color = require "game.color"

kopp.KOPPEN = {
	'BWh', 'BWk', 'BSh', 'BSk',
	'Af', 'Am', 'Aw',
	'Csa', 'Csb', 'Csc',
	'Cwa', 'Cwb', 'Cwc',
	'Cfa', 'Cfb', 'Cfc',
	'Dsa', 'Dsb', 'Dsc',
	'Dwa', 'Dwb', 'Dwc',
	'Dfa', 'Dfb', 'Dfc',
	'ET', 'EF',
	'W', -- W stands for water
	'R', -- R stands for error
}

kopp.KOPPEN_COLORS = {
	BWh = { 255, 0, 0 },
	BWk = { 255, 150, 150 },
	BSh = { 245, 163, 0 },
	BSk = { 255, 219, 99 },
	Af  = { 0, 0, 255 },
	Am  = { 0, 119, 255 },
	Aw  = { 70, 169, 255 },
	Csa = { 255, 255, 0 },
	Csb = { 198, 199, 0 },
	Csc = { 150, 150, 0 },
	Cwa = { 150, 255, 150 },
	Cwb = { 99, 199, 100 },
	Cwc = { 50, 150, 51 },
	Cfb = { 102, 255, 51 },
	Cfa = { 198, 255, 78 },
	Dsa = { 255, 0, 254 },
	Cfc = { 51, 191, 1 },
	Dsc = { 150, 50, 149 },
	Dsb = { 198, 1, 199 },
	Dwb = { 90, 119, 219 },
	Dwa = { 171, 177, 255 },
	Dfa = { 0, 255, 255 },
	Dwc = { 76, 81, 181 },
	Dfc = { 0, 126, 126 },
	Dfb = { 56, 199, 255 },
	EF  = { 104, 104, 104 },
	ET  = { 178, 178, 178 },
	R   = { 0, 0, 0 },
	W   = { 255, 255, 255 },
}

kopp.COLORS_KOPPEN = {}
for k, v in pairs(kopp.KOPPEN_COLORS) do
	local id = color.rgb_to_id(v[1] / 255.0, v[2] / 255.0, v[3] / 255.0)
	kopp.COLORS_KOPPEN[id] = k
end

function kopp.get_koppen(january_temperature, july_temperature, january_rainfall, july_rainfall, is_land)
	if is_land then
		local average_temp = (july_temperature + january_temperature) / 2.0;
		local average_precipitation_total = 12.0 * (july_rainfall + january_rainfall) / 2.0;

		local min_temp = math.min(january_temperature, july_temperature);
		local max_temp = math.max(january_temperature, july_temperature);
		local driest_precipitation = math.min(january_rainfall, july_rainfall);

		local winter_precipitation, summer_precipitation
		if january_temperature < july_temperature then
			winter_precipitation = january_rainfall
			summer_precipitation = july_rainfall
		else
			winter_precipitation = july_rainfall
			summer_precipitation = january_rainfall
		end

		local seasons_factor = 0
		if january_temperature < july_temperature then
			seasons_factor = july_rainfall / (july_rainfall + january_rainfall)
		else
			seasons_factor = january_rainfall / (july_rainfall + january_rainfall)
		end

		local threshold_b = average_temp * 20.0
		if seasons_factor >= 0.7 then
			threshold_b = threshold_b + 280.0
		elseif seasons_factor >= 0.3 then
			threshold_b = threshold_b + 140.0
		end

		if average_precipitation_total < threshold_b then
			if average_precipitation_total < 0.5 * threshold_b then
				if average_temp > 18.0 then
					return 'BWh'
				else
					return 'BWk'
				end
			else
				if average_temp > 18.0 then
					return 'BSh'
				else
					return 'BSk'
				end
			end
		elseif min_temp >= 18.0 then
			if driest_precipitation >= 60.0 then
				return 'Af'
			elseif driest_precipitation >= 100.0 - average_precipitation_total / 25.0 then
				return 'Am'
			else
				return 'Aw'
			end
		elseif max_temp > 10.0 then
			if min_temp >= -3.0 then
				if winter_precipitation > 0.7 * (winter_precipitation + summer_precipitation) then
					if max_temp > 22.0 then
						return 'Csa'
					elseif max_temp > 18.0 then
						return 'Csb'
					else
						return 'Csc'
					end
				elseif summer_precipitation > 0.7 * (winter_precipitation + summer_precipitation) then
					if max_temp > 22.0 then
						return 'Cwa'
					elseif max_temp > 18.0 then
						return 'Cwb'
					else
						return 'Cwc'
					end
				else
					if max_temp > 22.0 then
						return 'Cfa'
					elseif max_temp > 18.0 then
						return 'Cfb'
					else
						return 'Cfc'
					end
				end
			else
				if winter_precipitation > 0.7 * (winter_precipitation + summer_precipitation) then
					if max_temp > 22.0 then
						return 'Dsa'
					elseif max_temp > 18.0 then
						return 'Dsb'
					else
						return 'Dsc'
					end
				elseif summer_precipitation > 0.7 * (winter_precipitation + summer_precipitation) then
					if max_temp > 22.0 then
						return 'Dwa'
					elseif max_temp > 18.0 then
						return 'Dwb'
					else
						return 'Dwc'
					end
				else
					if max_temp > 22.0 then
						return 'Dfa'
					elseif max_temp > 18.0 then
						return 'Dfb'
					else
						return 'Dfc'
					end
				end
			end
		else
			if max_temp >= 0.0 then
				return 'ET'
			else
				return 'EF'
			end
		end
	else
		return 'W'
	end
end

--[[
pub fn get_koppen_on_tile(tile: TileCoordinates, world: &World) -> Koppen {
	let size = world.get_config().size;
	let is_land = world.tiles[tile.as_index(size as u16)].is_land();

	get_koppen(
		tile.get_january_temperature(world),
		tile.get_july_temperature(world),
		tile.get_january_rainfall(world),
		tile.get_july_rainfall(world),
		is_land,
	)
}
]]



return kopp
