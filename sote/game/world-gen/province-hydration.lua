local tile = require "game.entities.tile"
local hydr = {}

function hydr.run()
	-- Recalculate hydration!
	DATA.for_each_province(function (province_id)
		local fat = DATA.fatten_province(province_id)
		local support = 5
		if DATA.tile_get_is_land(fat.center) then
			for _, tile_membership_id in pairs(DATA.get_tile_province_membership_from_province(province_id)) do
				local tile_id = DATA.tile_province_membership_get_tile(tile_membership_id)
				local jan_rain, _, jul_rain, _ = tile.get_climate_data(tile_id)
				support = support + (jan_rain + jul_rain) * 0.5 / 2 / 30
			end
		end
		fat.hydration = support

		assert(fat.hydration > 0)
	end)
end

return hydr
