local tabb = require "engine.table"
local pop_utils = require "game.entities.pop".POP
local warband_utils = require "game.entities.warband"
local army_utils = require "game.entities.army"

local economy_values = require "game.raws.values.economy"
local economy_triggers = require "game.raws.triggers.economy"

local prov = {}
local col = require "game.color"

prov.Province = {}
prov.Province.__index = prov.Province

---Returns a new province. Remember to assign "center" tile!
---@param fake_flag boolean? do not register province if true
function prov.Province.new(fake_flag)
	local o = DATA.fatten_province(DATA.create_province())


	-- print("add province:", o.id)

	o.name = "<uninhabited>"

	local r, g, b = col.hsv_to_rgb(
		love.math.random(),
		0.9 + 0.1 * love.math.random(),
		0.9 + 0.1 * love.math.random()
	)
	o.r = r
	o.g = g
	o.b = b

	if not fake_flag then
		WORLD.province_count = WORLD.province_count + 1
	end

	return o.id
end

---comment
---@param province province_id
---@return province_id|nil
function prov.Province.get_random_neighbor(province)
	local neighbors = DATA.get_province_neighborhood_from_origin(province)
	local s = tabb.size(neighbors)
	local random_neigh = neighbors[love.math.random(s)]
	if random_neigh then
		local neighbor = DATA.province_neighborhood_get_target(random_neigh)
		return neighbor
	else
		return nil
	end
end

---Adds a tile to the province. Handles removal from the previous province, if necessary.
---@param province province_id
---@param tile tile_id
function prov.Province.add_tile(province, tile)
	-- print("add tile:", province, tile)

	--- easiest way to handle it, i guess
	if DATA.tile_get_is_land(tile) then
		DATA.province_set_is_land(province, true)
	end

	local membership = DATA.get_tile_province_membership_from_tile(tile)

	if membership ~= INVALID_ID then
		DATA.tile_province_membership_set_province(membership, province)
	else
		DATA.force_create_tile_province_membership(province, tile)
	end

	-- sanity check
	-- local belongs2 = DATA.tile_province_membership_get_province(DATA.get_tile_province_membership_from_tile(tile)) == province
	-- assert(belongs2, membership)

	-- if membership ~= INVALID_ID then
	-- 	local c1 = DATA.get_tile_province_membership_from_tile(tile)
	-- 	assert(c1 == membership, tostring(c1) .. " " .. tostring(membership).. " " .. tostring(tile))
	-- end

	-- local belongs = false
	-- DATA.for_each_tile_province_membership_from_province(province, function (item)
	-- 	local check = DATA.tile_province_membership_get_tile(item)
	-- 	assert(DATA.tile_province_membership_get_province(DATA.get_tile_province_membership_from_tile(check)) == province)
	-- 	print("???")
	-- 	if tile == check then
	-- 		belongs = true
	-- 	end
	-- end)
	-- assert(belongs, membership)
end

---@param province province_id
function prov.Province.update_size(province)
	DATA.province_set_size(province, tabb.size(DATA.get_tile_province_membership_from_province(province)))
end

---Returns the total military size of the province.
---@param province province_id
---@return number
function prov.Province.military(province)
	local total = 0
	DATA.for_each_warband_location_from_location(province, function (item)
		---@type number
		total = total + warband_utils.size(DATA.warband_location_get_warband(item))
	end)
	return total
end

---Returns the total target military size of the province.
---@param province province_id
---@return number
function prov.Province.military_target(province)
	local total = 0
	DATA.for_each_warband_location_from_location(province, function (item)
		---@type number
		total = total + warband_utils.target_size(DATA.warband_location_get_warband(item))
	end)
	return total
end

---Returns the total population of the province, not including characters.
---Doesn't include outlaws and active armies.
---@param province province_id
---@return number
function prov.Province.local_population(province)
	local result = 0
	DATA.for_each_pop_location_from_location(province, function (item)
		result = result + 1
	end)
	return result
end

---Returns the total amount of characters of the province, not including characters.
---Doesn't include outlaws and active armies.
---@param province province_id
---@return number
function prov.Province.local_characters(province)
	return tabb.size(DATA.get_character_location_from_location(province))
end

