---@class rand

local rand = {}
rand.__index = rand

---@param  seed number
---@return rand
function rand:new(seed)
	local new = {}
	new.rng = love.math.newRandomGenerator(seed)
	setmetatable(new, rand)
	return new
end

---@return number [0 .. 1)
function rand:random()
	return self.rng:random()
end

---@param max number
---@return number [0 .. max)
function rand:random_int_max(max)
	return math.floor(self.rng:random() * max)
end

---@param min number
---@param max number
---@return number [min .. max)
function rand:random_int_min_max(min, max)
	return math.floor(self.rng:random() * (max - min) + min)
end

---@param min number
---@param max number
---@return number [min .. max)
function rand:random_float_min_max(min, max)
	return self.rng:random() * (max - min) + min
end

local ffi = require("ffi")
local bit = require("bit")

ffi.cdef[[
typedef uint32_t uint;
]]

---@param input number
---@return number?
function rand.pcg_hash(input)
	local state = ffi.new("uint", input * 747796405 + 2891336453)
	local word = ffi.new("uint", bit.bxor(state, bit.rshift(state, bit.bxor(bit.rshift(state, 28), 4))) * 277803737)
	return tonumber(bit.bxor(word, bit.rshift(word, 22)))
end

return rand