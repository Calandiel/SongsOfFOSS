local ge = {}

function ge.run()
	for _, res_id in pairs(RAWS_MANAGER.resources_by_name) do
		DCON.apply_resource(res_id - 1)
	end

	-- Write resources back on tiles for faster querying
	DATA.for_each_province(function (province)
		for _, tile_membership_id in pairs(DATA.get_tile_province_membership_from_province(province)) do
			local tile_id = DATA.tile_province_membership_get_tile(tile_membership_id)
			local res = DATA.tile_get_resource(tile_id)
			if res ~= INVALID_ID then
				-- add resource to province
				for i = 1, MAX_RESOURCES_IN_PROVINCE_INDEX - 1 do
					local ith_resource = DATA.province_get_local_resources_resource(province, i)
					if ith_resource == INVALID_ID then
						DATA.province_set_local_resources_location(province, i, tile_id)
						DATA.province_set_local_resources_resource(province, i, res)
						break
					end
				end
			end
		end
	end)
end

return ge