---Returns the total count of all pops who consider this province home, not including characters.
---Doesn't include outlaws and active armies.
---@param province province_id
---@return number
function prov.Province.home_population(province)
	return tabb.size(tabb.filter_array(DATA.get_home_from_home(province), function (a)
		return not IS_CHARACTER(DATA.home_get_pop(a))
	end))
end

---Returns the total count of all pops who consider this province home, not including characters.
---Doesn't include outlaws and active armies.
---@param province province_id
---@return number
function prov.Province.home_characters(province)
	return tabb.size(tabb.filter_array(DATA.get_home_from_home(province), function (a)
		return IS_CHARACTER(DATA.home_get_pop(a))
	end))
end

---Returns the total count of all pops who consider this province home, including characters.
---Doesn't include outlaws and active armies.
---@param province province_id
---@return number
function prov.Province.total_home_population(province)
	return tabb.size(DATA.get_home_from_home(province))
end

---@param province province_id
function prov.Province.validate_population(province)
	for _, pop_location in pairs(DATA.get_pop_location_from_location(province)) do
		local check_province = DATA.pop_location_get_location(pop_location)
		local pop = DATA.pop_location_get_pop(pop_location)
		if check_province == INVALID_ID then
			error("pop_id " .. DATA.pop_get_name(pop) .. " DOESN'T HAVE PROVINCE")
		end
		if province ~= check_province then
			error("pop_id " .. DATA.pop_get_name(pop) .. " HAS WRONG PROVINCE SET")
		end
	end

	for _, pop_location in pairs(DATA.get_home_from_home(province)) do
		local home_province = DATA.home_get_home(pop_location)
		local pop = DATA.home_get_pop(pop_location)
		if home_province == INVALID_ID then
			error("pop_id " .. DATA.pop_get_name(pop) .. " DOESN'T HAVE HOME PROVINCE")
		end
		if home_province ~= province then
			error("pop_id " .. DATA.pop_get_name(pop) .. " HAS WRONG HOME PROVINCE SET")
		end
	end

	for _, pop_location in pairs(DATA.get_character_location_from_location(province)) do
		local check_province = DATA.character_location_get_location(pop_location)
		local pop = DATA.character_location_get_character(pop_location)
		if province == INVALID_ID then
			error("Character " .. DATA.pop_get_name(pop) .. " DOESN'T HAVE PROVINCE")
		end
		if province ~= check_province then
			error("Character " .. DATA.pop_get_name(pop) .. " HAS WRONG PROVINCE SET")
		end
	end
end

---Returns the total population weight of the province.
---@param province province_id
---@return number
function prov.Province.population_weight(province)
	local total = 0
	for _, pop_location in pairs(DATA.get_pop_location_from_location(province)) do
		local pop = DATA.pop_location_get_pop(pop_location)
		-- weight is dependent on food needs, which are age dependent
		local race = DATA.pop_get_race(pop)
		local age_multiplier = pop_utils.get_age_multiplier(pop)

		total = total + DATA.race_get_carrying_capacity_weight(race) * age_multiplier
	end
	return total
end

--- Transfers a pop to the target province
---@param pop pop_id
---@param target province_id
function prov.Province.transfer_pop(pop, target)
	if IS_CHARACTER(pop) then
		local current_location = DATA.get_character_location_from_character(pop)
		DATA.character_location_set_location(current_location, target)
	end
	-- print(pop.name, "pop_id", self.name, "-->", target.name)
	local current_location = DATA.get_pop_location_from_pop(pop)
	local origin = DATA.pop_location_get_location(current_location)
	DATA.pop_location_set_location(current_location, target)
	local relevant_children =
		tabb.filter_array(
			tabb.map_array(
				DATA.get_parent_child_relation_from_parent(pop),
				DATA.parent_child_relation_get_child
			),
			function(child)
				local child_location = DATA.pop_location_get_location(DATA.get_pop_location_from_pop(child))
				if child_location ~= origin then
					return false
				end

				local home_location = DATA.home_get_home(DATA.get_home_from_pop(child))
				if home_location ~= origin then
					return false
				end

				local unit_of = DATA.get_warband_unit_from_unit(child)
				if unit_of ~= INVALID_ID then
					return false
				end

				local employer = DATA.employment_get_building(DATA.get_employment_from_worker(child))
				if employer ~= INVALID_ID then
					return false
				end

				return true;
			end
		)

	for _, c in ipairs(relevant_children) do
		prov.Province.transfer_pop(c, target)
	end
