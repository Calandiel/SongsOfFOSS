local car = {}

local dbm = require "game.economy.diet-breadth-model"

---Returns carrying capacity for humans, for a tile
---@param tile_id tile_id
---@return number
function car.get_tile_carrying_capacity(tile_id)
	local primary_production, marine_production, _, _ = require "game.economy.diet-breadth-model".total_production(tile_id)
	local cc = primary_production + marine_production
	return cc
end

function car.calculate()
	for _, province in pairs(WORLD.provinces) do
		if DATA.tile_get_is_land(province.center) then
			local amounts = dbm.total_foraging_amounts(province)
			dbm.set_foraging_targets(province, amounts)
		else
			province.foragers_limit = 0
		end
	end
end

return car
