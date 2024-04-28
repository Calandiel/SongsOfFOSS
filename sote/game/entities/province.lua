local tabb = require "engine.table"
local wb = require "game.entities.warband"

local EconomicValues = require "game.raws.values.economical"
local economic_triggers = require "game.raws.triggers.economy"

---@alias Character POP

local prov = {}

---@class (exact) Province
---@field __index Province
---@field name string
---@field r number
---@field g number
---@field b number
---@field is_land boolean
---@field province_id number
---@field size number
---@field tiles table<Tile, Tile>
---@field hydration number Number of humans that can live of off this provinces innate water
---@field neighbors table<Province, Province>
---@field movement_cost number
---@field center Tile The tile which contains this province's settlement, if there is any.
---@field infrastructure_needed number
---@field infrastructure number
---@field infrastructure_investment number
---@field realm Realm?
---@field buildings table<Building, Building>
---@field all_pops table<POP, POP> -- all pops
---@field characters table<Character, Character>
---@field home_to table<POP, POP> Set of characters and pops which think of this province as their home
---@field technologies_present table<Technology, Technology>
---@field technologies_researchable table<Technology, Technology>
---@field buildable_buildings table<BuildingType, BuildingType>
---@field local_production table<TradeGoodReference, number>
---@field local_consumption table<TradeGoodReference, number>
---@field local_demand table<TradeGoodReference, number>
---@field local_storage table<TradeGoodReference, number>
---@field local_prices table<TradeGoodReference, number|nil>
---@field local_wealth number
---@field trade_wealth number
---@field local_income number
---@field local_building_upkeep number
---@field foragers number Keeps track of the number of foragers in the province. Used to calculate yields of independent foraging.
---@field foragers_limit number
---@field foragers_targets table<ForageResource, {icon: string, output: table<TradeGoodReference, number>, amount: number, handle: JOBTYPE}>
---@field local_resources table<Resource, Resource> A hashset containing all resources present on tiles of this province
---@field local_resources_location {[1]: Tile, [2]: Resource}[] An array of local resources and their positions
---@field mood number how local population thinks about the state
---@field outlaws table<POP, POP>
---@field unit_types table<UnitType, UnitType>
---@field warbands table<Warband, Warband>
---@field throughput_boosts table<ProductionMethod, number>
---@field input_efficiency_boosts table<ProductionMethod, number>
---@field output_efficiency_boosts table<ProductionMethod, number>
---@field on_a_river boolean
---@field on_a_forest boolean

local col = require "game.color"

---@class Province
prov.Province = {}
prov.Province.__index = prov.Province

---Returns a new province. Remember to assign "center" tile!
---@param fake_flag boolean? do not register province if true
---@return Province
function prov.Province:new(fake_flag)
	---@type Province
	local o = {}

	o.name = "<uninhabited>"

	local r, g, b = col.hsv_to_rgb(
		love.math.random(),
		0.9 + 0.1 * love.math.random(),
		0.9 + 0.1 * love.math.random()
	)
	o.r = r
	o.g = g
	o.b = b

	o.outlaws = {}
	o.mood = 0
	o.province_id = WORLD.entity_counter
	o.tiles = {}
	o.size = 0
	o.neighbors = {}
	o.movement_cost = 1
	o.foragers_limit = 0
	o.is_land = false
	o.buildings = {}
	o.all_pops = {}
	o.characters = {}
	o.home_to = {}
	o.technologies_present = {}
	o.technologies_researchable = {}
	o.buildable_buildings = {}
	o.hydration = 5
	o.local_resources = {}
	o.local_resources_location = {}
	o.local_production = {}
	o.local_consumption = {}
	o.local_demand = {}
	o.local_storage = {}
	o.local_prices = {}
	o.local_wealth = 0
	o.trade_wealth = 0
	o.local_income = 0
	o.local_building_upkeep = 0
	o.foragers = 0
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
		WORLD.entity_counter = WORLD.entity_counter + 1
		WORLD.provinces[o.province_id] = o
		table.insert(WORLD.ordered_provinces_list, o)
		WORLD.province_count = WORLD.province_count + 1
	end

	setmetatable(o, prov.Province)
	return o
end

function prov.Province:get_random_neighbor()
	local s = tabb.size(self.neighbors)
	return tabb.nth(self.neighbors, love.math.random(s))
end

---Adds a tile to the province. Handles removal from the previous province, if necessary.
---@param tile Tile
function prov.Province:add_tile(tile)
	--- easiest way to handle it, i guess
	if tile.is_land then
		self.is_land = true
	end

	if tile.province ~= nil then
		tile.province.size = tile.province.size - 1
		tile.province.tiles[tile] = nil
	end
	self.tiles[tile] = tile
	self.size = self.size + 1
	tile.province = self
