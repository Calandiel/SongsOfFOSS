local dbm = require "game.economy.diet-breadth-model"

local car = {}

---Returns carrying capacity for humans, for a tile
---@param tile Tile
---@return number
function car.get_tile_carrying_capacity(tile)
	local plant_production, _, marine_production, animal_production, mushroom_production = dbm.net_primary_production(tile)
	return plant_production + marine_production + animal_production + mushroom_production
end

function car.calculate()
	for _, province in pairs(WORLD.provinces) do
		if province.center.is_land then
			require "game.economy.diet-breadth-model".foragers_targets(province)
		else
			province.foragers_limit = 0
		end
	end
end

return car
