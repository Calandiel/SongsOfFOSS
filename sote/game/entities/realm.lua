local pv = require "game.raws.values.political"

---@class RewardFlag
---@field flag_type 'explore'|'raid'|'destroy'|'kill'|'devastate'
---@field reward number
---@field owner Character
---@field target Province


---@class BudgetCategory
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

---@class Budget
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

---@class Realm
---@field realm_id number
---@field name string
---@field budget Budget
---@field get_education_efficiency fun(self:Realm):number
---@field get_average_mood fun(self:Realm):number
---@field get_total_population fun(self:Realm):number
---@field get_court_efficiency fun(self:Realm):number
---@field r number
---@field g number
---@field b number
---@field primary_race Race
---@field primary_culture Culture
---@field primary_faith Faith
---@field capitol Province
---@field leader Character?
---@field overseer Character?
---@field tribute_collectors table<Character, Character>
---@field paying_tribute_to table<Realm, Realm>
---@field tributaries table<Realm, Realm>
---@field provinces table<Province, Province>
---@field reward_flags table<RewardFlag, RewardFlag>
---@field raiders_preparing table<RewardFlag, table<Warband, Warband>?>
---@field patrols table<Province, table<Warband, Warband>>
---@field prepare_attack_flag boolean?
---@field add_province fun(self:Realm, province:Province)
---@field new fun(self:Realm):Realm
---@field known_provinces table<Province, Province> For terra incognita.
---@field explore fun(self:Realm, province:Province)
---@field get_explore_cost fun(self:Realm, province:Province): number
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
---@field get_realm_population fun(self:Realm):number
---@field get_realm_military fun(self:Realm):number Returns a sum of "unraised" military and active armies
---@field get_realm_ready_military fun(self:Realm):number Returns the "unraised" military
---@field get_realm_military_target fun(self:Realm):number Returns the sum of military targets, not that it DOESNT include active armies.
---@field get_realm_active_army_size fun(self:Realm):number Returns the size of active armies on the field
---@field get_realm_militarization fun(self:Realm):number
---@field raise_army fun(self:Realm, warbands: table<Warband, Warband>): Army
---@field raise_warband fun(self: Realm, warband: Warband)
---@field raise_local_army fun(self: Realm, province: Province): Army
---@field disband_army fun(self:Realm, army:Army): table<Warband, Warband>
---@field get_speechcraft_efficiency fun(self:Realm):number
---@field get_province_pop_weights fun(self:Realm):table<Province, number> Returns a table mapping provinces to numbers that add up to 1 and which represent the 'weight' of a province based on its population. Useful for pop weighted selections of provinces
---@field get_random_pop_weighted_province fun(self:Realm):Province
---@field get_n_random_pop_weighted_provinces fun(self:Realm, n:number):table<number, Province>
---@field get_province_from_weights fun(self:Realm, weights:table<Province,number>):Province
---@field armies table<Army, Army>
---@field neighbors_realm fun(self:Realm, other:Realm):boolean
---@field wars table<War, War> Wars
---@field at_war_with fun(self:Realm, other:Realm):boolean Wars
---@field get_warbands fun(self:Realm): Warband[]
---@field add_raider fun(self:Realm, f: RewardFlag, warband: Warband)
---@field remove_raider fun(self:Realm, f: RewardFlag, warband: Warband)
---@field add_patrol fun(self:Realm, prov: Province, warband: Warband)
---@field remove_patrol fun(self:Realm, prov: Province, warband: Warband)
---@field get_top_realm fun(self:Realm, sources:table<Realm, Realm> | nil, depth: number | nil):table<Realm, Realm> Returns the set of top dogs of a tributary chains. Handles loops.
---@field is_realm_in_hierarchy fun(self:Realm, realm_to_check_for:Realm, sources:table<Realm, Realm> | nil, depth: number | nil):boolean Checks if a realm is in the overlord chain of a tributary.
---@field get_random_province fun(self:Realm): Province | nil

