local retrieve_use_case = require "game.raws.raws-utils".trade_good_use_case


---@class (exact) PortraitSet
---@field fallback PortraitDescription
---@field child PortraitDescription?
---@field teen PortraitDescription?
---@field adult PortraitDescription?
---@field middle PortraitDescription?
---@field elder PortraitDescription?

---@class (exact) PortraitDescription
---@field folder string
---@field layers string[]
---@field layers_groups string[][]



local Race = {}
Race.__index = Race


function Race:new(o)
	---@type Race
	local r = {}

	--- default values
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
	r.minimum_comfortable_elevation = 0
	r.fecundity = 1
	r.spotting = 1
	r.visibility = 1
	r.female_body_size = 1
	r.female_needs = {}
	r.female_infrastructure_needs = 1
	r.male_body_size = 1
	r.male_needs = {}
	r.male_infrastructure_needs = 1
	r.carrying_capacity_weight = 1

	r.female_efficiency = {
		[JOBTYPE.FARMER] = 1,
		[JOBTYPE.ARTISAN] = 1,
		[JOBTYPE.CLERK] = 1,
		[JOBTYPE.LABOURER] = 1,
		[JOBTYPE.WARRIOR] = 1,
		[JOBTYPE.HAULING] = 1,
		[JOBTYPE.FORAGER] = 1,
		[JOBTYPE.HUNTING] = 1
	}

	local female_needs = {
		{need = NEED.FOOD, use_case = WATER_USE_CASE, required = 1},
		{need = NEED.FOOD, use_case = CALORIES_USE_CASE, required = 1}, -- 1000
		{need = NEED.FOOD, use_case = retrieve_use_case('fruit'), required = 0.5}, --- 500
		{need = NEED.FOOD, use_case = retrieve_use_case('meat'), required = 0.25}, --- 500
		{need = NEED.CLOTHING, use_case = retrieve_use_case('clothes'), required = 1},
		{need = NEED.FURNITURE, use_case = retrieve_use_case('furniture'), required = 1},
		{need = NEED.HEALTHCARE, use_case = retrieve_use_case('healthcare'), required = 1},
		{need = NEED.LUXURY, use_case = retrieve_use_case('liquors'), required = 1}
	}

	r.male_efficiency = {
		[JOBTYPE.FARMER] = 1,
		[JOBTYPE.ARTISAN] = 1,
		[JOBTYPE.CLERK] = 1,
		[JOBTYPE.LABOURER] = 1,
		[JOBTYPE.WARRIOR] = 1,
		[JOBTYPE.HAULING] = 1,
		[JOBTYPE.FORAGER] = 1,
		[JOBTYPE.HUNTING] = 1
	}

	r.requires_large_river = false
	r.requires_large_forest = false

	for k, v in pairs(o) do
		r[k] = v
	end

	setmetatable(r, Race)
	if RAWS_MANAGER.races_by_name[r.name] ~= nil then
		local msg = "Failed to load a race (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end

	-- assert that needs are valid
	local amount = 0
	for i = 1, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
		assert(r.male_needs[i].need == r.female_needs[i].need)
		assert(r.male_needs[i].use_case == r.female_needs[i].use_case)
		if r.male_needs[i].need then
			amount = amount + 1
		end
	end

	--- shift index by one to make consistent with
	for i = 0, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
		assert(r.male_needs[i].need == r.female_needs[i].need)
		assert(r.male_needs[i].use_case == r.female_needs[i].use_case)
		if r.male_needs[i].need then
			amount = amount + 1
		end
	end

	RAWS_MANAGER.races_by_name[r.name] = r
	return r
end

return Race
