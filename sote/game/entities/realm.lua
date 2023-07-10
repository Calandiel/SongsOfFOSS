---@class Realm
---@field realm_id number
---@field name string
---@field treasury number
---@field wasted_treasury number
---@field treasury_real_delta number
---@field military_spending number
---@field realized_military_spending number The fraction of military upkeep that was actually covered
---@field old_treasury number
---@field building_upkeep number
---@field voluntary_contributions number
---@field voluntary_contributions_accumulator number
---@field monthly_infrastructure_investment number
---@field education_endowment number
---@field education_investment number
---@field education_endowment_needed number
---@field monthly_education_investment number
---@field get_education_efficiency fun(self:Realm):number
---@field get_average_mood fun(self:Realm):number
---@field get_total_population fun(self:Realm):number
---@field court_wealth number
---@field court_investment number
---@field court_wealth_needed number
---@field monthly_court_investment number
---@field get_court_efficiency fun(self:Realm):number
---@field r number
---@field g number
---@field b number
---@field primary_race Race
---@field primary_culture Culture
---@field primary_faith Faith
---@field capitol Province
---@field provinces table<Province, Province>
---@field raiding_targets table<Province, Province|nil>
---@field raiders_preparing table<Province, table<Warband, Warband>>
---@field toggle_raiding_target fun(self:Realm, province:Province)
---@field add_raiding_target fun(self:Realm, province:Province)
---@field remove_raiding_target fun(self:Realm, province:Province)
---@field random_raiding_target fun(self:Realm): Province
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
---@field resources table<TradeGood, number> Currently stockpiled resources
---@field production table<TradeGood, number> A "balance" of resource creation
---@field bought table<TradeGood, number>
---@field sold table<TradeGood, number>
---@field get_price fun(self:Realm, trade_good:TradeGood):number
---@field get_pessimistic_price fun(self:Realm, trade_good:TradeGood, amount:number):number
---@field expected_food_consumption number
---@field get_realm_population fun(self:Realm):number
---@field get_realm_military fun(self:Realm):number Returns a sum of "unraised" military and active armies
---@field get_realm_ready_military fun(self:Realm):number Returns the "unraised" military
---@field get_realm_military_target fun(self:Realm):number Returns the sum of military targets, not that it DOESNT include active armies.
---@field get_realm_active_army_size fun(self:Realm):number Returns the size of active armies on the field
---@field get_realm_militarization fun(self:Realm):number
--@field raise_army_of_size fun(self:Realm, size:number):Army Raises an army of a given size
---@field raise_army fun(self:Realm, warbands: table<Warband, Warband>): Army
---@field raise_warband fun(self: Realm, warband: Warband)
---@field raise_local_army fun(self: Realm, province: Province): Army
---@field disband_army fun(self:Realm, army:Army)
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
---@field add_raider fun(self:Realm, prov: Province, warband: Warband)
---@field remove_raider fun(self:Realm, prov: Province, warband: Warband)

local realm = {}
local tabb = require "engine.table"

---@type Realm
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
	o.treasury = 0
	o.wasted_treasury = 0
	o.treasury_real_delta = 0
	o.old_treasury = 0
	o.building_upkeep = 0
	o.voluntary_contributions = 0
	o.voluntary_contributions_accumulator = 0
	o.monthly_infrastructure_investment = 0
	o.education_endowment = 0
	o.education_investment = 0
	o.education_endowment_needed = 0
	o.monthly_education_investment = 0
	o.court_wealth = 0
	o.court_investment = 0
	o.court_wealth_needed = 0
	o.monthly_court_investment = 0
	o.military_spending = 0
	o.realized_military_spending = 1
	o.provinces = {}
	o.raiding_targets = {}
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

---Adds a province to the realm's raiding targets.
---@param prov Province
function realm.Realm:add_raiding_target(prov)
	self.raiding_targets[prov] = prov
	if self.raiders_preparing[prov] == nil then
		self.raiders_preparing[prov] = {}
	end
end

