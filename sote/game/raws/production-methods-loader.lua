local d = {}

function d.load()
	local ProductionMethod = require "game.raws.production-methods"
	local job = require "game.raws.raws-utils".job
	local good = require "game.raws.raws-utils".trade_good

	-- Keep in mind that outputs are per worker already!
	ProductionMethod:new {
		name = 'none',
		description = 'nothing at all!',
		icon = 'triangle-target.png',
		r = 0.1,
		g = 0.1,
		b = 0.1,
		inputs = {},
		outputs = {},
		jobs = {},
		self_sourcing_fraction = 1,
	}
	ProductionMethod:new {
		name = 'communal-fire',
		description = 'communal fire',
		icon = 'celebration-fire.png',
		r = 1,
		g = 0.1,
		b = 0.1,
		inputs = {},
		outputs = { ['administration'] = 10 },
		jobs = {},
		self_sourcing_fraction = 0,
	}
	ProductionMethod:new {
		name = 'water-carrier',
		description = 'water carrier',
		icon = 'droplets.png',
		r = 0.1,
		g = 0.1,
		b = 1,
		inputs = {},
		outputs = { ['water'] = 10 },
		jobs = { [job('water-carriers')] = 1 },
		self_sourcing_fraction = 0,
	}
	ProductionMethod:new {
		name = 'gathering',
		description = 'gathering',
		icon = 'berries-bowl.png',
		r = 0.1,
		g = 1,
		b = 0.1,
		inputs = { ['tools'] = 0.05 },
		outputs = { ['food'] = 1.5 },
		jobs = { [job('gatherers')] = 1 },
		self_sourcing_fraction = 0.05,
		foraging = true,
		nature_yield_dependence = 1,
	}
	ProductionMethod:new {
		name = 'hunting',
		description = 'hunting',
		icon = 'bow-arrow.png',
		r = 1,
		g = 0.2,
		b = 0.3,
		inputs = { ['tools'] = 0.05 },
		outputs = { ['food'] = 1.33, ['meat'] = 0.5, ['hide'] = 1 },
		jobs = { [job('hunters')] = 1 },
		self_sourcing_fraction = 0.05,
		foraging = true,
		nature_yield_dependence = 1,
	}
	ProductionMethod:new {
		name = 'flint-extraction',
		description = 'flint knapping',
		icon = 'stone-stack.png',
		r = 0.1,
		g = 1,
		b = 0.1,
		inputs = { },
		outputs = { ['knapping-blanks'] = 2 },
		jobs = { [job('knappers')] = 3 },
		self_sourcing_fraction = 0,
	}
	ProductionMethod:new {
		name = 'flint-knapping',
		description = 'flint knapping',
		icon = 'stone-stack.png',
		r = 0.1,
		g = 1,
		b = 0.1,
		inputs = { ['knapping-blanks'] = 1 / 24 }, -- one blank serves for two years - made up value
		outputs = { ['tools'] = 0.25 },
		jobs = { [job('knappers')] = 1 },
		self_sourcing_fraction = 0.8,
	}
	ProductionMethod:new {
		name = 'brewing',
		description = 'ale, beer made with hops or rarer ingredients',
		icon = 'beer-stein.png',
		r = 0.7,
		g = 0.36,
		b = 0.9,
		inputs = { ['water'] = 4 },
		outputs = { ['liquors'] = 4 },
		jobs = { [job('brewers')] = 2 },
		self_sourcing_fraction = 0.2,
	}
	ProductionMethod:new {
		name = 'surface-copper-mining',
		description = 'mining ore close to the surface',
		icon = 'ore.png',
		r = 0.65,
		g = 0.65,
		b = 0.65,
		inputs = { ['tools'] = 5, ['timber'] = 15 },
		outputs = { ['copper-bars'] = 20 },
		jobs = { [job('miners')] = 5, [job('smelters')] = 1 },
		self_sourcing_fraction = 0.75
	}
	ProductionMethod:new {
		name = 'clay-extraction',
		description = 'clay extraction',
		icon = 'powder.png',
		r = 0.25,
		g = 0.25,
		b = 0.25,
		inputs = { ['containers'] = 0.1 },
		outputs = { ['clay'] = 20 },
		jobs = { [job('gatherers')] = 1, },
		self_sourcing_fraction = 0.1,
		clay_extreme_max = 1,
		clay_ideal_max = 1,
		clay_ideal_min = 0.65,
		clay_extreme_min = 0.4,
	}
	ProductionMethod:new {
		name = 'pottery',
		description = 'pottery',
		icon = 'painted-pottery.png',
		r = 0.55,
		g = 0.25,
		b = 0.25,
		inputs = { ['clay'] = 10 },
		outputs = { ['containers'] = 10 },
		jobs = { [job('potterers')] = 1, },
		self_sourcing_fraction = 0.5,
	}
	ProductionMethod:new {
		name = 'woodcutting',
		description = 'woodcutting',
		icon = 'stone-axe.png',
		r = 0.35,
		g = 0.25,
		b = 0.65,
		inputs = { ['tools'] = 1 },
		outputs = { ['timber'] = 15 },
		jobs = { [job('woodcutters')] = 1, },
		self_sourcing_fraction = 0.5,
		forest_dependence = 1,
	}
	ProductionMethod:new {
		name = 'tanning',
		description = 'tanning',
		icon = 'animal-hide.png',
		r = 1,
		g = 0.55,
		b = 0.55,
		inputs = { ['tools'] = 0.2, ['hide'] = 5 },
		outputs = { ['leather'] = 5 },
		jobs = { [job('tanners')] = 1, },
		self_sourcing_fraction = 0.7,
	}
	ProductionMethod:new {
		name = 'leather-clothing',
		description = 'leather clothing',
		icon = 'kimono.png',
		r = 1,
		g = 0.75,
		b = 0.45,
		inputs = { ['tools'] = 0.2, ['leather'] = 5 },
		outputs = { ['clothes'] = 5 },
		jobs = { [job('artisans')] = 1, },
		self_sourcing_fraction = 0.75,
	}
	ProductionMethod:new {
		name = 'furniture',
		description = 'furniture',
		icon = 'wooden-chair.png',
		r = 1,
		g = 0.55,
		b = 0.65,
		inputs = { ['tools'] = 3, ['timber'] = 3 },
		outputs = { ['furniture'] = 3 },
		jobs = { [job('artisans')] = 1, },
		self_sourcing_fraction = 0.85,
	}
	ProductionMethod:new {
		name = 'rye-farming',
		description = 'Rye',
		icon = 'wheat.png',
		r = 0.2,
		g = 0.65,
		b = 0,
		inputs = { ['tools'] = 1 },
		outputs = { ['food'] = 2 },
		jobs = { [job('farmers')] = 1, },
		self_sourcing_fraction = 0.125,
		crop = true,
		temperature_ideal_min = 11,
		temperature_ideal_max = 13,
		temperature_extreme_min = 3,
		temperature_extreme_max = 30,
		rainfall_ideal_min = 40,
		rainfall_ideal_max = 70,
		rainfall_extreme_min = 5,
		rainfall_extreme_max = 200,
	}
end

return d
