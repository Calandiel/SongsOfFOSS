---@class ProductionMethod
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field jobs table<Job, number>
---@field total_jobs fun():number
---@field inputs table<TradeGood, number>
---@field outputs table<TradeGood, number>
---@field new fun(self:ProductionMethod, o:ProductionMethod):ProductionMethod
---@field self_sourcing_fraction number Amount of time spent self sourcing materials in case of a material shortage!
---@field foraging boolean If true, counts towards the forager limit
---@field nature_yield_dependence number How much does the local flora and fauna impact this buildings yield? Defaults to 0
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
---@field get_efficiency fun(self:ProductionMethod, tile:Tile):number Returns a fraction describing efficiency on a given tile (used for crops and gathering and such)

---@type ProductionMethod
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
	r.self_sourcing_fraction = 0
	r.foraging = false
	r.nature_yield_dependence = 0
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



	for k, v in pairs(o) do
		r[k] = v
	end
	setmetatable(r, ProductionMethod)
	if WORLD.production_methods_by_name[r.name] ~= nil then
		local msg = "Failed to load a production method (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end
	WORLD.production_methods_by_name[r.name] = r
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

---@param tile Tile
---@return number
function ProductionMethod:get_efficiency(tile)
	local nature_yield = 1
	local crop_yield = 1
	if self.nature_yield_dependence > 0 then
		nature_yield = tile.broadleaf * 1.5 + tile.conifer * 1.2 + tile.shrub * 0.9 + tile.grass * 1
	end
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
			local d = (t - self.temperature_extreme_min) / (self.temperature_ideal_min - self.temperature_extreme_min)
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

	return nature_yield * crop_yield * soil_efficiency
end

return ProductionMethod
