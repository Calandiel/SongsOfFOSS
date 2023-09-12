---@class Race
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field carrying_capacity_weight number
---@field fecundity number
---@field spotting number How good is this unit at scouting
---@field visibility number How visible is this unit in battles
---@field males_per_hundred_females number
---@field child_age number
---@field teen_age number
---@field adult_age number
---@field middle_age number
---@field elder_age number
---@field max_age number
---@field minimum_comfortable_temperature number
---@field minimum_absolute_temperature number
---@field female_body_size number
---@field female_worker_efficiency number
---@field female_artisan_efficiency number
---@field female_clerk_efficiency number
---@field female_ruler_efficiency number
---@field female_water_needs number
---@field female_food_needs number
---@field female_grains_needs number
---@field female_fruit_needs number
---@field female_meat_needs number
---@field female_clothing_needs number
---@field female_infrastructure_needs number
---@field male_body_size number
---@field male_worker_efficiency number
---@field male_artisan_efficiency number
---@field male_clerk_efficiency number
---@field male_ruler_efficiency number
---@field male_water_needs number
---@field male_food_needs number
---@field male_grains_needs number
---@field male_fruit_needs number
---@field male_meat_needs number
---@field male_clothing_needs number
---@field male_infrastructure_needs number
---@field requires_large_river boolean

---@class Race
local Race = {}
Race.__index = Race
---@param o table
---@return Race
function Race:new(o)
	---@type Race
	local r = {}

	r.name = "<race>"
	r.icon = "uncertainty.png"
	r.description = "<race description>"
	r.r = love.math.random()
	r.g = love.math.random()
	r.b = love.math.random()
	r.males_per_hundred_females = 104
	r.child_age = 3
	r.teen_age = 12
	r.adult_age = 16
	r.middle_age = 40
	r.elder_age = 65
	r.max_age = 85
	r.minimum_comfortable_temperature = 5
	r.minimum_absolute_temperature = -10
	r.fecundity = 1
	r.spotting = 1
	r.visibility = 1
	r.female_body_size = 1
	r.female_worker_efficiency = 1
	r.female_artisan_efficiency = 1
	r.female_clerk_efficiency = 1
	r.female_ruler_efficiency = 1
	r.female_water_needs = 1
	r.female_food_needs = 1
	r.female_grains_needs = 1
	r.female_fruit_needs = 1
	r.female_meat_needs = 1
	r.female_clothing_needs = 0.1
	r.female_infrastructure_needs = 1
	r.male_body_size = 1
	r.male_worker_efficiency = 1
	r.male_artisan_efficiency = 1
	r.male_clerk_efficiency = 1
	r.male_ruler_efficiency = 1
	r.male_water_needs = 1
	r.male_food_needs = 1
	r.male_grains_needs = 1
	r.male_fruit_needs = 1
	r.male_meat_needs = 1
	r.male_clothing_needs = 0.1
	r.male_infrastructure_needs = 1
	r.carrying_capacity_weight = 1

	r.requires_large_river = false

	for k, v in pairs(o) do
		r[k] = v
	end
	setmetatable(r, Race)
	if RAWS_MANAGER.races_by_name[r.name] ~= nil then
		local msg = "Failed to load a race (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end
	RAWS_MANAGER.races_by_name[r.name] = r
	return r
end

return Race
