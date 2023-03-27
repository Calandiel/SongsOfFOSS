local d = {}

function d.load()
	local Job = require "game.raws.jobs"

	Job:new {
		name = 'water-carriers',
		icon = 'droplets.png',
		description = 'water carriers',
		r = 0.2,
		g = 0.2,
		b = 1.3,
	}
	Job:new {
		name = 'gatherers',
		icon = 'high-grass.png',
		description = 'gatherers',
		r = 0.3,
		g = 1,
		b = 0.3,
	}
	Job:new {
		name = 'hunters',
		icon = 'bow-arrow.png',
		description = 'hunters',
		r = 1,
		g = 0.3,
		b = 0.3,
	}
	Job:new {
		name = 'knappers',
		icon = 'stone-spear.png',
		description = 'knappers',
		r = 0.3,
		g = 0.3,
		b = 1,
	}
	Job:new {
		name = 'shamans',
		icon = 'tribal-pendant.png',
		description = 'shamans',
		r = 0.6,
		g = 0.3,
		b = 0.98,
	}
	Job:new {
		name = 'warriors',
		icon = 'stone-axe.png',
		description = 'warriors',
		r = 0.67,
		g = 0.45,
		b = 0.33,
	}
	Job:new {
		name = 'brewers',
		icon = 'beer-stein.png',
		description = 'brewing various plants into alcoholic beverages',
		r = 0.5,
		g = 0.2,
		b = 0.6,
	}
	Job:new {
		name = 'miners',
		icon = 'war-pick.png',
		description = 'the dredgers of the earth',
		r = 0.02,
		g = 0.02,
		b = 0.02
	}
	Job:new {
		name = 'smelters',
		icon = 'silver.png',
		description = 'refining ore into usable products',
		r = 0.71,
		g = 0.25,
		b = 0.05,
	}
	Job:new {
		name = 'farmers',
		icon = 'pitchfork.png',
		description = 'farmers',
		r = 0,
		g = 0.65,
		b = 0,
	}
	Job:new {
		name = 'potterers',
		icon = 'painted-pottery.png',
		description = 'potterers',
		r = 0.46,
		g = 0.2,
		b = 0.2,
	}
	Job:new {
		name = 'woodcutters',
		icon = 'stone-axe.png',
		description = 'woodcutters',
		r = 0.36,
		g = 0.2,
		b = 0.5,
	}
	Job:new {
		name = 'artisans',
		icon = 'crafting.png',
		description = 'artisans',
		r = 0.36,
		g = 1,
		b = 1,
	}
	Job:new {
		name = 'tanners',
		icon = 'animal-hide.png',
		description = 'tanners',
		r = 1,
		g = 0.45,
		b = 0.45,
	}


end

return d
