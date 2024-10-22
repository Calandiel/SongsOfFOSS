local ll = {}

function ll.load()
	local Biome = require "game.raws.biomes"
	local arctic_threshold = 16.5 -- maximum summer temperature

	Biome:new {
		name = "tundra",
		r = 75 / 255,
		g = 75 / 255,
		b = 75 / 255,
		maximum_summer_temperature = arctic_threshold
	}

	-- OCEAN BIOMES AND SUCH
	Biome:new {
		name = "abyssal-plains",
		r = 0 / 255,
		g = 0 / 255,
		b = 70 / 255,
		aquatic = true,
		maximum_elevation = -300,
		minimum_elevation = -6000,
	}
	Biome:new {
		name = "continental-shelf",
		r = 0 / 255,
		g = 0 / 255,
		b = 150 / 255,
		aquatic = true,
		minimum_elevation = -300,
	}
	Biome:new {
		name = "trench",
		r = 0 / 255,
		g = 0 / 255,
		b = 30 / 255,
		aquatic = true,
		maximum_elevation = -6000,
	}
	Biome:new {
		name = "glacier",
		r = 255 / 255,
		g = 255 / 255,
		b = 255 / 255,
		icy = true,
	}
	Biome:new {
		name = "glaciated-sea",
		r = 181 / 255,
		g = 181 / 255,
		b = 255 / 255,
		icy = true,
		aquatic = true,
	}

	local forest_threshold = 0.65
	local woodland_threshold = 0.4
	local savanna_threshold = 0.2
	local shrubland = 0.65
	local scrubland_threshold = 0.4

	local tropical_threshold = 18.0 -- minimum winter temperature
	local warm_forest_threshold = 9.0
	local desert_threshold = 0.35
	local moderate_desert_threshold = 0.7
	local sprase_desert_threshold = 0.35
	local severe_desert_threshold = 0.1

	----------------Forests------------------
	Biome:new {
		name = "mixed-forest",
		r = 8 / 255,
		g = 90 / 255,
		b = 25 / 255,
		minimum_trees = forest_threshold,
		minimum_conifer_fraction = 0.25,
		maximum_conifer_fraction = 0.75,
	}
	Biome:new {
		name = "coniferous-forest",
		r = 8 / 255,
		g = 70 / 255,
		b = 50 / 255,
		minimum_trees = forest_threshold,
		minimum_conifer_fraction = 0.75,
	}
	Biome:new {
		name = "taiga",
		r = 18 / 255, -- 8
		g = 80 / 255, -- 70
		b = 60 / 255, -- 50
		minimum_trees = forest_threshold,
		maximum_summer_temperature = arctic_threshold,
	}
	Biome:new {
		name = "broadleaf-forest",
		r = 8 / 255,
		g = 104 / 255,
		b = 0 / 255,
		minimum_trees = forest_threshold,
		maximum_conifer_fraction = 0.25,
	}
	Biome:new {
		name = "warm-dry-broadleaf-forest",
		r = 8 / 255,
		g = 104 / 255,
		b = 0 / 255,
		minimum_trees = forest_threshold,
		minimum_winter_temperature = warm_forest_threshold,
		maximum_conifer_fraction = 0.25,
		maximum_available_water = 5,
	}
	Biome:new {
		name = "wet-jungle",
		r = 5 / 255,
		g = 70 / 255,
		b = 0 / 255,
		minimum_trees = forest_threshold,
		maximum_conifer_fraction = 0.25,
		minimum_winter_temperature = tropical_threshold,
		minimum_available_water = 100,
	}
	Biome:new {
		name = "jungle",
		r = 6 / 255,
		g = 85 / 255,
		b = 0 / 255,
		minimum_trees = forest_threshold,
		maximum_conifer_fraction = 0.25,
		minimum_winter_temperature = tropical_threshold,
		minimum_available_water = 5,
		maximum_available_water = 100,
	}
	Biome:new {
		name = "dry-jungle",
		r = 8 / 255,
		g = 104 / 255,
		b = 0 / 255,
		minimum_trees = forest_threshold,
		maximum_conifer_fraction = 0.25,
		minimum_winter_temperature = tropical_threshold,
		maximum_available_water = 5,
	}
	----------------Woodlands------------------
	Biome:new {
		name = "mixed-woodland",
		r = 45 / 255,
		g = 80 / 255,
		b = 20 / 255,
		minimum_trees = woodland_threshold,
		maximum_trees = forest_threshold,
		minimum_conifer_fraction = 0.25,
		maximum_conifer_fraction = 0.75,
		maximum_dead_land = 0.6,
	}
	Biome:new {
		name = "coniferous-woodland",
		r = 45 / 255,
		g = 60 / 255,
		b = 45 / 255,
		minimum_trees = woodland_threshold,
		maximum_trees = forest_threshold,
		minimum_conifer_fraction = 0.75,
		maximum_dead_land = 0.6,
	}
	Biome:new {
		name = "woodland-taiga",
		r = 55 / 255, --45
		g = 70 / 255, --60
		b = 55 / 255, --45
		minimum_trees = woodland_threshold,
		maximum_trees = forest_threshold,
		maximum_dead_land = 0.6,
		maximum_summer_temperature = arctic_threshold
	}
	Biome:new {
		name = "warm-wet-broadleaf-woodland",
		r = 45 / 255,
		g = 90 / 255,
		b = 20 / 255,
		minimum_trees = woodland_threshold,
		maximum_trees = forest_threshold,
		maximum_conifer_fraction = 0.25,
		maximum_dead_land = 0.6,
		minimum_winter_temperature = warm_forest_threshold,
		minimum_available_water = 5,
	}
	Biome:new {
		name = "warm-dry-broadleaf-woodland",
		r = 55 / 255,
		g = 100 / 255,
		b = 0 / 255,
		minimum_trees = woodland_threshold,
		maximum_trees = forest_threshold,
		maximum_conifer_fraction = 0.25,
		maximum_dead_land = 0.6,
		minimum_winter_temperature = warm_forest_threshold,
		maximum_available_water = 5,
	}
	Biome:new {
		name = "broadleaf-woodland",
		r = 45 / 255,
		g = 90 / 255,
		b = 0 / 255,
		minimum_trees = woodland_threshold,
		maximum_trees = forest_threshold,
		maximum_conifer_fraction = 0.25,
		maximum_dead_land = 0.6,
	}

	----------------Savannas------------------
	--- Savannas are grass dominant
	--- scrubland is shrub dominant
	--- Both scrubland and Savannas have between 0.2-0.4 treecover, but vary depending on whether they have grass or shrubs
	--- We actually need grassland thresholds?
	Biome:new {
		name = "savanna",
		r = 230 / 255,
		g = 225 / 255,
		b = 25 / 255,
		minimum_trees = savanna_threshold,
		maximum_trees = woodland_threshold,
		maximum_dead_land = desert_threshold,
		maximum_shrubs = scrubland_threshold,
		minimum_grass = 0.3,
	}
	----------------Shrublands/Scrublands------------------
	Biome:new {
		name = "shrubland",
		r = 240 / 255,
		g = 152 / 255,
		b = 91 / 255,
		maximum_dead_land = desert_threshold,
		minimum_shrubs = 0.6,
	}
	Biome:new {
		name = "woody-scrubland",
		r = 122 / 255,
		g = 176 / 255,
		b = 60 / 255,
		maximum_dead_land = desert_threshold,
		minimum_shrubs = 0.3,
		maximum_shrubs = 0.6,
		minimum_trees = 0.3,
	}
	Biome:new {
		name = "grassy-scrubland",
		r = 179 / 255,
		g = 200 / 255,
		b = 110 / 255,
		maximum_dead_land = desert_threshold,
		minimum_shrubs = 0.3,
		maximum_shrubs = 0.6,
		minimum_grass = 0.3,
	}
	Biome:new {
		name = "mixed-scrubland",
		r = 150 / 255,
		g = 188 / 255,
		b = 85 / 255,
		maximum_dead_land = desert_threshold,
		minimum_shrubs = 0.3,
		maximum_shrubs = 0.6,
		maximum_trees = 0.3,
		maximum_grass = 0.3,
	}
	----------------Grasslands------------------
	Biome:new {
		name = "grassland",
		r = 177 / 255,
		g = 232 / 255,
		b = 14 / 255,
		maximum_dead_land = desert_threshold,
		maximum_shrubs = 0.3,
		maximum_trees = savanna_threshold,
	}
	local moderate_desert_threshold = 0.15
	local sparse_desert_threshold = 0.50
	local severe_desert_threshold = 0.90
	----------------Deserts------------------
	Biome:new {
		name = "barren-mountainside",
		r = 128 / 255,
		g = 107 / 255,
		b = 92 / 255,
		minimum_dead_land = severe_desert_threshold,
		minimum_slope = 40,
	}
	Biome:new {
		name = "barren-mountainside-low-altitude",
		r = 128 / 255,
		g = 107 / 255,
		b = 92 / 255,
		minimum_dead_land = severe_desert_threshold,
		minimum_slope = 40,
		maximum_elevation = 1000
	}
	Biome:new {
		name = "barren-mountainside-high-altitude",
		r = 128 / 255,
		g = 107 / 255,
		b = 92 / 255,
		minimum_dead_land = severe_desert_threshold,
		minimum_slope = 40,
		minimum_elevation = 1800
	}
	Biome:new {
		-- this is the default biome so we don't want any checks
		name = "rocky-wasteland",
		r = 108 / 255,
		g = 87 / 255,
		b = 72 / 255,
	}
	Biome:new {
		name = "barren-desert",
		r = 240 / 255,
		g = 108 / 255,
		b = 14 / 255,
		minimum_dead_land = severe_desert_threshold,
		minimum_soil_depth = 0.5,
		minimum_summer_temperature = arctic_threshold,
	}
	Biome:new {
		name = "sand-dunes",
		r = 227 / 255,
		g = 217 / 255,
		b = 77 / 255,
		minimum_dead_land = severe_desert_threshold,
		minimum_soil_depth = 0.5,
		minimum_summer_temperature = arctic_threshold,
	}
	Biome:new {
		name = "badlands",
		r = 201 / 255,
		g = 72 / 255,
		b = 16 / 255,
		minimum_dead_land = severe_desert_threshold,
		minimum_soil_depth = 0.1,
		minimum_clay = 0.4,
		minimum_summer_temperature = arctic_threshold,
	}
	Biome:new {
		name = "xeric-desert",
		r = 245 / 255,
		g = 123 / 255,
		b = 37 / 255,
		minimum_dead_land = sparse_desert_threshold,
		maximum_dead_land = severe_desert_threshold,
		--minimum_soil_depth = 0.5,
		minimum_shrubs = 0.05,
		minimum_summer_temperature = arctic_threshold,
	}
	Biome:new {
		name = "xeric-shrubland",
		r = 240 / 255,
		g = 133 / 255,
		b = 58 / 255,
		minimum_dead_land = moderate_desert_threshold,
		maximum_dead_land = severe_desert_threshold,
		--minimum_soil_depth = 0.5,
		minimum_shrubs = 0.2,
		minimum_summer_temperature = arctic_threshold,
	}
	Biome:new {
		name = "rugged-mountainside",
		r = 173 / 255,
		g = 136 / 255,
		b = 109 / 255,
		minimum_dead_land = sparse_desert_threshold,
		maximum_dead_land = severe_desert_threshold,
		minimum_slope = 40,
	}
	Biome:new {
		name = "rugged-mountainside-low-altitude",
		r = 173 / 255,
		g = 136 / 255,
		b = 109 / 255,
		minimum_dead_land = sparse_desert_threshold,
		maximum_dead_land = severe_desert_threshold,
		minimum_slope = 40,
		maximum_elevation = 1000
	}
	Biome:new {
		name = "mountainside-scrub",
		r = 196 / 255,
		g = 134 / 255,
		b = 90 / 255,
		minimum_dead_land = moderate_desert_threshold,
		maximum_dead_land = sparse_desert_threshold,
		minimum_slope = 40,
	}
	Biome:new {
		name = "mountainside-scrub-low-altitude",
		r = 196 / 255,
		g = 134 / 255,
		b = 90 / 255,
		minimum_dead_land = moderate_desert_threshold,
		maximum_dead_land = sparse_desert_threshold,
		minimum_slope = 40,
		maximum_elevation = 1000
	}

	Biome:new {
		name = "bog",
		r = 211 / 255,
		g = 135 / 255,
		b = 224 / 255,
		marsh = true,
	}
	Biome:new {
		name = "marsh",
		r = 211 / 255,
		g = 135 / 255,
		b = 224 / 255,
		marsh = true,
		minimum_grass = 0.5,
	}
	Biome:new {
		name = "swamp",
		r = 211 / 255,
		g = 135 / 255,
		b = 224 / 255,
		marsh = true,
		maximum_grass = 0.5,
	}

	-- Define the load order at the end!
	RAWS_MANAGER.biomes_load_order = {
		RAWS_MANAGER.biomes_by_name["rocky-wasteland"],
		RAWS_MANAGER.biomes_by_name["tundra"],
		RAWS_MANAGER.biomes_by_name["abyssal-plains"],
		RAWS_MANAGER.biomes_by_name["continental-shelf"],
		RAWS_MANAGER.biomes_by_name["trench"],
		RAWS_MANAGER.biomes_by_name["glacier"],
		RAWS_MANAGER.biomes_by_name["glaciated-sea"],
		RAWS_MANAGER.biomes_by_name["coniferous-forest"],
		RAWS_MANAGER.biomes_by_name["broadleaf-forest"],
		RAWS_MANAGER.biomes_by_name["warm-dry-broadleaf-forest"],
		RAWS_MANAGER.biomes_by_name["mixed-forest"],
		RAWS_MANAGER.biomes_by_name["wet-jungle"],
		RAWS_MANAGER.biomes_by_name["jungle"],
		RAWS_MANAGER.biomes_by_name["dry-jungle"],
		RAWS_MANAGER.biomes_by_name["taiga"],
		RAWS_MANAGER.biomes_by_name["coniferous-woodland"],
		RAWS_MANAGER.biomes_by_name["broadleaf-woodland"],
		RAWS_MANAGER.biomes_by_name["warm-wet-broadleaf-woodland"],
		RAWS_MANAGER.biomes_by_name["warm-dry-broadleaf-woodland"],
		RAWS_MANAGER.biomes_by_name["mixed-woodland"],
		RAWS_MANAGER.biomes_by_name["woodland-taiga"],
		RAWS_MANAGER.biomes_by_name["savanna"],
		RAWS_MANAGER.biomes_by_name["shrubland"],
		RAWS_MANAGER.biomes_by_name["woody-scrubland"],
		RAWS_MANAGER.biomes_by_name["grassy-scrubland"],
		RAWS_MANAGER.biomes_by_name["mixed-scrubland"],
		RAWS_MANAGER.biomes_by_name["grassland"],
		RAWS_MANAGER.biomes_by_name["barren-mountainside"],
		RAWS_MANAGER.biomes_by_name["barren-mountainside-low-altitude"],
		RAWS_MANAGER.biomes_by_name["barren-mountainside-high-altitude"],
		RAWS_MANAGER.biomes_by_name["barren-desert"],
		RAWS_MANAGER.biomes_by_name["sand-dunes"],
		RAWS_MANAGER.biomes_by_name["badlands"],
		RAWS_MANAGER.biomes_by_name["xeric-desert"],
		RAWS_MANAGER.biomes_by_name["xeric-shrubland"],
		RAWS_MANAGER.biomes_by_name["rugged-mountainside"],
		RAWS_MANAGER.biomes_by_name["rugged-mountainside-low-altitude"],
		RAWS_MANAGER.biomes_by_name["mountainside-scrub"],
		RAWS_MANAGER.biomes_by_name["mountainside-scrub-low-altitude"],
		RAWS_MANAGER.biomes_by_name["bog"],
		RAWS_MANAGER.biomes_by_name["marsh"],
		RAWS_MANAGER.biomes_by_name["swamp"],
	}
end

return ll
