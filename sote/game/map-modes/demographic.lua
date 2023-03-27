local ut = require "game.map-modes.utils"
local tabb = require "engine.table"
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
		return math.max(0, t.province:population() - 10) / 100
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
	local tt = require "game.scenes.game".cached_selected_tech
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

---@type TradeGood?
HACKY_MAP_MODE_CONTEXT_TRADE_CATEGORY = nil

function dem.prices()
	local c = HACKY_MAP_MODE_CONTEXT_TRADE_CATEGORY
	if c ~= nil then
		for _, tile in ipairs(WORLD.tiles) do
			ut.set_default_color(tile)
			if tile.is_land then
				if tile.province.realm ~= nil then
					local price = tile.province.realm:get_price(c)
					ut.hue_from_value(tile, 1 - math.log(price, 2) / 10)
				end
			end
		end
	else
		print("Nil for " .. tostring(c))
	end
end

return dem