local realm = {}
local tabb = require "engine.table"

---@class RewardFlag
realm.RewardFlag = {}
realm.RewardFlag.__index = realm.RewardFlag

---@param i RewardFlag
---@return RewardFlag
function realm.RewardFlag:new(i)
	---@type table
	local o = {}
	---@diagnostic disable-next-line: no-unknown
	for k, v in pairs(i) do
	---@diagnostic disable-next-line: no-unknown
		o[k] = v
	end
	setmetatable(o, realm.RewardFlag)
	return o
end

---@class Realm
realm.Realm = {}
realm.Realm.__index = realm.Realm
---@return Realm
function realm.Realm:new()
	---@type Realm
	local o = {}

	-- print("a")

	o.name = "<realm>"
	o.wars = {}
	o.r = love.math.random()
	o.g = love.math.random()
	o.b = love.math.random()
	o.expected_food_consumption = 0
	o.budget = generate_empty_budget()

	o.tribute_collectors = {}
	o.tributaries = {}
	o.paying_tribute_to = {}

	o.provinces = {}
	o.reward_flags = {}
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
	o.raiders_preparing = {}
	o.patrols = {}
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
	prov.realm = nil
end

---Adds a province to the realm's raiding targets.
---@param f RewardFlag
function realm.Realm:add_reward_flag(f)
	self.reward_flags[f] = f
	if self.raiders_preparing[f] == nil then
		self.raiders_preparing[f] = {}
	end
end

---Removes a province from the realm's raiding targets.
---@param f RewardFlag
function realm.Realm:remove_reward_flag(f)
	self.reward_flags[f] = nil

	if self.raiders_preparing[f] == nil then
		return
	end

	for _, warband in pairs(self.raiders_preparing[f]) do
		if warband.status == 'preparing_raid' then
			warband.status = 'idle'
		end
	end
	self.raiders_preparing[f] = {}
end

-- function realm.Realm:toggle_reward_flag(f)
-- 	if self.reward_flags[f] then
-- 		self:remove_reward_flag(f)
-- 	else
-- 		self:add_reward_flag(f)
-- 	end
-- end

function realm.Realm:get_random_province()
	local n = tabb.size(self.provinces)
	return tabb.nth(self.provinces, love.math.random(n))
end

---Adds warband as potential raider of province
---@param f RewardFlag
---@param warband Warband
function realm.Realm:add_raider(f, warband)
	if warband.status ~= 'idle' then return end
	if self.reward_flags[f] then
		self.raiders_preparing[f][warband] = warband
		warband.status = 'preparing_raid'
	end
end

---Removes warband as potential raider of province
---@param f RewardFlag
---@param warband Warband
function realm.Realm:remove_raider(f, warband)
	if self.reward_flags[f] then
		self.raiders_preparing[f][warband] = nil
		warband.status = "idle"
	end
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

function realm.Realm:roll_reward_flag()
	---@type table<RewardFlag, number>
	local targets = {}
	for flag, k in pairs(self.reward_flags) do
		local popularity = pv.popularity(k.owner, self)
		targets[k] = k.reward * popularity
	end
	return tabb.random_select(targets)
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
	if province.center.is_land then
		local path = require "game.ai.pathfinding"
		local cost, r = path.pathfind(self.capitol, province)
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
		local po = p:population()
		mood = mood + p.mood * po
		pop = pop + po
	end
	return mood / pop
end

---@return number
function realm.Realm:get_realm_population()
	local total = 0
	for _, p in pairs(self.provinces) do
		total = total + p:population()
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
	for pop, unit_type in pairs(warband.units) do
		local province = warband.pops[pop].home_province
		province:take_away_pop(pop)
	end
end

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
			if pop.home_province.realm then
				pop.home_province:return_pop_from_army(pop, unit)
			else
				self.capitol:return_pop_from_army(pop, unit)
			end
			pop.drafted = true
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
		local po = p:population()
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
