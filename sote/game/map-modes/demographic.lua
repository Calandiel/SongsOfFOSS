local ut = require "game.map-modes.utils"
local tabb = require "engine.table"
local csu = require "game.map-modes._color-space-utils"

local ev = require "game.raws.values.economical"

local dem = {}

function dem.culture()
	for _, p in pairs(WORLD.provinces) do
		ut.set_default_color(p.center)
		local e = p:get_dominant_culture()
		if e ~= nil then
			p.center:set_real_color(e.r, e.g, e.b)
		end
	end
end

function dem.faith()
	for _, p in pairs(WORLD.provinces) do
		ut.set_default_color(p.center)
		local e = p:get_dominant_faith()
		if e ~= nil then
			p.center:set_real_color(e.r, e.g, e.b)
		end
	end
end

function dem.race()
	for _, p in pairs(WORLD.provinces) do
		ut.set_default_color(p.center)
		local e = p:get_dominant_race()
		if e ~= nil then
			p.center:set_real_color(e.r, e.g, e.b)
		end
	end
end

function dem.population()
	ut.provincial_hue_map_mode(function(province)
		if (province.size == 0) then return 0 end
		return math.min(1, province:population() / 100)
	end)
end

function dem.population_1000()
	ut.provincial_hue_map_mode(function(province)
		if (province.size == 0) then return 0 end
		return math.min(1, province:population() / 1000)
	end)
end

function dem.population_density()
	ut.provincial_hue_map_mode(function(province)
		if (province.size == 0) then return 0 end
		return math.min(1, math.max(0, province:population() - 10) / province.size)
	end)
end

function dem.military()
	ut.provincial_hue_map_mode(function(province)
		return math.max(0, province:military()) / 15
	end)
end

function dem.military_target()
	ut.provincial_hue_map_mode(function(province)
		return math.max(0, province:military_target()) / 15
	end)
end

function dem.technologies()
	ut.provincial_hue_map_mode(function(province)
		local count = tabb.size(province.technologies_present)
		return math.max(0, count) / 10
	end)
end

function dem.selected_technology()
	-- local selected_blob = require "game.scenes.game".selected
	local tt = CACHED_TECH
	if tt == nil then
		print("Nil tech")
	else
		print(tt.name)
	end

	ut.clear_color_provinces()
	if tt then
		for _, prov in pairs(WORLD.provinces) do
			if prov.technologies_present[tt] then
				prov.center:set_real_color(0, 0, 1)
			elseif prov.technologies_researchable[tt] then
				prov.center:set_real_color(0, 1, 1)
			end
		end
	end
end

---@type BuildingType?
CACHED_BUILDING_TYPE = nil


function dem.selected_building_efficiency()
	if CACHED_BUILDING_TYPE == nil then
		print("Nil tech")
	else
		print(CACHED_BUILDING_TYPE.name)
	end

	ut.clear_color_provinces()
	if CACHED_BUILDING_TYPE ~= nil then
		for _, province in pairs(WORLD.provinces) do
			local eff = CACHED_BUILDING_TYPE.production_method:get_efficiency(province)
			local r, g, b = csu.hsv_to_rgb(eff * 90, 0.4, math.min(eff / 3 + 0.2))
			province.center:set_real_color(r, g, b)
		end
	end
end

---@type TradeGoodReference?
HACKY_MAP_MODE_CONTEXT_TRADE_CATEGORY = nil

function dem.prices()
	local c = HACKY_MAP_MODE_CONTEXT_TRADE_CATEGORY
	if c ~= nil then
		-- calculate stats
		local total = 0
		local mean = 0

		---@type table<number, Province> | table<Province, Province>
		local provinces = WORLD.provinces
		if WORLD.player_character then
			provinces = WORLD.player_character.realm.known_provinces
		end

		for _, province in pairs(provinces) do
			if province.realm ~= nil then
				local price = ev.get_local_price(province, c)
				total = total + 1
				mean = mean + price
			end
		end
		mean = mean / total
		print("mean of price: ", mean)

		local std = 0
		for _, province in pairs(provinces) do
			if province.realm ~= nil then
				local price = ev.get_local_price(province, c)
				std = std + (price - mean) * (price - mean)
			end
		end
		std = math.sqrt(std / (total - 1)) + 0.001 -- to avoid division by zero
		print("std of price: ", std)

		for _, province in pairs(WORLD.provinces) do
			ut.set_default_color(province.center)
			if province.center.is_land then
				if province.realm ~= nil then
					local price = ev.get_local_price(province, c)
					-- ut.hue_from_value(tile, 1 - math.log(1 + (price - mean) / std, 2) / 10)
					local normalized = (price - mean) / std
					ut.hue_from_value(province.center, 0.5 * (1 + normalized / (1 + math.abs(normalized))))
				end
			end
		end
	else
		print("Nil for " .. tostring(c))
	end
end

return dem
