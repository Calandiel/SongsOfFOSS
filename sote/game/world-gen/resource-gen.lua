local tabb = require "engine.table"
local tile = require "game.entities.tile"

local ge = {}

function ge.run()
	for _, tile_id in pairs(WORLD.tiles) do
		for _, res in pairs(RAWS_MANAGER.resources_by_name) do
			if DATA.tile_get_is_land(tile_id) then
				if not res.land then
					goto NEXT
				end
			else
				if not res.water then
					goto NEXT
				end
			end
			if res.coastal and not tile.is_coast(tile_id) then
				goto NEXT
			end
			if tabb.size(res.required_bedrock) > 0 then
				if not tabb.contains(res.required_bedrock, DATA.tile_get_bedrock(tile_id)) then
					goto NEXT
				end
			end
			if tabb.size(res.required_biome) > 0 then
				if not tabb.contains(res.required_biome, DATA.tile_get_biome(tile_id)) then
					goto NEXT
				end
			end

			local elevation = DATA.tile_get_elevation(tile_id)
			if elevation < res.minimum_elevation or elevation > res.maximum_elevation then
				goto NEXT
			end

			local conifers = DATA.tile_get_conifer(tile_id)
			local broadleaf = DATA.tile_get_broadleaf(tile_id)
			local total = conifers + broadleaf

			if total < res.minimum_trees or total > res.maximum_trees then
				goto NEXT
			end
			if res.ice_age then
				if DATA.tile_get_ice_age_ice(tile_id) == 0 then
					goto NEXT
				end
			end

			--
			local chance = 1.0 / res.base_frequency
			if love.math.random() < chance then
				DATA.tile_set_resource(tile_id, res);
				break
			end
			::NEXT::
		end
	end
	-- Write resources back on tiles for faster querying
	for _, province in pairs(WORLD.provinces) do
		for _, tile_id in pairs(province.tiles) do
			local resource = DATA.tile_get_resource(tile_id)
			if resource then
				province.local_resources[resource] = resource
				table.insert(province.local_resources_location,
					{
						tile_id, resource
					}
				)
			end
		end
	end
end

return ge
