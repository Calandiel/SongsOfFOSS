local tabb = require "engine.table"

local ge = {}

function ge.run()
	for _, tile in pairs(WORLD.tiles) do
		for _, res in pairs(RAWS_MANAGER.resources_by_name) do
			if tile.is_land then
				if not res.land then
					goto NEXT
				end
			else
				if not res.water then
					goto NEXT
				end
			end
			if res.coastal and not tile:is_coast() then
				goto NEXT
			end
			if tabb.size(res.required_bedrock) > 0 then
				if not tabb.contains(res.required_bedrock, tile.bedrock) then
					goto NEXT
				end
			end
			if tabb.size(res.required_biome) > 0 then
				if not tabb.contains(res.required_biome, tile.biome) then
					goto NEXT
				end
			end
			if tile.elevation < res.minimum_elevation or tile.elevation > res.maximum_elevation then
				goto NEXT
			end
			if tile.conifer + tile.broadleaf < res.minimum_trees or tile.conifer + tile.broadleaf > res.maximum_trees then
				goto NEXT
			end
			if res.ice_age then
				if tile.ice_age_ice == 0 then
					goto NEXT
				end
			end

			--
			local chance = 1.0 / res.base_frequency
			if love.math.random() < chance then
				tile.resource = res
				break
			end
			::NEXT::
		end
	end
	-- Write resources back on tiles for faster querying
	for _, province in pairs(WORLD.provinces) do
		for _, tile in pairs(province.tiles) do
			local resource = tile.resource
			if resource then
				province.local_resources[resource] = resource
				table.insert(province.local_resources_location,
					{
						tile, resource
					}
				)
			end
		end
	end
end

return ge
