local d = {}

function d.load()
	local Technology = require "game.raws.technologies"
	local met = require "game.raws.raws-utils".production_method
	local cat = require "game.raws.raws-utils".trade_category
	local tec = require "game.raws.raws-utils".technology
	local res = require "game.raws.raws-utils".resource
	local prod = require "game.raws.raws-utils".production_method

	Technology:new {
		name = 'paleolithic-knowledge',
		icon = 'high-grass.png',
		description = 'paleolithic knowledge',
		r = 1,
		g = 1,
		b = 1,
		required_biome = {},
		required_race = {},
		unlocked_by = {},
		research_cost = 0.2,
	}
	Technology:new {
		name = 'vegetable-tanning',
		icon = 'animal-hide.png',
		description = 'vegetable tanning',
		r = 1,
		g = 1,
		b = 1,
		unlocked_by = { tec('paleolithic-knowledge') },
		research_cost = 0.2,
	}
	Technology:new {
		name = 'ground-stone-tools',
		icon = 'stone-stack.png',
		description = 'ground stone tools',
		r = 1,
		g = 1,
		b = 1,
		unlocked_by = { tec('paleolithic-knowledge') },
		research_cost = 0.2,
		throughput_boosts = { [prod('flint-knapping')] = 0.1 },
		input_efficiency_boosts = { [prod('flint-knapping')] = 0.25 },
	}
	Technology:new {
		name = 'dedicated-woodcutters',
		icon = 'stone-axe.png',
		description = 'dedicated woodcutters',
		r = 1,
		g = 1,
		b = 1,
		unlocked_by = { tec('ground-stone-tools') },
		research_cost = 0.2,
	}
	Technology:new {
		name = 'wooden-furniture',
		icon = 'wooden-chair.png',
		description = 'wooden furniture',
		r = 0.5,
		g = 1,
		b = 1,
		unlocked_by = { tec('dedicated-woodcutters') },
		research_cost = 0.25,
	}
	Technology:new {
		name = 'metal-working',
		icon = 'asteroid.png',
		description = 'cold working of native metals',
		r = 1,
		g = 1,
		b = 1,
		unlocked_by = { tec('paleolithic-knowledge') },
		required_resource = { res("meteoric-iron"), res("native-copper"), res("native-gold") },
		research_cost = 0.25,
	}
	Technology:new {
		name = 'agriculture',
		icon = 'pitchfork.png',
		description = 'agriculture',
		r = 0,
		g = 0.65,
		b = 0,
		required_biome = {},
		required_race = {},
		required_resource = {
			res('rye'),
			res('barley'),
			res('wheat'),
			res('yam'),
			res('rice'),
		},
		unlocked_by = { tec('paleolithic-knowledge') },
		throughput_boosts = { [prod('gathering')] = 0.15 },
		research_cost = 0.15,
	}
	Technology:new {
		name = 'basic-fermentation',
		icon = 'beer-stein.png',
		description = 'fermenting things to create alcohol',
		r = love.math.random(),
		g = love.math.random(),
		b = love.math.random(),
		unlocked_by = { tec('agriculture'), },
		research_cost = 0.65,
	}
	Technology:new {
		name = 'warm-fermentation',
		icon = 'beer-stein.png',
		description = 'ales created through warm fermentation',
		r = love.math.random(),
		g = love.math.random(),
		b = love.math.random(),
		unlocked_by = { tec('basic-fermentation'), },
		research_cost = 1,
		throughput_boosts = { [prod('brewing')] = 0.15 },
	}
	Technology:new {
		name = "surface-mining",
		icon = "war-pick.png",
		description = 'mining shallow deposits of minerals',
		r = 0.3,
		g = 0.01,
		b = 0.8,
		unlocked_by = { tec('metal-working') },
		required_resource = { res('copper'), },
		research_cost = 1
	}
	Technology:new {
		name = 'gem-cutting',
		icon = 'cut-gems.png',
		description = 'cutting exotic gemstones to please the eye',
		r = 0.72,
		g = 0.94,
		b = 1,
		unlocked_by = { tec('ground-stone-tools'), tec('metal-working') },
		required_resource = { res('gems') },
		research_cost = 1.2
	}
	Technology:new {
		name = 'watchtowers',
		icon = 'watchtower.png',
		description = 'watchtowers',
		r = 0.74,
		g = 0.32,
		b = 0.923,
		required_biome = {},
		required_race = {},
		unlocked_by = { tec('dedicated-woodcutters') },
		research_cost = 0.055,
	}
	Technology:new {
		name = 'pottery',
		icon = 'powder.png',
		description = 'pottery',
		r = 0.23,
		g = 0.23,
		b = 0.23,
		unlocked_by = { tec('paleolithic-knowledge') },
		research_cost = 0.3,
		required_resource = { res('quality-clay') },
	}

end

return d
