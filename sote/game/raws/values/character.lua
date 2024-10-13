local character_values = {}

---commenting
---@param character Character
---@return boolean
function character_values.is_traveller(character)
	for i = 0, MAX_TRAIT_INDEX do
		local trait = DATA.pop_get_traits(character, i)

		if trait == INVALID_ID then
			break
		end

		local traveller = DATA.trait_get_traveller(trait)

		if traveller > 0 then
			return true
		end
	end
	return false
end

---commenting
---@param character Character
---@return number
function character_values.admin_score(character)
	local total = 0
	for i = 0, MAX_TRAIT_INDEX do
		local trait = DATA.pop_get_traits(character, i)
		if trait == INVALID_ID then
			break
		end
		total = total + DATA.trait_get_admin(trait)
	end
	return total
end

---Modifies desired profit of characters
---@param character Character
---@return number
function character_values.profit_desire(character)
	local total = 0
	for i = 0, MAX_TRAIT_INDEX do
		local trait = DATA.pop_get_traits(character, i)
		if trait == INVALID_ID then
			break
		end
		total = total + DATA.trait_get_greed(trait)
	end
	return total
end

---Calculates travel speed of given character
---@param character Character
---@return fun(province: Province): number
function character_values.travel_speed(character)
	local total_weight = 1
	for good_name, amount in pairs(character.inventory) do
		-- TODO: implement weight of trade goods
		total_weight = total_weight + amount / 10
	end

	local total_hauling = character:job_efficiency(JOBTYPE.HAULING)

	local party = character.leading_warband

	if party then
		total_hauling = party:total_hauling()
	end

	local function speed(province)
		-- TODO: add adittional race variable which influences this base value
		---@type number
		local race_modifier = 1
		if character.race.requires_large_river and province.on_a_river then
			---@type number
			race_modifier = race_modifier * 5
		end
		if character.race.requires_large_river and province.on_a_forest then
			---@type number
			race_modifier = race_modifier * 2.5
		end
		return race_modifier * (1 + total_hauling / total_weight)
	end

	return speed
end

---Calculates travel speed of given race  \
-- Used for diplomatic actions when there is no moving character: only abstract "diplomat"  \
-- To be removed when we will have actual diplomats.
---@param race Race
---@return fun(province: Province): number
function character_values.travel_speed_race(race)
	local function speed(province)
		-- TODO: add adittional race variable which influences this base value
		---@type number
		local race_modifier = 1
		if race.requires_large_river and province.on_a_river then
			---@type number
			race_modifier = race_modifier * 2
		end
		if race.requires_large_river and province.on_a_forest then
			---@type number
			race_modifier = race_modifier * 1.5
		end
		return race_modifier
	end

	return speed
end

return character_values