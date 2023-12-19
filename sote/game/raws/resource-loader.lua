local d = {}

function d.load()
	local Resource = require "game.raws.resources"
	local met = require "game.raws.raws-utils".production_method
	local cat = require "game.raws.raws-utils".trade_category
	local tec = require "game.raws.raws-utils".technology
	local bio = require "game.raws.raws-utils".biome
	local bedrock = require "game.raws.raws-utils".bedrock

	Resource:new {
		name = 'flint',
		icon = 'stone-stack.png',
		description = 'flint',
		r = 0.75,
		g = 0.75,
		b = 0.775,
		--required_biome
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
	}
	Resource:new {
		name = 'native-copper',
		icon = 'ore.png',
		description = 'native copper',
		r = 0.9,
		g = 0.64,
		b = 0.2,
		base_frequency = 20000
	}
	Resource:new {
		name = 'native-gold',
		icon = 'gold-nuggets.png',
		r = 1,
		g = 0.84,
		b = 0,
		base_frequency = 9000
	}
	Resource:new {
		name = 'copper',
		icon = 'ore.png',
		description = 'copper',
		r = 0.71,
		g = 0.25,
		b = 0.05,
		base_frequency = 4000
	}
	Resource:new {
		name = 'stone',
		icon = 'stone-block.png',
		description = 'stone',
		r = 0.8,
		g = 0.8,
		b = 0.8,
		base_frequency = 10000
	}
	Resource:new {
		name = 'gems',
		icon = 'gems.png',
		r = 0.31,
		g = 0.78,
		b = 0.47,
		base_frequency = 20000,
	}
	Resource:new {
		name = 'quality-clay',
		icon = 'powder.png',
		r = 0.21,
		g = 0.28,
		b = 0.27,
		base_frequency = 5000,
	}
	-- PLANTS
	Resource:new {
		name = 'rye',
		icon = 'wheat.png',
		r = 0.21,
		g = 0.78,
		b = 0.1,
		base_frequency = 1000,
		maximum_elevation = 1500.0,
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
		r = 0.51,
		g = 0.78,
		b = 0.1,
		base_frequency = 1000,
		maximum_elevation = 1500.0,
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
		r = 0.71,
		g = 0.78,
		b = 0.1,
		base_frequency = 1000,
		maximum_elevation = 1500.0,
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
		r = 0.11,
		g = 0.34,
		b = 0.1,
		base_frequency = 1000,
		maximum_elevation = 1500.0,
		required_biome = {
			bio('dry-jungle'),
			bio('wet-jungle'),
		},
	}
	Resource:new {
		name = 'rice',
		icon = 'potato.png',
		r = 1,
		g = 0.9,
		b = 0.9,
		base_frequency = 1000,
		maximum_elevation = 1500.0,
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



end

return d
