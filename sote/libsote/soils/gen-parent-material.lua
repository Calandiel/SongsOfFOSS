local gpm = {}

-- NOTE 2024.07.03: The comments are close to the original, but may have been edited for clarity and relevance to the current state.
-- Any existing humor belongs to the original author :-) (probably Demian?)
-- In order to distinguish between the original comments and the new ones, the original ones are marked with "--*"

local rock_types = require "libsote.rock-type".TYPES
local rock_qualities = require "libsote.rock-qualities"
local open_issues = require "libsote.soils.open-issues"

-- local logger = require("libsote.debug-loggers").get_parent_material_logger("d:/temp")

--* Weathering Defines
local base_weathering              =   1 --* Guaranteed amount of weathering in a tile. Generally quite low
local base_ice_wedging             =   3 --* The base amount of Ice Wedging that occurs if we meet the 0 degree threshold
local global_ice_wedging_intensity =  15 --* Higher value reduces intensity
local biological_tuning_factor     = 200 --* higher value reduces intensity
local weathered_volume_tuner       =  10

--* The extent to which freezing and thawing breaks up rocks
local function calculate_ice_wedging_weathering(temp_jan, temp_jul)
	if (temp_jan < 0 and temp_jul > 0) or (temp_jan > 0 and temp_jul < 0) then
		local wedging_baseline = math.min(math.abs(temp_jan), math.abs(temp_jul))
		return (base_ice_wedging + wedging_baseline) / global_ice_wedging_intensity
	end
	return 0
end

--* The extent to which flowing water influences weathering rate*
local function calculate_waterflow_weathering(ti, total_rainfall, world)
	local base = open_issues.waterflow_weathering_base(world.water_movement[ti])
	return base + (total_rainfall / 100)
end

--* The extent to which roots, Earth Worm stomach acid, etc influences weathering rate*
local function calculate_biological_weathering(total_rainfall)
	local bio_abundance_multiplier = 1 + (total_rainfall / biological_tuning_factor)
	return bio_abundance_multiplier
end

local function calculate_slope_weathering(ti, world)
	local max_elevation_drop = 0
	world:for_each_neighbor(ti, function(nti)
		max_elevation_drop = math.max(max_elevation_drop, world.elevation[ti] - world.elevation[nti])
	end)
	return math.max(math.pow((max_elevation_drop / 100), 0.5), 0.75)
end

local function apply_bias(current_percentage, bias, other1_percentage, other2_percentage)
	local potential_increase = math.min(100 - current_percentage, 20)
	local current_disposed = current_percentage + (potential_increase - (potential_increase / bias))
	local amount_to_redistribute = current_disposed - current_percentage

	local total_other_percentage = other1_percentage + other2_percentage
	local other1_disposed = other1_percentage - (amount_to_redistribute * (other1_percentage / total_other_percentage))
	local other2_disposed = other2_percentage - (amount_to_redistribute * (other2_percentage / total_other_percentage))

	return current_disposed, other1_disposed, other2_disposed
end

local function process_tile(ti, world)
	if not world.is_land[ti] then return end

	local temp_jan = world.jan_temperature[ti]
	local temp_jul = world.jul_temperature[ti]
	local total_rainfall = world.jan_rainfall[ti] + world.jul_rainfall[ti]
	local rock_type = world.rock_type[ti]
	local is_volcanic_rock = rock_type == rock_types.acid_volcanics or rock_type == rock_types.mixed_volcanics or rock_type == rock_types.basic_volcanics

	--* Prep pertinent variables
	local ice_wedging_weathering = calculate_ice_wedging_weathering(temp_jan, temp_jul)
	local waterflow_weathering = calculate_waterflow_weathering(ti, total_rainfall, world)
	local biological_weathering = calculate_biological_weathering(total_rainfall)
	local slope_weathering = calculate_slope_weathering(ti, world)

	local weathering_multiplier = base_weathering + ice_wedging_weathering + waterflow_weathering + biological_weathering --* The intensity of the weathering process
	local base_weathered_rock = weathering_multiplier * weathered_volume_tuner

	local sand_disposed, silt_disposed, clay_disposed, mineral_richness, rock_mass_conversion, rock_weathering_rate = rock_qualities.get_characteristics_for_rock(rock_type, 34, 33, 33, 0, 1, 1)
	if not is_volcanic_rock then mineral_richness = mineral_richness * slope_weathering end

	local final_weathered_rock = base_weathered_rock * rock_mass_conversion * rock_weathering_rate

	--* Apply bias
	local sand_clay_bias = open_issues.sand_clay_bias(world, ti)
	local silt_multiplier = world.tmp_float_3[ti]

	if sand_clay_bias > 0 then --* If greater than 0 it means we are sand disposed
		sand_disposed, silt_disposed, clay_disposed = apply_bias(sand_disposed, sand_clay_bias, silt_disposed, clay_disposed)
	else --* Otherwise it is clay disposed. If clay disposed we need to set the value to positive temporarily and multiply into our result
		clay_disposed, silt_disposed, sand_disposed = apply_bias(clay_disposed, -sand_clay_bias, silt_disposed, sand_disposed)
	end
	silt_disposed, clay_disposed, sand_disposed = apply_bias(silt_disposed, silt_multiplier, clay_disposed, sand_disposed)

	world.sand[ti] = world.sand[ti] + ((sand_disposed / 100) * final_weathered_rock)
	world.silt[ti] = world.silt[ti] + ((silt_disposed / 100) * final_weathered_rock)
	world.clay[ti] = world.clay[ti] + ((clay_disposed / 100) * final_weathered_rock)
	world.mineral_richness[ti] = world.mineral_richness[ti] + math.floor((mineral_richness * final_weathered_rock) / 100)

	--* We need to have a soil depth factor multiplied into the equation for mineral nutrients.
