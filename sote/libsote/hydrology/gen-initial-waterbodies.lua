local giw = {}

local queue = require("engine.queue"):new()

local waterbodies_created = 0

local function process(tile_index, world)
	if world.is_land[tile_index] then return end

	if world:is_tile_waterbody_valid(tile_index) then return end

	-- "no ice" check is skipped for now

	local new_waterbody_id = world:create_new_waterbody()
	waterbodies_created = waterbodies_created + 1

	local waterbody = world.waterbodies[new_waterbody_id]
	waterbody.id = new_waterbody_id
	waterbody.tiles[1] = tile_index

	world.waterbody_id_by_tile[tile_index] = new_waterbody_id
	queue:enqueue(tile_index)

	while not queue:is_empty() do
		local ti = queue:dequeue()

		world:for_each_neighbor(ti, function(nti)
			if world.is_land[nti] then return end

			if world:is_tile_waterbody_valid(nti) then return end

			world.waterbody_id_by_tile[nti] = new_waterbody_id
			waterbody.tiles[#waterbody.tiles + 1] = nti

			queue:enqueue(nti)
		end)
	end
end

function giw.run(world)
	world:for_each_tile(process)
	print("Waterbodies created: " .. waterbodies_created)
end

return giw