local d = {}

function d.load()
	local TradeGood = require "game.raws.trade-goods"


	-- CAPACITIES
	TradeGood:new {
		name = 'administration',
		description = 'administration',
		icon = 'bookmarklet.png',
		r = 0.32,
		g = 0.42,
		b = 0.92,
		base_price = 1,
		category = 'capacity',
	}
	-- BASE GOODS
	TradeGood:new {
		name = 'food',
		description = 'food',
		icon = 'high-grass.png',
		r = 0.12,
		g = 0.12,
		b = 1,
		base_price = 2,
	}
	-- CRUCIAL SETTLEMENT SERVICES
	TradeGood:new {
		name = 'water',
		description = 'water',
		icon = 'droplets.png',
		r = 0.12,
		g = 1,
		b = 1,
		category = 'service',
		base_price = 0.75,
	}
	TradeGood:new {
		name = 'healthcare',
		description = 'healthcare',
		icon = 'health-normal.png',
		r = 0.683,
		g = 0.128,
		b = 0.974,
		category = 'service',
		base_price = 6,
	}
	TradeGood:new {
		name = 'amenities',
		description = 'amenities',
		icon = 'star-swirl.png',
		r = 0.32,
		g = 0.838,
		b = 0.38,
		category = 'service',
		base_price = 2,
	}
	-- POP NEEDS
	TradeGood:new {
		name = 'clothes',
		description = 'clothes',
		icon = 'kimono.png',
		r = 1,
		g = 0.6,
		b = 0.7,
		base_price = 15,
	}
	TradeGood:new {
		name = 'furniture',
		description = 'furniture',
		icon = 'wooden-chair.png',
		r = 0.5,
		g = 0.4,
		b = 0.1,
		base_price = 20,
	}
	TradeGood:new {
		name = 'liquors',
		description = 'liquors',
		icon = 'beer-stein.png',
		r = 0.7,
		g = 1,
		b = 0.3,
		base_price = 10,
	}
	TradeGood:new {
		name = 'containers',
		description = 'containers',
		icon = 'amphora.png',
		r = 0.34,
		g = 0.212,
		b = 1,
		base_price = 7,
	}
	-- TRADE GOODS
	TradeGood:new {
		name = 'hide',
		description = 'hide',
		icon = 'animal-hide.png',
		r = 1,
		g = 0.3,
		b = 0.3,
		base_price = 4,
	}
	TradeGood:new {
		name = 'leather',
		description = 'leather',
		icon = 'animal-hide.png',
		r = 1,
		g = 0.65,
		b = 0.65,
		base_price = 8,
	}
	TradeGood:new {
		name = 'meat',
		description = 'meat',
		icon = 'meat.png',
		r = 1,
		g = 0.1,
		b = 0.1,
		base_price = 8,
	}
	TradeGood:new {
		name = 'timber',
		description = 'timber',
		icon = 'wood-pile.png',
		r = 0.72,
		g = 0.41,
		b = 0.22,
		base_price = 5,
	}
	TradeGood:new {
		name = 'tools',
		description = 'tools',
		icon = 'stone-axe.png',
		r = 0.162,
		g = 0.141,
		b = 0.422,
		base_price = 8,
	}
	TradeGood:new {
		name = 'knapping-blanks',
		description = 'knapping blanks',
		icon = 'rock.png',
		r = 0.162,
		g = 0.141,
		b = 0.422,
		base_price = 6,
	}
	TradeGood:new {
		name = 'copper-bars',
		description = 'copper',
		icon = 'metal-bar.png',
		r = 0.71,
		g = 0.25,
		b = 0.05,
		base_price = 15
	}
	TradeGood:new {
		name = 'clay',
		description = 'clay',
		icon = 'powder.png',
		r = 0.262,
		g = 0.241,
		b = 0.222,
		base_price = 2,
	}

end

return d
