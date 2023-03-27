---@class Biome
---@field name string
---@field r number
---@field g number
---@field b number
---@field aquatic boolean
---@field marsh boolean
---@field icy boolean
---@field minimum_slope number m
---@field maximum_slope number m
---@field minimum_elevation number m
---@field maximum_elevation number m
---@field minimum_temperature number C
---@field maximum_temperature number C
---@field minimum_summer_temperature number C
---@field maximum_summer_temperature number C
---@field minimum_winter_temperature number C
---@field maximum_winter_temperature number C
---@field maximum_rain number mm
---@field minimum_rain number mm
---@field minimum_available_water number abstract, adjusted for permeability
---@field maximum_available_water number abstract, adjusted for permeability
---@field minimum_trees number %
---@field maximum_trees number %
---@field minimum_grass number %
---@field maximum_grass number %
---@field minimum_shrubs number %
---@field maximum_shrubs number %
---@field minimum_conifer_fraction number %
---@field maximum_conifer_fraction number %
---@field minimum_dead_land number %
---@field maximum_dead_land number %
---@field minimum_soil_depth number m
---@field maximum_soil_depth number m
---@field minimum_soil_richness number %
---@field maximum_soil_richness number %
---@field minimum_sand number %
---@field maximum_sand number %
---@field minimum_clay number %
---@field maximum_clay number %
---@field minimum_silt number %
---@field maximum_silt number %

local col = require "game.color"

local Biome = {}
Biome.__index = Biome
---@param o table
---@return Biome
function Biome:new(o)
	local MIN = -99999999
	local MAX = -MIN
	local r = {}
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
	setmetatable(r, Biome)

	if WORLD.biomes_by_name[r.name] ~= nil then
		local msg = "Failed to load a biome (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end
	WORLD.biomes_by_name[r.name] = r

	return r
end

return Biome
