local ut = require "game.map-modes.utils"
local tabb = require "engine.table"
local csu = require "game.map-modes._color-space-utils"

local ev = require "game.raws.values.economy"
local tile = require "game.entities.tile"
local province_utils = require "game.entities.province".Province
local production_utils = require "game.raws.production-methods"

local dem = {}

function dem.culture()
	DATA.for_each_province(function (province)
		local center = DATA.province_get_center(province)
		ut.set_default_color(center)
		local e = province_utils.get_dominant_culture(province)
		if e ~= nil then
			tile.set_real_color(center, e.r, e.g, e.b)
		end
	end)
end

function dem.faith()
	DATA.for_each_province(function (province)
		local center = DATA.province_get_center(province)
		ut.set_default_color(center)
		local e = province_utils.get_dominant_faith(province)
		if e ~= nil then
			tile.set_real_color(center, e.r, e.g, e.b)
		end
	end)
end

function dem.race()
	DATA.for_each_province(function (province)
		local center = DATA.province_get_center(province)
		ut.set_default_color(center)
		local e = province_utils.get_dominant_race(province)
		if e ~= INVALID_ID then
			local fat = DATA.fatten_race(e)
			tile.set_real_color(DATA.province_get_center(province), fat.r, fat.g, fat.b)
		end
	end)
end

function dem.population()
	ut.provincial_hue_map_mode(function(province)
		if (DATA.province_get_size(province) == 0) then return 0 end
		return math.min(1, province_utils.local_population(province) / 100)
	end)
end

function dem.population_1000()
	ut.provincial_hue_map_mode(function(province)
		if (DATA.province_get_size(province) == 0) then return 0 end
		return math.min(1, province_utils.local_population(province) / 1000)
	end)
end

function dem.population_density()
	ut.provincial_hue_map_mode(function(province)
		if (DATA.province_get_size(province) == 0) then return 0 end
		return math.min(1, math.max(0, province_utils.local_population(province) / DATA.province_get_size(province)))
	end)
end

function dem.military()
	ut.provincial_hue_map_mode(function(province)
		return math.max(0, province_utils.military(province)) / 15
	end)
end

function dem.military_target()
	ut.provincial_hue_map_mode(function(province)
		return math.max(0, province_utils.military_target(province)) / 15
	end)
end

function dem.technologies()
	ut.provincial_hue_map_mode(function(province)
		local count = 0
		DATA.for_each_technology(function (item)
			if DATA.province_get_technologies_present(province, item) == 1 then
				count = count + 1
			end
		end)
		return math.max(0, count) / 10
	end)
end

function dem.selected_technology()
	-- local selected_blob = require "game.scenes.game".selected
	local tt = CACHED_TECH
	if tt == nil then
		print("Nil tech")
		error("Tried to recalculate the selected technology map mode but cached tech is nil!")
	else
		print(DATA.technology_get_description(tt))
	end

	ut.clear_color_provinces()
	if tt then
		DATA.for_each_province(function (province)
			local fat_province = DATA.fatten_province(province)
			local realm = province_utils.realm(province)
			if fat_province.is_land and realm ~= INVALID_ID then
				if DATA.province_get_technologies_present(province, tt) == 1 then
					tile.set_real_color(fat_province.center, 0, 0, 1)
				elseif DATA.province_get_technologies_researchable(province, tt) == 1 then
					tile.set_real_color(fat_province.center, 0, 1, 1)
				else
					tile.set_real_color(fat_province.center, 1, 0, 0)
				end
			else
				ut.set_default_color(fat_province.center)
			end
		end)
	end
end

---@type BuildingType?
CACHED_BUILDING_TYPE = nil

function dem.selected_building_efficiency()
	if CACHED_BUILDING_TYPE == nil then
		print("Nil tech")
	else
		print(DATA.building_type_get_name(CACHED_BUILDING_TYPE))
	end

	ut.clear_color_provinces()
	if CACHED_BUILDING_TYPE ~= nil then
		local method = DATA.building_type_get_production_method(CACHED_BUILDING_TYPE)
		DATA.for_each_province(function (province)
			local eff = production_utils.get_efficiency(method, province)
			local r, g, b = csu.hsv_to_rgb(eff * 90, 0.4, math.min(eff / 3 + 0.2))
			tile.set_real_color(DATA.province_get_center(province), r, g, b)
		end)
	end
end

---@type trade_good_id
HACKY_MAP_MODE_CONTEXT_TRADE_CATEGORY = INVALID_ID

function dem.prices()
	local c = HACKY_MAP_MODE_CONTEXT_TRADE_CATEGORY
	if c ~= INVALID_ID then
		-- calculate stats
		local total = 0
		local mean = 0

		---@type table<number, Province> | table<Province, Province>
		local provinces = DATA.filter_province(function (item)
			return true
		end)

		if WORLD.player_character ~= INVALID_ID then
			local realm = REALM(WORLD.player_character)
			provinces = DATA.realm_get_known_provinces(realm)
		end

		for _, province in pairs(provinces) do
			if province_utils.realm(province) ~= INVALID_ID then
				local price = ev.get_local_price(province, c)
				total = total + 1
				mean = mean + price
			end
		end
		mean = mean / total
		print("mean of price: ", mean)

		local std = 0
		for _, province in pairs(provinces) do
			if province_utils.realm(province) ~= INVALID_ID then
				local price = ev.get_local_price(province, c)
				std = std + (price - mean) * (price - mean)
			end
		end
		std = math.sqrt(std / (total - 1)) + 0.001 -- to avoid division by zero
		print("std of price: ", std)

		DATA.for_each_province(function (province)
			local center = DATA.province_get_center(province)
			ut.set_default_color(center)
			if DATA.tile_get_is_land(center) then
				if province_utils.realm(province) ~= INVALID_ID then
					local price = ev.get_local_price(province, c)
					-- ut.hue_from_value(tile, 1 - math.log(1 + (price - mean) / std, 2) / 10)
					local normalized = (price - mean) / std
					ut.hue_from_value(center, 0.5 * (1 + normalized / (1 + math.abs(normalized))))
				end
			end
		end)
	else
		print("Nil for " .. tostring(c))
	end
end

return dem
