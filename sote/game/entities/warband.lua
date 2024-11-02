local tabb = require "engine.table"
local pop_utils = require "game.entities.pop".POP

local warband_utils = {}

---Returns a list of all officers
---@param warband warband_id
---@return table<Character, Character> officers
function warband_utils.get_officers(warband)
	---@type table<Character, Character>
	local officers = {}
	local leader_link = DATA.get_warband_leader_from_warband(warband)
	local commander_link = DATA.get_warband_commander_from_warband(warband)
	local recruiter_link = DATA.get_warband_recruiter_from_warband(warband)

	if leader_link then
		local leader = DATA.warband_leader_get_leader(leader_link)
		officers[leader] = leader
	end
	if commander_link then
		local commander = DATA.warband_commander_get_commander(commander_link)
		officers[commander] = commander
	end
	if recruiter_link then
		local recruiter = DATA.warband_recruiter_get_recruiter(recruiter_link)
		officers[recruiter] = recruiter
	end
	return officers
end

---Returns a the highest ranking officer
---@param warband warband_id
---@return Character officer
function warband_utils.active_leader(warband)
	local leader_link = DATA.get_warband_leader_from_warband(warband)
	local commander_link = DATA.get_warband_commander_from_warband(warband)
	local recruiter_link = DATA.get_warband_recruiter_from_warband(warband)

	if leader_link then
		local leader = DATA.warband_leader_get_leader(leader_link)
		return leader
	end

	if recruiter_link then
		local recruiter = DATA.warband_recruiter_get_recruiter(recruiter_link)
		return recruiter
	end

	if commander_link then
		local commander = DATA.warband_commander_get_commander(commander_link)
		return commander
	end

	return INVALID_ID
end

---Returns a the lowest ranking officer
---@param warband warband_id
---@return Character? officers
function warband_utils.active_commander(warband)
	local leader_link = DATA.get_warband_leader_from_warband(warband)
	local commander_link = DATA.get_warband_commander_from_warband(warband)
	local recruiter_link = DATA.get_warband_recruiter_from_warband(warband)

	if commander_link then
		local commander = DATA.warband_commander_get_commander(commander_link)
		return commander
	end

	if recruiter_link then
		local recruiter = DATA.warband_recruiter_get_recruiter(recruiter_link)
		return recruiter
	end

	if leader_link then
		local leader = DATA.warband_leader_get_leader(leader_link)
		return leader
	end

	return nil
end

---Returns location of warband, either the leader's province or the guard realm
---@param warband warband_id
---@return province_id
function warband_utils.location(warband)
	local location = DATA.get_warband_location_from_warband(warband)
	return DATA.warband_location_get_location(location)
end

---Returns realm of warband, either the leader's realm or the realm it's a guard of
---@param warband warband_id
---@return Realm
function warband_utils.realm(warband)
	local leadership = DATA.get_warband_leader_from_warband(warband)
	if leadership then
		return REALM(DATA.warband_leader_get_leader(leadership))
	else
		-- TODO
		local guard_of = DATA.get_realm_guard_from_guard(warband)
		if guard_of == INVALID_ID then
			return INVALID_ID
		end
		return DATA.realm_guard_get_realm(guard_of)
	end
end

---comment
---@param warband warband_id
---@return number
function warband_utils.loot_capacity(warband)
	local cap = 0.01
	for _, membership in ipairs(DATA.get_warband_unit_from_warband(warband)) do
		local pop = DATA.warband_unit_get_unit(membership)
		local unit_type = DATA.warband_unit_get_type(membership)
		---@type number
		cap = cap + pop_utils.get_supply_capacity(pop, unit_type)
	end
	for _, pop in pairs(warband_utils.get_officers(warband)) do
		local warband_membership = DATA.get_warband_unit_from_unit(pop)
		if not warband_membership then
			cap = cap + pop_utils.get_supply_capacity(pop, 0)
		end
	end
	return cap
end

---@param warband warband_id
function warband_utils.total_hauling(warband)
	return warband_utils.loot_capacity(warband)
end

