local dbm = require "game.economy.diet-breadth-model"

local car = {}

---Returns carrying capacity for humans, for a tile
---@param tile Tile
---@return number
function car.get_tile_carrying_capacity(tile)
	local primary_production, marine_production _, _ = dbm.total_production(tile)
	return primary_production + marine_production
end

function car.calculate()
	for _, province in pairs(WORLD.provinces) do
		if province.center.is_land then
			local amounts = dbm.total_foraging_amounts(province)
			require "game.economy.diet-breadth-model".set_foraging_targets(province, amounts)
		else
			province.foragers_limit = 0
		end
	end
end

return car
