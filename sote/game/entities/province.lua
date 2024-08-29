local tabb = require "engine.table"
local wb = require "game.entities.warband"
local pop_utils = require "game.entities.pop".POP

local EconomicValues = require "game.raws.values.economical"
local economic_triggers = require "game.raws.triggers.economy"

local prov = {}
local col = require "game.color"

prov.Province = {}
prov.Province.__index = prov.Province

---Returns a new province. Remember to assign "center" tile!
---@param fake_flag boolean? do not register province if true
function prov.Province.new(fake_flag)
	local o = DATA.fatten_province(DATA.create_province())

	o.name = "<uninhabited>"

	local r, g, b = col.hsv_to_rgb(
		love.math.random(),
		0.9 + 0.1 * love.math.random(),
		0.9 + 0.1 * love.math.random()
	)
	o.r = r
	o.g = g
	o.b = b

	o.mood = 0
	o.size = 0
	o.movement_cost = 1
	o.foragers_limit = 0
	o.is_land = false
	o.buildings = {}
	o.technologies_present = {}
	o.technologies_researchable = {}
	o.buildable_buildings = {}
	o.hydration = 5
	o.local_wealth = 0
	o.trade_wealth = 0
	o.local_income = 0
	o.local_building_upkeep = 0
	o.foragers = 0
	o.foragers_water = 0
	o.foragers_targets = {}
	o.infrastructure_needed = 0
	o.infrastructure = 0
	o.infrastructure_investment = 0
	o.unit_types = {}
	o.throughput_boosts = {}
	o.input_efficiency_boosts = {}
	o.output_efficiency_boosts = {}
	o.on_a_river = false
	o.on_a_forest = false
	o.warbands = {}

	if not fake_flag then
		WORLD.province_count = WORLD.province_count + 1
	end

	return o
end

---comment
---@param province province_id
---@return province_id
function prov.Province.get_random_neighbor(province)
	local neighbors = DATA.get_province_neighborhood_from_origin(province)
	local s = tabb.size(neighbors)
	local neighbor = DATA.province_neighborhood_get_target(tabb.nth(neighbors, love.math.random(s)))
	return neighbor
end

---Adds a tile to the province. Handles removal from the previous province, if necessary.
---@param province province_id
---@param tile tile_id
function prov.Province.add_tile(province, tile)
	--- easiest way to handle it, i guess
	if DATA.tile_get_is_land(tile) then
		DATA.province_set_is_land(province, true)
	end

	local membership = DATA.tile_province_membership_from_tile[tile]

	if membership then
		DATA.tile_province_membership_set_province(membership, province)
	else
		local new_membership = DATA.create_tile_province_membership()
		DATA.tile_province_membership_set_province(new_membership, province)
		DATA.tile_province_membership_set_tile(new_membership, tile)
	end
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
	local warbands = DATA.province_get_warbands(province)
	for _, party in pairs(warbands) do
		total = total + party:size()
	end
	return total
end

---Returns the total target military size of the province.
---@param province province_id
---@return number
function prov.Province.military_target(province)
	local sum = 0
	local warbands = DATA.province_get_warbands(province)
	for _, warband in pairs(warbands) do
		for _, u in pairs(warband.units_target) do
			sum = sum + u
		end
		-- adding up leader position
		sum = sum + 1
	end
	return sum
end

---Returns the total population of the province, not including characters.
---Doesn't include outlaws and active armies.
---@param province province_id
---@return number
function prov.Province.local_population(province)
	return tabb.size(DATA.get_pop_location_from_location(province))
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
	for _, pop in pairs(DATA.get_pop_location_from_location(province)) do
		local check_province = DATA.pop_location_get_pop(pop)
		if check_province == nil then
			error("pop_id " .. DATA.pop_get_name(pop) .. " DOESN'T HAVE PROVINCE")
		end
		if province ~= check_province then
			error("pop_id " .. DATA.pop_get_name(pop) .. " HAS WRONG PROVINCE SET")
		end
	end

	for _, pop in pairs(DATA.get_home_from_home(province)) do
		local home_province = DATA.home_get_home(pop)
		if home_province == nil then
			error("pop_id " .. DATA.pop_get_name(pop) .. " DOESN'T HAVE HOME PROVINCE")
		end
		if home_province ~= province then
			error("pop_id " .. DATA.pop_get_name(pop) .. " HAS WRONG HOME PROVINCE SET")
		end
	end

	for _, pop in pairs(DATA.get_character_location_from_location(province)) do
		local check_province = DATA.character_location_get_location(pop)
		if province == nil then
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
	for _, pop in pairs(DATA.get_pop_location_from_location(province)) do
		-- weight is dependent on food needs, which are age dependent
		local race = DATA.pop_get_race(pop)
		local age_multiplier = pop_utils.get_age_multiplier(pop)

		total = total + DATA.race_get_carrying_capacity_weight(race) * age_multiplier
	end
	return total
