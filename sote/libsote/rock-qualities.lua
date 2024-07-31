local rq = {}

local rock_characteristics = {}

function rock_characteristics:new(t)
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj.sand = 0
	obj.silt = 0
	obj.clay = 0
	obj.mass_conversion = 0
	obj.weathering_rate = 0
	obj.mineral_nutrients = 0

	for k, v in pairs(t) do
		obj[k] = v
	end

	return obj
end

local rock_types = require "libsote.rock-type".TYPES

local rock_characteristics_by_rock_type = {}

rock_characteristics_by_rock_type[rock_types.limestone] = rock_characteristics:new {
	sand = 45,
	silt = 30,
	clay = 25,
	mass_conversion = 25,
	weathering_rate = 1,
	mineral_nutrients = 40
}

rock_characteristics_by_rock_type[rock_types.mudstone] = rock_characteristics:new {
	sand = 20,
	silt = 10,
	clay = 70,
	mass_conversion = 100,
	weathering_rate = 1,
	mineral_nutrients = 60
}

rock_characteristics_by_rock_type[rock_types.siltstone] = rock_characteristics:new {
	sand = 30,
	silt = 45,
	clay = 25,
	mass_conversion = 100,
	weathering_rate = 1,
	mineral_nutrients = 30
}

rock_characteristics_by_rock_type[rock_types.sandstone] = rock_characteristics:new {
	sand = 75,
	silt = 15,
	clay = 10,
	mass_conversion = 100,
	weathering_rate = 0.7,
	mineral_nutrients = 40
}

rock_characteristics_by_rock_type[rock_types.slate] = rock_characteristics:new {
	sand = 40,
	silt = 5,
	clay = 55,
	mass_conversion = 100,
	weathering_rate = 0.7,
	mineral_nutrients = 75
}

rock_characteristics_by_rock_type[rock_types.marble] = rock_characteristics:new {
	sand = 40,
	silt = 30,
	clay = 30,
	mass_conversion = 20,
	weathering_rate = 1,
	mineral_nutrients = 50
}

rock_characteristics_by_rock_type[rock_types.acid_plutonics] = rock_characteristics:new {
	sand = 70,
	silt = 10,
	clay = 20,
	mass_conversion = 100,
	weathering_rate = 0.5,
	mineral_nutrients = 80
}

rock_characteristics_by_rock_type[rock_types.mixed_plutonics] = rock_characteristics:new {
	sand = 65,
	silt = 0,
	clay = 35,
	mass_conversion = 100,
	weathering_rate = 0.75,
	mineral_nutrients = 120
}

rock_characteristics_by_rock_type[rock_types.basic_plutonics] = rock_characteristics:new {
	sand = 25,
	silt = 0,
	clay = 75,
	mass_conversion = 100,
	weathering_rate = 0.8,
	mineral_nutrients = 150
}

rock_characteristics_by_rock_type[rock_types.acid_volcanics] = rock_characteristics:new {
	sand = 40,
	silt = 30,
	clay = 30,
	mass_conversion = 100,
	weathering_rate = 0.8,
	mineral_nutrients = 80
}

rock_characteristics_by_rock_type[rock_types.mixed_volcanics] = rock_characteristics:new {
	sand = 20,
	silt = 45,
	clay = 35,
	mass_conversion = 100,
	weathering_rate = 0.9,
	mineral_nutrients = 110
}

rock_characteristics_by_rock_type[rock_types.basic_volcanics] = rock_characteristics:new {
	sand = 10,
	silt = 45,
	clay = 45,
	mass_conversion = 100,
	weathering_rate = 1,
	mineral_nutrients = 150
}

function rq.get_characteristics_for_rock(rock_type, def_sand, def_silt, def_clay, def_mineral_nutrients, def_mass_conversion, def_weathering_rate)
	local characteristics = rock_characteristics_by_rock_type[rock_type]
	if characteristics == nil then
		return def_sand, def_silt, def_clay, def_mineral_nutrients, def_mass_conversion, def_weathering_rate
	end

	return characteristics.sand, characteristics.silt, characteristics.clay, characteristics.mineral_nutrients, characteristics.mass_conversion, characteristics.weathering_rate
end

return rq