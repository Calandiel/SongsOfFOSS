local character_values = {}

---Calculates travel speed of given character
---@param character Character
---@return fun(province: Province): number
function character_values.travel_speed(character)
	local total_weight = 1
	for good_name, amount in pairs(character.inventory) do
		-- TODO: implement weight of trade goods
		total_weight = total_weight + amount / 10
	end

	local function speed(province)
		-- TODO: add adittional race variable which influences this base value
		---@type number
		local race_modifier = 1
		if character.race.requires_large_river and province.on_a_river then
			---@type number
			race_modifier = race_modifier * 2
		end
		if character.race.requires_large_river and province.on_a_forest then
			---@type number
			race_modifier = race_modifier * 1.5
		end
		return race_modifier / total_weight
	end

	return speed
end

return character_values