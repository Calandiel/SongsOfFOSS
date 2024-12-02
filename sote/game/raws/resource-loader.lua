local d = {}

function d.load()
	local Resource = require "game.raws.resources"
	local bio = require "game.raws.raws-utils".biome
	local bedrock = require "game.raws.raws-utils".bedrock

	Resource:new {
		name = 'flint',
		icon = 'stone-stack.png',
		description = 'flint',
		r = 0.75,
		g = 0.75,
		b = 0.775,
		required_biome = {},
		required_bedrock = { bedrock('limestone'), bedrock('chalk') },
		base_frequency = 300
		--coastal
		--land
		--water
		--minimum_trees
		--maximum_trees
		--minimum_elevation
		--maximum_elevation
		--ice_age
	}
	Resource:new {
		name = 'obsidian',
		icon = 'stone-stack.png',
		description = 'obsidian',
		r = 0.75,
		g = 0.75,
		b = 0.775,
		required_biome = {},
		required_bedrock = { bedrock('rhyolite') },
		base_frequency = 50
	}
	Resource:new {
		name = 'cowry-shells',
		icon = 'sewed-shell.png',
		description = 'cowry shells',
		r = 0,
		g = 1,
		b = 1,
		coastal = true,
		required_biome = {},
		required_bedrock = {},
		base_frequency = 333,
	}
	Resource:new {
		name = 'meteoric-iron',
		icon = 'asteroid.png',
		description = 'meteoric iron',
		r = 0.6,
		g = 0.35,
		b = 1,
		base_frequency = 10000,
		required_biome = {},
		required_bedrock = {},
	}
	Resource:new {
		name = 'iron',
		icon = 'asteroid.png',
		description = 'meteoric iron',
		r = 0.6,
		g = 0.35,
		b = 1,
		base_frequency = 6000,
		required_biome = {},
		required_bedrock = {},
	}
	Resource:new {
		name = 'native-copper',
		icon = 'ore.png',
		description = 'native copper',
		r = 0.9,
		g = 0.64,
		b = 0.2,
		base_frequency = 20000,
		required_biome = {},
		required_bedrock = {},
	}
	Resource:new {
		name = 'native-gold',
		icon = 'gold-nuggets.png',
		description = "Native gold",
		r = 1,
		g = 0.84,
		b = 0,
		base_frequency = 9000,
		required_biome = {},
		required_bedrock = {},
	}
	Resource:new {
		name = 'gold',
		icon = 'gold-nuggets.png',
		description = "Gold",
		r = 1,
		g = 0.84,
		b = 0,
		base_frequency = 6000,
		required_biome = {},
		required_bedrock = {},
	}
	Resource:new {
		name = 'silver',
		icon = 'gold-nuggets.png',
		description = "Silver",
		r = 1,
		g = 0.84,
		b = 1,
		base_frequency = 6000,
		required_biome = {},
		required_bedrock = {},
	}
	Resource:new {
		name = 'arsenic',
		icon = 'ore.png',
		description = "Arsenic",
		r = 0.6,
		g = 0.84,
		b = 0.9,
		base_frequency = 3000,
		required_biome = {},
		required_bedrock = {},
	}
	Resource:new {
		name = 'copper',
		icon = 'ore.png',
		description = 'Copper',
		r = 0.71,
		g = 0.25,
		b = 0.05,
		base_frequency = 4000,
		required_biome = {},
		required_bedrock = {},
	}
	Resource:new {
		name = 'native-bronze',
		icon = 'ore.png',
		description = "Native bronze",
		r = 0.36,
		g = 0.125,
		b = 0.025,
		base_frequency = 4000,
		required_biome = {},
		required_bedrock = {},
	}
	Resource:new {
		name = 'tin',
		icon = 'ore.png',
		description = "Tin",
		r = 0.31,
		g = 1.0,
		b = 0.05,
		base_frequency = 4000,
		required_biome = {},
		required_bedrock = {},
	}
	Resource:new {
		name = 'zinc',
		icon = 'ore.png',
		description = "Zinc",
		r = 0.01,
		g = 0.8,
		b = 0.35,
		base_frequency = 4000,
		required_biome = {},
		required_bedrock = {},
	}
	Resource:new {
		name = 'stone',
		icon = 'stone-block.png',
		description = 'stone',
		r = 0.8,
		g = 0.8,
		b = 0.8,
		base_frequency = 10000,
		required_biome = {},
		required_bedrock = {},
	}
	Resource:new {
		name = 'gems',
		icon = 'gems.png',
		description = "Gems",
		r = 0.31,
		g = 0.78,
		b = 0.47,
		base_frequency = 20000,
		required_biome = {},
		required_bedrock = {},
	}
	Resource:new {
		name = 'quality-clay',
		icon = 'powder.png',
		description = "Clay",
		r = 0.21,
		g = 0.28,
		b = 0.27,
		base_frequency = 5000,
		required_biome = {},
		required_bedrock = {},
	}
	-- PLANTS
	Resource:new {
		name = 'rye',
		icon = 'wheat.png',
		description = "Rye",
		r = 0.21,
		g = 0.78,
		b = 0.1,
		base_frequency = 1000,
		maximum_elevation = 1500.0,
		required_bedrock = {},
		required_biome = {
			bio('grassy-scrubland'),
			bio('mixed-scrubland'),
			bio('woody-scrubland'),
			bio('grassland'),
		},
	}
	Resource:new {
		name = 'wheat',
		icon = 'wheat.png',
		description = "Wheat",
		r = 0.51,
		g = 0.78,
		b = 0.1,
		base_frequency = 1000,
		maximum_elevation = 1500.0,
		required_bedrock = {},
		required_biome = {
			bio('grassy-scrubland'),
			bio('mixed-scrubland'),
			bio('woody-scrubland'),
			bio('grassland'),
		},
	}
	Resource:new {
		name = 'barley',
		icon = 'wheat.png',
		description = "Barley",
		r = 0.71,
		g = 0.78,
		b = 0.1,
		base_frequency = 1000,
		maximum_elevation = 1500.0,
		required_bedrock = {},
		required_biome = {
			bio('grassy-scrubland'),
			bio('mixed-scrubland'),
			bio('woody-scrubland'),
			bio('grassland'),
		},
	}
	Resource:new {
		name = 'yam',
		icon = 'potato.png',
		description = "Yam",
		r = 0.11,
		g = 0.34,
		b = 0.1,
		base_frequency = 1000,
		maximum_elevation = 1500.0,
		required_bedrock = {},
		required_biome = {
			bio('dry-jungle'),
			bio('wet-jungle'),
		},
	}
	Resource:new {
		name = 'rice',
		icon = 'potato.png',
		description = "Rice",
		r = 1,
		g = 0.9,
		b = 0.9,
		base_frequency = 1000,
		maximum_elevation = 1500.0,
		required_bedrock= {},
		required_biome = {
			bio('grassy-scrubland'),
			bio('mixed-scrubland'),
			bio('woody-scrubland'),
			bio('grassland'),
			bio('broadleaf-forest'),
			bio('mixed-forest'),
			bio('broadleaf-woodland'),
			bio('mixed-woodland'),
		},
	}
	-- ANIMALS
	Resource:new {
		name = 'bees',
		icon = 'wheat.png',
		description = "Bees",
		r = 0.76,
		g = 0.78,
		b = 0.1,
		base_frequency = 1000,
		maximum_elevation = 1250.0,
		required_bedrock = {},
		required_biome = {
			bio('grassland'),
		},
	}
end

return d
