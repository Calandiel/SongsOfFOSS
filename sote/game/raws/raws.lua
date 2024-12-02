print("Loading raws...")

---A special function that sets up "raws" on the world
-- @param do_logging boolean|nil
return function(do_logging, load_save)
	if load_save then
		if do_logging then
			print('decisions')
		end
		require "game.raws.decisions-loader".load()

		if do_logging then
			print('events')
		end
		require "game.raws.events-loader".load()

		print('raws done')
		return
	end

	RAWS_MANAGER = require "game.entities.raws_manager":new()
	if do_logging ~= nil then
		RAWS_MANAGER.do_logging = do_logging
	end

	local Realm = require "game.raws.biogeographic-realms"
	local tabb = require "engine.table"

	print("Loading bedrocks")
	require "game.raws.bedrocks-loader".load()

	print("Loading biomes")
	require "game.raws.biomes-loader".load()
	Realm:new {
		name = "palearctic",
		r = 191,
		g = 89,
		b = 91,
	}

	print("Loading needs and goods")
	require "game.raws.use-case-loader".load()
	require "game.raws.trade-goods-loader".load()

	RECALCULATE_WEIGHTS_TABLE()

	print("Loading races")
	require "game.raws.race-loader".load()
	require "game.raws.jobs-loader".load()

	print("Loading resources")
	require 'game.raws.resource-loader'.load()

	print('Loading production methods')
	require "game.raws.production-methods-loader".load()

	require "game.raws.technology-loader".load()

	if do_logging then
		print('building types')
	end
	require "game.raws.building-types-loader".load()

	if do_logging then
		print('unit-types')
	end
	require "game.raws.unit-types-loader".load()

	if do_logging then
		print('decisions')
	end
	require "game.raws.decisions-loader".load()

	if do_logging then
		print('events')
	end
	require "game.raws.events-loader".load()

	print('raws done')
end
