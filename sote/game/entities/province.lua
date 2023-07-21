local tabb = require "engine.table"
local wb = require "game.entities.warband"

---@alias Character POP

local prov = {}

---@class Province
---@field name string
---@field r number
---@field g number
---@field b number
---@field province_id number
---@field new fun(self:Province):Province
---@field add_tile fun(self: Province, tile: Tile)
---@field size number
---@field tiles table<Tile, Tile>
---@field hydration number Number of humans that can live of off this provinces innate water
---@field neighbors table<Province, Province>
---@field movement_cost number
---@field center Tile The tile which contains this province's settlement, if there is any.
---@field infrastructure_needed number
---@field infrastructure number
---@field infrastructure_investment number
---@field get_infrastructure_efficiency fun(self:Province):number
---@field realm Realm?
---@field buildings table<Building, Building>
---@field all_pops table<POP, POP> -- all pops
---@field characters table<Character, Character>
---@field neighbors_realm fun(self:Province, realm:Realm):boolean Returns whether or not a province borders a given realm
---@field military fun(self:Province):number
---@field military_target fun(self:Province):number
---@field population fun(self:Province):number
---@field population_weight fun(self:Province):number
---@field add_pop fun(self:Province, pop:POP)
---@field add_character fun(self:Province, pop:Character)
---@field kill_pop fun(self:Province, pop:POP)
---@field fire_pop fun(self:Province, pop:POP)
---@field unregister_military_pop fun(self:Province, pop:POP) The "fire" routine for soldiers. Also used in some other contexts?
---@field employ_pop fun(self:Province, pop:POP, building:Building)
---@field potential_job fun(self:Province, building:Building):Job?
---@field technologies_present table<Technology, Technology>
---@field technologies_researchable table<Technology, Technology>
---@field buildable_buildings table<BuildingType, BuildingType>
---@field research fun(self:Province, technology:Technology)
---@field local_production table<TradeGood, number>
---@field local_consumption table<TradeGood, number>
---@field local_wealth number
---@field local_income number
---@field local_building_upkeep number
---@field foragers number Keeps track of the number of foragers in the province. Used to calculate yields of independent foraging.
---@field foragers_limit number
---@field can_build fun(self:Province, funds:number, building:BuildingType, location:Tile?):boolean,BuildingAttemptFailureReason?
---@field building_type_present fun(self:Province, building:BuildingType):boolean Returns true when a building of a given type has been built in a province
---@field local_resources table<Resource, Resource> A hashset containing all resources present on tiles of this province
---@field mood number how local population thinks about the state
---@field outlaws table<POP, POP>
---@field outlaw_pop fun(self:Province, pop:POP) Marks a pop as an outlaw
---@field recruit fun(self:Province, pop:POP, unit_type:UnitType) Marks a pop as a soldier of a given type
---@field get_dominant_culture fun(self:Province):Culture|nil
---@field get_dominant_faith fun(self:Province):Faith|nil
---@field get_dominant_race fun(self:Province):Race|nil
---@field soldiers table<POP, UnitType>
---@field unit_types table<UnitType, UnitType>
---@field units table<UnitType, table<POP, POP>> Recruited units
---@field units_target table<UnitType, number> Units to recruit
---@field warbands table<Warband, Warband>
---@field vacant_warbands fun(self: Province): Warband[]
---@field get_spotting fun(self:Province):number Returns the local "spotting" power
---@field get_hiding fun(self:Province):number Returns the local "hiding" space
---@field spot_chance fun(self:Province, visibility: number): number Returns a chance to spot an army with given visibility.
---@field army_spot_test fun(self:Province, army:Army):boolean Performs an army spotting test in this province.
---@field get_job_ratios fun(self:Province):table<Job, number> Returns a table containing jobs mapped to fractions of population. Used for, among other things, research.
---@field get_unemployment fun(self:Province):number Returns the number of unemployed people in the province.
---@field throughput_boosts table<ProductionMethod, number>
---@field input_efficiency_boosts table<ProductionMethod, number>
---@field output_efficiency_boosts table<ProductionMethod, number>
---@field on_a_river boolean
---@field take_away_pop fun(self:Province, pop:POP): POP
---@field return_pop_from_army fun(self:Province, pop:POP, unit_type:UnitType): POP

local col = require "game.color"

---@type Province
prov.Province = {}
prov.Province.__index = prov.Province
---Returns a new province. Remember to assign 'center' tile!
---@return Province
function prov.Province:new()
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
	o.technologies_present = {}
	o.technologies_researchable = {}
	o.buildable_buildings = {}
	o.hydration = 5
	o.local_resources = {}
	o.local_production = {}
	o.local_consumption = {}
	o.local_wealth = 0
	o.local_income = 0
	o.local_building_upkeep = 0
	o.foragers = 0
	o.infrastructure_needed = 0
	o.infrastructure = 0
	o.infrastructure_investment = 0
	o.unit_types = {}
	o.soldiers = {}
	o.units = {}
	o.units_target = {}
	o.throughput_boosts = {}
	o.input_efficiency_boosts = {}
	o.output_efficiency_boosts = {}
	o.on_a_river = false
	o.warbands = {}

	WORLD.entity_counter = WORLD.entity_counter + 1
	WORLD.provinces[o.province_id] = o

	setmetatable(o, prov.Province)
	return o
end

