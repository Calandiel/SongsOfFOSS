---@class (exact) BudgetCategory
---@field ratio number
---@field budget number
---@field to_be_invested number
---@field target number

local function budget_category()
	return {
		ratio = 0,
		budget = 0,
		to_be_invested = 0,
		target = 0,
	}
end

---@alias BudgetCategoryReference 'education'|'court'|'infrastructure'|'military'|'tribute'

---@alias WealthByCategory table<EconomicReason, number?>

---@class (exact) Budget
---@field change number
---@field saved_change number
---@field spending_by_category WealthByCategory
---@field income_by_category WealthByCategory
---@field treasury_change_by_category WealthByCategory
---@field treasury number
---@field treasury_target number
---@field education BudgetCategory
---@field court BudgetCategory
---@field infrastructure BudgetCategory
---@field military BudgetCategory
---@field tribute BudgetCategory


---Generates empty budget
---@return Budget
local function generate_empty_budget()
	return {
		treasury = 0,
		treasury_history = {},
		change = 0,
		saved_change = 0,
		treasury_target = 0,
		spending_by_category = {},
		income_by_category = {},
		treasury_change_by_category = {},
		education = budget_category(),
		court = budget_category(),
		infrastructure = budget_category(),
		military = budget_category(),
		tribute = budget_category(),
	}
end

---@class (exact) Realm
---@field __index Realm
---@field realm_id number
---@field exists boolean
---@field name string
---@field budget Budget
---@field tax_target number
---@field tax_collected_this_year number
---@field r number
---@field g number
---@field b number
---@field primary_race Race
---@field primary_culture Culture
---@field primary_faith Faith
---@field capitol Province
---@field leader Character?
---@field overseer Character?
---@field trading_right_given_to table<Character, Character>
---@field trading_right_cost number
---@field trading_right_law TradingRightLaw
---@field building_right_given_to table<Character, Character>
---@field building_right_cost number
---@field building_right_law BuildingRightLaw
---@field tribute_collectors table<Character, Character>
---@field paying_tribute_to table<Realm, Realm>
---@field tributaries table<Realm, Realm>
---@field tributary_status table<Realm, TributaryStatus>
---@field provinces table<Province, Province>
---@field quests_raid table<Province, nil|number> reward for raid
---@field quests_explore table<Province, nil|number> reward for exploration
---@field quests_patrol table<Province, nil|number> reward for patrol
---@field patrols table<Province, table<Warband, Warband>>
---@field capitol_guard Warband?
---@field prepare_attack_flag boolean?
---@field known_provinces table<Province, Province> For terra incognita.
---@field coa_base_r number
---@field coa_base_g number
---@field coa_base_b number
---@field coa_background_r number
---@field coa_background_g number
---@field coa_background_b number
---@field coa_foreground_r number
---@field coa_foreground_g number
---@field coa_foreground_b number
---@field coa_emblem_r number
---@field coa_emblem_g number
---@field coa_emblem_b number
---@field coa_background_image number
---@field coa_foreground_image number
---@field coa_emblem_image number
---@field resources table<TradeGoodReference, number> Currently stockpiled resources
---@field production table<TradeGoodReference, number> A "balance" of resource creation
---@field bought table<TradeGoodReference, number>
---@field sold table<TradeGoodReference, number>
---@field expected_food_consumption number
---@field armies table<Army, Army>
---@field wars table<War, War> Wars

local realm = {}
local tabb = require "engine.table"

---@class (exact) TributaryStatus
---@field wealth_transfer boolean
---@field goods_transfer boolean
---@field warriors_contribution boolean
---@field protection boolean
---@field local_ruler boolean

