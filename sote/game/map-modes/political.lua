local ut = require "game.map-modes.utils"
local pol = {}

function pol.diplomacy(clicked_tile_id)
	local clicked_tile = WORLD.tiles[clicked_tile_id]
	if clicked_tile then
		if clicked_tile.province then
			if clicked_tile.province.realm then
				local rr = clicked_tile.province.realm
				for _, tile in pairs(WORLD.tiles) do
					ut.set_default_color(tile)
					if tile.province ~= nil then
						if tile.province.realm ~= nil then
							if rr then
								if tile.province.realm == rr then
									tile:set_real_color(051 / 255, 117 / 255, 056 / 255)
								elseif tile.province.realm.tributaries[rr] ~= nil then
									tile:set_real_color(150 / 255, 60 / 255, 100 / 255) -- color overlords
								elseif tile.province.realm.paying_tribute_to == rr then
									tile:set_real_color(220 / 255, 205 / 255, 125 / 255) -- color tributaries
								elseif tile.province.realm:at_war_with(rr) then
									tile:set_real_color(126 / 255, 041 / 255, 084 / 255) -- color wars
								end
							end
						end
					end
				end
			end
		end
	else
		ut.clear_color()
	end
end

function pol.realms()
	for _, tile in pairs(WORLD.tiles) do
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
	for _, tile in pairs(WORLD.tiles) do
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

local cp = require "cpml".color
---Returns a [0-1]^3 RGB color based on a hsv color.
---@param h number hue [0-360]
---@param s number saturation [0-1]
---@param v number value [0-1]
---@return number r
---@return number g
---@return number b
function pol.hsv_to_rgb(h, s, v)
	local c = v * s;
	local x = c * (1 - math.abs((h / 60) % 2 - 1));
	local m = v - c;
	if h < 60 then return c + m, x + m, 0 + m end
	;
	if h < 120 then return x + m, c + m, 0 + m end
	;
	if h < 180 then return 0 + m, c + m, x + m end
	;
	if h < 240 then return 0 + m, x + m, c + m end
	;
	if h < 300 then return x + m, 0 + m, c + m end
	;
	return c + m, 0 + m, x + m;
end

---Given r/g/b values in the 0-1 space, return the hsv values
---@param r number
---@param g number
---@param b number
---@return number h 0 to 360
---@return number s 0 to 1
---@return number v 0 to 1
local function rgb_to_hsv(r, g, b)
	local max = math.max(r, math.max(g, b))
	local min = math.min(r, math.min(g, b))

	local h = 0
	if max == min then
		h = 0
	elseif max == r then
		h = (g - b) * 60 / (max - min) % 360
	elseif max == g then
		h = (b - r) * 60 / (max - min) + 120
	elseif max == b then
		h = (r - g) * 60 / (max - min) + 240
	end
	local s = 0
	if max == 0 then
		s = 0
	else
		s = 1 - min / max
	end
	local v = max

	return h, s, v
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
				---@type Realm
				local source_realm = tile.province.realm:get_top_realm()

				local ele_h, ele_s, ele_v = rgb_to_hsv(tile.real_r, tile.real_g, tile.real_b)
				local pol_h, pol_s, pol_v = rgb_to_hsv(source_realm.r, source_realm.g,
					source_realm.b)
				local r, g, b = pol.hsv_to_rgb(mix(ele_h, pol_h, 0.9), mix(ele_s, pol_s, 0.6), mix(ele_v, pol_v, 0.3))

				tile:set_real_color(
					r,
					g,
					b
				)
			end
		end
	end
end

return pol
