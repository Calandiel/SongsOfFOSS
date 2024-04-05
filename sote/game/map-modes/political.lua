local ut = require "game.map-modes.utils"
local csu = require "game.map-modes._color-space-utils"

local pol = {}

function pol.diplomacy(clicked_tile_id)
	local clicked_tile = WORLD.tiles[clicked_tile_id]
	if clicked_tile then
		if clicked_tile.province then
			if clicked_tile.province.realm then
				local rr = clicked_tile.province.realm

				for _, province in pairs(WORLD.provinces) do
					ut.set_default_color(province.center)
					local tile = province.center
					if tile.province.realm ~= nil then
						if rr then
							if tile.province.realm == rr then
								tile:set_real_color(051 / 255, 117 / 255, 056 / 255)
							elseif tile.province.realm.tributaries[rr] ~= nil then
								tile:set_real_color(150 / 255, 60 / 255, 100 / 255) -- color overlords
							elseif tile.province.realm.paying_tribute_to[rr] ~= nil then
								tile:set_real_color(220 / 255, 205 / 255, 125 / 255) -- color tributaries
							elseif tile.province.realm:is_realm_in_hierarchy(rr) then
								tile:set_real_color(120 / 255, 105 / 255, 55 / 255) -- color indirect tributaries
							elseif tile.province.realm:at_war_with(rr) then
								tile:set_real_color(126 / 255, 041 / 255, 084 / 255) -- color wars
							end
						end
					end
				end
			end
		end
	else
		ut.clear_color_provinces()
	end
end

function pol.realms()
	for _, province in pairs(WORLD.provinces) do
		local tile = province.center

		ut.set_default_color(tile)
		if tile.province ~= nil then
			if tile.province.realm ~= nil then
				tile:set_real_color(
					tile.province.realm.r,
					tile.province.realm.g,
					tile.province.realm.b
				)
			end
		end
	end
end

function pol.province()
	for _, province in pairs(WORLD.provinces) do
		local tile = province.center

		ut.set_default_color(tile)
		if tile.province ~= nil then
			if tile.is_land then
				tile:set_real_color(tile.province.r, tile.province.g, tile.province.b)
			else
				tile:set_real_color(0.25 * tile.province.r, 0.25 * tile.province.g, 0.25 * tile.province.b)
			end
		end
	end
end



local function mix(x, y, a)
	return x * (1 - a) + y * a;
end

function pol.atlas()
	ut.simple_map_mode(
		function(tile)
			if tile.is_land then
				return math.max(0, tile.elevation)
			else
				return math.min(0, tile.elevation)
			end
		end, ut.elevation_threshold)

	for _, tile in pairs(WORLD.tiles) do
		if tile.province ~= nil then
			if tile.province.realm ~= nil then
				--- Resolve colors for tributaries so that we can map paint!
				for _, source_realm in pairs(tile.province.realm:get_top_realm()) do
					local ele_h, ele_s, ele_v = csu.rgb_to_hsv(
						tile.real_r, tile.real_g, tile.real_b
					)

					local pol_h, pol_s, pol_v = csu.rgb_to_hsv(
						source_realm.r, source_realm.g, source_realm.b
					)

					local r, g, b = csu.hsv_to_rgb(
						mix(ele_h, pol_h, 0.9), mix(ele_s, pol_s, 0.6), mix(ele_v, pol_v, 0.3)
					)

					tile:set_real_color(
						r, g, b
					)
				end
			end
		end
	end
end

return pol
