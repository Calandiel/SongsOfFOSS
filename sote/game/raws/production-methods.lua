local JOBTYPE = require "game.raws.job_types"
local dbm = require "game.economy.diet-breadth-model"

---@class (exact) ProductionMethod
---@field __index ProductionMethod
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field jobs table<Job, number>
---@field job_weight number
---@field job_type JOBTYPE
---@field total_jobs fun(self:ProductionMethod):number
---@field inputs table<TradeGoodUseCaseReference, number>
---@field outputs table<TradeGoodReference, number>
---@field new fun(self:ProductionMethod, o:ProductionMethod):ProductionMethod
---@field foraging boolean If true, counts towards the forager limit
---@field nature_yield_dependence number How much does the local flora and fauna impact this buildings yield? Defaults to 0
---@field forest_dependence number Set to 1 if building consumes local forests
---@field crop boolean If true, the building will periodically change its yield for a season.
---@field temperature_ideal_min number
---@field temperature_ideal_max number
---@field temperature_extreme_min number
---@field temperature_extreme_max number
---@field rainfall_ideal_min number
---@field rainfall_ideal_max number
---@field rainfall_extreme_min number
---@field rainfall_extreme_max number
---@field clay_ideal_min number
---@field clay_ideal_max number
---@field clay_extreme_min number
---@field clay_extreme_max number
---@field get_efficiency fun(self:ProductionMethod, province:Province):number Returns a fraction describing efficiency on a given province (used for crops and gathering and such)

---@class ProductionMethod
local ProductionMethod = {}
ProductionMethod.__index = ProductionMethod
---Creates a new production method
---@param o ProductionMethod
---@return ProductionMethod
function ProductionMethod:new(o)
	print("ProductionMethod: " .. o.name)
	---@type ProductionMethod
	local r = {}

	r.name = "<production method>"
	r.icon = 'uncertainty.png'
	r.description = "<production method description>"
	r.r = 0
	r.g = 0
	r.b = 0
	r.jobs = {}
	r.inputs = {}
	r.outputs = {}
	r.job_weight = 1
	r.foraging = false
	r.nature_yield_dependence = 0
	r.forest_dependence = 0
	r.crop = false
	r.temperature_ideal_min = 10
	r.temperature_ideal_max = 30
	r.temperature_extreme_min = 0
	r.temperature_extreme_max = 50
	r.rainfall_ideal_min = 50
	r.rainfall_ideal_max = 100
	r.rainfall_extreme_min = 5
	r.rainfall_extreme_max = 350
	r.clay_ideal_min = 0
	r.clay_ideal_max = 1
	r.clay_extreme_min = 0
	r.clay_extreme_max = 1
	r.job_type = JOBTYPE.FORAGER



	for k, v in pairs(o) do
		r[k] = v
	end
	setmetatable(r, ProductionMethod)
	if RAWS_MANAGER.production_methods_by_name[r.name] ~= nil then
		local msg = "Failed to load a production method (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end
	RAWS_MANAGER.production_methods_by_name[r.name] = r
	return r
end

---@return number
function ProductionMethod:total_jobs()
	local rett = 0
	for _, amount in pairs(self.jobs) do
		rett = rett + amount
	end
	return rett
end

---@param province Province
---@return number
function ProductionMethod:get_efficiency(province)
	-- Return 0 efficiency for water provinces
	if not province.center.is_land then
		return 0
	end

	local total_efficiency = 0
	local tile_count = 0
	for _, tile in pairs(province.tiles) do
		tile_count = tile_count + 1
		local crop_yield = 1
		if self.crop then
			local jan_rain, jan_temp, jul_rain, jul_temp = tile:get_climate_data()
			local t = (jan_temp + jul_temp) / 2
			local r = (jan_rain + jul_rain) / 2
			if r > self.rainfall_ideal_min and r < self.rainfall_ideal_max then
				-- Ideal conditions for growing this plant!
			elseif r < self.rainfall_ideal_min then
				local d = (r - self.rainfall_extreme_min) / (self.rainfall_ideal_min - self.rainfall_extreme_min)
				crop_yield = crop_yield * math.max(0, d)
			elseif r > self.rainfall_ideal_max then
				local d = (r - self.rainfall_ideal_max) /
					(self.rainfall_extreme_max - self.rainfall_ideal_max)
				d = 1 - d
				crop_yield = crop_yield * math.max(0, d)
			end
			if t > self.temperature_ideal_min and r < self.temperature_ideal_max then
				-- Ideal conditions for growing this plant!
			elseif t < self.temperature_ideal_min then
				local d = (t - self.temperature_extreme_min) /
					(self.temperature_ideal_min - self.temperature_extreme_min)
				crop_yield = crop_yield * math.max(0, d)
			elseif t > self.temperature_ideal_max then
				local d = (t - self.temperature_ideal_max) /
					(self.temperature_extreme_max - self.temperature_ideal_max)
				d = 1 - d
				crop_yield = crop_yield * math.max(0, d)
			end
		end
		local soil_efficiency = 1
		if self.clay_ideal_min > 0 or self.clay_ideal_max < 1 then
			local clay = tile.clay
			if clay > self.clay_ideal_min and clay < self.clay_ideal_max then
				-- Ideal conditions!
			elseif clay < self.clay_ideal_min then
				local d = (clay - self.clay_extreme_min) / (self.clay_ideal_min - self.clay_extreme_min)
				soil_efficiency = soil_efficiency * math.max(0, d)
			elseif clay > self.clay_ideal_max then
				local d = (clay - self.clay_ideal_max) /
					(self.clay_extreme_max - self.clay_ideal_max)
				d = 1 - d
				soil_efficiency = soil_efficiency * math.max(0, d)
			end
		end
		total_efficiency = total_efficiency + crop_yield * soil_efficiency
	end
	local nature_yield = 1
	if self.forest_dependence > 0 then
		nature_yield = (province.foragers_targets[dbm.ForageResource.Wood]) * self.forest_dependence
	end
	if self.nature_yield_dependence > 0 then
		nature_yield = math.max(1, province.foragers_limit / require "engine.table".size(province.tiles)) * self.nature_yield_dependence
	end
	return total_efficiency * nature_yield / tile_count
end

return ProductionMethod
