local col = {}

---Given r/g/b values in 0-1 range, returns a special identifier unique to that color
---@param r number
---@param g number
---@param b number
---@return number
function col.rgb_to_id(r, g, b)
	return math.floor(256 * r  + 256 * 256 * g + 256 * 256 * 256 * b)
end

---Transforms the 0-1 color space to the 0-255 color space...
---@param r number
---@param g number
---@param b number
---@return number r
---@return number g
---@return number b
function col.to_255(r, g, b)
	return math.floor(255 * r),
		math.floor(255 * g),
		math.floor(255 * b)
end

---Given two colors, returns true if they're equal
---@param r number
---@param g number
---@param b number
---@param vr number
---@param vg number
---@param vb number
---@return boolean
function col.equals(r, g, b, vr, vg, vb)
	return r == vr and
		g == vg and
		b == vb
end

local cp = require "cpml".color
---Returns a [0-1]^3 RGB color based on a hsv color.
---@param h number hue [0-1]
---@param s number saturation [0-1]
---@param v number value [0-1]
---@return number r
---@return number g
---@return number b
function col.hsv_to_rgb(h, s, v)
	local rgb = cp.from_hsv(h, s, v)
	local r, g, b = rgb:unpack()
	return r, g, b
end

---Given r/g/b values in the 0-1 space, return the hsv values
---@param r number
---@param g number
---@param b number
---@return number h 0 to 360
---@return number s 0 to 1
---@return number v 0 to 1
function col.rgb_to_hsv(r, g, b)
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

return col
