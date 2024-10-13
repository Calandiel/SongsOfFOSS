local values = {}

---commenting
---@param realm Realm
---@return Character
function values.overseer(realm)
	local overseer = DATA.get_realm_overseer_from_realm(realm)
	if overseer == INVALID_ID then
		return INVALID_ID
	end
	return DATA.realm_overseer_get_overseer(overseer)
end

---commenting
---@param realm Realm
---@return integer
function values.count_collectors(realm)
	local count = 0

	DATA.for_each_tax_collector_from_realm(realm, function (item)
		count = count + 1
	end)

	return count
end

return values