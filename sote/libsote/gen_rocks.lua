local gr = {}

local rock_layers = require("libsote.rock_layers")
local rand = require("libsote.randomness")

local function assign_rock_layer_to_tile(index, world)
    local tile_rock_type = world.rock_type[index]
    local hashed_layer_index = rand.pcg_hash(tile_rock_type + world.plate[index] + world.seed)
    local random_layer_index = hashed_layer_index % #rock_layers[tile_rock_type] + 1
    local layer = rock_layers[tile_rock_type][random_layer_index]

    world.rocks[index].name = layer.name
    world.rocks[index].r = layer.r
    world.rocks[index].g = layer.g
    world.rocks[index].b = layer.b
    -- store rgb_id as well? or just id instead of rgb?
end

local function run(index, world)
    assign_rock_layer_to_tile(index, world)

    -- resources, but skip for now
end

function gr.run(world)
    for index = 0, world.tile_count - 1 do
        run(index, world)
    end
end

return gr