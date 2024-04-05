

local color_space = {}

---Returns a [0-1]^3 RGB color based on a hsv color.
---@param h number hue [0-360]
---@param s number saturation [0-1]
---@param v number value [0-1]
---@return number r
---@return number g
---@return number b
function color_space.hsv_to_rgb(h, s, v)
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
function color_space.rgb_to_hsv(r, g, b)
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

return color_space