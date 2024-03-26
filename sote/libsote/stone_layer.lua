---@class stone_layer
---@field name string
---@field r number
---@field g number
---@field b number
---@field igneous_extrusive boolean
---@field acidity number
---@field igneous_intrusive boolean
---@field sedimentary boolean
---@field clastic boolean
---@field grain_size number
---@field evaporative boolean
---@field metamorphic_marble boolean
---@field metamorphic_slate boolean
---@field oceanic boolean
---@field sedimentary_ocean_deep boolean
---@field sedimentary_ocean_shallow boolean

local col = require "game.color"

local layers_by_id = {}
local stone_layer = {}

stone_layer.__index = stone_layer

---@param obj stone_layer
---@return stone_layer
function stone_layer:new(obj)
    local new = {}

    new.name = "stone"
    new.r = 0
    new.g = 0
    new.b = 0
    new.igneous_extrusive = false
    new.acidity = 0.0
    new.igneous_intrusive = false
    new.sedimentary = false
    new.clastic = false
    new.grain_size = 0.0
    new.evaporative = false
    new.metamorphic_marble = false
    new.metamorphic_slate = false
    new.oceanic = false
    new.sedimentary_ocean_deep = false
    new.sedimentary_ocean_shallow = false

    for k, v in pairs(obj) do
        new[k] = v
    end

    setmetatable(new, stone_layer)

    local id = col.rgb_to_id(new.r, new.g, new.b)
    layers_by_id[id] = new

    return new
end

function stone_layer.get_layers_by_id()
    return layers_by_id
end

return stone_layer