end

--- Changes home province of a pop/character to the target province
---@param origin province_id
---@param pop Character
---@param target province_id
function prov.Province.transfer_home(origin, pop, target)
	local current_home = DATA.get_home_from_pop(pop)
	assert(DATA.home_get_home(current_home) == origin, "INVALID HOME OF POP")
	DATA.home_set_home(current_home, target)

	local relevant_children =
		tabb.filter_array(
			tabb.map_array(
				DATA.get_parent_child_relation_from_parent(pop),
				DATA.parent_child_relation_get_child
			),
			function(child)
				local child_location = DATA.pop_location_get_location(DATA.get_pop_location_from_pop(child))
				if child_location ~= origin then
					return false
				end

				local home_location = DATA.home_get_home(DATA.get_home_from_pop(child))
				if home_location ~= origin then
					return false
				end

				local unit_of = DATA.get_warband_unit_from_unit(child)
				if unit_of ~= INVALID_ID then
					return false
				end

				local employer = DATA.employment_get_building(DATA.get_employment_from_worker(child))
				if employer ~= INVALID_ID then
					return false
				end

				return true;
			end
		)

	for _, c in ipairs(relevant_children) do
		prov.Province.transfer_home(origin, c, target)
	end
end

---@param province province_id
function prov.Province.local_army_size(province)
	local total = 0
	DATA.for_each_warband_location_from_location(province, function (item)
		local warband = DATA.warband_location_get_warband(item)
		local status = DATA.warband_get_current_status(warband)
		if status == WARBAND_STATUS.PATROL then
			---@type number
			total = total + warband_utils.size(warband)
		end
	end)
	return total
end

---Removes the pop from the province without killing it  \
---Does not change home province of pop
---@param province province_id
---@param pop pop_id
function prov.Province.take_away_pop(province, pop)
	local location = DATA.get_pop_location_from_pop(pop)
	assert(DATA.pop_location_get_location(location) == province, "INVALID STATE")
	DATA.delete_pop_location(location)
end

---@param province province_id
---@param pop pop_id
function prov.Province.return_pop_from_army(province, pop)
	prov.Province.add_pop(province, pop)
end


---Employs a pop and handles its removal from relevant data structures...
---@param province province_id
---@param pop pop_id
---@param building building_id
function prov.Province.employ_pop(province, pop, building)
	local potential_job = prov.Province.potential_job(province, building)
	if potential_job == nil then
		return
	end
	-- Now that we know that the job is needed, employ the pop!
	-- ... but fire them first to update the previous building if needed
	local employment = DATA.get_employment_from_worker(pop)
	if DATA.employment_get_building(employment) == INVALID_ID then
		-- no need to update stuff: just create new employment
		local new_employment = DATA.fatten_employment(DATA.force_create_employment(building, pop))
		new_employment.job = potential_job
	else
		local fat = DATA.fatten_employment(employment)

		local old_building = fat.building
		-- clean up data if it was the last worker
		if tabb.size(DATA.get_employment_from_building(old_building)) == 0 then
			local fat_building = DATA.fatten_building(old_building)
			fat_building.last_income = 0
			fat_building.last_donation_to_owner = 0
			fat_building.subsidy_last = 0
		end

		fat.building = building
		fat.job = potential_job
	end
end

---Returns a potential job, if a pop was to be employed by this building.
---@param province province_id
---@param building building_id
---@return job_id?
function prov.Province.potential_job(province, building)
	local btype = DATA.building_get_current_type(building)
	local method = DATA.building_type_get_production_method(btype)

	for i = 1, MAX_SIZE_ARRAYS_PRODUCTION_METHOD - 1 do
		local job = DATA.production_method_get_jobs_job(method, i)
		if job == INVALID_ID then
			break
		end

		local workers_with_this_job = 0
		for _, employment in ipairs(DATA.get_employment_from_building(building)) do
			if DATA.employment_get_job(employment) == job then
				workers_with_this_job = workers_with_this_job + 1
			end
		end

		local max_amount = DATA.production_method_get_jobs_amount(method, i)
		if max_amount > workers_with_this_job then
			return job
		end
	end

	return nil
end

