local character_values = require "game.raws.values.character"

local military_values = {}

---Returns scalar field representing how fast army can move in this province
---@param army Army
---@return province_scalar_field
function military_values.army_speed(army)
    -- speed is a minimal speed across all warbands
	return function(province)
		local speed = 1
		for _, warband in pairs(army.warbands) do
			local speed_warband = military_values.warband_speed(warband)(province)
			if speed == nil or speed > speed_warband then
				speed = speed_warband
			end
		end
		return speed
	end
end

---Returns scalar field representing how fast warband can move in this province
---@param warband Warband
---@return province_scalar_field
function military_values.warband_speed(warband)
    -- speed is a minimal speed across all warbands
	return function(province)
		local speed = character_values.travel_speed(warband.leader)(province)
		for _, pop in pairs(warband.pops) do
			local speed_pop = character_values.travel_speed(pop)(province)
			if speed > speed_pop then
				speed = speed_pop
			end
		end
		return speed
	end
end

return military_values