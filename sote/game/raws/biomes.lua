local col = require "game.color"

local biome_index = 1

local Biome = {}
Biome.__index = Biome
---@param o biome_id_data_blob
---@return biome_id
function Biome:new(o)
	local MIN = -99999999
	local MAX = -MIN
	local r = DATA.fatten_biome(biome_index)
	r.name = "biome"
	r.r = 0
	r.g = 0
	r.b = 0
	r.aquatic = false
	r.marsh = false
	r.icy = false
	r.minimum_slope = MIN
	r.maximum_slope = MAX
	r.minimum_elevation = MIN
	r.maximum_elevation = MAX
	r.minimum_temperature = MIN
	r.maximum_temperature = MAX
	r.minimum_summer_temperature = MIN
	r.maximum_summer_temperature = MAX
	r.minimum_winter_temperature = MIN
	r.maximum_winter_temperature = MAX
	r.minimum_rain = MIN
	r.maximum_rain = MAX
	r.minimum_available_water = MIN
	r.maximum_available_water = MAX
	r.minimum_trees = MIN
	r.maximum_trees = MAX
	r.minimum_grass = MIN
	r.maximum_grass = MAX
	r.minimum_shrubs = MIN
	r.maximum_shrubs = MAX
	r.minimum_conifer_fraction = MIN
	r.maximum_conifer_fraction = MAX
	r.minimum_dead_land = MIN
	r.maximum_dead_land = MAX
	r.minimum_soil_depth = MIN
	r.maximum_soil_depth = MAX
	r.minimum_soil_richness = MIN
	r.maximum_soil_richness = MAX
	r.minimum_sand = MIN
	r.maximum_sand = MAX
	r.minimum_clay = MIN
	r.maximum_clay = MAX
	r.minimum_silt = MIN
	r.maximum_silt = MAX

	for k, v in pairs(o) do
		r[k] = v
	end

	if RAWS_MANAGER.biomes_by_name[r.name] ~= nil then
		local msg = "Failed to load a biome (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end

	RAWS_MANAGER.biomes_by_name[r.name] = r.id

	biome_index = biome_index + 1
	return r
end

return Biome
