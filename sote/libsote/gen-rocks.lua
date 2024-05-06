local gr = {}

local rock_types = require "libsote.rock-type".types

local function fix_rock_type(index, world)
	if world.rock_type[index] == rock_types.no_type and world.is_land[index] then
		world.rock_type[index] = rock_types.acid_volcanics
	end
end

local rock_layers = require "libsote.rock-layers"
local rand = require "libsote.randomness"

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

local function process(tile_index, world)
	fix_rock_type(tile_index, world)
	assign_rock_layer_to_tile(tile_index, world)

	-- resources, but skip for now
end

function gr.run(world)
	for i = 0, world.tile_count - 1 do
		process(i, world)
	end
end

return gr