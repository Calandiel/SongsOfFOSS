local geo = {}

local ut = require "game.map-modes.utils"

function geo.resources()
	for _, tile in pairs(WORLD.tiles) do
		if tile.resource then
			local r, g, b = tile.resource.r, tile.resource.g, tile.resource.b
			tile:set_real_color(r, g, b)
		else
			ut.set_default_color(tile)
		end
	end
end

function geo.plates()
	for _, tile in pairs(WORLD.tiles) do
		if tile.plate then
			local r, g, b = tile.plate.r, tile.plate.g, tile.plate.b
			tile:set_real_color(r, g, b)
		else
			tile:set_real_color(0.1, 0.1, 0.1)
		end
	end
end

function geo.rocks()
	for _, tile in pairs(WORLD.tiles) do
		if tile.bedrock then
			local r, g, b = tile.bedrock.r, tile.bedrock.g, tile.bedrock.b
			tile:set_real_color(r, g, b)
		else
			tile:set_real_color(0.1, 0.1, 0.1)
		end
	end
end

function geo.elevation()
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
		if tile.ice > 0 then
			tile:set_real_color(0.95, 0.95, 1)
		end
	end
end

return geo