end

---Adds a pop to the province. Sets province as a home. Does not handle cleaning of old data
---@param province province_id
---@param pop pop_id
function prov.Province.add_pop(province, pop)
	prov.Province.add_guest_pop(province, pop)
	prov.Province.set_home(province, pop)
end

---Adds pop as a guest of this province. Preserves old home of a pop.
---@param province province_id
---@param pop pop_id
function prov.Province.add_guest_pop(province, pop)
	local location = DATA.get_pop_location_from_pop(pop)
	if location then
		DATA.pop_location_set_location(location, province)
	else
		local new_location = DATA.create_pop_location()
		DATA.pop_location_set_location(new_location, province)
		DATA.pop_location_set_pop(new_location, pop)
	end
end

---Adds a character to the province
---@param province province_id
---@param character Character
function prov.Province.add_character(province, character)
	local location = DATA.get_character_location_from_character(character)
	if location then
		DATA.character_location_set_location(location, province)
	else
		local new_location = DATA.create_pop_location()
		DATA.character_location_set_location(new_location, province)
		DATA.character_location_set_character(new_location, character)
	end
end

---Sets province as pop's home
---@param province province_id
---@param pop pop_id
function prov.Province.set_home(province, pop)
	-- print('SET HOME', pop.name)
	local home = DATA.get_home_from_pop(pop)
	if home then
		DATA.home_set_home(home, province)
	else
		local new_home = DATA.create_home()
		DATA.home_set_home(new_home, province)
		DATA.home_set_pop(new_home, pop)
	end

	-- as this province is your home, you belong to local realm now
	local realm = DATA.province_get_realm(province)
	if realm then
		DATA.pop_set_realm(pop, realm)
	end
end

--- Transfers a character to the target province
---@param origin province_id
---@param character Character
---@param target province_id
function prov.Province.transfer_character(origin, character, target)
	-- print(character.name, "CHARACTER", self.name, "-->", target.name)
	-- validate that origin is really an origin

	local current_location = DATA.get_character_location_from_character(character)
	assert(DATA.character_location_get_location(current_location) == origin, "CHARACTER ATTEMPTS TO TRAVEL NOT FROM HIS LOCATION")
	DATA.character_location_set_location(current_location, target)
end

--- Transfers a pop to the target province
---@param origin province_id
---@param pop pop_id
---@param target province_id
function prov.Province.transfer_pop(origin, pop, target)
	-- print(pop.name, "pop_id", self.name, "-->", target.name)
	local current_location = DATA.get_pop_location_from_pop(pop)
	assert(DATA.character_location_get_location(current_location) == origin, "POP ATTEMPTS TO TRAVEL NOT FROM HIS LOCATION")
	DATA.character_location_set_location(current_location, target)

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

				local home_location = DATA.get_home_from_pop(DATA.get_home_from_pop(child))
				if home_location ~= origin then
					return false
				end

				local unit_of = DATA.pop_get_unit_of_warband(child)
				if unit_of ~= nil then
					return false
				end

				local employer = DATA.pop_get_employer(child)
				if employer ~= nil then
					return false
				end

				return true;
			end
		)

	for _, c in ipairs(relevant_children) do
		prov.Province.transfer_pop(origin, c, target)
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

				local home_location = DATA.get_home_from_pop(DATA.get_home_from_pop(child))
				if home_location ~= origin then
					return false
				end

				local unit_of = DATA.pop_get_unit_of_warband(child)
				if unit_of ~= nil then
					return false
				end

				local employer = DATA.pop_get_employer(child)
				if employer ~= nil then
					return false
				end

				return true;
			end
		)

	for _, c in ipairs(relevant_children) do
		prov.Province.transfer_home(origin, c, target)
	end