end

---Returns the total military size of the province.
---@return number
function prov.Province:military()
	local total = 0
	for _, party in pairs(self.warbands) do
		total = total + party:size()
	end
	return total
end

---Returns the total target military size of the province.
---@return number
function prov.Province:military_target()
	local sum = 0
	for _, warband in pairs(self.warbands) do
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
---@return number
function prov.Province:local_population()
	return tabb.size(self.all_pops)
end

---Returns the total count of all pops who consider this province home, not including characters.
---Doesn't include outlaws and active armies.
---@return number
function prov.Province:home_population()
	return tabb.size(tabb.filter(self.home_to, function (a)
		return not a:is_character()
	end))
end

---Returns the total count of all pops who consider this province home, not including characters.
---Doesn't include outlaws and active armies.
---@return number
function prov.Province:home_characters()
	return tabb.size(tabb.filter(self.home_to, function (a)
		return a:is_character()
	end))
end

---Returns the total count of all pops who consider this province home, including characters.
---Doesn't include outlaws and active armies.
---@return number
function prov.Province:total_home_population()
	return tabb.size(self.home_to)
end

function prov.Province:validate_population()
	for _, pop in pairs(self.all_pops) do
		if pop.province == nil then
			error("POP " .. pop.name .. " DOESN'T HAVE PROVINCE")
		end
		if pop.province ~= self then
			error("POP " .. pop.name .. " HAS WRONG PROVINCE SET")
		end
	end

	for _, pop in pairs(self.home_to) do
		if pop.home_province == nil then
			error("POP " .. pop.name .. " DOESN'T HAVE HOME PROVINCE")
		end
		if pop.home_province ~= self then
			error("POP " .. pop.name .. " HAS WRONG HOME PROVINCE SET")
		end
	end

	for _, pop in pairs(self.characters) do
		if pop.province == nil then
			error("Character " .. pop.name .. " DOESN'T HAVE PROVINCE")
		end
		if pop.province ~= self then
			error("Character " .. pop.name .. " HAS WRONG PROVINCE SET")
		end
	end
end

---Returns the total population of the province.
---@return number
function prov.Province:population_weight()
	local total = 0
	for _, pop in pairs(self.all_pops) do
		total = total + pop.race.carrying_capacity_weight
	end
	return total
end

---Adds a pop to the province. Sets province as a home. Does not handle cleaning of old data
---@param pop POP
function prov.Province:add_pop(pop)
	self:add_guest_pop(pop)
	self:set_home(pop)
end

---Adds pop as a guest of this province. Preserves old home of a pop.
---@param pop POP
function prov.Province:add_guest_pop(pop)
	self.all_pops[pop] = pop
	pop.province = self
end

---Adds a character to the province
---@param character Character
function prov.Province:add_character(character)
	-- print(character.name, "-->", self.name)

	self.characters[character] = character
	character.province = self
end

---Sets province as pop's home
---@param pop POP
function prov.Province:set_home(pop)
	-- print('SET HOME', pop.name)

	self.home_to[pop] = pop
	pop.home_province = self
	pop.realm = self.realm
end

--- Transfers a character to the target province
---@param character Character
---@param target Province
function prov.Province:transfer_character(character, target)
	-- print(character.name, "CHARACTER", self.name, "-->", target.name)
	if character.province ~= self then
		error("CHARACTER DOES NOT HAS ACCORDING PROVINCE ")
	end

	self.characters[character] = nil
	target.characters[character] = character

	character.province = target
end

--- Transfers a pop to the target province
---@param pop POP
---@param target Province
function prov.Province:transfer_pop(pop, target)
	-- print(pop.name, "POP", self.name, "-->", target.name)
	if pop.province ~= self then
		error("POP DOES NOT HAS ACCORDING PROVINCE ")
	end

	self.all_pops[pop] = nil
	target.all_pops[pop] = pop

	pop.province = target

	local children = tabb.filter(pop.children, function(c)
		return self.all_pops[c] and c.home_province ~= self
			and not c.unit_of_warband and not c.employer
	end)
	for _, c in pairs(children) do
		self:transfer_pop(c, target)
	end
end

--- Changes home province of a pop/character to the target province
---@param pop Character
---@param target Province
function prov.Province:transfer_home(pop, target)
	if pop.home_province ~= self then
		error("POP DOES NOT HAS ACCORDING HOME PROVINCE ")
	end

	self:set_home_pop_nil_wrapper(pop)
	target:set_home(pop)
	local children = tabb.filter(pop.children, function(c)
		return self.all_pops[c] and not c.unit_of_warband and not c.employer
	end)
	for _, c in pairs(children) do
		self:transfer_home(c, target)
	end
