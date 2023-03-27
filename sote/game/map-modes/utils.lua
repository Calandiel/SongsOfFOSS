local col = require "cpml".color

local ut = {}

---@class FastMapModeEntry
---@field r number
---@field g number
---@field b number
---@field threshold number

---Colors tiles given a closure and color thresholds
---@param get_val_closure fun(Tile):number
---@param colors table<FastMapModeEntry>
function ut.simple_map_mode(get_val_closure, colors)
	for _, tile in ipairs(WORLD.tiles) do
		local val = get_val_closure(tile)
		local r, g, b = 0.1, 0.1, 0.1
		for _, cl in ipairs(colors) do
			if cl.threshold > val then
				r = cl.r
				g = cl.g
				b = cl.b
				break
			end
		end
		tile.real_r = r
		tile.real_g = g
		tile.real_b = b
	end
end

---Sets a hue based tile color from a 0-1 value. Clamps internally.
---@param tile Tile
---@param vval number
function ut.hue_from_value(tile, vval)
	local hue = math.min(1, math.max(0, vval)) * 0.7
	local rgb = col.from_hsv(hue, 1, 0.75 + vval / 4)
	local r, g, b = rgb:unpack()
	tile.real_r = r
	tile.real_g = g
	tile.real_b = b

	if tile.is_land then
		-- nothing to do, it's a land tile!
	else
		ut.set_default_color(tile) -- fill the sea tiles
	end
end

---Colors tiles given a closure and color thresholds
---@param get_val_closure fun(Tile):number Should return a number between 0 and 1
---@param include_sea boolean?
function ut.simple_hue_map_mode(get_val_closure, include_sea)
	--print("hue")
	local prev = -1
	for i, tile in ipairs(WORLD.tiles) do
		if i < 150 then
			--print("Check: ", prev == i)
		end
		if i == prev then
			print("Repeated ID: " .. tostring(i))
			error("Repeated ID: " .. tostring(i))
			love.event.quit()
			break
		end
		if include_sea then
			-- nothing to do, we include sea!
		else
			--is_land
			--if tile.is_land then print(i, 'vs', prev) end
			local vval = get_val_closure(tile)
			if i < 150 then
				if tile.is_land then print(vval, tile.tile_id) end
			end
			ut.hue_from_value(tile, vval)
		end
		if i < 150 then
			--print(prev, 'vs', i)
		end
		prev = i
		if i < 150 then
			--print(prev, 'vs', i)
		end
	end
end

---Sets the real color on a tile to the default color
---@param tile Tile
function ut.set_default_color(tile)
	if tile.is_land then
		tile:set_real_color(0.2, 0.2, 0.2)
	else
		tile:set_real_color(0.1, 0.1, 0.1)
	end
end

---Loops through all tiles and sets them to the default color.
function ut.clear_color()
	for _, tile in ipairs(WORLD.tiles) do
		ut.set_default_color(tile)
	end
end

return ut
