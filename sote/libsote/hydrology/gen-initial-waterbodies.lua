local giw = {}

local queue = require("engine.queue"):new()

local waterbodies_created = 0

local function process(tile_index, world)
	local is_land = world:get_is_land_by_index(tile_index)
	if is_land then return end

	if world:is_waterbody_valid(tile_index) then return end

	local new_waterbody_id = world:create_new_waterbody()
	waterbodies_created = waterbodies_created + 1

	world.waterbody_by_tile[tile_index] = new_waterbody_id
	queue:enqueue(tile_index)

	while not queue:is_empty() do
		local current_tile_index = queue:dequeue()

		world:for_each_neighbor(current_tile_index, function(ni)
			local neighbor_is_land = world:get_is_land_by_index(ni)
			if neighbor_is_land then return end

			if world:is_waterbody_valid(ni) then return end

			world.waterbody_by_tile[ni] = new_waterbody_id
			queue:enqueue(ni)
		end)
	end
end

function giw.run(world)
	for i = 0, world.tile_count - 1 do
		process(i, world)
	end

	print("Waterbodies created: " .. waterbodies_created)
end

return giw