---Returns true if pop is a character
---@param pop_id pop_id
function IS_CHARACTER(pop_id)
	return DATA.pop_get_rank(pop_id) ~= CHARACTER_RANK.POP
end

---Returns province of a pop
---@param pop_id pop_id
---@return province_id
function PROVINCE(pop_id)
	-- assume that pop has location?
	local location_pop = DATA.get_pop_location_from_pop(pop_id)
	local location_character = DATA.get_character_location_from_character(pop_id)

	if location_pop ~= INVALID_ID then
		return DATA.pop_location_get_location(location_pop)
	end
	if location_character ~= INVALID_ID then
		return DATA.character_location_get_location(location_character)
	end

	return INVALID_ID
end

---Returns realm of a pop
---@param pop_id pop_id
function REALM(pop_id)
	return DATA.pop_get_realm(pop_id)
end

--- update these values when you change description in according generator descriptors


MAX_TRAIT_INDEX = 19
MAX_NEED_SATISFACTION_POSITIONS_INDEX = 19
MAX_RESOURCES_IN_PROVINCE_INDEX = 24
MAX_REQUIREMENTS_TECHNOLOGY = 20
MAX_REQUIREMENTS_BUILDING_TYPE = 20
MAX_REQUIREMENTS_RESOURCE = 20
MAX_SIZE_ARRAYS_PRODUCTION_METHOD = 8
INVALID_ID = 0

---@alias Character pop_id
---@alias POP pop_id
---@alias Province province_id
---@alias BuildingType building_type_id
---@alias Technology technology_id
---@alias Building building_id
---@alias Race race_id
---@alias Realm realm_id
---@alias Warband warband_id
---@alias Army army_id

---@type table<trade_good_id, table<use_case_id, number>>
USE_WEIGHT = {}

function RECALCULATE_WEIGHTS_TABLE()
	DATA.for_each_trade_good(function (trade_good)
		USE_WEIGHT[trade_good] = {}
		DATA.for_each_use_case(function (use_case)
			USE_WEIGHT[trade_good][use_case] = 0
		end)
	end)

	DATA.for_each_use_weight(function (use_weight)
		local fat = DATA.fatten_use_weight(use_weight)
		USE_WEIGHT[fat.trade_good][fat.use_case] = fat.weight
	end)
end