local ut = require "game.map-modes.utils"
local province_utils = require "game.entities.province".Province
local eco = {}

function eco.local_income()
	local max_income = 0.01
	local avg = 0
	local count = 0
	DATA.for_each_province(function (province)
		local fat = DATA.fatten_province(province)
		if DATA.tile_get_is_land(fat.center) then
			max_income = math.max(max_income, fat.local_income)
			avg = avg + fat.local_income
			count = count + 1
		end
	end)
	avg = avg / count
	ut.provincial_hue_map_mode(function(prov)
		return math.max(0, DATA.province_get_local_income(prov)) / (avg * 5.0)
	end)
end

function eco.realm_income()
	ut.provincial_hue_map_mode(function(prov)
		local realm = province_utils.realm(prov)
		if realm ~= INVALID_ID then
			return math.max(0, DATA.realm_get_budget_change(realm)) / 10
		else
			return 0
		end
	end)
end

return eco
