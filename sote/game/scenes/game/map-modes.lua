local mm = {}

function mm.set_up_map_modes(game_thingy)
	local geo_map_modes = require "game.map-modes.geologic"
	local cli_map_modes = require "game.map-modes.climate"
	local ecology_map_modes = require "game.map-modes.ecology"
	local soil_map_modes = require "game.map-modes.soils"
	local debug_map_modes = require "game.map-modes.debug"
	local political_map_modes = require "game.map-modes.political"
	local demographic_map_modes = require "game.map-modes.demographic"
	local economic_map_modes = require "game.map-modes.economic"
	game_thingy.map_mode_data = {
		diplomacy = {
			"Diplomacy",
			"peace-dove.png",
			"Shows the realm and its active conflicts",
			political_map_modes.diplomacy
		},
		selected_technology = {
			"Selected technology",
			"barbute.png", -- doesn't matter, it can't be rendered in the map mode ui anyway...
			"tooltip thingy",
			demographic_map_modes.selected_technology
		},
		military_target = {
			"Military (target)",
			"barbute.png",
			"A map mode showing the desired size of the military per province",
			demographic_map_modes.military_target
		},
		military = {
			"Military",
			"barbute.png",
			"A map mode showing the amount of local troops per province",
			demographic_map_modes.military
		},
		races = {
			"Race",
			"barbute.png",
			"A map mode showing the most dominant race per province",
			demographic_map_modes.race
		},
		cultures = {
			"Culture",
			"musical-notes.png",
			"A map mode showing the most dominant culture per province",
			demographic_map_modes.culture
		},
		faiths = {
			"Faith",
			"fire-bowl.png",
			"A map mode showing the most dominant faith per province",
			demographic_map_modes.faith
		},
		coastlines = {
			"Coastlines",
			"mesh-ball.png",
			"A debug map mode visualizing coastlines. Potentially useful for map making too",
			debug_map_modes.coastlines
		},
		technologies = {
			"Technologies",
			"erlenmeyer.png",
			"Visualizes number of technologies per province",
			demographic_map_modes.technologies
		},
		local_income = {
			"Local income",
			"coins.png",
			"Shows local income of a province",
			economic_map_modes.local_income
		},
		realm_income = {
			"Realm income",
			"coins.png",
			"Shows income per realm",
			economic_map_modes.realm_income
		},
		tile_improvements = {
			"Tile improvements",
			"horizon-road.png",
			"Shows local tile improvements",
			economic_map_modes.tile_infrastructure
		},
		resources = {
			"Resources",
			"rock.png",
			"Shows resources on tiles",
			geo_map_modes.resources
		},
		prices = {
			"Prices",
			"coins.png",
			"Shows prices of the currently selected trade good",
			demographic_map_modes.prices
		},
		population = {
			"Population (100)",
			"minions.png",
			"Shows population with the most blue shades representing 100 people.",
			demographic_map_modes.population
		},
		population_1000 = {
			"Population (1000)",
			"minions.png",
			"Shows population with the most blue shades representing 1000 people.",
			demographic_map_modes.population_1000
		},
		population_density = {
			"Population density",
			"minions.png",
			"Shows population density.",
			demographic_map_modes.population_density
		},
		tile_carrying_capacity = {
			"Carrying capacity (tile)",
			"noodles.png",
			"Shows carrying capacity per tile.",
			ecology_map_modes.tile_carrying_capacity
		},
		realms = {
			"Realms",
			"flying-flag.png",
			"Shows realms.",
			political_map_modes.realms
		},
		carrying_capacity = {
			"Carrying capacity",
			"noodles.png",
			"Shows carrying capacity.",
			ecology_map_modes.carrying_capacity
		},
		province = {
			"Provinces",
			"mesh-ball.png",
			"Shows provinces.",
			political_map_modes.province
		},
		biomes = {
			"Biomes",
			"sprout-disc.png",
			"Shows biomes.",
			ecology_map_modes.biomes
		},
		itcz = {
			"ITCZ",
			"info.png",
			"Shows the ITCZ.",
			cli_map_modes.itcz
		},
		plants = {
			"Vegetation",
			"pine-tree.png",
			"Shows types of plants. Red for shrubs, green for grass, blue for trees.",
			ecology_map_modes.plants
		},
		jan_flow = {
			"January waterflow",
			"waterfall.png",
			"Shows january waterflow.",
			cli_map_modes.jan_flow
		},
		jul_flow = {
			"July waterflow",
			"waterfall.png",
			"Shows july waterflow.",
			cli_map_modes.jul_flow
		},
		koppen = {
			"Kopppen",
			"raining.png",
			"Shows the koppen classification.",
			cli_map_modes.koppen
		},
		jan_rain = {
			"January rainfall",
			"droplets.png",
			"Shows january rainfall.",
			cli_map_modes.jan_rain
		},
		jul_rain = {
			"July rainfall",
			"droplets.png",
			"Shows july rainfall.",
			cli_map_modes.jul_rain
		},
		jan_temp = {
			"January temperature",
			"thermometer-cold.png",
			"Shows january temperature.",
			cli_map_modes.jan_temp
		},
		jul_temp = {
			"July temperature",
			"thermometer-hot.png",
			"Shows july temperature.",
			cli_map_modes.jul_temp
		},
		soil_organics = {
			"Soil organics",
			"plow.png",
			"Shows soil organics.",
			soil_map_modes.organics
		},
		soil_minerals = {
			"Soil minerals",
			"plow.png",
			"Shows soil minerals.",
			soil_map_modes.minerals
		},
		soil_texture = {
			"Soil texture",
			"plow.png",
			"Shows soil texture.",
			soil_map_modes.texture
		},
		soil_depth = {
			"Soil depth",
			"plow.png",
			"Shows soil depth.",
			soil_map_modes.depth
		},
		plates = {
			"Plates",
			"world.png",
			"Shows tectonic plates",
			geo_map_modes.plates
		},
		rocks = {
			"Rocks",
			"stone-block.png",
			"Shows bedrocks",
			geo_map_modes.rocks
		},
		elevation = {
			"Elevation",
			"mountains.png",
			"Shows elevation",
			geo_map_modes.elevation
		},
		yellow = {
			"Yellow",
			"mesh-ball.png",
			"A debug map mode showing all tiles as yellow!",
			debug_map_modes.yellow
		},
		selected_tile = {
			"Selected tile",
			"flat-platform.png",
			"A debug map mode showing the selected tile!",
			debug_map_modes.selected_tile
		},
		debug = {
			"Debug color",
			"magnifying-glass.png",
			"A debug map mode showing the debug color that was set on tiles by the developers!",
			debug_map_modes.debug_color
		},
        atlas = {
			"Atlas",
			"flying-flag.png",
			"Shows combined information.",
			political_map_modes.atlas
		},
	}
	game_thingy.map_mode_tabs = {}
	game_thingy.map_mode_selected_tab = "all"
	game_thingy.map_mode_tabs.all = {
		"elevation", "biomes", "plants", "koppen",
		"realms", "population", "population_1000", 'population_density', "plates", "rocks", 'tile_carrying_capacity',
		"resources", "soil_texture", "soil_depth", "soil_organics", "soil_minerals",
		"jan_rain", "jul_rain", "jan_temp", "jul_temp", "jan_flow", "jul_flow",
		"province", "carrying_capacity", 'tile_improvements', "realm_income", "local_income", "coastlines",
		'races', 'cultures', 'faiths', "military_target", "military", 'diplomacy'
	}
	game_thingy.map_mode_tabs.political = {
		"realms", "province", "atlas", "diplomacy"
	}
	game_thingy.map_mode_tabs.demographic = {
		"population", "population_1000", 'population_density', 'technologies', 'races', 'cultures', 'faiths',
		"military_target", "military",
	}
	game_thingy.map_mode_tabs.debug = {
		"yellow", "selected_tile", "debug", "itcz", "coastlines",
	}
	game_thingy.map_mode_tabs.economic = {
		"tile_improvements", "realm_income", "local_income"
	}
end

return mm
