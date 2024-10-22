local ma = {}

---Returns true when x is NaN or -NaN
---@param x number
---@return boolean
function ma.is_nan(x)
	return x ~= x
end

-- The pos_mod function calculates the modulus of two numbers.
-- Unlike the standard modulus operation, pos_mod ensures the result is always positive.
-- @param a number
-- @param b number
-- @return number The positive modulus of a and b.
function ma.pos_mod(a, b)
	return ((a % b) + b) % b
end

local cpml = require "cpml"
local vec3 = cpml.vec3

--- Calculates the barycentric coordinates of a point with respect to a triangle.
-- @param vec3 p The point.
-- @param vec3 a The first vertex of the triangle.
-- @param vec3 b The second vertex of the triangle.
-- @param vec3 c The third vertex of the triangle.
-- @return number u The first barycentric coordinate.
-- @return number v The second barycentric coordinate.
-- @return number w The third barycentric coordinate.
function ma.barycentric_coordinates(p, a, b, c)
	local v0 = b - a
	local v1 = c - a
	local v2 = p - a
	local d00 = vec3.dot(v0, v0)
	local d01 = vec3.dot(v0, v1)
	local d11 = vec3.dot(v1, v1)
	local d20 = vec3.dot(v2, v0)
	local d21 = vec3.dot(v2, v1)
	local denom = d00 * d11 - d01 * d01
	local v = (d11 * d20 - d01 * d21) / denom
	local w = (d00 * d21 - d01 * d20) / denom
	local u = 1.0 - v - w
	return u, v, w
end

local default_fmt = "%.7f"

-- @param num n
-- @param string fmt
-- @return string
function ma.num_to_string(n, fmt)
	return string.format(fmt or default_fmt, n)
end

-- @param vec2 v
-- @param string fmt
-- @return string
function ma.vec2_to_string(v, fmt)
	return "(" .. string.format(fmt or default_fmt, v.x) .. ", " .. string.format(fmt or default_fmt, v.y) .. ")"
end

-- @param vec3 v
-- @param string fmt
-- @return string
function ma.vec3_to_string(v, fmt)
	return "(" .. string.format(fmt or default_fmt, v.x) .. ", " .. string.format(fmt or default_fmt, v.y) .. ", " .. string.format(fmt or default_fmt, v.z) .. ")"
end

-- @param x number
-- @param y number
-- @param s number
-- @return number
function ma.lerp(x, y, s)
	return x + s * (y - x)
end

return ma
