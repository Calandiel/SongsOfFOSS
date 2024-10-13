local tabb = require "engine.table"

local realm_utils = require "game.entities.realm".Realm
local province_utils = require "game.entities.province".Province


local values = {}

---commenting
---@param realm realm_id
---@return realm_id
function values.sample_tributary(realm)
	local tributaries = DATA.filter_array_realm_subject_relation_from_overlord(realm, ACCEPT_ALL)
	local count = #tributaries
	if count == 0 then
		return INVALID_ID
	end
	return tributaries[love.math.random(count)]
end

return values