end

--- Removes a character from the province
---@param character Character
function prov.Province:remove_character(character)
	-- print(character.name, "R", self.name, character.province.name)
	self.characters[character] = nil
	character.province = nil
end

---Wrapper for setting table value to nil for easier logging
---@param pop any
function prov.Province:set_home_pop_nil_wrapper(pop)
	-- print('UNSET HOME', pop.name, self.name)
	self.home_to[pop] = nil
end

--- Pop stops thinking of this province as a home
---@param pop POP
function prov.Province:unset_home(pop)
	self:set_home_pop_nil_wrapper(pop)
	pop.home_province = nil
end

---Kills a single pop and removes it from all relevant references.
---@param pop POP
function prov.Province:kill_pop(pop)
	-- print("kill " .. pop.name)

	self:fire_pop(pop)
	pop:unregister_military()
	self.all_pops[pop] = nil
	self:set_home_pop_nil_wrapper(pop)

	self.outlaws[pop] = nil
	pop.province = nil

	if pop.home_province then
		pop.home_province:unset_home(pop)
	end

	if pop.parent then pop.parent.children[pop] = nil end
	for _, c in pairs(pop.children) do
		c.parent = nil
		pop.children[c] = nil
	end
end

function prov.Province:local_army_size()
	local total = 0
	for _, w in pairs(self.warbands) do
		if w.status == "idle" or w.status == "patrol" then
			total = total + w:size()
		end
	end
	return total
end

---Removes the pop from the province without killing it  \
---Does not change home province of pop
---@param pop POP
---@return POP
function prov.Province:take_away_pop(pop)
	-- print("take away", pop.name)
	self.all_pops[pop] = nil
	return pop
end

function prov.Province:return_pop_from_army(pop, unit_type)
	-- print("return", pop.name)
	self.all_pops[pop] = pop
	return pop
end

---Fires an employed pop and adds it to the unemployed pops list.
---It leaves the "job" set so that inference of social class can be performed.
---@param pop POP
function prov.Province:fire_pop(pop)
	if pop.employer then
		pop.employer.workers[pop] = nil
		if tabb.size(pop.employer.workers) == 0 then
			pop.employer.last_income = 0
			pop.employer.last_donation_to_owner = 0
			pop.employer.subsidy_last = 0
		end
		pop.employer = nil
		pop.job = nil -- clear the job!
	end
end

---Employs a pop and handles its removal from relevant data structures...
---@param pop POP
---@param building Building
function prov.Province:employ_pop(pop, building)
	if pop.employer ~= building then
		local potential_job = self:potential_job(building)
		if potential_job then
			-- Now that we know that the job is needed, employ the pop!
			-- ... but fire them first to update the previous building
			if pop.employer ~= nil then
				self:fire_pop(pop)
			end
			building.workers[pop] = pop
			pop.employer = building
			pop.job = potential_job
		end
	end
end

---Returns a potential job, if a pop was to be employed by this building.
---@param building Building
---@return Job?
function prov.Province:potential_job(building)
	for job, amount in pairs(building.type.production_method.jobs) do
		-- Make sure that the building doesn't have this job filled out...
		local actually_employed = 0
		for _, worker in pairs(building.workers) do
			if worker.job == job then
				actually_employed = actually_employed + 1
			end
		end
		if actually_employed < amount then
			return job
		end
	end
	return nil
end

---@param technology Technology
function prov.Province:research(technology)
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
					if biome == self.center.biome then
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
			for _, biome in b.required_biome do
				if biome == self.center.biome then
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
---@param technology Technology
function prov.Province:forget(technology)
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
		self:research(old_technology)
	end
end

---@param building_type BuildingType
---@return boolean
function prov.Province:building_type_present(building_type)
	for bld in pairs(self.buildings) do
		if bld.type == building_type then
			return true
		end
	end
	return false
end

---@alias BuildingAttemptFailureReason "ok" | "not_enough_funds" | "unique_duplicate" | "missing_local_resources" | "no_permission"

---comment
---@param funds number
---@param building BuildingType
---@param overseer POP?
---@param public boolean
---@return boolean
---@return BuildingAttemptFailureReason
function prov.Province:can_build(funds, building, overseer, public)
	local resource_check_passed = true
	if #building.required_resource > 0 then
		resource_check_passed = false
		for _, tile in pairs(self.tiles) do
			if tile.resource then
				for _, res in pairs(building.required_resource) do
					if tile.resource == res then
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

	if building.unique and self:building_type_present(building) then
		return false, "unique_duplicate"
	elseif not resource_check_passed then
		return false, "missing_local_resources"
	elseif construction_cost <= funds then
		return true, "ok"
	else
		return false, "not_enough_funds"
	end
