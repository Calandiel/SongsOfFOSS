local d = {}

function d.load()
	local TradeGoodUseCase = require "game.raws.trade-goods-use-case"

	---commenting
	---@param name string
	---@param description string
	---@param icon string
	---@param r number
	---@param g number
	---@param b number
	local function make_use_case(name, description, icon, r, g, b)
		TradeGoodUseCase:new {
			name = name,
			description = description,
			icon = icon,
			r = r,
			g = g,
			b = b,
		}
	end

	make_use_case("administration", "administration", "bookmarklet.png", 0.32, 0.42, 0.92)
	make_use_case("food", "food", "high-grass.png", 0.12, 0.12, 1)
	make_use_case("water", "water", "droplets.png", 0.12, 1, 1)
	make_use_case("healthcare", "healthcare", "health-normal.png", 0.683, 0.128, 0.974)
	make_use_case("amenities", "amenities", "star-swirl.png", 0.32, 0.838, 0.38)
	make_use_case("clothes", "clothes", "kimono.png", 1, 0.6, 0.7)
	make_use_case("furniture", "furniture", "wooden-chair.png", 0.5, 0.4, 0.1)
	make_use_case("liquors", "liquors", "beer-stein.png", 0.7, 1, 0.3)
	make_use_case("containers", "containers", "amphora.png", 0.34, 0.212, 1)
	make_use_case("hide", "hide", "animal-hide.png", 1, 0.3, 0.3)
	make_use_case("leather", "leather", "animal-hide.png", 1, 0.65, 0.65)
	make_use_case("meat", "meat", "meat.png", 1, 0.1, 0.1)
	make_use_case("timber", "timber", "wood-pile.png", 0.72, 0.41, 0.22)
	make_use_case("mead-substrate", "ingredients in mead production", "high-grass.png", 0.32, 0.42, 0.92)

	-- tools
	make_use_case("tools-like", "tools", "stone-axe.png", 0.162, 0.141, 0.422)
	make_use_case("tools", "tools", "stone-axe.png", 0.162, 0.141, 0.422)
	make_use_case("tools-advanced", "tools", "stone-axe.png", 0.162, 0.141, 0.422)

	-- stone tools materials
	make_use_case("blanks-flint", "flint blanks", "rock.png", 0.162, 0.141, 0.422)
	make_use_case("blanks-obsidian", "obsidian blanks", "rock.png", 0.162, 0.141, 0.422)

	-- copper chain materials
	make_use_case("copper-bars", "copper", "metal-bar.png", 0.71, 0.25, 0.05)
	make_use_case("copper-source", "copper-source", "ore.png", 0.71, 0.25, 0.05)
	make_use_case("copper-native", "copper-native", "ore.png", 0.71, 0.25, 0.05)

	-- structural materials
	make_use_case("structural-material", "structural-material", "stone-block.png", 0.262, 0.241, 0.222)

	make_use_case("stone", "stone", "stone-block.png", 0.262, 0.241, 0.222)
	make_use_case("clay", "clay", "powder.png", 0.262, 0.241, 0.222)
end

return d
