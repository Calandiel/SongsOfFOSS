local pop_utils = require "game.entities.pop".POP
local warband_utils = require "game.entities.warband"

local army_utils = {}

---@param army army_id
---@return number
function army_utils.get_visibility(army)
	local vis = 0
	for _, army_membership in pairs(DATA.get_army_membership_from_army(army)) do
		local warband = DATA.army_membership_get_member(army_membership)

		vis = vis + warband_utils.visibility(warband)
	end
	return vis
end

---@param army army_id
---@return number
function army_utils.size(army)
	local result = 0
	for _, army_membership in pairs(DATA.get_army_membership_from_army(army)) do
		local warband = DATA.army_membership_get_member(army_membership)
		result = result + warband_utils.size(warband)
	end
	return result
end

---@param army army_id
---@return number
function army_utils.loot_capacity(army)
	local cap = 0
	for _, army_membership in pairs(DATA.get_army_membership_from_army(army)) do
		local warband = DATA.army_membership_get_member(army_membership)

		cap = cap + warband_utils.loot_capacity(warband)
	end
	return cap
end

---Kill everyone in the army
---@param army army_id
function army_utils.decimate(army)
	for _, army_membership in pairs(DATA.get_army_membership_from_army(army)) do
		local warband = DATA.army_membership_get_member(army_membership)
		warband_utils.decimate(warband)
	end
end

---Returns the pop membership in the army
---@param army army_id
---@return warband_unit_id[]
function army_utils.pops(army)
	local res = {}
	for _, army_membership in pairs(DATA.get_army_membership_from_army(army)) do
		for _, unit in pairs(DATA.get_warband_unit_from_warband(DATA.army_membership_get_member(army_membership))) do
			table.insert(res, unit)
		end
	end
	return res
end

return army_utils
