local tabb = require "engine.table"
local tile = require "game.entities.tile"

local ut = require "game.map-modes.utils"
local csu = require "game.map-modes._color-space-utils"

local province_utils = require "game.entities.province".Province
local realm_utils = require "game.entities.realm".Realm

local pol = {}

function pol.diplomacy(clicked_tile_id)
	ut.clear_color_provinces()

	local clicked_tile = clicked_tile_id
	local clicked_realm = tile.realm(clicked_tile)

	if clicked_realm then
		DATA.for_each_province(function (province)
			local checked_realm = province_utils.realm(province)
			local center = DATA.province_get_center(province)
			ut.set_default_color(center)
			if checked_realm ~= INVALID_ID then

				local is_tributary = false
				DATA.for_each_realm_subject_relation_from_overlord(clicked_realm, function (item)
					local subject = DATA.realm_subject_relation_get_subject(item)
					if subject == checked_realm then
						is_tributary = true
					end
				end)

				local is_overlord = false
				DATA.for_each_realm_subject_relation_from_subject(clicked_realm, function (item)
					local overlord = DATA.realm_subject_relation_get_subject(item)
					if overlord == checked_realm then
						is_overlord = true
					end
				end)

				if checked_realm == clicked_realm then
					tile.set_real_color(center, 051 / 255, 117 / 255, 056 / 255)
				elseif is_overlord then
					tile.set_real_color(center, 150 / 255, 60 / 255, 100 / 255) -- color overlords
				elseif is_tributary then
					tile.set_real_color(center, 220 / 255, 205 / 255, 125 / 255) -- color tributaries
				elseif realm_utils.is_realm_in_hierarchy(checked_realm, clicked_realm) then
					tile.set_real_color(center, 120 / 255, 105 / 255, 55 / 255) -- color indirect tributaries
				elseif realm_utils.at_war_with(checked_realm, clicked_realm) then
					tile.set_real_color(center, 126 / 255, 041 / 255, 084 / 255) -- color wars
				end
			end
		end)
	end

	DATA.for_each_province(function (province)
		local center = DATA.province_get_center(province)
		tile.set_real_color(center, 0.1, 0.1, 0.1)
		local realm = province_utils.realm(province)

		if realm == INVALID_ID then
			return
		end

		local is_part_of_regional_power = false
		DATA.for_each_realm_subject_relation_from_overlord(realm, function (item)
			is_part_of_regional_power = true
		end)
		DATA.for_each_realm_subject_relation_from_subject(realm, function (item)
			is_part_of_regional_power = true
		end)

		if is_part_of_regional_power then
			local top_realms = realm_utils.get_top_realm(realm)
			if tabb.size(top_realms) == 1 then
				for _, top in pairs(top_realms) do
					local fat_top = DATA.fatten_realm(top)
					tile.set_real_color(center, fat_top.r, fat_top.g, fat_top.b)
				end
			end
		end
	end)
end

function pol.realms()
	DATA.for_each_province(function (province)
		local center = DATA.province_get_center(province)
		ut.set_default_color(center)
		local local_province = tile.province(center)
		if local_province == INVALID_ID then
			return
		end

		local realm = province_utils.realm(province)
		if realm == INVALID_ID then
			return
		end

		local fat = DATA.fatten_realm(realm)

		tile.set_real_color(center,
			fat.r,
			fat.g,
			fat.b
		)
	end)
end

function pol.province()
	DATA.for_each_province(function (province)
		local center = DATA.province_get_center(province)
		ut.set_default_color(center)

		local fat = DATA.fatten_province(province)

		if DATA.tile_get_is_land(center) then
			tile.set_real_color(center, fat.r, fat.g, fat.b)
		else
			tile.set_real_color(center, 0.25 * fat.r, 0.25 * fat.g, 0.25 * fat.b)
		end
	end)
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

	DATA.for_each_tile(function (tile_id)
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
	end)
end

function pol.atlas_provinces()
	DATA.for_each_province(function (province)
		local center = DATA.province_get_center(province)
		local realm = province_utils.realm(province)
		if realm == INVALID_ID then
			tile.set_real_color(
				center,
				1, 1, 1
			)
			return
		end

		local fat_realm = DATA.fatten_realm(realm)

		local result_h, result_s, result_v = csu.rgb_to_hsv(
			fat_realm.r, fat_realm.g, fat_realm.b
		)

		--- Resolve colors for tributaries so that we can map paint!
		local top_realms = realm_utils.get_top_realm(realm)
		if tabb.size(top_realms) == 1 then
			for _, source_realm in pairs(top_realms) do
				local fat_source = DATA.fatten_realm(source_realm)

				local pol_h, pol_s, pol_v = csu.rgb_to_hsv(
					fat_source.r, fat_source.g, fat_source.b
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
			center,
			r, g, b
		)
	end)
end

return pol
