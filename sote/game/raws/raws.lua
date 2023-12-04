print("Loading raws...")

---A special function that sets up "raws" on the world
return function()
	RAWS_MANAGER = require "game.entities.raws_manager":new()

	local Realm = require "game.raws.biogeographic-realms"
	local tabb = require "engine.table"

	require "game.raws.bedrocks-loader".load()
	require "game.raws.biomes-loader".load()
	Realm:new {
		name = "palearctic",
		r = 191,
		g = 89,
		b = 91,
	}
	require "game.raws.needs"
	require "game.raws.race-loader".load()
	require "game.raws.jobs-loader".load()
	require "game.raws.trade-goods-loader".load()

	require 'game.raws.resource-loader'.load()

	print('production methods')
	require "game.raws.production-methods-loader".load()

	require "game.raws.technology-loader".load()
	for _, t in pairs(RAWS_MANAGER.technologies_by_name) do
		for _, tt in pairs(t.unlocked_by) do
			tt.potentially_unlocks[#tt.potentially_unlocks + 1] = t
		end
	end

	print('building types')
	require "game.raws.building-types-loader".load()
	for _, b in pairs(RAWS_MANAGER.building_types_by_name) do
		b.unlocked_by.unlocked_buildings[#b.unlocked_by.unlocked_buildings + 1] = b
	end

	print('unit-types')
	require "game.raws.unit-types-loader".load()
	for _, u in pairs(RAWS_MANAGER.unit_types_by_name) do
		u.unlocked_by.unlocked_unit_types[#u.unlocked_by.unlocked_unit_types + 1] = u
	end

	print('decisions')
	require "game.raws.decisions-loader".load()

	print('events')
	require "game.raws.events-loader".load()

	print('raws done')
end
