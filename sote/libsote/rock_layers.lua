local rock_layers = {}

---@enum rock_types
local rock_types = {
    no_type         = 0,
    acid_plutonics  = 3,
    sandstone       = 4,
    siltstone       = 5,
    mudstone        = 7,
    limestone       = 10, -- 0x0000000A
    limestone_reef  = 12, -- 0x0000000C
    basic_volcanics = 22, -- 0x00000016
    basic_plutonics = 23, -- 0x00000017
    mixed_volcanics = 24, -- 0x00000018
    mixed_plutonics = 25, -- 0x00000019
    acid_volcanics  = 26, -- 0x0000001A
    slate           = 27, -- 0x0000001B
    marble          = 28, -- 0x0000001C
}

for _, value in pairs(rock_types) do
    rock_layers[value] = {}
end

require("libsote.stone_layers_loader").load()
local stone_layers = require("libsote.stone_layer").get_layers_by_id()

local function assign_igneous_extrusive(stone_layer)
    if stone_layer.acidity < 0.33000001311302185 then
        table.insert(rock_layers[rock_types.basic_volcanics], stone_layer)
    elseif stone_layer.acidity < 0.6600000262260437 then
        table.insert(rock_layers[rock_types.mixed_volcanics], stone_layer)
    else
        table.insert(rock_layers[rock_types.acid_volcanics], stone_layer)
    end
end

local function assign_igneous_intrusive(stone_layer)
    if stone_layer.acidity < 0.33000001311302185 then
        table.insert(rock_layers[rock_types.basic_plutonics], stone_layer)
    elseif stone_layer.acidity < 0.6600000262260437 then
        table.insert(rock_layers[rock_types.mixed_plutonics], stone_layer)
    else
        table.insert(rock_layers[rock_types.acid_plutonics], stone_layer)
    end
end

local function assign_sedimentary(stone_layer)
    if stone_layer.clastic then
        if stone_layer.grain_size < 0.33000001311302185 then
            table.insert(rock_layers[rock_types.mudstone], stone_layer)
        elseif stone_layer.grain_size < 0.6600000262260437 then
            table.insert(rock_layers[rock_types.siltstone], stone_layer)
        else
            table.insert(rock_layers[rock_types.sandstone], stone_layer)
        end
    elseif stone_layer.evaporative then -- redundant branch, for readability from the perspective of the underlying geological principles
        table.insert(rock_layers[rock_types.limestone], stone_layer)
    else
        table.insert(rock_layers[rock_types.limestone], stone_layer)
    end
end

local function assign_to_rock_layer(stone_layer)
    if stone_layer.igneous_extrusive then
        assign_igneous_extrusive(stone_layer)
    end

    if stone_layer.igneous_intrusive then
        assign_igneous_intrusive(stone_layer)
    end

    if stone_layer.sedimentary then
        assign_sedimentary(stone_layer)
    end

    if stone_layer.metamorphic_marble then
        table.insert(rock_layers[rock_types.marble], stone_layer)
    end

    if stone_layer.metamorphic_slate then
        table.insert(rock_layers[rock_types.slate], stone_layer)
    end

    if stone_layer.oceanic then
        table.insert(rock_layers[rock_types.no_type], stone_layer)
    end

    if stone_layer.sedimentary_ocean_deep or stone_layer.sedimentary_ocean_shallow then
        table.insert(rock_layers[rock_types.limestone_reef], stone_layer)
    end
end

for _, stone_layer in pairs(stone_layers) do
    assign_to_rock_layer(stone_layer)
end

-- local rock_types_to_name = {}
-- for k, v in pairs(rock_types) do
--     rock_types_to_name[v] = k
-- end

-- for rock_type, layers in pairs(rock_layers) do
--     local rock_type_key = rock_types_to_name[rock_type] or "unknown"
--     print("rock type: " .. rock_type_key .. "; " .. #layers .. " layers")
--     for i, layer in ipairs(layers) do
--         print("\tlayer " .. i .. ": " .. layer.name)
--     end
--     if #layers == 0 then
--         print("\tno layers for this rock type")
--     end
-- end

return rock_layers