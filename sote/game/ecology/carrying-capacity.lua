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
	DATA.for_each_province(function (province_id)
		if DATA.tile_get_is_land(DATA.province_get_center(province_id)) then
			dbm.update_foraging_targets(province_id)
			-- local amounts = dbm.total_foraging_amounts(province_id)
			-- dbm.set_foraging_targets(province_id, amounts)
		else
			DATA.province_set_foragers_limit(province_id, 0)
		end
	end)
end

return car