---@class Realm
realm.Realm = {}
realm.Realm.__index = realm.Realm
---@return Realm
function realm.Realm:new()
	---@type Realm
	local o = {}

	-- print("new realm")

	o.name = "<realm>"
	o.wars = {}
	o.r = love.math.random()
	o.g = love.math.random()
	o.b = love.math.random()
	o.expected_food_consumption = 0
	o.budget = generate_empty_budget()

	o.tribute_collectors = {}
	o.tributaries = {}
	o.tributary_status = {}
	o.paying_tribute_to = {}

	o.tax_target = 0
	o.tax_collected_this_year = 0


	o.trading_right_given_to = {}
	o.trading_right_cost = 10
	o.trading_right_law = require "game.raws.laws.economy".TRADE_RIGHT.NOBLES

	o.building_right_given_to = {}
	o.building_right_cost = 50
	o.building_right_law = require "game.raws.laws.economy".BUILDING_RIGHT.NOBLES

	o.provinces = {}
	o.bought = {}
	o.sold = {}
	o.known_provinces = {}
	o.coa_base_r = love.math.random()
	o.coa_base_g = love.math.random()
	o.coa_base_b = love.math.random()
	o.coa_background_r = love.math.random()
	o.coa_background_g = love.math.random()
	o.coa_background_b = love.math.random()
	o.coa_foreground_r = love.math.random()
	o.coa_foreground_g = love.math.random()
	o.coa_foreground_b = love.math.random()
	o.coa_emblem_r = love.math.random()
	o.coa_emblem_g = love.math.random()
	o.coa_emblem_b = love.math.random()
	-- print("bbb")
	o.coa_background_image = love.math.random(#ASSETS.coas)
	o.coa_foreground_image = love.math.random(#ASSETS.coas)
	o.resources = {}
	o.production = {}
	o.armies = {}
	o.patrols = {}

	o.quests_explore = {}
	o.quests_patrol = {}
	o.quests_raid = {}

	o.exists = true

	-- print("bb")
	if love.math.random() < 0.6 then
		o.coa_emblem_image = love.math.random(#ASSETS.emblems)
	else
		o.coa_emblem_image = 0 -- have a lot of "empty" emblems so that not everything is a frog
	end

	-- print("b")
	o.realm_id = WORLD.entity_counter
	WORLD.entity_counter = WORLD.entity_counter + 1
	WORLD.realms[o.realm_id] = o
	-- print("c")
	setmetatable(o, realm.Realm)
	return o
end

---Adds a province to the realm. Handles removal of the province from the previous owner.
---@param prov Province
function realm.Realm:add_province(prov)
	if prov.realm ~= nil then
		prov.realm.provinces[prov] = nil
	end
	self.provinces[prov] = prov
	prov.realm = self
end

---Removes province from realm. Does not handle any additional logic!
---@param prov Province
function realm.Realm:remove_province(prov)
	self.provinces[prov] = nil
	if prov.realm == self then
		prov.realm = nil
	end
end

function realm.Realm:get_random_province()
	local n = tabb.size(self.provinces)
	return tabb.nth(self.provinces, love.math.random(n))
end

---Adds warband as potential raider of province
---@param prov Province
---@param warband Warband
function realm.Realm:add_patrol(prov, warband)
	if warband.status ~= 'idle' then return end
	if self.patrols[prov] then
		self.patrols[prov][warband] = warband
		warband.status = 'preparing_patrol'
	else
		self.patrols[prov] = {}
		self.patrols[prov][warband] = warband
		warband.status = 'preparing_patrol'
	end
end

---Removes warband as potential patrol of province
---@param prov Province
---@param warband Warband
function realm.Realm:remove_patrol(prov, warband)
	if self.patrols[prov] then
		self.patrols[prov][warband] = nil
		warband.status = "idle"
	end
end

---Adds a province to the explored provinces list.
---@param province Province
function realm.Realm:explore(province)
	self.known_provinces[province] = province
	for _, n in pairs(province.neighbors) do
		self.known_provinces[n] = n
	end
end

---Returns a percentage describing the education investments
---@return number
function realm.Realm:get_education_efficiency()
	local ed = 0
	if self.budget.education.target > 0 then
		ed = self.budget.education.budget / self.budget.education.target
	end
	return ed
end

---@return number
function realm.Realm:get_court_efficiency()
	local co = 0
	if self.budget.court.target > 0 then
		co = self.budget.court.budget / self.budget.court.target
	end
	return co
end

---@param province Province
---@return number
function realm.Realm:get_explore_cost(province)
	-- We don't want movement cost to ACTUALLY cost nigh infinite amounts on land
	-- So we'll reduce it by this amount instead.
	local mulp = 0.1
	if DATA.tile_get_is_land(province.center) then
		local path = require "game.ai.pathfinding"
		local cost, r = path.pathfind(self.capitol, province, nil, self.known_provinces)
		if r then
			return cost * mulp
		else
			return math.huge
		end
	else
		return province.movement_cost
	end
end

---@return number
function realm.Realm:get_speechcraft_efficiency()
	local cc = 0.5 + self:get_court_efficiency()
	return cc
end

---@return number
function realm.Realm:get_average_mood()
	local mood = 0
	local pop = 0
	for _, p in pairs(self.provinces) do
		local po = p:local_population()
		mood = mood + p.mood * po
		pop = pop + po
	end
	return mood / pop
end

---@return number
function realm.Realm:get_average_needs_satisfaction()
	local sum = 0
	local total_population = 0
	for _, province in pairs(self.provinces) do
		for _, pop in pairs(province.all_pops) do
			sum = sum + pop.basic_needs_satisfaction + pop.life_needs_satisfaction
			total_population = total_population + 1
		end
	end
	return sum / total_population
end

---@return number
function realm.Realm:get_realm_population()
	local total = 0
	for _, p in pairs(self.provinces) do
		total = total + p:home_population()
	end
	return total
end

---@return number
function realm.Realm:get_realm_military()
	local total = 0
	for _, p in pairs(self.provinces) do
		---@type number
		total = total + p:military()
	end
	for _, a in pairs(self.armies) do
		total = total + tabb.size(a:pops())
	end
	return total
end

---@return number
function realm.Realm:get_realm_ready_military()
	local total = 0
	for _, p in pairs(self.provinces) do
		total = total + p:military()
	end
	return total
end

---@return number
function realm.Realm:get_realm_military_target()
	local total = 0
	for _, p in pairs(self.provinces) do
		total = total + p:military_target()
	end
	return total
end

---@return number
function realm.Realm:get_realm_active_army_size()
	local total = 0
	for _, a in pairs(self.armies) do
		total = total + tabb.size(a:pops())
	end
	return total
end

function realm.Realm:get_top_realm(sources, depth)
	local depth = depth or 0
	local sources = sources or {}
	if tabb.size(sources) == 0 then sources[self] = self end
	---@type table<Realm, Realm>
	local result = {}

	if (tabb.size(self.paying_tribute_to) == 0) or (sources[self] and depth > 0) then
		result[self] = self
		return result
	else
		sources[self] = self
		for _, overlord in pairs(self.paying_tribute_to) do
			local top_dogs = overlord:get_top_realm(sources, depth + 1)
			for k, v in pairs(top_dogs) do
				result[k] = v
			end
		end
		return result
	end
end

function realm.Realm:is_realm_in_hierarchy(realm_to_check_for, sources, depth)
	if self == realm_to_check_for then
		return true
	end

	local depth = depth or 0
	local sources = sources or {}
	if tabb.size(sources) == 0 then sources[self] = self end

	if (tabb.size(self.paying_tribute_to) == 0) or (sources[self] and depth > 0) then
		return false
	else
		sources[self] = self

		local result = false

		for _, realm in pairs(self.paying_tribute_to) do
			result = result or realm:is_realm_in_hierarchy(realm_to_check_for, sources, depth + 1)
		end

		return result
	end
end

---@return number
function realm.Realm:get_realm_militarization()
	return self:get_realm_military() / self:get_realm_population()
end

function realm.Realm:raise_warband(warband)
	for _, pop in pairs(warband.pops) do
		-- print(pop.name, "raised from province")
		local province = pop.province
		province:take_away_pop(pop)
	end
end

---Raise local army
---@param province Province
---@return Army
function realm.Realm:raise_local_army(province)
	local army = require "game.entities.army":new()

	if self.provinces[province] == nil then
		return army
	end

	for _, w in pairs(province.warbands) do
		if w.status == 'idle' then
			self:raise_warband(w)
			army.warbands[w] = w
		end
		if w.status == 'patrol' then
			self:raise_warband(w)
			army.warbands[w] = w
		end
	end

	return army
end

---@param warbands table<Warband, Warband>
---@return Army
function realm.Realm:raise_army(warbands)
	--print("army")
	local army = require "game.entities.army":new()
	for _, w in pairs(warbands) do
		self:raise_warband(w)
		army.warbands[w] = w
	end
	self.armies[army] = army
	return army
end

---Disbands an army and returns pops to their provinces.
---@param army Army
---@return table<Warband, Warband>
function realm.Realm:disband_army(army)
	self.armies[army] = nil

	for _, warband in pairs(army.warbands) do
		-- if warband was patrolling, let it continue

		for _, pop in pairs(warband.pops) do
			local unit = warband.units[pop]
			pop.province:return_pop_from_army(pop, unit)
		end

		if warband.status ~= 'patrol' then
			warband.status = 'idle'
		end
	end

	return army.warbands
end

---@return table<Province, number>
function realm.Realm:get_province_pop_weights()
	---@type table<Province, number>
	local weights = {}
	local total = 0
	for _, p in pairs(self.provinces) do
		local po = p:home_population()
		total = total + po
		weights[p] = po
	end
	for p, v in pairs(weights) do
		weights[p] = v / total
	end
	return weights
end

function realm.Realm:get_province_from_weights(weights)
	local w = love.math.random()
	local sum = 0
	for k, v in pairs(weights) do
		sum = sum + v
		if sum > w then
			return k
		end
	end
	return tabb.nth(self.provinces, 1)
end

---@return Province
function realm.Realm:get_random_pop_weighted_province()
	local ws = self:get_province_pop_weights()
	return self:get_province_from_weights(ws)
end

---@return table<number, Province>
function realm.Realm:get_n_random_pop_weighted_provinces(n)
	---@type table<number, Province>
	local returns = {}
	local ws = self:get_province_pop_weights()
	for i = 1, n do
		returns[#returns + 1] = self:get_province_from_weights(ws)
	end
	return returns
end

---@return number
function realm.Realm:get_total_population()
	---@type number
	local pop = 0

	for _, army in pairs(self.armies) do
		pop = pop + tabb.size(army:pops())
	end
	for _, prov in pairs(self.provinces) do
		---@type number
		pop = pop + tabb.size(prov.all_pops)
	end

	return pop
end

---@return Warband[]
function realm.Realm:get_warbands()
	local res = {}

	for _, prov in pairs(self.provinces) do
		for _, warband in pairs(prov.warbands) do
			table.insert(res, warband)
		end
	end

	return res
end

---Returns true if the realm neighbors other
---@param other Realm
---@return boolean
function realm.Realm:neighbors_realm(other)
	for p, _ in pairs(self.provinces) do
		if p:neighbors_realm(other) then
			return true
		end
	end
	return false
end

---Returns whether or not a realm is at war with another.
---@param other Realm
---@return boolean
function realm.Realm:at_war_with(other)
	for war, _ in pairs(self.wars) do
		-- Find if we're attacking or defending
		local attacking = false
		for r, _ in pairs(war.attackers) do
			if r == self then
				attacking = true
				break
			end
		end
		if attacking then
			for r, _ in pairs(war.defenders) do
				if r == other then
					return true
				end
			end
		else
			for r, _ in pairs(war.attackers) do
				if r == other then
					return true
				end
			end
		end
	end
	return false
end

return realm
