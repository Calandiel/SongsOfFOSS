local col = require "cpml".color
local tile = require "game.entities.tile"
local tabb = require "engine.table"

local ut = {}

---@enum MAP_MODE_GRANULARITY
ut.MAP_MODE_GRANULARITY = {
	TILE = 1,
	PROVINCE = 2,
	MIXED = 3
}

---@enum MAP_MODE_UPDATES_TYPE
ut.MAP_MODE_UPDATES_TYPE= {
	STATIC = 1,
	DYNAMIC = 2,
	DYNAMIC_PROVINCE_STATIC_TILE = 3
}

---@class (exact) FastMapModeEntry
---@field r number
---@field g number
---@field b number
---@field threshold number

---Colors tiles given a closure and color thresholds
---@param get_val_closure fun(tile_id):number
---@param colors table<FastMapModeEntry>
function ut.simple_map_mode(get_val_closure, colors)
	DATA.for_each_tile(function (tile_id)
		local val = get_val_closure(tile_id)
		local r, g, b = 0.1, 0.1, 0.1
		for _, cl in ipairs(colors) do
			if cl.threshold > val then
				r = cl.r
				g = cl.g
				b = cl.b
				break
			end
		end
		tile.set_real_color(tile_id, r, g, b)
	end)
end

---Sets a hue based tile color from a 0-1 value. Clamps internally.
---@param tile_id tile_id
---@param vval number
function ut.hue_from_value(tile_id, vval)
	local hue = math.min(1, math.max(0, vval)) * 0.7
	local rgb = col.from_hsv(hue, 1, 0.75 + vval / 4)
	local r, g, b = rgb:unpack()

	tile.set_real_color(tile_id, r, g, b)

	if DATA.tile_get_is_land(tile_id) then
		-- nothing to do, it's a land tile!
	else
		ut.set_default_color(tile_id) -- fill the sea tiles
	end
end

---Colors tiles given a closure and color thresholds
---@param get_val_closure fun(tile_id):number Should return a number between 0 and 1
---@param include_sea boolean?
function ut.simple_hue_map_mode(get_val_closure, include_sea)
	--print("hue")

	local prev = -1
	DATA.for_each_tile(function (tile_id)
		if include_sea then
			-- nothing to do, we include sea!
		else
			--is_land
			--if DATA.tile_get_is_land(tile_id) then print(i, 'vs', prev) end
			local vval = get_val_closure(tile_id)
			ut.hue_from_value(tile_id, vval)
		end
	end)
end

---@param get_val_closure fun(prov: Province):number Should return a number between 0 and 1
---@param include_sea boolean?
function ut.provincial_hue_map_mode(get_val_closure, include_sea)
	--print("hue")
	local prev = -1
	DATA.for_each_province(function (province)
		if include_sea then
			-- nothing to do, we include sea!
		else
			local vval = get_val_closure(province)
			ut.hue_from_value(DATA.province_get_center(province), vval)
		end
	end)
end

---Sets the real color on a tile to the default color
---@param tile_id tile_id
function ut.set_default_color(tile_id)
	if DATA.tile_get_is_land(tile_id) then
		tile.set_real_color(tile_id,0.2, 0.2, 0.2)
	else
		tile.set_real_color(tile_id,0.1, 0.1, 0.1)
	end
end

---Loops through all tiles and sets them to the default color.
function ut.clear_color()
	DATA.for_each_tile(function (tile_id)
		ut.set_default_color(tile_id)
	end)
end

function ut.clear_color_provinces()
	DATA.for_each_province(function (province)
		tile.set_real_color(DATA.province_get_center(province), 0.1, 0.1, 0.1)
	end)
end

ut.elevation_threshold = {
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
		r = 0.4,
		g = 0.6,
		b = 0.4
	},
	{
		threshold = 10,
		r = 0.42,
		g = 0.62,
		b = 0.42
	},
	{
		threshold = 30,
		r = 0.44,
		g = 0.64,
		b = 0.44
	},
	{
		threshold = 50,
		r = 0.46,
		g = 0.66,
		b = 0.46
	},
	{
		threshold = 200,
		r = 0.47,
		g = 0.7,
		b = 0.47
	},
	{
		threshold = 275,
		r = 0.48,
		g = 0.75,
		b = 0.49
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
}

return ut