end

--* Okay so... Mineral need to have a quantity relative to the total mass of the soil. So theoretically it should be represented as a percentage. Initially
--* when we first weather away the parent material it can be expressed as 0 - 100 percent. Basalts will be super high where as quartz will be super low...
--* Then the mineral nutrient value get transported with the sediment load... Let's see if we can get this first part done correctly first!

function gpm.run(world)
	world:for_each_tile(function(ti)
		process_tile(ti, world)
	end)

	-- commented out in original code
	--* Iterate through all pertinent tiles and nuke silt where relevant

	-- commented out in original code
	--* Quick mineral leeching which will add or subtract base mineral value of soil
end

--* Plan for soil creation ///
--* ---First, we create some local resolution biases in generation of silt, sand, clay. Then we will evaluate each tile, apply the biases, and then based on the bias and
--* bedrock type we will produce a specific quantity of sand, silt, and clay. We'll need a number of factors influencing this production. Some silt will be produced by glacial action,
--* either historic or current, some production of sand, silt, and clay will be the result of alluvial weathering, some silt will be produced as a result of the decomposition,
--* of organics into 2 micrometer humus particles, and some sand, silt, and clay will result from "other" weathering causes (seasonal temperature changes, etc).
--* ---Once we have this "mass" of material, we will then transport it either by wind or water. In effect, some tiles will have material which is mostly native, aka,
--* the material was produced by local bedrock weathering. However, some locations will be dominated by subsidies of material, such as Leoss soils and alluvial soils
--* along river banks. Some locations will be a mix.
--* We then either create 3 byte sized variables for a tile's soil texture (silt, sand and clay) or we simply create an enumeration for the 16 or so soil texture categories.
--* 


--* Immediate plan... for silt production ///
--* We can generate water flow silt first... but its tricky.
--* Select tiles which were glaciated but current are not. The colder they are, the less silt they should end up getting cause they were "unglaciated" for less time.
--* Generate silt to be "drained". Then we drain it. We don't need to be concerned at this point about sediment load capacity because we're dealing with glacial melt.
--* So just run a trunkated version of our rainfall algorithm, with no repeats. Terminate as soon as silt reaches any kind of waterbody. Then add that silt to the waterbody.
--* Then we'll probably want to transfer that sediment load downstream afterward so that we understand how much silt is passed downstream.
--* We will reserve flooding for AFTER we determine other sediment load from bedrock weathering and transport



--* AUXILLIARY Plan for non-bedrock weathering Silt Production ///
--* ---Can be produced from glacial activity. Some is blown around from maximum and minimum extent of ice sheets. Some flows via rivers.
--* Will be based on the bedrock material that was ground up.
--* ---Can be produced from winds blowing across deserts. Age of desert matters, will be dispersed by winds in all directions.
--* ---Can be produced from water flow. As water flows down river, large particles are broken up and become silt sized
--* DONE ---Can be produced from volcanic ash, and is blown around the surrounding area
--* ---We need to run a loop for wind blown siltation sources. First we do it for glaciers and ice sheets. Then we do it for sand dunes. Then we do it for volcanoes. Each time
--* we record how much silt and mineral nutrient is generated in the tile. Then we blow it everywhere.

--* 2700 Tiles circumference
--* 40,000 KM circumference    Hawaii, 633 / 1.6 percent the circumference of the world
--* Small volcanic island SotE, 0.1 percent circumference of the world, Real world: 0.04 percent
--* Delta: 0.15 percent in SotE, Real world 0.47 percent
--* Mountain Valley Width: SotE 0.1 percent, Real World 0.023 percent
--* 0.5 percent, 0.2

return gpm