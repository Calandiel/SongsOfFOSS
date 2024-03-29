local ut = require "game.map-modes.utils"
local tabb = require "engine.table"

local ev = require "game.raws.values.economical"

local dem = {}

function dem.culture()
	for _, t in ipairs(WORLD.tiles) do
		ut.set_default_color(t)
		local e = t.province:get_dominant_culture()
		if e ~= nil then
			t:set_real_color(e.r, e.g, e.b)
		end
	end
end

function dem.faith()
	for _, t in ipairs(WORLD.tiles) do
		ut.set_default_color(t)
		local e = t.province:get_dominant_faith()
		if e ~= nil then
			t:set_real_color(e.r, e.g, e.b)
		end
	end
end

function dem.race()
	for _, t in ipairs(WORLD.tiles) do
		ut.set_default_color(t)
		local e = t.province:get_dominant_race()
		if e ~= nil then
			t:set_real_color(e.r, e.g, e.b)
		end
	end
end

function dem.population()
	ut.simple_hue_map_mode(function(tile)
		---@type Tile
		local t = tile
		if (t.province.size == 0) then return 0 end
		return math.min(1, t.province:population() / 100)
	end)
end

function dem.population_1000()
	ut.simple_hue_map_mode(function(tile)
		---@type Tile
		local t = tile
		if (t.province.size == 0) then return 0 end
		return math.min(1, t.province:population() / 1000)
	end)
end

function dem.population_density()
	ut.simple_hue_map_mode(function(tile)
		---@type Tile
		local t = tile
		if (t.province.size == 0) then return 0 end
		return math.min(1, math.max(0, t.province:population() - 10) / t.province.size)
	end)
end

function dem.military()
	ut.simple_hue_map_mode(function(tile)
		---@type Tile
		local t = tile
		return math.max(0, t.province:military()) / 15
	end)
end

function dem.military_target()
	ut.simple_hue_map_mode(function(tile)
		---@type Tile
		local t = tile
		return math.max(0, t.province:military_target()) / 15
	end)
end

function dem.technologies()
	ut.simple_hue_map_mode(function(tile)
		---@type Tile
		local t = tile
		local count = tabb.size(t.province.technologies_present)
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

	ut.clear_color()
	if tt then
		for _, tile in ipairs(WORLD.tiles) do
			local prov = tile.province
			if prov.technologies_present[tt] then
				tile:set_real_color(0, 0, 1)
			elseif prov.technologies_researchable[tt] then
				tile:set_real_color(0, 1, 1)
			end
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

		for _, tile in ipairs(WORLD.tiles) do
			ut.set_default_color(tile)
			if tile.is_land then
				if tile.province.realm ~= nil then
					local price = ev.get_local_price(tile.province, c)
					-- ut.hue_from_value(tile, 1 - math.log(1 + (price - mean) / std, 2) / 10)
					local normalized = (price - mean) / std
					ut.hue_from_value(tile, 0.5 * (1 + normalized / (1 + math.abs(normalized))))
				end
			end
		end
	else
		print("Nil for " .. tostring(c))
	end
end

return dem
