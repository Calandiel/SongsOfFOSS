local giw = {}

local queue = require("engine.queue"):new()

local waterbodies_created = 0

local function process(tile_index, world)
	if world.is_land[tile_index] then return end

	if world:is_tile_waterbody_valid(tile_index) then return end

	-- "no ice" check is skipped for now

	local new_wb = world:create_new_waterbody_from_tile(tile_index)
	waterbodies_created = waterbodies_created + 1

	queue:enqueue(tile_index)

	while not queue:is_empty() do
		local ti = queue:dequeue()

		world:for_each_neighbor(ti, function(nti)
			if world.is_land[nti] or world:is_tile_waterbody_valid(nti) then return end

			world:add_tile_to_waterbody(new_wb, nti)

			queue:enqueue(nti)
		end)
	end
end

function giw.run(world)
	world:for_each_tile(process)
	-- print("Waterbodies created: " .. waterbodies_created)
end

return giw