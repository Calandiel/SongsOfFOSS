--- Helper functions to reduce key presses to type names of common wrappers

---Returns true if pop is a character
---@param pop_id pop_id
function IS_CHARACTER(pop_id)
	return DATA.pop_get_rank(pop_id) ~= CHARACTER_RANK.POP
end

---@class world_tile_id : number
---@field is_world_tile_id nil

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

---commenting
---@param province province_id
---@return realm_id
function PROVINCE_REALM(province)
	local realm_membership = DATA.get_realm_provinces_from_province(province)
	if realm_membership == INVALID_ID then
		return INVALID_ID
	end
	return DATA.realm_provinces_get_realm(realm_membership)
end

---commenting
---@param pop_id Character
---@return Character
function LOYAL_TO(pop_id)
	local loyalty = DATA.get_loyalty_from_bottom(pop_id)
	if loyalty == INVALID_ID then
		return INVALID_ID
	end
	return DATA.loyalty_get_top(loyalty)
end


---Returns province of a pop
---@param pop_id pop_id
---@return province_id
function HOME(pop_id)
	-- assume that pop has location?
	local location_pop = DATA.get_home_from_pop(pop_id)

	if location_pop ~= INVALID_ID then
		return DATA.home_get_home(location_pop)
	end

	return INVALID_ID
end

---Returns parent of a pop
---@param pop_id pop_id
---@return pop_id
function PARENT(pop_id)
	local parenthood = DATA.get_parent_child_relation_from_child(pop_id)
	if parenthood == INVALID_ID then
		return INVALID_ID
	end
	return DATA.parent_child_relation_get_parent(parenthood)
end

function ACCEPT_ALL (item)
	return true
end

---Returns realm of a pop
---@param pop_id pop_id
function REALM(pop_id)
	local pop_realm = DATA.get_realm_pop_from_pop(pop_id)
	if pop_realm == INVALID_ID then
		return INVALID_ID
	else
		return DATA.realm_pop_get_realm(pop_realm)
	end
end

function LOCAL_REALM(pop_id)
	local province = PROVINCE(pop_id)
	if province == INVALID_ID then
		return INVALID_ID
	end

	local realm_membership = DATA.get_realm_provinces_from_province(province)

	if realm_membership == INVALID_ID then
		return INVALID_ID
	end

	return DATA.realm_provinces_get_realm(realm_membership)
end

---Returns realm of a pop
---@param pop_id pop_id
---@return boolean
function BUSY(pop_id)
	return DATA.pop_get_busy(pop_id)
end

---@param pop_id pop_id
---@param realm realm_id
function SET_REALM(pop_id, realm)
	local pop_realm = DATA.get_realm_pop_from_pop(pop_id)
	if pop_realm == INVALID_ID then
		DATA.force_create_realm_pop(realm, pop_id)
	else
		DATA.realm_pop_set_realm(pop_realm, realm)
	end
end

---commenting
---@param realm realm_id
---@return pop_id
function LEADER(realm)
	local leadership = DATA.get_realm_leadership_from_realm(realm)
	if leadership == INVALID_ID then
		return INVALID_ID
	end
	return DATA.realm_leadership_get_leader(leadership)
end

---@param pop_id pop_id
---@return CHARACTER_RANK
function RANK(pop_id)
	return DATA.pop_get_rank(pop_id)
end

---commenting
---@param realm realm_id
---@return province_id
function CAPITOL(realm)
	return DATA.realm_get_capitol(realm)
end

---commenting
---@param realm realm_id
---@return race_id
function MAIN_RACE(realm)
	return DATA.realm_get_primary_race(realm)
end

---commenting
---@param pop_id pop_id
---@return string
function NAME(pop_id)
	return DATA.pop_get_name(pop_id)
end

---commenting
---@param pop_id pop_id
---@return race_id
function RACE(pop_id)
	return DATA.pop_get_race(pop_id)
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