---@param province province_id
---@param researched_technology Technology
function prov.Province.research(province, researched_technology)
	DATA.province_set_technologies_present(province, researched_technology, 1)
	DATA.province_set_technologies_researchable(province, researched_technology, 0)

	-- print("unlock " .. DATA.technology_get_name(researched_technology))

	--- update technologies which could be potentially unlocked
	for _, t in pairs(DATA.get_technology_unlock_from_origin(researched_technology)) do
		local potential_technology = DATA.technology_unlock_get_unlocked(t)
		if DATA.province_get_technologies_present(province, potential_technology) == 1 then
			goto continue
		end

		-- print("test for technology unlock " .. DATA.technology_get_name(potential_technology))

		--print(t.name)
		local ok = true

		local has_required_resource = true

		for i = 1, MAX_REQUIREMENTS_TECHNOLOGY - 1 do
			local required_resource = DATA.technology_get_required_resource(potential_technology, i)
			if required_resource == INVALID_ID then
				break
			end
			has_required_resource = false

			for j = 1, MAX_RESOURCES_IN_PROVINCE_INDEX - 1 do
				local resource = DATA.province_get_local_resources_resource(province, j)
				if resource == INVALID_ID then
					break
				end

				if resource == required_resource then
					has_required_resource = true
					break
				end
			end

			if has_required_resource then
				break
			end
		end

		ok = ok and has_required_resource

		local has_required_race = true

		for i = 1, MAX_REQUIREMENTS_TECHNOLOGY - 1 do
			local required_race = DATA.technology_get_required_race(potential_technology, i)
			if required_race == INVALID_ID then
				break
			end
			has_required_race = false

			local realm = DATA.realm_provinces_get_realm(DATA.get_realm_provinces_from_province(province))

			if DATA.realm_get_primary_race(realm) == required_race then
				has_required_race = true
			end

			if has_required_race then
				break
			end
		end

		ok = ok and has_required_race

		local has_required_biome = true

		for i = 1, MAX_REQUIREMENTS_TECHNOLOGY - 1 do
			local required_biome = DATA.technology_get_required_biome(potential_technology, i)
			if required_biome == INVALID_ID then
				break
			end
			has_required_biome = false

			local center = DATA.province_get_center(province)

			if DATA.tile_get_biome(center) == required_biome then
				has_required_biome = true
			end

			if has_required_biome then
				break
			end
		end

		ok = ok and has_required_biome


		if #DATA.get_technology_unlock_from_unlocked(potential_technology) > 0 then
			local new_ok = true
			for _, te in pairs(DATA.get_technology_unlock_from_unlocked(potential_technology)) do
				local required_tech = DATA.technology_unlock_get_origin(te)
				if DATA.province_get_technologies_present(province, required_tech) == 1 then
					-- nothing to do, tech present
				else
					-- tech missing, this tech cannot be unlocked...
					new_ok = false
					break
				end
			end
			if not new_ok then
				ok = false
			end
		end

		-- print(ok)

		if ok then
			DATA.province_set_technologies_researchable(province, potential_technology, 1)
		end

		::continue::
	end


	-- update buildings

	for _, b in pairs(DATA.get_technology_building_from_technology(researched_technology)) do
		local building_type = DATA.technology_building_get_unlocked(b)
		local ok = true

		for i = 1, MAX_REQUIREMENTS_BUILDING_TYPE - 1 do
			local required_biome = DATA.building_type_get_required_biome(building_type, i)
			if required_biome == INVALID_ID then
				break
			end

			ok = false

			if DATA.tile_get_biome(DATA.province_get_center(province)) == required_biome then
				ok = true
				break
			end
		end

		local has_required_resource = true

		for i = 1, MAX_REQUIREMENTS_TECHNOLOGY - 1 do
			local required_resource = DATA.building_type_get_required_resource(building_type, i)
			if required_resource == INVALID_ID then
				break
			end
			has_required_resource = false

			for j = 1, MAX_RESOURCES_IN_PROVINCE_INDEX - 1 do
				local resource = DATA.province_get_local_resources_resource(province, j)
				if resource == INVALID_ID then
					break
				end

				if resource == required_resource then
					has_required_resource = true
					break
				end
			end

			if has_required_resource then
				break
			end
		end

		ok = has_required_resource and ok

		if ok then
			DATA.province_set_buildable_buildings(province, building_type, 1)
		end
	end

	for _, unit_id in ipairs(DATA.get_technology_unit_from_technology(researched_technology)) do
		local unit_type = DATA.technology_unit_get_unlocked(unit_id)
		DATA.province_set_unit_types(province, unit_type, 1)
	end

	DATA.for_each_production_method(function (i)
		DATA.province_inc_throughput_boosts(province, i, DATA.technology_get_throughput_boosts(researched_technology, i))
		DATA.province_inc_input_efficiency_boosts(province, i, DATA.technology_get_input_efficiency_boosts(researched_technology, i))
		DATA.province_inc_output_efficiency_boosts(province, i, DATA.technology_get_output_efficiency_boosts(researched_technology, i))
	end)

	local realm = prov.Province.realm(province)
	if WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification("Technology unlocked: " .. DATA.technology_get_name(researched_technology))
	end
