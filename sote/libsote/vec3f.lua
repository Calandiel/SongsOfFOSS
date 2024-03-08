local vec3f = {}

local ffi = require "ffi"

local float_num = ffi.new("float[1]")
local function to_float(n)
	float_num[0] = n
	return float_num[0]
end

function vec3f.new(x, y, z)
    return ffi.new("float[3]", x, y, z)
end

function vec3f.add(a, b)
    return vec3f.new(
        a[0] + b[0],
        a[1] + b[1],
        a[2] + b[2]
    )
end

function vec3f.sub(a, b)
    return vec3f.new(
        a[0] - b[0],
        a[1] - b[1],
        a[2] - b[2]
    )
end

function vec3f.add3(a, b, c)
    return vec3f.new(
        a[0] + b[0] + c[0],
        a[1] + b[1] + c[1],
        a[2] + b[2] + c[2]
    )
end

function vec3f.scale(a, b)
    return vec3f.new(
        to_float(a[0] * b),
        to_float(a[1] * b),
        to_float(a[2] * b)
    )
end

function vec3f.len2(a)
    return to_float(a[0] * a[0]) + to_float(a[1] * a[1]) + to_float(a[2] * a[2])
end

function vec3f.cross(a, b)
    return vec3f.new(
        to_float(a[1] * b[2]) - to_float(a[2] * b[1]),
        to_float(a[2] * b[0]) - to_float(a[0] * b[2]),
        to_float(a[0] * b[1]) - to_float(a[1] * b[0])
    )
end

function vec3f.dot(a, b)
    return to_float(to_float(to_float(a[0] * b[0]) + to_float(a[1] * b[1])) + to_float(a[2] * b[2]))
end

-- here we want to return a double
function vec3f.dot_double(a, b)
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
end

function vec3f.to_string(a)
	return string.format("(%.17f, %.17f, %.17f)", a[0], a[1], a[2])
end

return vec3f

-- local vec3f    = {}
-- local vec3f_mt = {}

-- -- Private constructor.
-- local function new(x, y, z)
-- 	return setmetatable({
-- 		x = x or 0,
-- 		y = y or 0,
-- 		z = z or 0
-- 	}, vec3f_mt)
-- end

-- -- Do the check to see if JIT is enabled. If so use the optimized FFI structs.
-- local status, ffi
-- if type(jit) == "table" and jit.status() then
-- 	status, ffi = pcall(require, "ffi")
-- 	if status then
-- 		ffi.cdef "typedef float sote_vec3f[3];"
-- 		new = ffi.typeof("sote_vec3f")
-- 	end
-- end

-- local float_num = ffi.new("float")
-- local function to_float(n)
-- 	float_num = n
-- 	return float_num
-- end

-- function vec3f.new(x, y, z)
--     return new(x, y, z)
-- end

-- function vec3f.is_vec3f(a)
-- 	if type(a) == "cdata" then
-- 		return ffi.istype("sote_vec3f", a)
-- 	end

-- 	return
-- 		type(a)   == "table"  and
-- 		type(a.x) == "number" and
-- 		type(a.y) == "number" and
-- 		type(a.z) == "number"
-- end

-- function vec3f.add(a, b)
-- 	return new(
-- 		a.x + b.x,
-- 		a.y + b.y,
-- 		a.z + b.z
-- 	)
-- end

-- function vec3f.sub(a, b)
-- 	return new(
-- 		a.x - b.x,
-- 		a.y - b.y,
-- 		a.z - b.z
-- 	)
-- end

-- function vec3f.mul(a, b)
-- 	return new(
-- 		to_float(a.x * b.x),
-- 		to_float(a.y * b.y),
-- 		to_float(a.z * b.z)
-- 	)
-- end

-- function vec3f.scale(a, b)
-- 	return new(
-- 		a.x * b,
-- 		a.y * b,
-- 		a.z * b
-- 	)
-- end

-- function vec3f.len2(a)
-- 	return a.x * a.x + a.y * a.y + a.z * a.z
-- end

-- function vec3f.cross(a, b)
-- 	return new(
-- 		a.y * b.z - a.z * b.y,
-- 		a.z * b.x - a.x * b.z,
-- 		a.x * b.y - a.y * b.x
-- 	)
-- end

-- function vec3f.dot(a, b)
-- 	return to_float(a.x * b.x) + to_float(a.y * b.y) + to_float(a.z * b.z)
-- end

-- function vec3f.to_string(a)
-- 	return string.format("(%.9f, %.9f, %.9f)", a[0], a[1], a[2])
-- end

-- vec3f_mt.__index    = vec3f
-- vec3f_mt.__tostring = vec3f.to_string

-- function vec3f_mt.__call(_, x, y, z)
-- 	return vec3f.new(x, y, z)
-- end

-- function vec3f_mt.__add(a, b)
-- 	return a:add(b)
-- end

-- function vec3f_mt.__sub(a, b)
-- 	return a:sub(b)
-- end

-- function vec3f_mt.__mul(a, b)
-- 	if vec3f.is_vec3f(b) then
-- 		return a:mul(b)
-- 	end

-- 	return a:scale(b)
-- end

-- if status then
-- 	xpcall(function()
-- 		ffi.metatype(new, vec3f_mt)
-- 	end, function() end)
-- end

-- return setmetatable({}, vec3f_mt)
