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
									tile:set_real_color(0, 1, 0)
									---@diagnostic disable-next-line: param-type-mismatch
								elseif tile.province.realm:at_war_with(rr) then
									tile:set_real_color(1, 0, 0)
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
---@param h number hue [0-1]
---@param s number saturation [0-1]
---@param v number value [0-1]
---@return number r
---@return number g
---@return number b
function hsv_to_rgb(h, s, v)
    local c = v * s;
    local x = c * (1 - math.abs((h / 60) % 2 - 1));
    local m = v - c;
    if h <  60 then return c + m, x + m, 0 + m end;
    if h < 120 then return x + m, c + m, 0 + m end;
    if h < 180 then return 0 + m, c + m, x + m end;
    if h < 240 then return 0 + m, x + m, c + m end;
    if h < 300 then return x + m, 0 + m, c + m end;
                    return c + m, 0 + m, x + m;
end

---Given r/g/b values in the 0-1 space, return the hsv values
---@param r number
---@param g number
---@param b number
---@return number h 0 to 360
---@return number s 0 to 1
---@return number v 0 to 1
function rgb_to_hsv(r, g, b)
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

function pol.atlas()
    ut.simple_map_mode(
		function(tile)
			if tile.is_land then
				return math.max(0, tile.elevation)
			else
				return math.min(0, tile.elevation)
			end
		end, {
		-- WATER
		{
			threshold = -7500,
			r = 0.1,
			g = 0.1,
			b = 0.1
		},
		{
			threshold = -5000,
			r = 0.15,
			g = 0.15,
			b = 0.3
		},
		{
			threshold = -4000,
			r = 0.2,
			g = 0.2,
			b = 0.4
		},
		{
			threshold = -3500,
			r = 0.2125,
			g = 0.225,
			b = 0.45
		},
		{
			threshold = -3000,
			r = 0.225,
			g = 0.25,
			b = 0.5
		},
		{
			threshold = -2500,
			r = 0.2375,
			g = 0.275,
			b = 0.55
		},
		{
			threshold = -2000,
			r = 0.25,
			g = 0.3,
			b = 0.6
		},
		{
			threshold = -1750,
			r = 0.275,
			g = 0.35,
			b = 0.65
		},
		{
			threshold = -1500,
			r = 0.3,
			g = 0.4,
			b = 0.7
		},
		{
			threshold = -1250,
			r = 0.325,
			g = 0.45,
			b = 0.75
		},
		{
			threshold = -1000,
			r = 0.35,
			g = 0.5,
			b = 0.8
		},
		{
			threshold = -750,
			r = 0.375,
			g = 0.55,
			b = 0.85
		},
		{
			threshold = -500,
			r = 0.4,
			g = 0.6,
			b = 0.9
		},
		{
			threshold = -250,
			r = 0.6,
			g = 0.75,
			b = 0.95
		},
		{
			threshold = -125,
			r = 0.7,
			g = 0.825,
			b = 0.975
		},
		{
			threshold = -75,
			r = 0.75,
			g = 0.8625,
			b = 0.9875
		},
		{
			threshold = 0,
			r = 0.8,
			g = 0.9,
			b = 1
		},
		-- LAND
		{
			threshold = 2.5,
			r = 0.3,
			g = 0.45,
			b = 0.3
		},
		{
			threshold = 10,
			r = 0.35,
			g = 0.5,
			b = 0.35
		},
		{
			threshold = 30,
			r = 0.375,
			g = 0.55,
			b = 0.375
		},
		{
			threshold = 50,
			r = 0.4,
			g = 0.6,
			b = 0.4
		},
		{
			threshold = 200,
			r = 0.45,
			g = 0.7,
			b = 0.45
		},
		{
			threshold = 275,
			r = 0.475,
			g = 0.75,
			b = 0.475
		},
		{
			threshold = 350,
			r = 0.5,
			g = 0.8,
			b = 0.5
		},
		{
			threshold = 450,
			r = 0.65,
			g = 0.8,
			b = 0.5
		},
		{
			threshold = 650,
			r = 0.8,
			g = 0.8,
			b = 0.5
		},
		{
			threshold = 1500,
			r = 0.8,
			g = 0.75,
			b = 0.55
		},
		{
			threshold = 2000,
			r = 0.8,
			g = 0.7,
			b = 0.6
		},
		{
			threshold = 2250,
			r = 0.75,
			g = 0.65,
			b = 0.55
		},
		{
			threshold = 2500,
			r = 0.7,
			g = 0.6,
			b = 0.5
		},
		{
			threshold = 3000,
			r = 0.65,
			g = 0.55,
			b = 0.45
		},
		{
			threshold = 3500,
			r = 0.6,
			g = 0.5,
			b = 0.4
		},
		{
			threshold = 3750,
			r = 0.525,
			g = 0.45,
			b = 0.375
		},
		{
			threshold = 4000,
			r = 0.45,
			g = 0.4,
			b = 0.35
		},
		{
			threshold = 4500,
			r = 0.4,
			g = 0.375,
			b = 0.35
		},
		{
			threshold = 4750,
			r = 0.375,
			g = 0.3825,
			b = 0.35
		},
		{
			threshold = 5000,
			r = 0.35,
			g = 0.35,
			b = 0.35
		},
		{
			threshold = 6000,
			r = 0.3,
			g = 0.3,
			b = 0.3
		},
		{
			threshold = 9999999,
			r = 0.25,
			g = 0.25,
			b = 0.25
		},
	})


	for _, tile in pairs(WORLD.tiles) do
		-- ut.set_default_color(tile)
		if tile.province ~= nil then
			if tile.province.realm ~= nil then
                local ele_h, ele_s, ele_v = rgb_to_hsv(tile.real_r, tile.real_g, tile.real_b)
                local pol_h, pol_s, pol_v = rgb_to_hsv(tile.province.realm.r, tile.province.realm.g, tile.province.realm.b)
                local r, g, b = hsv_to_rgb(pol_h, ele_s, ele_v)
            
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