---Returns warbands current spotting bonus
---@param warband warband_id
---@return number
function warband_utils.spotting(warband)
	---@type number
	local result = 0

	for _, membership in ipairs(DATA.get_warband_unit_from_warband(warband)) do
		local pop = DATA.warband_unit_get_unit(membership)
		local unit_type = DATA.warband_unit_get_type(membership)
		---@type number
		result = result + pop_utils.get_spotting(pop, unit_type)
	end
	for _, pop in pairs(warband_utils.get_officers(warband)) do
		local warband_membership = DATA.get_warband_unit_from_unit(pop)
		if not warband_membership then
			result = result + pop_utils.get_spotting(pop, 0)
		end
	end

	local status = DATA.warband_get_current_status(warband)

	if status == WARBAND_STATUS.IDLE then
		result = result * 5
	end

	if status == WARBAND_STATUS.PATROL then
		result = result * 10
	end

	return result
end

---Returns warbands current visibility
---@param warband warband_id
---@return number
function warband_utils.visibility(warband)
	---@type number
	local result = 0
	for _, membership in ipairs(DATA.get_warband_unit_from_warband(warband)) do
		local pop = DATA.warband_unit_get_unit(membership)
		local unit_type = DATA.warband_unit_get_type(membership)
		---@type number
		result = result + pop_utils.get_visibility(pop, unit_type)
	end
	for _, pop in pairs(warband_utils.get_officers(warband)) do
		local warband_membership = DATA.get_warband_unit_from_unit(pop)
		if not warband_membership then
			result = result + pop_utils.get_spotting(pop, 0)
		end
	end

	return result
end

---Returns the sum of all units health, attack, armor, and speed along with count
---@param warband warband_id
---@return number total_health
---@return number total_attack
---@return number total_armor
---@return number total_speed
---@return number total_count
function warband_utils.total_strength(warband)
	local total_health, total_attack, total_armor,total_speed, total_count = 0, 0, 0, 0 ,0
	for _, membership in ipairs(DATA.get_warband_unit_from_warband(warband)) do
		local pop = DATA.warband_unit_get_unit(membership)
		local unit_type = DATA.warband_unit_get_type(membership)
		local health, attack, armor, speed = pop_utils.get_strength(pop, unit_type)
		total_health = total_health + health
		total_attack = total_attack + attack
		total_armor = total_armor + armor
		total_speed = total_speed + speed
		total_count = total_count + 1
	end
	return total_health, total_attack, total_armor, total_speed, total_count
end

---Returns average speed of warband, noncombatants included
---@param warband warband_id
---@return number total_speed
---@return number mean_speed
function warband_utils.speed(warband)
	local result = 0
	for _, membership in ipairs(DATA.get_warband_unit_from_warband(warband)) do
		local pop = DATA.warband_unit_get_unit(membership)
		local unit_type = DATA.warband_unit_get_type(membership)
		---@type number
		result = result + pop_utils.get_speed(pop, unit_type)
	end
	for _, pop in pairs(warband_utils.get_officers(warband)) do
		local warband_membership = DATA.get_warband_unit_from_unit(pop)
		if not warband_membership then
			result = result + pop_utils.get_speed(pop, 0)
		end
	end
	return result, math.max(result / warband_utils.size(warband), 0)
end

---Total size of warband
---@param warband warband_id
---@return integer
function warband_utils.size(warband)
	local result = tabb.size(DATA.get_warband_unit_from_warband(warband))
	for _, pop in pairs(warband_utils.get_officers(warband)) do
		local warband_membership = DATA.get_warband_unit_from_unit(pop)
		if not warband_membership then
			result = result + 1
		end
	end
	return result
end

---Target size of warband
---@param warband warband_id
---@return integer
function warband_utils.target_size(warband)
	local result = 0
	DATA.for_each_unit_type(function (item)
		result = result + DATA.warband_get_units_target(warband, item)
	end)

	for _, pop in pairs(warband_utils.get_officers(warband)) do
		local warband_membership = DATA.get_warband_unit_from_unit(pop)
		if not warband_membership then
			---@type number
			result = result + 1
		end
	end

	return result
