local tile = require "game.entities.tile"
local hydr = {}

function hydr.run()
	-- Recalculate hydration!
	for _, pr in pairs(WORLD.provinces) do
		---@type Province
		local pro = pr
		local support = 5
		if DATA.tile_get_is_land(pro.center) then
			for _, tile_id in pairs(pro.tiles) do
				local jan_rain, _, jul_rain, _ = tile.get_climate_data(tile_id)
				support = support + (jan_rain + jul_rain) * 0.5 / 2 / 30
			end
		end
		pro.hydration = support

		assert(pro.hydration > 0)
	end
end

return hydr
