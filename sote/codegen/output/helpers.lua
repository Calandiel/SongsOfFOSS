--- Helper functions to reduce key presses to type names of common wrappers

---Returns true if pop is a character
---@param pop_id pop_id
function IS_CHARACTER(pop_id)
	return DATA.pop_get_rank(pop_id) ~= CHARACTER_RANK.POP
end

---@param pop_id pop_id
function DEAD(pop_id)
	return DATA.pop_get_dead(pop_id)
end


---@class world_tile_id : number
---@field is_world_tile_id nil

---Returns province of a pop
---@param pop_id pop_id
---@return province_id
function PROVINCE(pop_id)
	-- assume that pop has location?
	local location_pop = DATA.pop_location_get_location(DATA.get_pop_location_from_pop(pop_id))
	local location_character = DATA.character_location_get_location(DATA.get_character_location_from_character(pop_id))

	if location_character ~= INVALID_ID then
		return location_character
	end
	if location_pop ~= INVALID_ID then
		return location_pop
	end

	return INVALID_ID
end

---commenting
---@param building_id building_id
---@return province_id
function BUILDING_PROVINCE(building_id)
	return DATA.building_location_get_location(DATA.get_building_location_from_building(building_id))
end

---commenting
---@param province province_id
---@return realm_id
function PROVINCE_REALM(province)
	local realm_membership = DATA.get_realm_provinces_from_province(province)
	return DATA.realm_provinces_get_realm(realm_membership)
end

---commenting
---@param pop_id pop_id
---@return number
function SAVINGS(pop_id)
	return DATA.pop_get_savings(pop_id)
end

---commenting
---@param pop_id pop_id
---@param trade_good trade_good_id
---@return number
function INVENTORY(pop_id, trade_good)
	return DATA.pop_get_inventory(pop_id, trade_good)
end

---commenting
---@param pop_id Character
---@return Character
function LOYAL_TO(pop_id)
	local loyalty = DATA.get_loyalty_from_bottom(pop_id)
	return DATA.loyalty_get_top(loyalty)
end


---Returns province of a pop
---@param pop_id pop_id
---@return province_id
function HOME(pop_id)
	-- assume that pop has location?
	local location_pop = DATA.get_home_from_pop(pop_id)
	return DATA.home_get_home(location_pop)
end

---Returns parent of a pop
---@param pop_id pop_id
---@return pop_id
function PARENT(pop_id)
	local parenthood = DATA.get_parent_child_relation_from_child(pop_id)
	return DATA.parent_child_relation_get_parent(parenthood)
end

function ACCEPT_ALL (item)
	return true
end

---Returns realm of a pop
---@param pop_id pop_id
function REALM(pop_id)
	local pop_realm = DATA.get_realm_pop_from_pop(pop_id)
	return DATA.realm_pop_get_realm(pop_realm)
end

---Returns local realm of a pop
---@param pop_id pop_id
function LOCAL_REALM(pop_id)
	local province = PROVINCE(pop_id)
	local realm_membership = DATA.get_realm_provinces_from_province(province)
	return DATA.realm_provinces_get_realm(realm_membership)
end

---Returns realm of a pop
---@param pop_id pop_id
---@return boolean
function BUSY(pop_id)
	return DATA.pop_get_busy(pop_id)
end

---@param pop_id pop_id
---@return number
function AGE(pop_id)
	return DATA.pop_get_age(pop_id)
end

---@param pop_id pop_id
function SET_BUSY(pop_id)
	DATA.pop_set_busy(pop_id, true)
end

---@param pop_id pop_id
function UNSET_BUSY(pop_id)
	DATA.pop_set_busy(pop_id, false)
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
	return DATA.realm_leadership_get_leader(leadership)
end

---commenting
---@param warband warband_id
---@return pop_id
function WARBAND_LEADER(warband)
	local leadership = DATA.get_warband_leader_from_warband(warband)
	return DATA.warband_leader_get_leader(leadership)
end

---commenting
---@param warband warband_id
---@return pop_id
function WARBAND_COMMANDER(warband)
	local leadership = DATA.get_warband_commander_from_warband(warband)
	return DATA.warband_commander_get_commander(leadership)
end

---commenting
---@param realm realm_id
---@return warband_id
function GUARD(realm)
	local guard = DATA.get_realm_guard_from_realm(realm)
	return DATA.realm_guard_get_guard(guard)
end

---commenting
---@param leader pop_id
---@return realm_id
function LEADER_OF(leader)
	local leadership = DATA.get_realm_leadership_from_leader(leader)
	return DATA.realm_leadership_get_warband(leadership)
end

---commenting
---@param leader pop_id
---@return warband_id
function LEADER_OF_WARBAND(leader)
	local leadership = DATA.get_warband_leader_from_leader(leader)
	return DATA.warband_leader_get_warband(leadership)
end

---commenting
---@param leader pop_id
---@return warband_id
function RECRUITER_OF_WARBAND(leader)
	local leadership = DATA.get_warband_recruiter_from_recruiter(leader)
	return DATA.warband_recruiter_get_warband(leadership)
end

---commenting
---@param unit pop_id
---@return warband_id
function UNIT_OF(unit)
	local unitship = DATA.get_warband_unit_from_unit(unit)
	return DATA.warband_unit_get_warband(unitship)
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
---@param province_id province_id
---@return string
function PROVINCE_NAME(province_id)
	return DATA.province_get_name(province_id)
end

---commenting
---@param realm_id realm_id
---@return string
function REALM_NAME(realm_id)
	return DATA.realm_get_name(realm_id)
end

---commenting
---@param pop_id pop_id
---@return race_id
function RACE(pop_id)
	return DATA.pop_get_race(pop_id)
end

---commenting
---@param pop_id pop_id
---@return Culture
function CULTURE(pop_id)
	return DATA.pop_get_culture(pop_id)
end

---@param pop_id pop_id
---@return fat_race_id
function F_RACE(pop_id)
	return DATA.fatten_race(RACE(pop_id))
end

---checks trait of character
---@param pop pop_id
---@param trait TRAIT
function HAS_TRAIT(pop, trait)
	for i = 1, MAX_TRAIT_INDEX  do
		if DATA.pop_get_traits(pop, i) == trait then
			return true
		end
	end
	return false
end

--- update these values when you change description in according generator descriptors

MAX_TRAIT_INDEX = 10
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
		assert(
			fat.trade_good ~= INVALID_ID,
			tostring(use_weight).. " " ..tostring(fat.trade_good).." " ..tostring( DATA.use_weight_get_trade_good(use_weight))
		)
		assert(
			fat.use_case ~= INVALID_ID,
			tostring(use_weight).." " ..tostring(fat.use_case).." " ..tostring(DATA.use_weight_get_use_case(use_weight))
		)
		USE_WEIGHT[fat.trade_good][fat.use_case] = fat.weight
	end)
end