end

---Returns the number of non character pops
---@param warband warband_id
---@return integer
function warband_utils.pop_size(warband)
	return tabb.size(DATA.get_warband_unit_from_warband(warband))
end

---Return the number of combat units
---@param warband warband_id
---@return integer
function warband_utils.war_size(warband)
	return tabb.size(DATA.get_warband_unit_from_warband(warband))
end

---@param warband warband_id
function warband_utils.decimate(warband)
	local pops_to_delete = tabb.map_array(DATA.get_warband_unit_from_warband(warband), DATA.warband_unit_get_unit)
	for _, pop in ipairs(pops_to_delete) do
		DATA.delete_pop(pop)
	end
end

---Handles hiring logic on warband's side
---@param warband warband_id
---@param pop POP
---@param unit unit_type_id
function warband_utils.hire_unit(warband, pop, unit)
	local location = DATA.get_pop_location_from_pop(pop)
	if location == INVALID_ID then
		error("ATTEMPT TO HIRE POP WITHOUT PROVINCE")
	end

	local warband_membership = DATA.get_warband_unit_from_unit(pop)
	if warband_membership ~= INVALID_ID then
		error("ATTEMPT TO HIRE POP ATTACHED TO WARBAND")
	end

	local new_membership = DATA.fatten_warband_unit(DATA.force_create_warband_unit(pop, warband))
	new_membership.type = unit

	DATA.warband_inc_units_current(warband, unit, 1)
	DATA.warband_inc_total_upkeep(warband, DATA.unit_type_get_upkeep(unit))
end

---Handles pop firing logic on warband's side
---@param warband warband_id
---@param pop pop_id
function warband_utils.fire_unit(warband, pop)
	-- print(pop.name, "leaves warband")
	local membership = DATA.get_warband_unit_from_unit(pop)
	local fat_membership = DATA.fatten_warband_unit(membership)

	assert(warband == fat_membership.warband, "INVALID OPERATION: POP WAS IN A WRONG WARBAND")

	DATA.warband_inc_units_current(warband, fat_membership.type, -1)
	DATA.warband_inc_total_upkeep(warband, -DATA.unit_type_get_upkeep(fat_membership.type))

	DATA.delete_warband_unit(membership)
end

--- sets a character as commander office and adds unit type to units table
---@param warband warband_id
---@param character Character
---@param unit unit_type_id
function warband_utils.set_commander(warband, character, unit)
	warband_utils.set_character_as_unit(warband, character, unit)
end

--- clears commander from office and units table
---@param warband warband_id
function warband_utils.unset_commander(warband)
	local current_commander = DATA.get_warband_commander_from_warband(warband)
	if current_commander == INVALID_ID then
		return
	end
	DATA.delete_warband_commander(current_commander)
end

---@param warband warband_id
---@param character Character
---@param unit unit_type_id
function warband_utils.set_character_as_unit(warband, character, unit)
	---#logging LOGS:write("set character as a unit \n")
	---#logging LOGS:flush()
	local current_unit = DATA.get_warband_unit_from_unit(character)
	local current_warband = DATA.warband_unit_get_warband(current_unit)

	local fat_warband = DATA.fatten_warband(warband)
	local fat_unit = DATA.fatten_unit_type(unit)

	local new_upkeep = DATA.unit_type_get_upkeep(unit)

	if current_warband == INVALID_ID then
		---#logging LOGS:write("no current warband\n")
		---#logging LOGS:flush()

		local new_membership = DATA.fatten_warband_unit(DATA.force_create_warband_unit(character, warband))
		new_membership.type = unit
	elseif current_warband ~= warband then
		---#logging LOGS:write("there is current warband but it's different\n")
		---#logging LOGS:flush()

		local current_type = DATA.warband_unit_get_type(current_unit)
		local current_upkeep = DATA.unit_type_get_upkeep(current_type)

		DATA.warband_inc_units_current(current_warband, unit, -1)
		DATA.warband_inc_total_upkeep(current_warband, -current_upkeep)

		DATA.warband_unit_set_warband(current_unit, warband)
		DATA.warband_unit_set_type(current_unit, unit)
	else
		---#logging LOGS:write("there is current warband and it's the same\n")
		---#logging LOGS:flush()

		local current_type = DATA.warband_unit_get_type(current_unit)
		local current_upkeep = DATA.unit_type_get_upkeep(current_type)

		DATA.warband_inc_units_current(current_warband, unit, -1)
		DATA.warband_inc_total_upkeep(current_warband, -current_upkeep)

		DATA.warband_unit_set_type(current_unit, unit)
	end

	fat_warband.total_upkeep = fat_warband.total_upkeep + fat_unit.upkeep
	DATA.warband_inc_units_current(warband, unit, 1)

	---#logging LOGS:write("taking up command was successful\n")
	---#logging LOGS:flush()
