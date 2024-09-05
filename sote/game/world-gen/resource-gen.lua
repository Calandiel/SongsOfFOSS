local tabb = require "engine.table"
local tile = require "game.entities.tile"

local ge = {}

function ge.run()
	DATA.for_each_tile(function (tile_id)
		for _, res_id in pairs(RAWS_MANAGER.resources_by_name) do
			local res = DATA.fatten_resource(res_id)
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
			do
				local ok = true
				for i = 0, MAX_REQUIREMENTS_RESOURCE - 1 do
					local requirement = DATA.resource_get_required_bedrock(res_id, i)
					if requirement == INVALID_ID then
						break
					end
					ok = false
					if requirement == DATA.tile_get_bedrock(tile_id) then
						ok = true
						break
					end
				end
				if not ok then
					goto NEXT
				end
			end

			do
				local ok = true
				for i = 0, MAX_REQUIREMENTS_RESOURCE - 1 do
					local requirement = DATA.resource_get_required_biome(res_id, i)
					if requirement == INVALID_ID then
						break
					end
					ok = false
					if requirement == DATA.tile_get_biome(tile_id) then
						ok = true
						break
					end
				end
				if not ok then
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
				DATA.tile_set_resource(tile_id, res_id);
				break
			end
			::NEXT::
		end
	end)
	-- Write resources back on tiles for faster querying
	DATA.for_each_province(function (province)
		for _, tile_membership_id in pairs(DATA.get_tile_province_membership_from_province(province)) do
			local tile_id = DATA.tile_province_membership_get_tile(tile_membership_id)
			local res = DATA.tile_get_resource(tile_id)
			if res ~= INVALID_ID then
				-- add resource to province
				for i = 0, MAX_RESOURCES_IN_PROVINCE_INDEX - 1 do
					local ith_resource = DATA.province_get_local_resources_resource(province, i)
					if ith_resource == INVALID_ID then
						DATA.province_set_local_resources_location(province, i, tile_id)
						DATA.province_set_local_resources_resource(province, i, res)
					end
				end
			end
		end
	end)
end

return ge
