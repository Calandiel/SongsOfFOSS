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

-- local cpml = require "cpml"
-- local vec3 = cpml.vec3
-- local mat4 = cpml.mat4
local vec3f = require "libsote.vec3f"

local ffi = require "ffi"
local float3 = ffi.new("float[3]")

--- Casts the components of a 3D vector to single-precision floats.
-- @param v vec3 The 3D vector.
-- @return vec3 The resulting 3D vector with single-precision
function ma.vec3_to_float(v)
	float3[0], float3[1], float3[2] = v[0], v[1], v[2]
	return vec3f(float3[0], float3[1], float3[2])
end

--- Casts a lua number to single-precision floats.
-- @param n number The 3D vector.
-- @return number The resulting number with single-precision
function ma.num_to_float(n)
	float3[0] = n
	return float3[0]
end

local fmt = "%.17f"

local function num_to_string(n)
    return string.format(fmt, n)
end

--- Calculates the barycentric coordinates of a point with respect to a triangle.
-- @param vec3f p The point.
-- @param vec3f v1 The first vertex of the triangle.
-- @param vec3f v2 The second vertex of the triangle.
-- @param vec3f v3 The third vertex of the triangle.
-- @return number u The first barycentric coordinate.
-- @return number v The second barycentric coordinate.
-- @return number w The third barycentric coordinate.
function ma.barycentric_coordinates(p, v1, v2, v3)
	local vec0 = vec3f.sub(v2, v1)
	local vec1 = vec3f.sub(v3, v1)
	local vec2 = vec3f.sub(p, v1)
	local d00 = vec3f.dot(vec0, vec0)
	local d01 = vec3f.dot(vec0, vec1)
	local d11 = vec3f.dot(vec1, vec1)
	local d20 = vec3f.dot(vec2, vec0)
	local d21 = vec3f.dot(vec2, vec1)
	-- print(num_to_string(d00) .. " " .. num_to_string(d01) .. " " .. num_to_string(d11) .. " " .. num_to_string(d20) .. " " .. num_to_string(d21))
	local denom = ma.num_to_float((d00 * d11) - (d01 * d01))
	local v = ma.num_to_float((d11 * d20 - d01 * d21) / denom)
	-- print(num_to_string(d00 * d21) .. " " .. num_to_string(d01 * d20) .. " " .. num_to_string(d00 * d21 - d01 * d20) .. " " .. num_to_string(denom) .. " " .. num_to_string(ma.num_to_float(ma.num_to_float(d00 * d21 - d01 * d20) / denom)))
	local w = ma.num_to_float(ma.num_to_float(d00 * d21 - d01 * d20) / denom)
	local u = ma.num_to_float(1.0 - v) - w
	return u, v, w
end

--- Multiplies a 4x4 matrix with a 3D vector.
-- @param mat4 m The 4x4 matrix.
-- @param vec3 v The 3D vector.
-- @return vec3 The resulting 3D vector.
-- function ma.mult_mat4_vec3(m, v)
-- 	local result = {}
-- 	mat4.mul_vec4(result, m, {v.x, v.y, v.z, 1})
-- 	return vec3(result[1], result[2], result[3])
-- end

-- --- Casts the elements of a table to single-precision floats.
-- -- @param t table The table.
-- -- @return table The resulting table with single-precision
-- function ma.table_to_float(t)
-- 	local result = {}
-- 	for i, v in ipairs(t) do
-- 		result[i] = ma.num_to_float(v)
-- 	end
-- 	return result
-- end

return ma
