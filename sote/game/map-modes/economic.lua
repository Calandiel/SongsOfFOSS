local ut = require "game.map-modes.utils"
local eco = {}

function eco.local_income()
	local max_income = 0.01
	local avg = 0
	local count = 0
	for _, prov in pairs(WORLD.provinces) do
		if prov.center.is_land then
			max_income = math.max(max_income, prov.local_income)
			avg = avg + prov.local_income
			count = count + 1
		end
	end
	avg = avg / count
	ut.simple_hue_map_mode(function(tile)
		---@type Tile
		local t = tile
		return math.max(0, t.province.local_income) / (avg * 5.0)
	end)
end

function eco.realm_income()
	ut.simple_hue_map_mode(function(tile)
		---@type Tile
		local t = tile
		if t.province.realm then
			return math.max(0, t.province.realm.budget.change) / 10
		else
			return 0
		end
	end)
end

return eco
