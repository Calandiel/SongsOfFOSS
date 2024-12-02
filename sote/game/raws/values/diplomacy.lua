local tabb = require "engine.table"

local realm_utils = require "game.entities.realm".Realm
local province_utils = require "game.entities.province".Province


local values = {}

---commenting
---@param realm realm_id
---@return realm_id|nil
function values.sample_tributary(realm)
	local tributaries = DATA.filter_array_realm_subject_relation_from_overlord(realm, ACCEPT_ALL)
	local count = #tributaries
	if count == 0 then
		return nil
	end
	return tributaries[love.math.random(count)]
end

---commenting
---@param realm Realm
---@param province Province
---@return boolean
function values.province_pays_taxes(realm, province)
	local target_realm = PROVINCE_REALM(province)

	if target_realm == INVALID_ID then
		return false
	end

	local result = false

	DATA.for_each_realm_subject_relation_from_overlord(realm, function (item)
		local subject = DATA.realm_subject_relation_get_subject(item)
		if DATA.realm_subject_relation_get_wealth_transfer(item) then
			result = true
		end
	end)

	return result
end

return values