end

---@return number
function prov.Province:get_infrastructure_efficiency()
	local inf = 0
	if self.infrastructure_needed > 0 then
		inf = 2 * self.infrastructure / (self.infrastructure + self.infrastructure_needed)
	end
	return inf
end

---@param pop POP
function prov.Province:outlaw_pop(pop)
	self:fire_pop(pop)
	pop:unregister_military()
	self.all_pops[pop] = nil
	self.outlaws[pop] = pop
end

---Marks a pop as a soldier of a given type in a given warband.
---@param pop POP
---@param unit_type UnitType
---@param warband Warband
function prov.Province:recruit(pop, unit_type, warband)
	-- if pop is already drafted, do nothing
	if pop.unit_of_warband then
		return
	end

	-- clean pop and set his unit type
	self:fire_pop(pop)
	pop:unregister_military()

	-- set warband
	warband:hire_unit(self, pop, unit_type)
end

---@return Culture|nil
function prov.Province:get_dominant_culture()
	local e = {}
	for _, p in pairs(self.all_pops) do
		local old = e[p.culture] or 0
		e[p.culture] = old + 1
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

---@return Faith|nil
function prov.Province:get_dominant_faith()
	local e = {}
	for _, p in pairs(self.all_pops) do
		local old = e[p.faith] or 0
		e[p.faith] = old + 1
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

---@return Race|nil
function prov.Province:get_dominant_race()
	local e = {}
	for _, p in pairs(self.all_pops) do
		local old = e[p.race] or 0
		e[p.race] = old + 1
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
---@param realm Realm
---@return boolean
function prov.Province:neighbors_realm(realm)
	for _, n in pairs(self.neighbors) do
		if n.realm == realm then
			return true
		end
	end
	return false
end

---Returns whether or not a province borders a given realm
---@param realm Realm
---@return boolean
function prov.Province:neighbors_realm_tributary(realm)
	for _, n in pairs(self.neighbors) do
		if n.realm and n.realm:is_realm_in_hierarchy(realm) then
			return true
		end
	end
	return false
end

---@return number
function prov.Province:get_spotting()
	local s = 0

	for p, _ in pairs(self.all_pops) do
		s = s + p.race.spotting
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

---@return number
function prov.Province:get_hiding()
	local hide = 1
	for t, _ in pairs(self.tiles) do
		hide = hide + 1 + t.grass + t.shrub * 2 + t.conifer * 3 + t.broadleaf * 5
	end
	return hide
end

function prov.Province:spot_chance(visibility)
	local spot = self:get_spotting()
	local hiding = self:get_hiding()
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

---@param army Army Attacking army
---@param stealth_penalty number? Multiplicative penalty, multiplies army visibility score.
---@return boolean True if the army was spotted.
function prov.Province:army_spot_test(army, stealth_penalty)
	-- To resolve this event we need to perform some checks.
	-- First, we should have a "scouting" check.
	-- Them, a potential battle ought to take place.`
	if stealth_penalty == nil then
		stealth_penalty = 1
	end

	local visib = (army:get_visibility() + love.math.random(20)) * stealth_penalty
	local odds = self:spot_chance(visib)
	if love.math.random() < odds then
		-- Spot!
		return true
	else
		-- Hide!
		return false
	end
end

function prov.Province:get_job_ratios()
	local r = {}

	local pop = 0
	for p, _ in pairs(self.all_pops) do
		if p.job then
			local old = r[p.job] or 0
			r[p.job] = old + 1
		end
		pop = pop + 1
	end
	for job, am in pairs(r) do
		r[job] = am / pop
	end

	return r
end

---Returns the number of unemployed people in the province.
---@return integer
function prov.Province:get_unemployment()
	local u = 0

	for _, p in pairs(self.all_pops) do
		if not p.unit_of_warband and p.job == nil then
			u = u + 1
		end
	end

	return u
end

function prov.Province:new_warband()
	local warband = wb:new()
	self.warbands[warband] = warband
	return warband
end

function prov.Province:num_of_warbands()
	return tabb.size(self.warbands)
end

function prov.Province:vacant_warbands()
	local res = {}

	for k, v in pairs(self.warbands) do
		if v:vacant() then
			table.insert(res, k)
		end
	end

	return res
end

function prov.Province:exploration_days()
	return self.movement_cost / 5
end

return prov
