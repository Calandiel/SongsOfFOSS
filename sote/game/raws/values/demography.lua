local tabb = require "engine.table"

local values = {}


---commenting
---@param province_id Province
---@return Character|nil
function values.sample_character_from_province(province_id)
	local characters = tabb.map_array(
		DATA.filter_array_character_location_from_location(province_id, ACCEPT_ALL),
		DATA.character_location_get_character
	)

	local amount = #characters
	if amount == 0 then
		return nil
	end

	local sample_index = love.math.random(amount)
	return characters[sample_index]
end


---all characters are pops
---@param province_id Province
---@return pop_id|nil
function values.sample_pop_from_province(province_id)
	local pops = tabb.map_array(
		DATA.filter_array_pop_location_from_location(province_id, ACCEPT_ALL),
		DATA.pop_location_get_pop
	)

	local amount = #pops
	if amount == 0 then
		return nil
	end

	local sample_index = love.math.random(amount)
	return pops[sample_index]
end

---all characters are pops
---@param province_id Province
---@return pop_id|nil
function values.sample_non_character_pop_from_province(province_id)
	local pops = tabb.map_array(
		DATA.filter_array_pop_location_from_location(province_id, function (item)
			local pop = DATA.pop_location_get_pop(item)
			if IS_CHARACTER(pop) then
				return false
			end
			return true
		end),
		DATA.pop_location_get_pop
	)

	local amount = #pops
	if amount == 0 then
		return nil
	end

	local sample_index = love.math.random(amount)
	return pops[sample_index]
end

return values