function realm.Realm:remove_raiding_target(prov)
	self.raiding_targets[prov] = nil
	for _, warband in pairs(self.raiders_preparing[prov]) do
		if warband.status == 'preparing_raid' then
			warband.status = 'idle'
		end
	end
	self.raiders_preparing[prov] = {}
end

function realm.Realm:toggle_raiding_target(prov)
	if self.raiding_targets[prov] then
		self:remove_raiding_target(prov)
	else
		self:add_raiding_target(prov)
	end
end

---Adds warband as potential raider of province
---@param prov Province
---@param warband Warband
function realm.Realm:add_raider(prov, warband)
	if warband.status ~= 'idle' then return end
	if self.raiding_targets[prov] then
		self.raiders_preparing[prov][warband] = warband
		warband.status = 'preparing_raid'
	end
end

---Removes warband as potential raider of province
---@param prov Province
---@param warband Warband
function realm.Realm:remove_raider(prov, warband)
	if self.raiding_targets[prov] then
		self.raiders_preparing[prov][warband] = nil
		warband.status = "idle"
	end
end

function realm.Realm:random_raiding_target()
	local targets = {}
	for k in pairs(self.raiding_targets) do
		table.insert(targets, k)
	end
	return self.raiding_targets[targets[math.random(#targets)]]
end

---Adds a province to the explored provinces list.
---@param province Province
function realm.Realm:explore(province)
	self.known_provinces[province] = province
	for _, n in pairs(province.neighbors) do
		self.known_provinces[n] = n
	end
end

---Note, it works ONLY for "real" trade goods.
---For services, use provincial functions instead!
---@param trade_good TradeGood
---@return number price
function realm.Realm:get_price(trade_good)
	local bought = self.bought[trade_good] or 0
	local sold = self.sold[trade_good] or 0
	return trade_good.base_price * bought / (sold + 0.25) -- the "plus" is there to prevent division by 0
end

---Calculates a "pessimistic" prise (that is, the price that we'd get if we tried to sell more goods after selling the goods given)
---@param trade_good TradeGood
---@param amount number
---@return number price
function realm.Realm:get_pessimistic_price(trade_good, amount)
	local bought = self.bought[trade_good] or 0
	bought = bought + amount
	local sold = self.sold[trade_good] or 0
	return trade_good.base_price * bought / (sold + 0.25) -- the "plus" is there to prevent division by 0
end

---Returns a percentage describing the education investments
---@return number
function realm.Realm:get_education_efficiency()
	local ed = 0
	if self.education_endowment_needed > 0 then
		ed = self.education_endowment / self.education_endowment_needed
	end
	return ed
end

---@return number
function realm.Realm:get_court_efficiency()
	local co = 0
	if self.court_wealth_needed > 0 then
		co = self.court_wealth / self.court_wealth_needed
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

---@return number
function realm.Realm:get_realm_militarization()
	return self:get_realm_military() / self:get_realm_population()
end

function realm.Realm:raise_warband(warband)
	for pop, unit_type in pairs(warband.units) do
		local province = warband.pops[pop]
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
function realm.Realm:disband_army(army)
	self.armies[army] = nil

	for _, warband in pairs(army.warbands) do
		for pop, province in pairs(warband.pops) do
			local unit = warband.units[pop]
			if province.realm then
				province:return_pop_from_army(pop, unit)
			else
				self.capitol:return_pop_from_army(pop, unit)
			end
			pop.drafted = true
		end
		warband.status = 'idle'
	end
end

---@return table<Province, number>
function realm.Realm:get_province_pop_weights()
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
	local returns = {}
	local ws = self:get_province_pop_weights()
	for i = 1, n do
		returns[#returns + 1] = self:get_province_from_weights(ws)
	end
	return returns
end

---@return number
function realm.Realm:get_total_population()
	local pop = 0

	for _, army in pairs(self.armies) do
		pop = pop + tabb.size(army:pops())
	end
	for _, prov in pairs(self.provinces) do
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