end

---Forget technology
---@param province province_id
---@param technology Technology
function prov.Province.forget(province, technology)
	-- remove tech from province
	DATA.province_set_technologies_present(province, technology, 0)
	DATA.province_set_technologies_researchable(province, technology, 1)

	-- temporary forget all buildings and bonuses

	---@param building_type building_type_id
	local function reset_building_type(building_type)
		DATA.province_set_buildable_buildings(province, building_type, 0)
	end

	---@param unit_type unit_type_id
	local function reset_unit_type(unit_type)
		DATA.province_set_unit_types(province, unit_type, 0)
	end

	---@param production_method production_method_id
	local function reset_production_method(production_method)
		DATA.province_set_throughput_boosts(province, production_method, 0)
		DATA.province_set_input_efficiency_boosts(province, production_method, 0)
		DATA.province_set_output_efficiency_boosts(province, production_method, 0)
	end

	DATA.for_each_building_type(reset_building_type)
	DATA.for_each_unit_type(reset_unit_type)
	DATA.for_each_production_method(reset_production_method)

	-- relearn everything
	-- sounds like a horrible solution
	-- but after some thinking,
	-- you would need to do all these checks
	-- for all techs anyway
	-- because there are no assumptions for a graph of technologies

	---@param any_technology Technology
	local function research(any_technology)
		if DATA.province_get_technologies_present(province, any_technology) == 1 then
			prov.Province.research(province, any_technology)
		end
	end

	DATA.for_each_technology(research)
end

---@param province province_id
---@param target_building_type BuildingType
---@return boolean
function prov.Province.building_type_present(province, target_building_type)
	local present = false
	DATA.for_each_building_location_from_location(province, function (item)
		local bld = DATA.building_location_get_building(item)
		local local_bld_type = DATA.building_get_current_type(bld)
		if local_bld_type == target_building_type then
			present = true
		end
	end)
	return present
end

---@alias BuildingAttemptFailureReason "ok" | "not_enough_funds" | "unique_duplicate" | "missing_local_resources" | "no_permission"

---comment
---@param province province_id
---@param funds number
---@param building building_type_id
---@param overseer pop_id
---@param public boolean
---@return boolean
---@return BuildingAttemptFailureReason
function prov.Province.can_build(province, funds, building, overseer, public)
	local resource_check_passed = true

	for i = 1, MAX_REQUIREMENTS_BUILDING_TYPE do
		local resource = DATA.building_type_get_required_resource(building, i)
		if resource == INVALID_ID then
			goto RESOURCE_CHECK_ENDED
		end

		resource_check_passed = false
		-- print("check for resource")
		-- print("required res is " .. resource)
		for _, tile_membership_id in pairs(DATA.get_tile_province_membership_from_province(province)) do
			local tile_id = DATA.tile_province_membership_get_tile(tile_membership_id)
			-- print(DATA.tile_get_resource(tile_id))
			if DATA.tile_get_resource(tile_id) == resource then
				resource_check_passed = true
				goto RESOURCE_CHECK_ENDED
			end
		end
	end
	::RESOURCE_CHECK_ENDED::

	local construction_cost = economy_values.building_cost(building, overseer, public)

	if not economy_triggers.allowed_to_build(overseer, prov.Province.realm(province)) then
		return false, "no_permission"
	end

	if DATA.building_type_get_unique(building) and prov.Province.building_type_present(province, building) then
		return false, "unique_duplicate"
	elseif not resource_check_passed then
		return false, "missing_local_resources"
	elseif construction_cost <= funds then
		return true, "ok"
	else
		return false, "not_enough_funds"
	end
end

