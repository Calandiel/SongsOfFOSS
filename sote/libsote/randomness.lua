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

---@return number
function rand:get_seed()
	return self.rng:getSeed()
end

---@return string
function rand:get_state()
	return self.rng:getState()
end

---@param seed number
function rand:set_seed(seed)
	self.rng:setSeed(seed)
end

---@param state string
function rand:set_state(state)
	self.rng:setState(state)
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

---@param input number
---@return number?
function rand.pcg_hash(input)
	local state = ffi.new("uint32_t", input * 747796405 + 2891336453)
	local word = ffi.new("uint32_t", bit.bxor(state, bit.rshift(state, bit.bxor(bit.rshift(state, 28), 4))) * 277803737)
	return tonumber(bit.bxor(word, bit.rshift(word, 22)))
end

return rand