---Adds a tile to the province. Handles removal from the previous province, if necessary.
---@param tile Tile
function prov.Province:add_tile(tile)
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
	local tabb = require "engine.table"
	return tabb.size(self.soldiers)
end

---Returns the total target military size of the province.
---@return number
function prov.Province:military_target()
	local sum = 0
	for _, u in pairs(self.units_target) do
		sum = sum + u
	end
	return sum
end

---Returns the total population of the province.
---Doesn't include outlaws and active armies.
---@return number
function prov.Province:population()
	local tabb = require "engine.table"
	return tabb.size(self.all_pops)
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

---Adds a pop to the province
---@param pop POP
function prov.Province:add_pop(pop)
	self.all_pops[pop] = pop
end

---Adds a character to the province
---@param character Character
function prov.Province:add_character(character)
	self.characters[character] = character
end

---Kills a single pop and removes it from all relevant references.
---@param pop POP
function prov.Province:kill_pop(pop)
	self:fire_pop(pop)
	self:unregister_military_pop(pop)
	self.all_pops[pop] = nil
	self.outlaws[pop] = nil
end

---Unregisters a pop as a military pop.
---@param pop POP
function prov.Province:unregister_military_pop(pop)
	if self.soldiers[pop] then
		local ut = self.soldiers[pop]
		self.units[ut][pop] = nil
		pop.drafted = false
	end
	for _, warband in pairs(self.warbands) do
		warband.units[pop] = nil
		warband.pops[pop] = nil
	end
	self.soldiers[pop] = nil
end


---Removes the pop from the province without killing it
function prov.Province:take_away_pop(pop)
	if self.soldiers[pop] then
		local unit_type = self.soldiers[pop]
		self.units[unit_type][pop] = nil
		self.units_target[unit_type] = self.units_target[unit_type] - 1
	end
	self.soldiers[pop] = nil
	self.all_pops[pop] = nil

	return pop
end

function prov.Province:return_pop_from_army(pop, unit_type)
	self.units[unit_type][pop] = pop
	self.units_target[unit_type] = self.units_target[unit_type] + 1
	self.soldiers[pop] = unit_type
	self.all_pops[pop] = pop
	return pop
end

---Fires an employed pop and adds it to the unemployed pops list.
---It leaves the "job" set so that inference of social class can be performed.
---@param pop POP
function prov.Province:fire_pop(pop)
	if pop.employer then
		pop.employer.workers[pop] = nil
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
		self.units[u] = {}
		self.units_target[u] = 0
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

---@alias BuildingAttemptFailureReason 'not_enough_funds' | 'unique_duplicate' | 'tile_improvement' | 'missing_local_resources'

---@param funds number
---@param building BuildingType
---@param location Tile?
---@return boolean, BuildingAttemptFailureReason?
function prov.Province:can_build(funds, building, location)
	local resource_check_passed = true
	if #building.required_resource > 0 then
		resource_check_passed = false
		if building.tile_improvement then
			if location then
				if location.resource then
					for _, res in pairs(building.required_resource) do
						if location.resource == res then
							resource_check_passed = true
							goto RESOURCE_CHECK_ENDED
						end
					end
				end
			end
		else
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
		end
		::RESOURCE_CHECK_ENDED::
	end
	if building.unique and self:building_type_present(building) then
		return false, 'unique_duplicate'
	elseif building.tile_improvement and location == nil then
		return false, 'tile_improvement'
	elseif not resource_check_passed then
		return false, 'missing_local_resources'
	elseif building.construction_cost <= funds then
		return true, nil
	else
		return false, 'not_enough_funds'
	end
end

---@return number
function prov.Province:get_infrastructure_efficiency()
	local inf = 0
	if self.infrastructure_needed > 0 then
		inf = self.infrastructure / self.infrastructure_needed
	end
	return inf
end

---@param pop POP
function prov.Province:outlaw_pop(pop)
	self:fire_pop(pop)
	self:unregister_military_pop(pop)
	self.all_pops[pop] = nil
	self.outlaws[pop] = pop
end

---@param pop POP
---@param unit_type UnitType
function prov.Province:recruit(pop, unit_type)
	-- if pop is already drafted, do nothing
	if pop.drafted then
		return
	end

	self:fire_pop(pop)
	self:unregister_military_pop(pop)
	pop.drafted = true
	if self.units[unit_type] == nil then
		self.units[unit_type] = {}
	end
	self.units[unit_type][pop] = pop
	self.soldiers[pop] = unit_type

	-- assign pop to random warband
	local vacant_warbands = self:vacant_warbands()
	local warband = nil
	if tabb.size(vacant_warbands) == 0 then
		warband = self:new_warband()
		warband.name = pop.culture.language:get_random_name()
	else
		warband = vacant_warbands[tabb.random_select_from_set(vacant_warbands)]
	end

	warband.pops[pop] = self
	warband.units[pop] = unit_type
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
		if w.status == 'idle' or w.status == 'patrol' then
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

---@param army Army
---@return boolean True if the army was spotted.
function prov.Province:army_spot_test(army)
	-- To resolve this event we need to perform some checks.
	-- First, we should have a "scouting" check.
	-- Them, a potential battle ought to take place.`	
	local visib = army:get_visibility() + love.math.random(20)
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

---@return number
function prov.Province:get_unemployment()
	local u = 0

	for _, p in pairs(self.all_pops) do
		if not p.drafted and p.job == nil then
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
		if v:size() < 6 then
			table.insert(res, k)
		end
	end

	return res
end

return prov
