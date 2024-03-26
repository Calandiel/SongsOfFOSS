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

function rand:random_max(max)
    return self.rng:random(max)
end

local ffi = require("ffi")
local bit = require("bit")

ffi.cdef[[
typedef uint32_t uint;
]]

-- github copilot port, unvalidated, untested
function rand.pcg_hash(input)
    local state = ffi.new("uint", input * 747796405 + 2891336453)
    local word = ffi.new("uint", bit.bxor(state, bit.rshift(state, bit.bxor(bit.rshift(state, 28), 4))) * 277803737)
    return tonumber(bit.bxor(word, bit.rshift(word, 22)))
end

return rand