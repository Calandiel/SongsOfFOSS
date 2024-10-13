local tabb = require "engine.table"

local values = {}


---commenting
---@param province_id Province
---@return Character
function values.sample_character_from_province(province_id)
	local characters = tabb.map_array(
		DATA.filter_character_location_from_location(province_id, ACCEPT_ALL),
		DATA.character_location_get_character
	)

	local amount = #characters
	if amount == 0 then
		return INVALID_ID
	end

	local sample_index = love.math.random(amount)
	return characters[sample_index]
end

return values