print("Loading raws...")

---A special function that sets up "raws" on the world
-- @param do_logging boolean|nil
return function(do_logging)
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
	for _, t in pairs(RAWS_MANAGER.technologies_by_name) do
		for _, tt in pairs(t.unlocked_by) do
			tt.potentially_unlocks[#tt.potentially_unlocks + 1] = t
		end
	end

	if do_logging then
		print('building types')
	end
	require "game.raws.building-types-loader".load()
	for _, b in pairs(RAWS_MANAGER.building_types_by_name) do
		b.unlocked_by.unlocked_buildings[#b.unlocked_by.unlocked_buildings + 1] = b
	end

	if do_logging then
		print('unit-types')
	end
	require "game.raws.unit-types-loader".load()
	for _, u in pairs(RAWS_MANAGER.unit_types_by_name) do
		u.unlocked_by.unlocked_unit_types[#u.unlocked_by.unlocked_unit_types + 1] = u
	end

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
