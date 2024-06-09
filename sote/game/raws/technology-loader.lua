local d = {}

function d.load()
	if RAWS_MANAGER.do_logging then
		print()
		print("=== LOADING TECHS ===")
		print()
	end
	local Technology = require "game.raws.technologies"
	local met = require "game.raws.raws-utils".production_method
	local cat = require "game.raws.raws-utils".trade_category
	local tec = require "game.raws.raws-utils".technology
	local res = require "game.raws.raws-utils".resource
	local bio = require "game.raws.raws-utils".biome
	local prod = require "game.raws.raws-utils".production_method

	Technology:new {
		name = "paleolithic-knowledge",
		icon = "high-grass.png",
		description = "paleolithic knowledge",
		r = 1,
		g = 1,
		b = 1,
		required_biome = {},
		required_race = {},
		unlocked_by = {},
		research_cost = 0.2,
	}
	Technology:new {
		name = "vegetable-tanning",
		icon = "animal-hide.png",
		description = "vegetable tanning",
		r = 1,
		g = 1,
		b = 1,
		unlocked_by = { tec("paleolithic-knowledge") },
		research_cost = 0.2,
	}
	Technology:new {
		name = "ground-stone-tools",
		icon = "stone-stack.png",
		description = "ground stone tools",
		r = 1,
		g = 1,
		b = 1,
		unlocked_by = { tec("paleolithic-knowledge") },
		research_cost = 0.2,
		throughput_boosts = {
			[prod("blanks-knapping")] = 0.1,
		},
		input_efficiency_boosts = {
			[prod("blanks-knapping")] = 0.75,
		},
		output_efficiency_boosts = {
			[prod("flint-extraction")] = 1.25,
			[prod("obsidian-extraction")] = 1.25,
		}
	}
	Technology:new {
		name = "dedicated-woodcutters",
		icon = "stone-axe.png",
		description = "dedicated woodcutters",
		r = 1,
		g = 1,
		b = 1,
		unlocked_by = { tec("ground-stone-tools") },
		research_cost = 0.2,
	}
	Technology:new {
		name = "wooden-furniture",
		icon = "wooden-chair.png",
		description = "wooden furniture",
		r = 0.5,
		g = 1,
		b = 1,
		unlocked_by = { tec("dedicated-woodcutters") },
		research_cost = 0.25,
	}
	Technology:new {
		name = "pottery",
		icon = "powder.png",
		description = "pottery",
		r = 0.23,
		g = 0.23,
		b = 0.23,
		unlocked_by = { tec("paleolithic-knowledge") },
		research_cost = 0.3,
		required_resource = { res("quality-clay") },
	}
	Technology:new {
		name = "early-metal-working",
		icon = "gold-nuggets.png",
		description = "cold working of native metals",
		r = 1,
		g = 1,
		b = 1,
		unlocked_by = { tec("ground-stone-tools") },
		required_resource = { res("meteoric-iron"), res("native-copper"), res("native-gold") },
		research_cost = 0.25,
	}
	Technology:new {
		name = "agriculture",
		icon = "wheat.png",
		description = "agriculture",
		r = 0,
		g = 0.65,
		b = 0,
		required_biome = {},
		required_race = {},
		required_resource = {
			res("rye"),
			res("barley"),
			res("wheat"),
			res("yam"),
			res("rice"),
		},
		unlocked_by = { tec("paleolithic-knowledge") },
		throughput_boosts = {
			[prod("gathering-0")] = 0.15,
			[prod("gathering-1")] = 0.15,
			[prod("gathering-2")] = 0.15
		},
		research_cost = 0.15,
	}
	Technology:new {
		name = "selective-plant-breeding",
		icon = "plant-roots.png",
		description = "creation of better plant cultivars",
		r = love.math.random(),
		g = love.math.random(),
		b = love.math.random(),
		unlocked_by = { tec("agriculture"), },
		research_cost = 0.65,
	}
	Technology:new {
		name = "hoes",
		icon = "pitchfork.png",
		description = "better agricultural tools",
		r = love.math.random(),
		g = love.math.random(),
		b = love.math.random(),
		unlocked_by = { tec("agriculture"), },
		research_cost = 0.5,
	}
	Technology:new {
		name = "sickles",
		icon = "pitchfork.png",
		description = "better agricultural tools",
		r = love.math.random(),
		g = love.math.random(),
		b = love.math.random(),
		unlocked_by = { tec("agriculture"), },
		research_cost = 0.5,
	}
	Technology:new {
		name = "beekeeping",
		icon = "high-grass.png",
		description = "beekeeping",
		r = love.math.random(),
		g = love.math.random(),
		b = love.math.random(),
		unlocked_by = { tec("paleolithic-knowledge") },
		required_resource = { res("bees") },
		research_cost = 0.65,
	}
	Technology:new {
		name = "basic-fermentation",
		icon = "beer-stein.png",
		description = "fermenting things to create alcohol",
		r = love.math.random(),
		g = love.math.random(),
		b = love.math.random(),
		unlocked_by = { tec("agriculture"), },
		research_cost = 0.65,
	}
	Technology:new {
		name = "warm-fermentation",
		icon = "beer-stein.png",
		description = "ales created through warm fermentation",
		r = love.math.random(),
		g = love.math.random(),
		b = love.math.random(),
		unlocked_by = { tec("basic-fermentation"), },
		research_cost = 1,
		throughput_boosts = {
			[prod("brewing-grain")] = 0.15,
			[prod("brewing-fruit")] = 0.15
		},
	}
	Technology:new {
		name = "mead",
		icon = "beer-stein.png",
		description = "mead",
		r = love.math.random(),
		g = love.math.random(),
		b = love.math.random(),
		unlocked_by = { tec("basic-fermentation"), tec("beekeeping") },
		research_cost = 0.65,
	}
	Technology:new {
		name = "resin-glue",
		icon = "pine-tree.png",
		description = "glue",
		r = love.math.random(),
		g = love.math.random(),
		b = love.math.random(),
		unlocked_by = { tec("basic-fermentation"), tec("beekeeping") },
		required_biome = { bio("taiga"), bio("woodland-taiga"), bio("coniferous-forest"), bio("coniferous-woodland") },
		research_cost = 0.65,
	}
	Technology:new {
		name = "animal-glue",
		icon = "meat.png",
		description = "glue",
		r = love.math.random(),
		g = love.math.random(),
		b = love.math.random(),
		unlocked_by = { tec("paleolithic-knowledge") },
		required_biome = {},
		research_cost = 0.35,
	}
	Technology:new {
		name = "surface-mining",
		icon = "war-pick.png",
		description = "mining shallow deposits of minerals",
		r = 0.3,
		g = 0.01,
		b = 0.8,
		unlocked_by = { tec("early-metal-working"), tec("pottery") },
		required_resource = { res("copper"), },
		research_cost = 1
	}
	Technology:new {
		name = "metal-casting",
		icon = "anvil.png",
		description = "casting metals",
		r = 0.3,
		g = 0.01,
		b = 0.8,
		unlocked_by = { tec("surface-mining") },
		required_resource = { res("copper") },
		research_cost = 1
	}
	Technology:new {
		name = "bloomeries",
		icon = "anvil.png",
		description = "hammering bloom into metals",
		r = 0.3,
		g = 0.01,
		b = 0.8,
		unlocked_by = { tec("surface-mining"), tec("dedicated-woodcutters") },
		required_resource = { res("iron") },
		research_cost = 1
	}
	Technology:new {
		name = "dedicated-stonecutters",
		icon = "stone-block.png",
		description = "cutting stones makes them more useful",
		r = 0.72,
		g = 0.94,
		b = 1,
		unlocked_by = { tec("ground-stone-tools"), tec("dedicated-woodcutters") },
		required_resource = { res("stone"), res("gems") },
		research_cost = 1.2
	}
	Technology:new {
		name = "gem-cutting",
		icon = "gems.png",
		description = "cutting exotic gemstones to please the eye",
		r = 0.72,
		g = 0.94,
		b = 1,
		unlocked_by = { tec("dedicated-stonecutters"), tec("early-metal-working") },
		required_resource = { res("gems") },
		research_cost = 1.2
	}
	Technology:new {
		name = "jewelry",
		icon = "tribal-pendant.png",
		description = "making proper jewelry from precious metals",
		r = 0.3,
		g = 0.01,
		b = 0.8,
		unlocked_by = { tec("gem-cutting"), tec("early-metal-working") },
		required_resource = { res("gold"), res("silver") },
		research_cost = 1
	}
	Technology:new {
		name = "watchtowers",
		icon = "watchtower.png",
		description = "watchtowers",
		r = 0.74,
		g = 0.32,
		b = 0.923,
		required_biome = {},
		required_race = {},
		unlocked_by = { tec("dedicated-woodcutters") },
		research_cost = 0.055,
	}

	Technology:new {
		name = "pottery-wheel",
		icon = "amphora.png",
		description = "pottery-wheel",
		r = 0.23,
		g = 0.23,
		b = 0.23,
		unlocked_by = { tec("pottery"), tec("dedicated-woodcutters") },
		research_cost = 0.3,
		required_resource = { res("quality-clay") },
	}

	Technology:new {
		name = "advanced-metal-working",
		icon = "anvil.png",
		description = "working metals with high skill",
		r = 1,
		g = 1,
		b = 1,
		unlocked_by = { tec("metal-casting"), tec("bloomeries") },
		required_resource = {},
		research_cost = 0.5,
	}
	Technology:new {
		name = "alloys",
		icon = "metal-bar.png",
		description = "mixing metals into new subtances",
		r = 1,
		g = 1,
		b = 1,
		unlocked_by = { tec("metal-casting"), tec("bloomeries") },
		required_resource = { res("native-bronze") },
		research_cost = 0.5,
	}
	Technology:new {
		name = "electrum",
		icon = "gold-nuggets.png",
		description = "mixing gold and silver",
		r = 1,
		g = 1,
		b = 1,
		unlocked_by = { tec("alloys") },
		required_resource = { res("gold"), res("silver") },
		research_cost = 0.5,
	}
	Technology:new {
		name = "arsenical-bronze",
		icon = "metal-bar.png",
		description = "mixing arsenic and copper",
		r = 1,
		g = 1,
		b = 1,
		unlocked_by = { tec("alloys") },
		required_resource = { res("arsenic"), res("copper") },
		research_cost = 0.5,
	}
	Technology:new {
		name = "tin-bronze",
		icon = "metal-bar.png",
		description = "mixing tin and copper",
		r = 1,
		g = 1,
		b = 1,
		unlocked_by = { tec("arsenical-bronze") },
		required_resource = { res("tin"), res("copper") },
		research_cost = 0.5,
	}
	Technology:new {
		name = "brass",
		icon = "metal-bar.png",
		description = "mixing zinc and copper",
		r = 1,
		g = 1,
		b = 1,
		unlocked_by = { tec("alloys") },
		required_resource = { res("zinc"), res("copper") },
		research_cost = 0.5,
	}
	Technology:new {
		name = "coinage",
		icon = "two-coins.png",
		description = "standardized currency",
		r = 1,
		g = 1,
		b = 1,
		unlocked_by = { tec("electrum") },
		required_resource = {},
		research_cost = 0.5,
	}
	Technology:new {
		name = "plate-armor",
		icon = "asteroid.png",
		description = "armor out of proper advanced metals",
		r = 1,
		g = 1,
		b = 1,
		unlocked_by = { tec("alloys") },
		required_resource = {},
		research_cost = 0.25,
	}
	Technology:new {
		name = "brickmaking",
		icon = "cubes.png",
		description = "simple sun-fired bricks",
		r = love.math.random(),
		g = love.math.random(),
		b = love.math.random(),
		unlocked_by = { tec("dedicated-woodcutters"), tec("pottery") },
		research_cost = 1,
	}
	Technology:new {
		name = "kiln",
		icon = "painted-pottery.png",
		description = "kilns for mass firing of pottery and bricks",
		r = love.math.random(),
		g = love.math.random(),
		b = love.math.random(),
		unlocked_by = { tec("brickmaking"), },
		research_cost = 1,
	}
	Technology:new {
		name = "fire-setting-mining",
		icon = "campfire.png",
		description = "more efficieng mining",
		r = love.math.random(),
		g = love.math.random(),
		b = love.math.random(),
		unlocked_by = { tec("surface-mining"), },
		research_cost = 1,
	}
	Technology:new {
		name = "transformation-magic",
		icon = "e-tablet.png",
		description = "Druids across the world have endeavored to take power over their bodies. We have mastered their ways. No longer will we be bound to our original forms!",
		r = 1,
		g = 0,
		b = 1,
		-- unlocked_decisions = { dec("gender-bender"), },
		research_cost = 1,
	}
end

return d