---@param province province_id
---@return number
function prov.Province.get_infrastructure_efficiency(province)
	local inf = 0
	local needed = DATA.province_get_infrastructure_needed(province)
	local provided = DATA.province_get_infrastructure(province)
	if needed > 0 then
		inf = 2 * provided / (provided + needed)
	end
	return inf
end

---@param province province_id
---@return culture_id|nil
function prov.Province.get_dominant_culture(province)
	---@type table<culture_id, number>
	local e = {}
	for _, p in pairs(DATA.get_pop_location_from_location(province)) do
		local pop_id = DATA.pop_location_get_pop(p)
		local culture = DATA.pop_get_culture(pop_id)
		local old = e[culture] or 0
		e[culture] = old + 1
	end
	local best = nil
	local max = 0
	for k, v in pairs(e) do
		if v > max then
			best = k
			max = v
		end
	end
	return best
end

---@param province province_id
---@return faith_id|nil
function prov.Province.get_dominant_faith(province)
	---@type table<faith_id, number>
	local e = {}
	for _, p in pairs(DATA.get_pop_location_from_location(province)) do
		local pop_id = DATA.pop_location_get_pop(p)
		local faith = DATA.pop_get_faith(pop_id)
		local old = e[faith] or 0
		e[faith] = old + 1
	end
	local best = nil
	local max = 0
	for k, v in pairs(e) do
		if v > max then
			best = k
			max = v
		end
	end
	return best
end

---@param province province_id
---@return race_id
function prov.Province.get_dominant_race(province)
	---@type table<race_id, number>
	local e = {}
	for _, p in pairs(DATA.get_pop_location_from_location(province)) do
		local pop_id = DATA.pop_location_get_pop(p)
		local race = DATA.pop_get_race(pop_id)

		local old = e[race] or 0
		e[race] = old + 1
	end
	local best = INVALID_ID
	local max = 0
	for k, v in pairs(e) do
		if v > max then
			best = k
			max = v
		end
	end
	return best
end

---Returns whether or not a province borders a given realm
---@param province province_id
---@param realm Realm
---@return boolean
function prov.Province.neighbors_realm(province, realm)
	for _, n in pairs(DATA.get_province_neighborhood_from_origin(province)) do
		local neighbor = DATA.province_neighborhood_get_target(n)
		local neighbor_realm = prov.Province.realm(neighbor)
		if neighbor_realm == realm then
			return true
		end
	end
	return false
end

---commenting
---@param province province_id
---@return realm_id
function prov.Province.realm(province)
	return PROVINCE_REALM(province)
end

---Adds pop as a guest of this province. Preserves old home of a pop.
---@param province province_id
---@param pop pop_id
function prov.Province.add_pop(province, pop)
	DATA.force_create_pop_location(province, pop)
end

---Adds a character to the province
---@param province province_id
---@param character Character
function prov.Province.add_character(province, character)
	DATA.force_create_character_location(province, character)
end

---Sets province as pop's home
---@param province province_id
---@param pop pop_id
function prov.Province.set_home(province, pop)
	local home = DATA.get_home_from_pop(pop)
	if home ~= INVALID_ID then
		DATA.home_set_home(home, province)
	else
		DATA.force_create_home(province, pop)
	end

	-- as this province is your home, you belong to local realm now
	local realm = prov.Province.realm(province)

	if realm ~= INVALID_ID then
		SET_REALM(pop, realm)
	end
end

---@param province province_id
---@return number
function prov.Province.get_spotting(province)
	local s = 0

	DATA.for_each_pop_location_from_location(province, function (p)
		local pop_id = DATA.pop_location_get_pop(p)
		local race = DATA.pop_get_race(pop_id)
		s = s + DATA.race_get_spotting(race)
	end)

	DATA.for_each_building_location_from_location(province, function (location)
		local building = DATA.building_location_get_building(location)
		local btype = DATA.building_get_current_type(building)
		local spotting = DATA.building_type_get_spotting(btype)
		---@type number
		s = s + spotting
	end)

	DATA.for_each_warband_location_from_location(province, function (party)
		local warband = DATA.warband_location_get_warband(party)
		local status = DATA.warband_get_current_status(warband)
		if status == WARBAND_STATUS.PATROL then
			---@type number
			s = s + warband_utils.spotting(warband)
		end
	end)

	return s
end

