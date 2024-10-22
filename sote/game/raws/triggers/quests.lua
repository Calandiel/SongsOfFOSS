local triggers = {}

---commenting
---@param realm Realm
---@param target Province
---@return boolean
function triggers.eligible_for_exploration(realm, target)
	if PROVINCE_REALM(target) == INVALID_ID then
		return false
	end

	local eligible = false
	DATA.for_each_province_neighborhood_from_origin(target, function (item)
		local n = DATA.province_neighborhood_get_target(item)

		if DATA.realm_get_known_provinces(realm)[n] == nil then
			eligible = true
		end
	end)

	return eligible
end

return triggers