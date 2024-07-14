local mmut = require "game.map-modes.utils"


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
			political_map_modes.diplomacy,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		selected_technology = {
			"Selected technology",
			"barbute.png", -- doesn't matter, it can't be rendered in the map mode ui anyway...
			"tooltip thingy",
			demographic_map_modes.selected_technology,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		selected_building_type_efficiency = {
			"Selected building type",
			"barbute.png", -- doesn't matter, it can't be rendered in the map mode ui anyway...
			"tooltip thingy",
			demographic_map_modes.selected_building_efficiency,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		military_target = {
			"Military (target)",
			"barbute.png",
			"A map mode showing the desired size of the military per province",
			demographic_map_modes.military_target,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		military = {
			"Military",
			"barbute.png",
			"A map mode showing the amount of local troops per province",
			demographic_map_modes.military,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		races = {
			"Race",
			"barbute.png",
			"A map mode showing the most dominant race per province",
			demographic_map_modes.race,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		cultures = {
			"Culture",
			"musical-notes.png",
			"A map mode showing the most dominant culture per province",
			demographic_map_modes.culture,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		faiths = {
			"Faith",
			"fire-bowl.png",
			"A map mode showing the most dominant faith per province",
			demographic_map_modes.faith,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		coastlines = {
			"Coastlines",
			"mesh-ball.png",
			"A debug map mode visualizing coastlines. Potentially useful for map making too",
			debug_map_modes.coastlines,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.STATIC
		},
		technologies = {
			"Technologies",
			"erlenmeyer.png",
			"Visualizes number of technologies per province",
			demographic_map_modes.technologies,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		local_income = {
			"Local income",
			"coins.png",
			"Shows local income of a province",
			economic_map_modes.local_income,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		realm_income = {
			"Realm income",
			"coins.png",
			"Shows income per realm",
			economic_map_modes.realm_income,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		resources = {
			"Resources",
			"rock.png",
			"Shows resources on tiles",
			geo_map_modes.resources,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		prices = {
			"Prices",
			"coins.png",
			"Shows prices of the currently selected trade good",
			demographic_map_modes.prices,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		population = {
			"Population (100)",
			"minions.png",
			"Shows population with the most blue shades representing 100 people.",
			demographic_map_modes.population,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		population_1000 = {
			"Population (1000)",
			"minions.png",
			"Shows population with the most blue shades representing 1000 people.",
			demographic_map_modes.population_1000,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		population_density = {
			"Population density",
			"minions.png",
			"Shows population density.",
			demographic_map_modes.population_density,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		tile_carrying_capacity = {
			"Carrying capacity (tile)",
			"noodles.png",
			"Shows carrying capacity per tile.",
			ecology_map_modes.tile_carrying_capacity,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		realms = {
			"Realms",
			"flying-flag.png",
			"Shows realms.",
			political_map_modes.realms,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		carrying_capacity = {
			"Carrying capacity",
			"noodles.png",
			"Shows carrying capacity.",
			ecology_map_modes.carrying_capacity,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		province = {
			"Provinces",
			"mesh-ball.png",
			"Shows provinces.",
			political_map_modes.province,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.STATIC
		},
		biomes = {
			"Biomes",
			"sprout-disc.png",
			"Shows biomes.",
			ecology_map_modes.biomes,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		itcz = {
			"ITCZ",
			"info.png",
			"Shows the ITCZ.",
			cli_map_modes.itcz,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.STATIC
		},
		plants = {
			"Vegetation",
			"pine-tree.png",
			"Shows types of plants. Red for shrubs, green for grass, blue for trees.",
			ecology_map_modes.plants,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		jan_flow = {
			"January waterflow",
			"waterfall.png",
			"Shows january waterflow.",
			cli_map_modes.jan_flow,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.STATIC
		},
		jul_flow = {
			"July waterflow",
			"waterfall.png",
			"Shows july waterflow.",
			cli_map_modes.jul_flow,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.STATIC
		},
		koppen = {
			"Kopppen",
			"raining.png",
			"Shows the koppen classification.",
			cli_map_modes.koppen,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.STATIC
		},
		jan_rain = {
			"January rainfall",
			"droplets.png",
			"Shows january rainfall.",
			cli_map_modes.jan_rain,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.STATIC
		},
		jul_rain = {
			"July rainfall",
			"droplets.png",
			"Shows july rainfall.",
			cli_map_modes.jul_rain,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.STATIC
		},
		jan_temp = {
			"January temperature",
			"thermometer-cold.png",
			"Shows january temperature.",
			cli_map_modes.jan_temp,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.STATIC
		},
		jul_temp = {
			"July temperature",
			"thermometer-hot.png",
			"Shows july temperature.",
			cli_map_modes.jul_temp,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.STATIC
		},
		soil_organics = {
			"Soil organics",
			"plow.png",
			"Shows soil organics.",
			soil_map_modes.organics,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		soil_minerals = {
			"Soil minerals",
			"plow.png",
			"Shows soil minerals.",
			soil_map_modes.minerals,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		soil_texture = {
			"Soil texture",
			"plow.png",
			"Shows soil texture.",
			soil_map_modes.texture,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		soil_depth = {
			"Soil depth",
			"plow.png",
			"Shows soil depth.",
			soil_map_modes.depth,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		plates = {
			"Plates",
			"world.png",
			"Shows tectonic plates",
			geo_map_modes.plates,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.STATIC
		},
		rocks = {
			"Rocks",
			"stone-block.png",
			"Shows bedrocks",
			geo_map_modes.rocks,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.STATIC
		},
		elevation = {
			"Elevation",
			"mountains.png",
			"Shows elevation",
			geo_map_modes.elevation,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.STATIC
		},
		yellow = {
			"Yellow",
			"mesh-ball.png",
			"A debug map mode showing all tiles as yellow!",
			debug_map_modes.yellow,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		selected_tile = {
			"Selected tile",
			"flat-platform.png",
			"A debug map mode showing the selected tile!",
			debug_map_modes.selected_tile,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		debug = {
			"Debug color",
			"magnifying-glass.png",
			"A debug map mode showing the debug color that was set on tiles by the developers!",
			debug_map_modes.debug_color,
			mmut.MAP_MODE_GRANULARITY.TILE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC
		},
		atlas = {
			"Atlas",
			"flying-flag.png",
			"Shows combined information.",
			political_map_modes.atlas_tiles,
			mmut.MAP_MODE_GRANULARITY.MIXED,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC_PROVINCE_STATIC_TILE,
			nil,
			political_map_modes.atlas_provinces
		},
		terrain = {
			"Terrain",
			"high-grass.png",
			"Shows terrain texture",
			political_map_modes.realms,
			mmut.MAP_MODE_GRANULARITY.PROVINCE,
			mmut.MAP_MODE_UPDATES_TYPE.DYNAMIC,
			mmut.MAP_MODE_TERRAIN_TEXTURE_INTERACTION.SHOW_TERRAIN
		}
	}

	local function compare_map_modes(a, b)
		return game_thingy.map_mode_data[a][1] < game_thingy.map_mode_data[b][1]
	end

	game_thingy.map_mode_tabs = {}
	game_thingy.map_mode_selected_tab = "all"
	game_thingy.map_mode_tabs.all = {
		"elevation", "biomes", "plants", "koppen",
		"realms", "population", "population_1000", "population_density", "plates", "rocks", "tile_carrying_capacity",
		"resources", "soil_texture", "soil_depth", "soil_organics", "soil_minerals",
		"jan_rain", "jul_rain", "jan_temp", "jul_temp", "jan_flow", "jul_flow",
		"province", "carrying_capacity", "realm_income", "local_income", "coastlines",
		"races", "cultures", "faiths", "military_target", "military", "diplomacy"
	}
	table.sort(game_thingy.map_mode_tabs.all, compare_map_modes)
	game_thingy.map_mode_tabs.political = {
		"realms", "province", "atlas", "diplomacy"
	}
	table.sort(game_thingy.map_mode_tabs.political, compare_map_modes)
	game_thingy.map_mode_tabs.demographic = {
		"population", "population_1000", "population_density", "technologies", "races", "cultures", "faiths",
		"military_target", "military",
	}
	table.sort(game_thingy.map_mode_tabs.demographic, compare_map_modes)
	game_thingy.map_mode_tabs.debug = {
		"yellow", "selected_tile", "debug", "itcz", "coastlines",
	}
	table.sort(game_thingy.map_mode_tabs.debug, compare_map_modes)
	game_thingy.map_mode_tabs.economic = {
		"realm_income", "local_income"
	}
	table.sort(game_thingy.map_mode_tabs.economic, compare_map_modes)
end

return mm