end

---Handles pop firing logic on warband's side
---@param warband warband_id
---@param character POP
function warband_utils.unset_character_as_unit(warband, character)
	local current_warband = DATA.get_warband_unit_from_unit(character)

	if current_warband ~= INVALID_ID then
		local fat_membership = DATA.fatten_warband_unit(current_warband)
		local old_warband = DATA.fatten_warband(fat_membership.warband)
		assert(old_warband.id == warband, "INVALID OPERATION")

		local old_unit = DATA.fatten_unit_type(fat_membership.type)
		old_warband.total_upkeep = old_warband.total_upkeep - old_unit.upkeep
		DATA.warband_inc_units_current(old_warband.id, old_unit.id, -1)
		DATA.delete_warband_unit(current_warband)
	end
end

---Predicts upkeep given the current units target of warbands
---@param warband warband_id
---@return number
function warband_utils.predict_upkeep(warband)
	local result = 0
	for _, membership in ipairs(DATA.get_warband_unit_from_warband(warband)) do
		local unit_type = DATA.warband_unit_get_type(membership)
		---@type number
		result = result + DATA.unit_type_get_upkeep(unit_type)
	end
	return result
end


---comment
---@param warband warband_id
---@return boolean
function warband_utils.vacant(warband)
	local vacant = false
	DATA.for_each_unit_type(function (item)
		if DATA.warband_get_units_target(warband, item) > DATA.warband_get_units_current(warband, item) then
			vacant = true
		end
	end)
	return vacant
end

---Returns monthly budget
---@param warband warband_id
---@return number
function warband_utils.monthly_budget(warband)
	return DATA.warband_get_treasury(warband) / 12
end

---Returs daily consumption of supplies.
---@param warband warband_id
---@return number
function warband_utils.daily_supply_consumption(warband)
	local result = 0
	for _, membership in ipairs(DATA.get_warband_unit_from_warband(warband)) do
		local pop = DATA.warband_unit_get_unit(membership)
		local unit_type = DATA.warband_unit_get_type(membership)
		---@type number
		result = result + pop_utils.get_supply_use(pop, unit_type)
	end
	for _, pop in pairs(warband_utils.get_officers(warband)) do
		local warband_membership = DATA.get_warband_unit_from_unit(pop)
		if not warband_membership then
			result = result + pop_utils.get_supply_use(pop, 0)
		end
	end

	return result * 0.05 --- made up value. raw value leads to VERY expensive trading
end

---@param warband warband_id
function warband_utils.supplies_target(warband)
	return warband_utils.daily_supply_consumption(warband) * DATA.warband_get_supplies_target_days(warband)
end


---Returns speed of exploration
---@param warband warband_id
---@return number
function warband_utils.exploration_speed(warband)
	return warband_utils.size(warband) * (1 - DATA.warband_get_current_free_time_ratio(warband))
end

---Unregisters a pop as a military pop.  \
---The "fire" routine for soldiers. Also used in some other contexts?
---@param pop pop_id
function warband_utils.unregister_military(pop)
	local unit_of = DATA.get_warband_unit_from_unit(pop)
	local warband = DATA.warband_unit_get_warband(unit_of)
	if warband == INVALID_ID then
		return
	end

	warband_utils.fire_unit(warband, pop)
end


return warband_utils
