local dbm = require "game.economy.diet-breadth-model"

local car = {}

---Returns carrying capacity for humans, for a tile
---@param tile Tile
---@return number
function car.get_tile_carrying_capacity(tile)
	local plant_production, _, shellfish_production, fish_production, animal_production, mushroom_production = dbm.net_primary_production(tile)
	return plant_production + shellfish_production + fish_production + animal_production + mushroom_production
end

function car.calculate()
	local tabb = require "engine.table"
	local min_et, max_et = 100, -100
	local min_pt, max_pt = 100, -100
	local min_mt, max_mt = 100, -100
	local min_tw, max_tw = 100, -100
	local min_tf, max_tf = 100, -100
	local min_pp, min_cc, max_pp, max_cc  = 100, 100, -100, -100
	local mean_et, mean_pt, mean_mt, mean_tw, mean_tf, mean_pp, mean_cc, count = 0, 0, 0, 0, 0, 0, 0, 0
	for _, province in pairs(WORLD.provinces) do
		if province.center.is_land then
--[[
			local cc = province.foragers_limit
			if cc < min_cc then
				min_cc = cc
			elseif cc > max_cc then
				max_cc = cc
			end
			mean_cc = mean_cc + cc
			mean_et = mean_et + tabb.accumulate(province.tiles, 0, function (a, k, v)
				local  _, warmest, _, coldest = v:get_climate_data()
				if coldest > warmest then
					warmest, coldest = coldest, warmest
				end
				local effective_temperature = (18 * warmest - 10 * coldest) / (warmest - coldest + 8)
				if effective_temperature < min_et then
					min_et = effective_temperature
				elseif effective_temperature > max_et then
					max_et = effective_temperature
				end
				local plant_temperature_weighting =  1 / (1 + math.exp(-0.2 * (effective_temperature - 10)))
				mean_pt = mean_pt + plant_temperature_weighting
				if plant_temperature_weighting < min_pt then
					min_pt = plant_temperature_weighting
				elseif plant_temperature_weighting > max_pt then
					max_pt = plant_temperature_weighting
				end
				local marine_temperature_weighting =  1 + effective_temperature / (effective_temperature - 70 )
				mean_mt = mean_mt + marine_temperature_weighting
				if marine_temperature_weighting < min_mt then
					min_mt = marine_temperature_weighting
				elseif marine_temperature_weighting > max_mt then
					max_mt = marine_temperature_weighting
				end
				local terrestrial_temperature_weight =  1.1 - 1 / (1 + math.exp(-0.1 * effective_temperature))
				mean_tw = mean_tw + terrestrial_temperature_weight
				if terrestrial_temperature_weight < min_tw then
					min_tw = terrestrial_temperature_weight
				elseif terrestrial_temperature_weight > max_tw then
					max_tw = terrestrial_temperature_weight
				end
				local flora_cover = (v.broadleaf + v.conifer) / 1
				local terrestrial_flora_weight =  0.25 + flora_cover / (flora_cover + 1)
				mean_tf = mean_tf + terrestrial_flora_weight
				if terrestrial_flora_weight < min_tf then
					min_tf = terrestrial_flora_weight
				elseif terrestrial_flora_weight > max_tf then
					max_tf = terrestrial_flora_weight
				end
				local pp, _, shellfish, fish, animal, mushroom = dbm.net_primary_production(v)
				pp = pp + shellfish + fish + animal + mushroom
				if pp < min_pp then
					min_pp = pp
				elseif pp > max_pp then
					max_pp = pp
				end
				mean_pp = mean_pp + pp
				count = count + 1
				return a + effective_temperature
			end)
]]
			require "game.economy.diet-breadth-model".foragable_targets(province)
		else
			province.foragers_limit = 0
		end
	end
	mean_cc = mean_cc / tabb.size(tabb.filter(WORLD.provinces, function (a)
		return a.center.is_land
	end))
	mean_pp = mean_pp / count
	mean_et = mean_et / count
	mean_pt = mean_pt / count
	mean_mt = mean_mt / count
	mean_tw = mean_tw / count
	mean_tf = mean_tf / count
	print("MAX CC: " .. max_cc .. " MIN CC: " .. min_cc .. " MEAN CC: " .. mean_cc)
	print("MAX PP: " .. max_pp .. " MIN PP: " .. min_pp .. " MEAN PP: " .. mean_pp)
	print("MAX ET: " .. max_et .. " MIN ET: " .. min_et .. " MEAN ET: " .. mean_et)
	print("MAX PT: " .. max_pt .. " MIN PT: " .. min_pt .. " MEAN PT: " .. mean_pt)
	print("MAX MT: " .. max_mt .. " MIN MT: " .. min_mt .. " MEAN MT: " .. mean_mt)
	print("MAX TW: " .. max_tw .. " MIN TW: " .. min_tw .. " MEAN TW: " .. mean_tw)
	print("MAX TF: " .. max_tf .. " MIN TF: " .. min_tf .. " MEAN TF: " .. mean_tf)
end

return car
