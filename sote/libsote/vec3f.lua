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
