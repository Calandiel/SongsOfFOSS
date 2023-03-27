local dpi = {}

function dpi.determine()
	-- First, clear old indices
	for _, tile in pairs(WORLD.tiles) do
		tile.pathfinding_index = 0
	end
	-- then, flood fill to fill new indices!
	local queue = require "engine.queue":new()
	local index = 0
	for _, tile in pairs(WORLD.tiles) do
		if tile.pathfinding_index == 0 then
			-- unasigned tile! time to flood fill!
			index = index + 1
			tile.pathfinding_index = index
			queue:enqueue(tile)
			while queue:length() > 0 do
				--print(queue:length())
				local pt = queue:dequeue()
				for neigh in pt:iter_neighbors() do
					if neigh.pathfinding_index == 0 and neigh.is_land == tile.is_land then
						neigh.pathfinding_index = index
						queue:enqueue(neigh)
					end
				end
			end
		end
	end
end

return dpi
