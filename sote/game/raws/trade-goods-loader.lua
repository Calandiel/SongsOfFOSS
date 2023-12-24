local d = {}

function d.load()
	local TradeGood = require "game.raws.trade-goods"
	local good = require "game.raws.raws-utils".trade_good
	local use_case = require "game.raws.raws-utils".trade_good_use_case

	---Adds a trade good to a use case
	---@param trade_good TradeGoodReference
	---@param trade_good_use_case string
	---@param weight number
	local function add_use_case(trade_good, trade_good_use_case, weight)
		local retrieved_use_case = use_case(trade_good_use_case)
		local retrieved_trade_good = good(trade_good)

		retrieved_use_case.goods[trade_good] = weight
		retrieved_trade_good.use_cases[trade_good_use_case] = weight
	end


	-- CAPACITIES
	TradeGood:new {
		name = "administration",
		description = "administration",
		icon = "bookmarklet.png",
		r = 0.32,
		g = 0.42,
		b = 0.92,
		base_price = 1,
		category = "capacity",
	}
	add_use_case("administration", "administration", 1)
	-- BASE GOODS
	TradeGood:new {
		name = "food",
		description = "food",
		icon = "high-grass.png",
		r = 0.12,
		g = 0.12,
		b = 1,
		category = "good",
		base_price = 2,
	}
	add_use_case("food", "food", 1)
	-- CRUCIAL SETTLEMENT SERVICES
	TradeGood:new {
		name = "water",
		description = "water",
		icon = "droplets.png",
		r = 0.12,
		g = 1,
		b = 1,
		category = "service",
		base_price = 0.01,
	}
	add_use_case("water", "water", 1)
	TradeGood:new {
		name = "healthcare",
		description = "healthcare",
		icon = "health-normal.png",
		r = 0.683,
		g = 0.128,
		b = 0.974,
		category = "service",
		base_price = 6,
	}
	add_use_case("healthcare", "healthcare", 1)
	TradeGood:new {
		name = "amenities",
		description = "amenities",
		icon = "star-swirl.png",
		r = 0.32,
		g = 0.838,
		b = 0.38,
		category = "service",
		base_price = 2,
	}
	add_use_case("amenities", "amenities", 1)
	-- POP NEEDS
	TradeGood:new {
		name = "clothes",
		description = "clothes",
		icon = "kimono.png",
		r = 1,
		g = 0.6,
		b = 0.7,
		base_price = 15,
	}
	add_use_case("clothes", "clothes", 1)
	TradeGood:new {
		name = "furniture",
		description = "furniture",
		icon = "wooden-chair.png",
		r = 0.5,
		g = 0.4,
		b = 0.1,
		base_price = 20,
	}
	add_use_case("furniture", "furniture", 1)
	TradeGood:new {
		name = "liquors",
		description = "liquors",
		icon = "beer-stein.png",
		r = 0.7,
		g = 1,
		b = 0.3,
		base_price = 10,
	}
	add_use_case("liquors", "liquors", 1)
	TradeGood:new {
		name = "containers",
		description = "containers",
		icon = "amphora.png",
		r = 0.34,
		g = 0.212,
		b = 1,
		base_price = 7,
	}
	add_use_case("containers", "containers", 1)
	-- TRADE GOODS
	TradeGood:new {
		name = "hide",
		description = "hide",
		icon = "animal-hide.png",
		r = 1,
		g = 0.3,
		b = 0.3,
		base_price = 4,
	}
	add_use_case("hide", "hide", 1)
	TradeGood:new {
		name = "leather",
		description = "leather",
		icon = "animal-hide.png",
		r = 1,
		g = 0.65,
		b = 0.65,
		base_price = 8,
	}
	add_use_case("leather", "containers", 0.1)
	add_use_case("leather", "leather", 1)
	TradeGood:new {
		name = "meat",
		description = "meat",
		icon = "meat.png",
		r = 1,
		g = 0.1,
		b = 0.1,
		base_price = 6,
	}
	add_use_case("meat", "meat", 1)
	TradeGood:new {
		name = "timber",
		description = "timber",
		icon = "wood-pile.png",
		r = 0.72,
		g = 0.41,
		b = 0.22,
		base_price = 5,
	}
	add_use_case("timber", "containers", 0.1)
	add_use_case("timber", "timber", 1)

	TradeGood:new {
		name = "blanks-flint",
		description = "flint blanks",
		icon = "rock.png",
		r = 0.162,
		g = 0.141,
		b = 0.422,
		base_price = 6,
	}

	add_use_case("blanks-flint", "tools-like", 0.5)
	add_use_case("blanks-flint", "blanks-flint", 1)

	TradeGood:new {
		name = "blanks-obsidian",
		description = "obsidian blanks",
		icon = "rock.png",
		r = 0.1,
		g = 0.1,
		b = 0.1,
		base_price = 6,
	}

	add_use_case("blanks-obsidian", "tools-like", 0.4)
	add_use_case("blanks-obsidian", "blanks-obsidian", 1)


	TradeGood:new {
		name = "tools-flint",
		description = "flint tools",
		icon = "stone-axe.png",
		r = 0.162,
		g = 0.141,
		b = 0.422,
		base_price = 8,
	}

	add_use_case("tools-flint", "tools-like", 1.5)
	add_use_case("tools-flint", "tools", 1)
	add_use_case("tools-flint", "tools-advanced", 0.3)

	TradeGood:new {
		name = "tools-obsidian",
		description = "obsidian tools",
		icon = "stone-axe.png",
		r = 0.1,
		g = 0.1,
		b = 0.1,
		base_price = 8,
	}
	add_use_case("tools-obsidian", "tools-like", 1.4)
	add_use_case("tools-obsidian", "tools", 0.9)
	add_use_case("tools-obsidian", "tools-advanced", 0.2)

	TradeGood:new {
		name = "tools-native-copper",
		description = "native copper tools",
		icon = "stone-axe.png",
		r = 0.71,
		g = 0.25,
		b = 0.05,
		base_price = 8,
	}

	add_use_case("tools-native-copper", "tools-like", 3)
	add_use_case("tools-native-copper", "tools", 2)
	add_use_case("tools-native-copper", "tools-advanced", 1.5)

	TradeGood:new {
		name = "tools-cast-copper",
		description = "cast copper tools",
		icon = "stone-axe.png",
		r = 0.71,
		g = 0.25,
		b = 0.05,
		base_price = 8,
	}

	add_use_case("tools-cast-copper", "tools-like", 2)
	add_use_case("tools-cast-copper", "tools", 1.5)
	add_use_case("tools-cast-copper", "tools-advanced", 1)

	TradeGood:new {
		name = "copper-bars",
		description = "copper",
		icon = "metal-bar.png",
		r = 0.71,
		g = 0.25,
		b = 0.05,
		base_price = 15
	}
	add_use_case("copper-bars", "copper-bars", 1)

	TradeGood:new {
		name = "copper-ore",
		description = "copper ore",
		icon = "ore.png",
		r = 0.71,
		g = 0.25,
		b = 0.05,
		base_price = 15
	}
	add_use_case("copper-ore", "copper-source", 1)

	TradeGood:new {
		name = "copper-native",
		description = "native copper",
		icon = "ore.png",
		r = 0.71,
		g = 0.25,
		b = 0.05,
		base_price = 15
	}
	add_use_case("copper-native", "copper-source", 1)
	add_use_case("copper-native", "copper-native", 1)


	TradeGood:new {
		name = "clay",
		description = "clay",
		icon = "powder.png",
		r = 0.262,
		g = 0.241,
		b = 0.222,
		base_price = 2,
	}
	add_use_case("clay", "clay", 1)
	add_use_case("clay", "structural-material", 1)

	TradeGood:new {
		name = "stone",
		description = "stone",
		icon = "stone-block.png",
		r = 0.8,
		g = 0.8,
		b = 0.8,
		base_price = 2,
	}
	add_use_case("stone", "stone", 1)
	add_use_case("stone", "structural-material", 1)
end

return d
