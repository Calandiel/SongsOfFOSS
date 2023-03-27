local ut = require "game.map-modes.utils"
local pol = {}

function pol.diplomacy(clicked_tile_id)
	local clicked_tile = WORLD.tiles[clicked_tile_id]
	if clicked_tile then
		if clicked_tile.province then
			if clicked_tile.province.realm then
				local rr = clicked_tile.province.realm
				for _, tile in pairs(WORLD.tiles) do
					ut.set_default_color(tile)
					if tile.province ~= nil then
						if tile.province.realm ~= nil then
							if rr then
								if tile.province.realm == rr then
									tile:set_real_color(0, 1, 0)
									---@diagnostic disable-next-line: param-type-mismatch
								elseif tile.province.realm:at_war_with(rr) then
									tile:set_real_color(1, 0, 0)
								end
							end
						end
					end
				end
			end
		end
	else
		ut.clear_color()
	end
end

function pol.realms()
	for _, tile in pairs(WORLD.tiles) do
		ut.set_default_color(tile)
		if tile.province ~= nil then
			if tile.province.realm ~= nil then
				tile:set_real_color(
					tile.province.realm.r,
					tile.province.realm.g,
					tile.province.realm.b
				)
			end
		end
	end
end

function pol.province()
	for _, tile in pairs(WORLD.tiles) do
		ut.set_default_color(tile)
		if tile.province ~= nil then
			if tile.is_land then
				tile:set_real_color(tile.province.r, tile.province.g, tile.province.b)
			else
				tile:set_real_color(0.25 * tile.province.r, 0.25 * tile.province.g, 0.25 * tile.province.b)
			end
		end
	end
end

return pol
