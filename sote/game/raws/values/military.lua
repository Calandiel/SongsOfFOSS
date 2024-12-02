local character_values = require "game.raws.values.character"
local warband_utils = require "game.entities.warband"

local military_values = {}

---Returns scalar field representing how fast army can move in this province
---@param army Army
---@return province_scalar_field
function military_values.army_speed(army)
    -- speed is a minimal speed across all warbands
	return function(province)
		local speed = 1
		DATA.for_each_army_membership_from_army(army, function (item)
			local warband = DATA.army_membership_get_member(item)
			local speed_warband = military_values.warband_speed(warband)(province)
			if speed == nil or speed > speed_warband then
				speed = speed_warband
			end
		end)
		return speed
	end
end

---Returns scalar field representing how fast warband can move in this province
---@param warband Warband
---@return province_scalar_field
function military_values.warband_speed(warband)
    -- speed is a minimal speed across all warbands
	return function(province)
		local leader = warband_utils.active_leader(warband)
		if leader == INVALID_ID then
			return 0
		end
		local speed = character_values.travel_speed(leader)(province)
		DATA.for_each_warband_unit_from_warband(warband, function (item)
			local pop = DATA.warband_unit_get_unit(item)
			local speed_pop = character_values.travel_speed(pop)(province)
			if speed > speed_pop then
				speed = speed_pop
			end
		end)
		return speed
	end
end

return military_values