end

---Kills a single pop and removes it from all relevant references.
---@param province province_id
---@param pop pop_id
function prov.Province.kill_pop(province, pop)
	-- print("kill " .. pop.name)

	prov.Province.fire_pop(province, pop)
	pop_utils.unregister_military(pop)

	DATA.delete_pop(pop)
end

---@param province province_id
function prov.Province.local_army_size(province)
	local total = 0
	for _, w in pairs(DATA.province_get_warbands(province)) do
		if w.status == "idle" or w.status == "patrol" then
			total = total + w:size()
		end
	end
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
function prov.Province.return_pop_from_army(province, pop, unit_type)
	prov.Province.add_guest_pop(province, pop)
end

---Fires an employed pop and adds it to the unemployed pops list.
---It leaves the "job" set so that inference of social class can be performed.
---@param province province_id
---@param pop pop_id
function prov.Province.fire_pop(province, pop)
	local employer = DATA.pop_get_employer(pop)
	if employer then
		employer.workers[pop] = nil
		if tabb.size(employer.workers) == 0 then
			employer.last_income = 0
			employer.last_donation_to_owner = 0
			employer.subsidy_last = 0
		end
		DATA.pop_set_employer(pop, nil)
		DATA.pop_set_job(pop, nil)
	end
end

---Employs a pop and handles its removal from relevant data structures...
---@param province province_id
---@param pop pop_id
---@param building Building
function prov.Province.employ_pop(province, pop, building)
	local employer = DATA.pop_get_employer(pop)
	if employer ~= building then
		local potential_job = prov.Province.potential_job(province, building)
		if potential_job then
			-- Now that we know that the job is needed, employ the pop!
			-- ... but fire them first to update the previous building
			if employer ~= nil then
				prov.Province.fire_pop(province, pop)
			end
			building.workers[pop] = pop
			DATA.pop_set_employer(pop, building)
			DATA.pop_set_job(pop, potential_job)
		end
	end
end

---Returns a potential job, if a pop was to be employed by this building.
---@param province province_id
---@param building Building
---@return Job?
function prov.Province.potential_job(province, building)
	for job, amount in pairs(building.type.production_method.jobs) do
		-- Make sure that the building doesn't have this job filled out...
		local actually_employed = 0
		for _, worker in pairs(building.workers) do
			local worker_job = DATA.pop_get_job(worker)
			if worker_job == job then
				actually_employed = actually_employed + 1
			end
		end
		if actually_employed < amount then
			return job
		end
	end
	return nil
end

---@param province province_id
---@param technology Technology
function prov.Province.research(province, technology)
	self.technologies_present[technology] = technology
	self.technologies_researchable[technology] = nil

	for _, t in pairs(technology.potentially_unlocks) do
		if self.technologies_present[t] == nil then
			--print(t.name)
			local ok = true
			if #t.required_resource > 0 then
				--print(t.name .. " -- --!")
				local new_ok = false
				for _, resource in pairs(t.required_resource) do
					if self.local_resources[resource] then
						new_ok = true
						break
					end
				end
				if not new_ok then
					ok = false
				else
					--print("notok")
				end
			end
			if #t.required_race > 0 then
				local new_ok = false
				for _, race in pairs(t.required_race) do
					if race == self.realm.primary_race then
						new_ok = true
						break
					end
				end
				if not new_ok then
					ok = false
				end
			end
			if #t.required_biome > 0 then
				local new_ok = false
				for _, biome in pairs(t.required_biome) do
					if biome == DATA.tile_get_biome(self.center) then
						new_ok = true
						break
					end
				end
				if not new_ok then
					ok = false
				end
			end
			if #t.unlocked_by > 0 then
				local new_ok = true
				for _, te in pairs(t.unlocked_by) do
					if self.technologies_present[te] then
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
			if ok then
				self.technologies_researchable[t] = t
			end
		end
	end
	for _, b in pairs(technology.unlocked_buildings) do
		local ok = true
		if #b.required_biome > 0 then
			ok = false
			for _, biome in pairs(b.required_biome) do
				if biome == DATA.tile_get_biome(self.center) then
					ok = true
					break
				end
			end
		end
		if ok then
			self.buildable_buildings[b] = b
		end
	end
	for _, u in pairs(technology.unlocked_unit_types) do
		self.unit_types[u] = u
	end
	for prod, am in pairs(technology.throughput_boosts) do
		local old = self.throughput_boosts[prod] or 0
		self.throughput_boosts[prod] = old + am
	end
	for prod, am in pairs(technology.input_efficiency_boosts) do
		local old = self.input_efficiency_boosts[prod] or 0
		self.input_efficiency_boosts[prod] = old + am
	end
	for prod, am in pairs(technology.output_efficiency_boosts) do
		local old = self.output_efficiency_boosts[prod] or 0
		self.output_efficiency_boosts[prod] = old + am
	end

	if WORLD:does_player_see_realm_news(self.realm) then
		WORLD:emit_notification("Technology unlocked: " .. technology.name)
	end
