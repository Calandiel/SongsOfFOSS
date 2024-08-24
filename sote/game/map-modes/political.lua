local tabb = require "engine.table"
local tile = require "game.entities.tile"

local ut = require "game.map-modes.utils"
local csu = require "game.map-modes._color-space-utils"

local pol = {}

function pol.diplomacy(clicked_tile_id)
	ut.clear_color_provinces()

	local clicked_tile = clicked_tile_id
	local clicked_realm = tile.realm(clicked_tile)

	if clicked_realm then
		for _, province in pairs(WORLD.provinces) do
			local checked_realm = province.realm
			ut.set_default_color(province.center)
			local tile_id = province.center
			if checked_realm ~= nil then
				if checked_realm then
					if checked_realm == clicked_realm then
						tile.set_real_color(tile_id, 051 / 255, 117 / 255, 056 / 255)
					elseif checked_realm.tributaries[clicked_realm] ~= nil then
						tile.set_real_color(tile_id, 150 / 255, 60 / 255, 100 / 255) -- color overlords
					elseif checked_realm.paying_tribute_to[clicked_realm] ~= nil then
						tile.set_real_color(tile_id, 220 / 255, 205 / 255, 125 / 255) -- color tributaries
					elseif checked_realm:is_realm_in_hierarchy(clicked_realm) then
						tile.set_real_color(tile_id, 120 / 255, 105 / 255, 55 / 255) -- color indirect tributaries
					elseif checked_realm:at_war_with(clicked_realm) then
						tile.set_real_color(tile_id, 126 / 255, 041 / 255, 084 / 255) -- color wars
					end
				end
			end
		end
	end

	for _, province in pairs(WORLD.provinces) do
		tile.set_real_color(province.center, 0.1, 0.1, 0.1)
		local realm = province.realm
		if realm and ((tabb.size(realm.paying_tribute_to) >= 1) or (tabb.size(realm.tributaries) >= 1)) then
			local top_realms = realm:get_top_realm()
			if tabb.size(top_realms) == 1 then
				for _, top in pairs(top_realms) do
					tile.set_real_color(province.center, top.r, top.g, top.b)
				end
			end
		end
	end
end

function pol.realms()
	for _, province in pairs(WORLD.provinces) do
		local tile_id = province.center
		ut.set_default_color(tile_id)
		local local_province = tile.province(tile_id)

		if local_province ~= nil then
			local local_realm = local_province.realm

			if local_realm ~= nil then
				tile.set_real_color(tile_id,
					local_realm.r,
					local_realm.g,
					local_realm.b
				)
			end
		end
	end
end

function pol.province()
	for _, province in pairs(WORLD.provinces) do
		local tile_id = province.center
		ut.set_default_color(tile_id)
		local local_province = tile.province(tile_id)

		if local_province ~= nil then
			if DATA.tile_get_is_land(tile_id) then
				tile.set_real_color(tile_id,local_province.r, local_province.g, local_province.b)
			else
				tile.set_real_color(tile_id,0.25 * local_province.r, 0.25 * local_province.g, 0.25 * local_province.b)
			end
		end
	end
end


---commenting
---@param x number
---@param y number
---@param a number
---@return number
local function mix(x, y, a)
	return x * (1 - a) + y * a;
end

function pol.atlas_tiles()
	ut.simple_map_mode(
		function(tile_id)
			local elevation = DATA.tile_get_elevation(tile_id)
			if DATA.tile_get_is_land(tile_id) then
				return math.max(0, tile_id)
			else
				return math.min(0, tile_id)
			end
		end, ut.elevation_threshold
	)

	for _, tile_id in ipairs(WORLD.tiles) do
		local h, s, v = csu.rgb_to_hsv(
			DATA.tile_get_real_r(tile_id),
			DATA.tile_get_real_g(tile_id),
			DATA.tile_get_real_b(tile_id)
		)
		s = s / 2
		v = math.sqrt(v + 0.2) - math.sqrt(1.2) + 1
		local r, g, b = csu.hsv_to_rgb(h, s, v)
		DATA.tile_set_real_r(tile_id, r)
		DATA.tile_set_real_g(tile_id, g)
		DATA.tile_set_real_b(tile_id, b)
	end
end

function pol.atlas_provinces()
	for _, province in pairs(WORLD.provinces) do
		local local_realm = province.realm
		if local_realm ~= nil then
			local result_h, result_s, result_v = csu.rgb_to_hsv(
				local_realm.r, local_realm.g, local_realm.b
			)

			--- Resolve colors for tributaries so that we can map paint!
			local top_realms = local_realm:get_top_realm()
			if tabb.size(top_realms) == 1 then
				for _, source_realm in pairs(top_realms) do

					local pol_h, pol_s, pol_v = csu.rgb_to_hsv(
						source_realm.r, source_realm.g, source_realm.b
					)

					result_h = mix(result_h, pol_h, 0.9)
					result_s = mix(result_s, pol_s, 0.8)
					result_v = mix(result_v, pol_v, 0.6)
				end
			end

			local r, g, b = csu.hsv_to_rgb(
				result_h, result_s / 2, math.sqrt(result_v + 0.5) + 1 - math.sqrt(1.5)
			)

			tile.set_real_color(
				province.center,
				r, g, b
			)
		else
			tile.set_real_color(
				province.center,
				1, 1, 1
			)
		end
	end
end

return pol
