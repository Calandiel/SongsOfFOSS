local tile = require "game.entities.tile"
local dpi = {}

function dpi.determine()
	-- First, clear old indices
	for _, tile_id in pairs(WORLD.tiles) do
		DATA.tile_set_pathfinding_index(tile_id, 0)
	end
	-- then, flood fill to fill new indices!
	---@type Queue<tile_id>
	local queue = require "engine.queue":new()
	local index = 0
	for _, tile_id in pairs(WORLD.tiles) do
		if DATA.tile_get_pathfinding_index(tile_id) == 0 then
			-- unasigned tile! time to flood fill!
			index = index + 1
			DATA.tile_set_pathfinding_index(tile_id, index)
			queue:enqueue(tile_id)
			while queue:length() > 0 do
				local pt = queue:dequeue()
				for neigh in tile.iter_neighbors(pt) do
					if DATA.tile_get_pathfinding_index(neigh) == 0 and DATA.tile_get_is_land(neigh) == DATA.tile_get_is_land(tile_id) then
						DATA.tile_set_pathfinding_index(neigh, index)
						queue:enqueue(neigh)
					end
				end
			end
		end
	end
end

return dpi