end

---Forget technology
---@param province province_id
---@param technology Technology
function prov.Province.forget(province, technology)
	self.technologies_present[technology] = nil
	self.technologies_researchable[technology] = technology

	-- temporary forget all buildings and bonuses
	self.buildable_buildings = {}
	self.unit_types = {}
	self.throughput_boosts = {}
	self.input_efficiency_boosts = {}
	self.output_efficiency_boosts = {}

	-- relearn everything
	-- sounds like a horrible solution
	-- but after some thinking,
	-- you would need to do all these checks
	-- for all techs anyway
	-- because there are no assumptions for a graph of technologies
	for _, old_technology in pairs(self.technologies_present) do
		prov.Province.research(old_technology)
	end
end

---@param province province_id
---@param building_type BuildingType
---@return boolean
function prov.Province.building_type_present(province, building_type)
	for bld in pairs(DATA.province_get_buildings(province)) do
		if bld.type == building_type then
			return true
		end
	end
	return false
end

---@alias BuildingAttemptFailureReason "ok" | "not_enough_funds" | "unique_duplicate" | "missing_local_resources" | "no_permission"

---comment
---@param province province_id
---@param funds number
---@param building BuildingType
---@param overseer pop_id?
---@param public boolean
---@return boolean
---@return BuildingAttemptFailureReason
function prov.Province.can_build(province, funds, building, overseer, public)
	local resource_check_passed = true
	if #building.required_resource > 0 then
		resource_check_passed = false
		for _, tile_id in pairs(self.tiles) do
			if DATA.tile_get_resource(tile_id) then
				for _, res in pairs(building.required_resource) do
					if DATA.tile_get_resource(tile_id) == res then
						resource_check_passed = true
						goto RESOURCE_CHECK_ENDED
					end
				end
			end
		end
		::RESOURCE_CHECK_ENDED::
	end

	local construction_cost = EconomicValues.building_cost(building, overseer, public)

	if not economic_triggers.allowed_to_build(overseer, self.realm) then
		return false, "no_permission"
	end

	if building.unique and prov.Province.building_type_present(building) then
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
---@param pop pop_id
function prov.Province.outlaw_pop(province, pop)
	-- ignore pops which are already outlawed
	if DATA.get_outlaw_location_from_outlaw(pop) then
		return
	end

	prov.Province.fire_pop(province, pop)
	pop_utils.unregister_military(pop)

	local id = DATA.create_outlaw_location()
	DATA.outlaw_location_set_location(id, province)
	DATA.outlaw_location_set_outlaw(id, pop)

	local pop_location = DATA.get_pop_location_from_pop(pop)
	if pop_location then
		return
	end
	DATA.delete_pop_location(pop_location)
end

---Marks a pop as a soldier of a given type in a given warband.
---@param province province_id
---@param pop pop_id
---@param unit_type UnitType
---@param warband Warband
function prov.Province.recruit(province, pop, unit_type, warband)
	-- if pop is already drafted, do nothing
	if DATA.pop_get_unit_of_warband(pop) then
		return
	end

	-- clean pop and set his unit type
	prov.Province.fire_pop(province, pop)
	pop_utils.unregister_military(pop)

	-- set warband
	warband:hire_unit(province, pop, unit_type)
end

