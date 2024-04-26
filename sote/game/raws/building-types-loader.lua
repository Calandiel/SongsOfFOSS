local d = {}

local COST_WORKSHOP = 80
local COST_AREA = 35
local COST_MINE = 70
local COST_FARM = 50

function d.load()
	local BuildingType = require "game.raws.building-types"
	local prod = require "game.raws.raws-utils".production_method
	local tec = require "game.raws.raws-utils".technology
	local good = require "game.raws.raws-utils".trade_good
	local res = require "game.raws.raws-utils".resource
--[[
	BuildingType:new {
		name = "communal-fire",
		description = "communal fire",
		icon = 'celebration-fire.png',
		r = 1,
		g = 0.1,
		b = 0.1,
		unlocked_by = tec('paleolithic-knowledge'),
		production_method = prod('communal-fire'),
		unique = true,
		government = true,
		construction_cost = 50,
		upkeep = 0.05,
		needed_infrastructure = 3,
		ai_weight = 2,
	}

	BuildingType:new {
		name = "witch-doctor-garden",
		description = "witch-doctor's garden",
		icon = "hut.png",
		r = 0,
		g = 1,
		b = 1,
		unlocked_by = tec('paleolithic-knowledge'),
		production_method = prod('witch-doctor'),
		construction_cost = COST_WORKSHOP,
		building_group = BUILDING_GROUP.WORKSHOP,
		needed_infrastructure = 1,
		ai_weight = 1
	}
	BuildingType:new {
		name = "water-carrier",
		description = "water carrier",
		icon = 'droplets.png',
		r = 0.1,
		g = 0.1,
		b = 1,
		unlocked_by = tec('paleolithic-knowledge'),
		production_method = prod('water-carrier'),
		construction_cost = COST_AREA,
		upkeep = 0.01,
		needed_infrastructure = 1,
		ai_weight = 0.05,
	}
	BuildingType:new {
		name = "hunting-grounds-0",
		description = "primitive hunting grounds",
		icon = 'bow-arrow.png',
		r = 1.0,
		g = 0.2,
		b = 0.3,
		unlocked_by = tec('paleolithic-knowledge'),
		production_method = prod('hunting-0'),
		construction_cost = COST_AREA,
		building_group = BUILDING_GROUP.GROUNDS,
		needed_infrastructure = 1,
		ai_weight = 1,
	}

	BuildingType:new {
		name = "hunting-grounds-1",
		description = "hunting grounds",
		icon = 'bow-arrow.png',
		r = 1.0,
		g = 0.2,
		b = 0.3,
		unlocked_by = tec('paleolithic-knowledge'),
		production_method = prod('hunting-1'),
		construction_cost = COST_AREA,
		building_group = BUILDING_GROUP.GROUNDS,
		needed_infrastructure = 1,
		ai_weight = 1,
	}
	BuildingType:new {
		name = "hunting-grounds-2",
		description = "hunting grounds (tools)",
		icon = 'bow-arrow.png',
		r = 1.0,
		g = 0.2,
		b = 0.3,
		unlocked_by = tec('paleolithic-knowledge'),
		production_method = prod('hunting-2'),
		construction_cost = COST_AREA,
		building_group = BUILDING_GROUP.GROUNDS,
		needed_infrastructure = 1,
		ai_weight = 1,
	}

	BuildingType:new {
		name = "gathering-grounds-0",
		description = "primitive gathering grounds",
		icon = 'fruit-bowl.png',
		r = 0.2,
		g = 1.0,
		b = 0.3,
		unlocked_by = tec('paleolithic-knowledge'),
		production_method = prod('gathering-0'),
		building_group = BUILDING_GROUP.GROUNDS,
		construction_cost = COST_AREA,
		needed_infrastructure = 1,
		ai_weight = 1,
	}

	BuildingType:new {
		name = "gathering-grounds-1",
		description = "gathering grounds",
		icon = 'fruit-bowl.png',
		r = 0.2,
		g = 1.0,
		b = 0.3,
		unlocked_by = tec('paleolithic-knowledge'),
		production_method = prod('gathering-1'),
		building_group = BUILDING_GROUP.GROUNDS,
		construction_cost = COST_AREA,
		needed_infrastructure = 1,
		ai_weight = 1,
	}

	BuildingType:new {
		name = "gathering-grounds-2",
		description = "gathering grounds (tools)",
		icon = 'fruit-bowl.png',
		r = 0.2,
		g = 1.0,
		b = 0.3,
		unlocked_by = tec('ground-stone-tools'),
		production_method = prod('gathering-2'),
		building_group = BUILDING_GROUP.GROUNDS,
		construction_cost = COST_AREA,
		needed_infrastructure = 1,
		ai_weight = 1,
	}

	BuildingType:new {
		name = "flint-extraction",
		description = "flint extraction",
		icon = 'stone-stack.png',
		r = 0.3,
		g = 1.0,
		b = 0.5,
		unlocked_by = tec('paleolithic-knowledge'),
		production_method = prod('flint-extraction'),
		required_resource = { res('flint') },
		construction_cost = 15,
		unique = true,
		needed_infrastructure = 1,
		ai_weight = 20,
	}
	BuildingType:new {
		name = "blanks-knapping",
		description = "tool knapping",
		icon = 'stone-stack.png',
		r = 0.3,
		g = 1.0,
		b = 0.5,
		unlocked_by = tec('paleolithic-knowledge'),
		production_method = prod('blanks-knapping'),
		required_resource = {},
		construction_cost = COST_WORKSHOP,
		needed_infrastructure = 1,
		ai_weight = 1,
	}
	BuildingType:new {
		name = "obsidian-extraction",
		description = "obsidian extraction",
		icon = 'stone-stack.png',
		r = 0.3,
		g = 1.0,
		b = 0.5,
		unlocked_by = tec('paleolithic-knowledge'),
		production_method = prod('obsidian-extraction'),
		required_resource = { res('obsidian') },
		construction_cost = 15,
		unique = true,
		needed_infrastructure = 1,
		ai_weight = 20,
	}

	BuildingType:new {
		name = "stone-extraction",
		description = "stone extraction",
		icon = 'stone-block.png',
		r = 0.8,
		g = 0.8,
		b = 0.8,
		unlocked_by = tec('dedicated-stonecutters'),
		production_method = prod('stone-extraction'),
		required_resource = { res('stone') },
		construction_cost = 50,
		unique = true,
		needed_infrastructure = 1,
		ai_weight = 20,
	}
	BuildingType:new {
		name = 'brewery-grain',
		description = 'beer brewery',
		icon = 'beer-stein.png',
		r = 0.75,
		g = 0.42,
		b = 0.86,
		unlocked_by = tec('basic-fermentation'),
		production_method = prod('brewing-grain'),
		construction_cost = COST_WORKSHOP,
		building_group = BUILDING_GROUP.WORKSHOP,
		needed_infrastructure = 15,
		ai_weight = 3.5
	}
	BuildingType:new {
		name = 'brewery-fruit',
		description = 'cider brewery',
		icon = 'beer-stein.png',
		r = 0.75,
		g = 0.42,
		b = 0.86,
		unlocked_by = tec('basic-fermentation'),
		production_method = prod('brewing-fruit'),
		construction_cost = COST_WORKSHOP,
		building_group = BUILDING_GROUP.WORKSHOP,
		needed_infrastructure = 15,
		ai_weight = 3.5
	}

	-- ###################
	-- #  COPPER CHAINS  #
	-- ###################

	-- MINING
	BuildingType:new {
		name = 'native-copper-gathering',
		description = 'native copper gathering',
		icon = 'ore.png',
		r = 0.56,
		g = 0.33,
		b = 0.02,
		unlocked_by = tec('early-metal-working'),
		production_method = prod('native-copper-gathering'),
		required_resource = { res('native-copper') },
		unique = true,
		needed_infrastructure = 10,
		construction_cost = COST_MINE,
		ai_weight = 10
	}
	BuildingType:new {
		name = 'surface-copper-mining',
		description = 'copper mine',
		icon = 'ore.png',
		r = 0.56,
		g = 0.33,
		b = 0.02,
		unlocked_by = tec('surface-mining'),
		production_method = prod('surface-copper-mining'),
		required_resource = { res('copper') },
		unique = true,
		needed_infrastructure = 30,
		construction_cost = COST_MINE,
		ai_weight = 10
	}
	BuildingType:new {
		name = 'copper-mining',
		description = 'copper mine',
		icon = 'ore.png',
		r = 0.56,
		g = 0.33,
		b = 0.02,
		unlocked_by = tec('fire-setting-mining'),
		production_method = prod('fire-copper-mining'),
		required_resource = { res('copper') },
		unique = true,
		needed_infrastructure = 30,
		construction_cost = COST_MINE,
		ai_weight = 10
	}

	-- SMELT ORE
	BuildingType:new {
		name = 'copper-smelting',
		description = 'copper smelting',
		icon = 'ore.png',
		r = 0.56,
		g = 0.33,
		b = 0.02,
		unlocked_by = tec('surface-mining'),
		production_method = prod('copper-smelting'),
		needed_infrastructure = 10,
		construction_cost = COST_WORKSHOP,
		ai_weight = 10
	}

	-- MAKING TOOLS
	BuildingType:new {
		name = 'smith-tools-native-copper',
		description = 'native copper smiths',
		icon = 'ore.png',
		r = 0.56,
		g = 0.33,
		b = 0.02,
		unlocked_by = tec('early-metal-working'),
		production_method = prod('smith-tools-native-copper'),
		needed_infrastructure = 15,
		construction_cost = COST_WORKSHOP,
		ai_weight = 10
	}
	BuildingType:new {
		name = 'copper-smith-tools',
		description = 'copper tools smiths',
		icon = 'ore.png',
		r = 0.56,
		g = 0.33,
		b = 0.02,
		unlocked_by = tec('surface-mining'),
		production_method = prod('smith-tools-cast-copper'),
		needed_infrastructure = 15,
		construction_cost = COST_WORKSHOP,
		ai_weight = 10
	}


	BuildingType:new {
		name = 'watchtower',
		description = 'watchtower',
		icon = 'watchtower.png',
		r = 0.36,
		g = 0.73,
		b = 0.32,
		unlocked_by = tec('watchtowers'),
		production_method = prod('none'),
		required_resource = {},
		unique = true,
		government = true,
		needed_infrastructure = 10,
		ai_weight = 50,
		spotting = 500,
		construction_cost = 150,
		upkeep = 0.15,
	}
	BuildingType:new {
		name = 'clay-pit',
		description = 'clay pit',
		icon = 'powder.png',
		r = 0.26,
		g = 0.23,
		b = 0.22,
		unlocked_by = tec('pottery'),
		production_method = prod('clay-extraction'),
		needed_infrastructure = 3.5,
		ai_weight = 50,
		construction_cost = COST_MINE,
	}
	BuildingType:new {
		name = 'potterer',
		description = 'potterer',
		icon = 'painted-pottery.png',
		r = 0.56,
		g = 0.23,
		b = 0.22,
		unlocked_by = tec('pottery'),
		production_method = prod('pottery'),
		needed_infrastructure = 10,
		ai_weight = 70,
		construction_cost = COST_WORKSHOP,
		building_group = BUILDING_GROUP.WORKSHOP
	}
	BuildingType:new {
		name = 'woodcutters',
		description = 'woodcutters',
		icon = 'stone-axe.png',
		r = 0.26,
		g = 0.23,
		b = 0.62,
		unlocked_by = tec('dedicated-woodcutters'),
		production_method = prod('woodcutting'),
		needed_infrastructure = 5,
		ai_weight = 20,
		construction_cost = COST_AREA,
		building_group = BUILDING_GROUP.GROUNDS
	}
	BuildingType:new {
		name = 'furniture-crafters',
		description = 'furniture crafters',
		icon = 'stone-axe.png',
		r = 0.26,
		g = 0.73,
		b = 0.62,
		unlocked_by = tec('wooden-furniture'),
		production_method = prod('furniture'),
		needed_infrastructure = 25,
		ai_weight = 50,
		construction_cost = COST_WORKSHOP,
		building_group = BUILDING_GROUP.WORKSHOP
	}
	BuildingType:new {
		name = 'tanners',
		description = 'tanners',
		icon = 'animal-hide.png',
		r = 1,
		g = 0.33,
		b = 0.33,
		unlocked_by = tec('vegetable-tanning'),
		production_method = prod('tanning'),
		needed_infrastructure = 25,
		ai_weight = 35,
		construction_cost = COST_WORKSHOP,
		building_group = BUILDING_GROUP.WORKSHOP
	}
	BuildingType:new {
		name = 'leather-workers',
		description = 'leather workers',
		icon = 'kimono.png',
		r = 1,
		g = 0.73,
		b = 0.42,
		unlocked_by = tec('vegetable-tanning'),
		production_method = prod('leather-clothing'),
		needed_infrastructure = 25,
		ai_weight = 50,
		construction_cost = COST_WORKSHOP,
		building_group = BUILDING_GROUP.WORKSHOP
	}
	BuildingType:new {
		name = 'rye-farm',
		description = 'rye farm',
		icon = 'wheat.png',
		r = 0.16,
		g = 0.43,
		b = 0.02,
		unlocked_by = tec('agriculture'),
		production_method = prod('rye-farming'),
		required_resource = {},
		needed_infrastructure = 2.5,
		ai_weight = 50,
		construction_cost = COST_FARM,
		building_group = BUILDING_GROUP.FARM
	}
	BuildingType:new {
		name = 'beehive',
		description = 'beehive',
		icon = 'wheat.png',
		r = 0.86,
		g = 0.83,
		b = 0.02,
		unlocked_by = tec('beekeeping'),
		production_method = prod('beekeeping'),
		required_resource = { res("bees") },
		needed_infrastructure = 0.5,
		ai_weight = 150,
		construction_cost = COST_FARM,
		building_group = BUILDING_GROUP.FARM
	}
]]
end

return d
