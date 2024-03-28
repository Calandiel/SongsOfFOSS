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

local function assign_igneous_extrusive(bedrock)
    if bedrock.acidity < 0.33 then
        table.insert(rock_layers[rock_types.basic_volcanics], bedrock)
    elseif bedrock.acidity < 0.66 then
        table.insert(rock_layers[rock_types.mixed_volcanics], bedrock)
    else
        table.insert(rock_layers[rock_types.acid_volcanics], bedrock)
    end
end

local function assign_igneous_intrusive(bedrock)
    if bedrock.acidity < 0.33 then
        table.insert(rock_layers[rock_types.basic_plutonics], bedrock)
    elseif bedrock.acidity < 0.66 then
        table.insert(rock_layers[rock_types.mixed_plutonics], bedrock)
    else
        table.insert(rock_layers[rock_types.acid_plutonics], bedrock)
    end
end

local function assign_sedimentary(bedrock)
    if bedrock.clastic then
        if bedrock.grain_size < 0.33 then
            table.insert(rock_layers[rock_types.mudstone], bedrock)
        elseif bedrock.grain_size < 0.66 then
            table.insert(rock_layers[rock_types.siltstone], bedrock)
        else
            table.insert(rock_layers[rock_types.sandstone], bedrock)
        end
    elseif bedrock.evaporative then -- redundant branch, for readability from the perspective of the underlying geological principles
        table.insert(rock_layers[rock_types.limestone], bedrock)
    else
        table.insert(rock_layers[rock_types.limestone], bedrock)
    end
end

local function assign_to_rock_layer(bedrock)
    if bedrock.igneous_extrusive then
        assign_igneous_extrusive(bedrock)
    end

    if bedrock.igneous_intrusive then
        assign_igneous_intrusive(bedrock)
    end

    if bedrock.sedimentary then
        assign_sedimentary(bedrock)
    end

    if bedrock.metamorphic_marble then
        table.insert(rock_layers[rock_types.marble], bedrock)
    end

    if bedrock.metamorphic_slate then
        table.insert(rock_layers[rock_types.slate], bedrock)
    end

    if bedrock.oceanic then
        table.insert(rock_layers[rock_types.no_type], bedrock)
    end

    if bedrock.sedimentary_ocean_deep or bedrock.sedimentary_ocean_shallow then
        table.insert(rock_layers[rock_types.limestone_reef], bedrock)
    end
end

for _, bedrock in pairs(RAWS_MANAGER.bedrocks_by_color) do
    assign_to_rock_layer(bedrock)
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