---@param province province_id
---@return number
function prov.Province.get_hiding(province)
	local hide = 1
	DATA.for_each_tile_province_membership_from_province(province, function (item)
		local tile_id = DATA.tile_province_membership_get_tile(item)
		local grass = DATA.tile_get_grass(tile_id)
		local shrub = DATA.tile_get_shrub(tile_id)
		local conifer = DATA.tile_get_conifer(tile_id)
		local broadleaf = DATA.tile_get_broadleaf(tile_id)
		hide = hide + 1 + grass + shrub * 2 + conifer * 3 + broadleaf * 5
	end)
	return hide
end

---@param province province_id
---@param visibility number
function prov.Province.spot_chance(province, visibility)
	local spot = prov.Province.get_spotting(province)
	local hiding = prov.Province.get_hiding(province)
	local actual_hiding = hiding - visibility
	local size = spot + visibility + hiding
	-- If spot == hide, we should get 50:50 odds.
	-- If spot > hide, we should get higher odds of spotting
	-- If spot < hide, we should get lower odds of spotting
	local odds = 0.5
	local delta = spot - actual_hiding
	if delta == 0 then
		-- nothing to do
	else
		delta = delta / size
	end
	odds = math.max(0, math.min(1, odds + 0.5 * delta))
	return odds
end

---@param province province_id
---@param army army_id Attacking army
---@param stealth_penalty number? Multiplicative penalty, multiplies army visibility score.
---@return boolean True if the army was spotted.
function prov.Province.army_spot_test(province, army, stealth_penalty)
	-- To resolve this event we need to perform some checks.
	-- First, we should have a "scouting" check.
	-- Them, a potential battle ought to take place.`
	if stealth_penalty == nil then
		stealth_penalty = 1
	end

	local visib = (army_utils.get_visibility(army) + love.math.random(20)) * stealth_penalty
	local odds = prov.Province.spot_chance(province, visib)
	if love.math.random() < odds then
		-- Spot!
		return true
	else
		-- Hide!
		return false
	end
end

---@param province province_id
---@return table<job_id, number>
function prov.Province.get_job_ratios(province)
	---@type table<job_id, number>
	local r = {}

	local pop = 0

	for _, p in pairs(DATA.get_pop_location_from_location(province)) do
		local pop_id = DATA.pop_location_get_pop(p)

		local employment = DATA.get_employment_from_worker(pop_id)
		if DATA.employment_get_building(employment) ~= INVALID_ID then
			local job = DATA.employment_get_job(employment)
			local old = r[job] or 0
			r[job] = old + 1
		end
		pop = pop + 1
	end

	for job, am in pairs(r) do
		r[job] = am / pop
	end

	return r
end

---Returns the number of unemployed people in the province.
---@param province province_id
---@return integer
function prov.Province.get_unemployment(province)
	local u = 0

	for _, p in pairs(DATA.get_pop_location_from_location(province)) do
		local pop_id = DATA.pop_location_get_pop(p)

		local unit_of = DATA.get_warband_unit_from_unit(pop_id)
		local employment = DATA.get_employment_from_worker(pop_id)
		if DATA.employment_get_building(employment) ~= INVALID_ID then

		elseif DATA.warband_unit_get_warband(unit_of) ~= INVALID_ID then

		else
			u = u + 1
		end
	end

	return u
end

---@param province province_id
---@return warband_id warband
function prov.Province.new_warband(province)
	local warband = DATA.create_warband()
	DATA.force_create_warband_location(province, warband)
	DATA.warband_set_current_status(warband, WARBAND_STATUS.IDLE)
	DATA.warband_set_idle_stance(warband, WARBAND_STANCE.FORAGE)
	return warband
end

---@param province province_id
function prov.Province.num_of_warbands(province)
	local amount = 0
	DATA.for_each_warband_location_from_location(province, function (item)
		amount = amount + 1
	end)
	return amount
end

---@param province province_id
---@return warband_id[]
function prov.Province.vacant_warbands(province)
	local res = {}

	DATA.for_each_warband_location_from_location(province, function (item)
		local warband = DATA.warband_location_get_warband(item)
		if warband_utils.vacant(warband) then
			table.insert(res, warband)
		end
	end)

	return res
end

---@param province province_id
function prov.Province.exploration_days(province)
	return DATA.province_get_movement_cost(province) / 5
end

return prov