---@param province province_id
---@return Culture|nil
function prov.Province.get_dominant_culture(province)
	---@type table<Culture, number>
	local e = {}
	for _, p in pairs(DATA.get_pop_location_from_location(province)) do
		local pop_id = DATA.pop_location_get_pop(p)
		local culture = DATA.pop_get_culture(p)
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
---@return Faith|nil
function prov.Province.get_dominant_faith(province)
	---@type table<Faith, number>
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
---@return race_id|nil
function prov.Province.get_dominant_race(province)
	---@type table<race_id, number>
	local e = {}
	for _, p in pairs(DATA.get_pop_location_from_location(province)) do
		local pop_id = DATA.pop_location_get_pop(p)
		local race = DATA.pop_get_race(pop_id)

		local old = e[race] or 0
		e[race] = old + 1
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

---Returns whether or not a province borders a given realm
---@param province province_id
---@param realm Realm
---@return boolean
function prov.Province.neighbors_realm(province, realm)
	for _, n in pairs(DATA.get_province_neighborhood_from_origin(province)) do
		local neighbor = DATA.province_neighborhood_get_target(n)
		local neighbor_realm = DATA.province_get_realm(neighbor)
		if neighbor_realm == realm then
			return true
		end
	end
	return false
end

---Returns whether or not a province borders a given realm
---@param province province_id
---@param realm Realm
---@return boolean
function prov.Province.neighbors_realm_tributary(province, realm)
	for _, n in pairs(DATA.get_province_neighborhood_from_origin(province)) do
		local neighbor = DATA.province_neighborhood_get_target(n)
		local neighbor_realm = DATA.province_get_realm(neighbor)

		if neighbor_realm and neighbor_realm:is_realm_in_hierarchy(realm) then
			return true
		end
	end
	return false
end

---@param province province_id
---@return number
function prov.Province.get_spotting(province)
	local s = 0

	for _, p in pairs(DATA.get_pop_location_from_location(province)) do
		local pop_id = DATA.pop_location_get_pop(p)
		local race = DATA.pop_get_race(pop_id)
		s = s + DATA.race_get_spotting(race)
	end

	for b, _ in pairs(self.buildings) do
		s = s + b.type.spotting
	end

	for _, w in pairs(self.warbands) do
		if w.status == "idle" or w.status == "patrol" then
			s = s + w:spotting()
		end
	end

	return s
end

---@param province province_id
---@return number
function prov.Province.get_hiding(province)
	local hide = 1
	for t, _ in pairs(DATA.get_tile_province_membership_from_province(province)) do
		local tile_id = DATA.tile_province_membership_get_tile(t)
		local grass = DATA.tile_get_grass(tile_id)
		local shrub = DATA.tile_get_shrub(tile_id)
		local conifer = DATA.tile_get_conifer(tile_id)
		local broadleaf = DATA.tile_get_broadleaf(tile_id)
		hide = hide + 1 + grass + shrub * 2 + conifer * 3 + broadleaf * 5
	end
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
---@param army Army Attacking army
---@param stealth_penalty number? Multiplicative penalty, multiplies army visibility score.
---@return boolean True if the army was spotted.
function prov.Province.army_spot_test(province, army, stealth_penalty)
	-- To resolve this event we need to perform some checks.
	-- First, we should have a "scouting" check.
	-- Them, a potential battle ought to take place.`
	if stealth_penalty == nil then
		stealth_penalty = 1
	end

	local visib = (army:get_visibility() + love.math.random(20)) * stealth_penalty
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
---@return table<Job, number>
function prov.Province.get_job_ratios(province)
	---@type table<Job, number>
	local r = {}

	local pop = 0

	for _, p in pairs(DATA.get_pop_location_from_location(province)) do
		local pop_id = DATA.pop_location_get_pop(p)

		local job = DATA.pop_get_job(pop_id)
		if job then
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

		local unit_of = DATA.pop_get_unit_of_warband(pop_id)
		local job = DATA.pop_get_job(pop_id)
		if job then

		elseif unit_of then

		else
			u = u + 1
		end
	end

	return u
end

---@param province province_id
function prov.Province.new_warband(province)
	local warband = wb:new()
	self.warbands[warband] = warband
	return warband
end

---@param province province_id
function prov.Province.num_of_warbands(province)
	return tabb.size(self.warbands)
end

---@param province province_id
function prov.Province.vacant_warbands(province)
	local res = {}

	for k, v in pairs(self.warbands) do
		if v:vacant() then
			table.insert(res, k)
		end
	end

	return res
end

---@param province province_id
function prov.Province.exploration_days(province)
	return DATA.province_get_movement_cost(province) / 5
end

return prov
