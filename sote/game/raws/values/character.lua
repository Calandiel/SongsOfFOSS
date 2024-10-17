local pop_utils = require "game.entities.pop".POP
local warband_utils = require "game.entities.warband"

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

---commenting
---@param character Character
---@return number
function character_values.ambition_score(character)
	local total = 0
	for i = 0, MAX_TRAIT_INDEX do
		local trait = DATA.pop_get_traits(character, i)
		if trait == INVALID_ID then
			break
		end
		total = total + DATA.trait_get_ambition(trait)
	end
	return total
end

---commenting
---@param character Character
---@return number
function character_values.aggression_score(character)
	local total = 0
	for i = 0, MAX_TRAIT_INDEX do
		local trait = DATA.pop_get_traits(character, i)
		if trait == INVALID_ID then
			break
		end
		total = total + DATA.trait_get_aggression(trait)
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

	DATA.for_each_trade_good(function (item)
		-- TODO: implement weight of trade goods
		total_weight = total_weight + DATA.pop_get_inventory(character, item) / 10
	end)

	local total_hauling = pop_utils.job_efficiency(character, JOBTYPE.HAULING)

	local party = DATA.get_warband_leader_from_leader(character)

	if party ~= INVALID_ID then
		total_hauling = warband_utils.total_hauling(DATA.warband_leader_get_warband(party))
	end

	local function speed(province)
		-- TODO: add adittional race variable which influences this base value
		---@type number
		local race_modifier = 1
		local race = DATA.pop_get_race(character)
		local river_fast = DATA.race_get_requires_large_river(race)
		local forest_fast = DATA.race_get_requires_large_forest(race)

		if river_fast and province.on_a_river then
			---@type number
			race_modifier = race_modifier * 5
		end
		if forest_fast and province.on_a_forest then
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
		local river_fast = DATA.race_get_requires_large_river(race)
		local forest_fast = DATA.race_get_requires_large_forest(race)

		if river_fast and province.on_a_river then
			---@type number
			race_modifier = race_modifier * 5
		end
		if forest_fast and province.on_a_forest then
			---@type number
			race_modifier = race_modifier * 2.5
		end
		return race_modifier
	end

	return speed
end

return character_values