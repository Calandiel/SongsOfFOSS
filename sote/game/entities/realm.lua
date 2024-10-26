local realm_utils = {}
local tabb = require "engine.table"

local province_utils = require "game.entities.province".Province
local army_utils = require "game.entities.army"

realm_utils.Realm = {}

function realm_utils.Realm.new()
	local realm_id = DATA.create_realm()
	local o = DATA.fatten_realm(realm_id)

	-- print("new realm")

	o.name = "<realm>"
	o.r = love.math.random()
	o.g = love.math.random()
	o.b = love.math.random()
	o.trading_right_cost = 10
	o.law_trade = LAW_TRADE.LOCALS_ONLY
	o.building_right_cost = 50
	o.law_building = LAW_BUILDING.LOCALS_ONLY
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

	return realm_id
end

function realm_utils.Realm.size(realm)
	local result = 0
	DATA.for_each_realm_provinces_from_realm(realm, function (item)
		result = result + 1
	end)

	return result
end

---Adds a province to the realm. Handles removal of the province from the previous owner.
---@param realm Realm
---@param prov Province
function realm_utils.Realm.add_province(realm, prov)
	local membership = DATA.get_realm_provinces_from_province(prov)
	if membership ~= INVALID_ID then
		DATA.realm_provinces_set_realm(membership, realm)
	else
		DATA.force_create_realm_provinces(prov, realm)
	end
end

---Removes province from realm. Does not handle any additional logic!
---@param realm Realm
---@param prov Province
function realm_utils.Realm.remove_province(realm, prov)
	local membeship = DATA.get_realm_provinces_from_province(prov)
	if membeship ~= INVALID_ID then
		DATA.delete_realm_provinces(membeship)
	end
end


---@param realm Realm
---@return province_id
function realm_utils.Realm.get_random_province(realm)
	local n = #DATA.get_realm_provinces_from_realm(realm)
	local membership = DATA.get_realm_provinces_from_realm(realm)[love.math.random(n)]
	if membership then
		return DATA.realm_provinces_get_province(membership)
	else
		return INVALID_ID
	end
end

---Adds warband as potential patrol of province
---@param realm Realm
---@param prov Province
---@param warband Warband
function realm_utils.Realm.add_patrol(realm, prov, warband)
	if DATA.warband_get_current_status(warband) ~= WARBAND_STATUS.IDLE then return end
	if DATA.realm_get_patrols(realm)[prov] then
		DATA.realm_get_patrols(realm)[prov][warband] = warband
	else
		DATA.realm_get_patrols(realm)[prov]  = {}
		DATA.realm_get_patrols(realm)[prov][warband] = warband
	end
	DATA.warband_set_current_status(warband, WARBAND_STATUS.PREPARING_PATROL)
end

---Removes warband as potential patrol of province
---@param realm Realm
---@param prov Province
---@param warband Warband
function realm_utils.Realm.remove_patrol(realm, prov, warband)
	if DATA.realm_get_patrols(realm)[prov] then
		DATA.realm_get_patrols(realm)[prov][warband] = nil
		DATA.warband_set_current_status(warband, WARBAND_STATUS.IDLE)
	end
end

---Adds a province to the explored provinces list.
---@param realm Realm
---@param province Province
function realm_utils.Realm.explore(realm, province)
	DATA.realm_get_known_provinces(realm)[province] = province
	DATA.for_each_province_neighborhood_from_origin(province, function (item)
		local n = DATA.province_neighborhood_get_target(item)
		DATA.realm_get_known_provinces(realm)[n] = n
	end)
end

---Returns a percentage describing the education investments
---@param realm Realm
---@return number
function realm_utils.Realm.get_education_efficiency(realm)
	local result = 0
	local target = DATA.realm_get_budget_target(realm, BUDGET_CATEGORY.EDUCATION)
	if target > 0 then
		local budget = DATA.realm_get_budget_budget(realm, BUDGET_CATEGORY.EDUCATION)
		result = budget / target
	end
	return result
end

---@param realm Realm
---@return number
function realm_utils.Realm.get_court_efficiency(realm)
	local result = 0
	local target = DATA.realm_get_budget_target(realm, BUDGET_CATEGORY.COURT)
	if target > 0 then
		local budget = DATA.realm_get_budget_budget(realm, BUDGET_CATEGORY.COURT)
		result = budget / target
	end
	return result
end

---@param realm Realm
---@param province Province
---@return number
function realm_utils.Realm.get_explore_cost(realm, province)
	-- We don't want movement cost to ACTUALLY cost nigh infinite amounts on land
	-- So we'll reduce it by this amount instead.
	local mulp = 0.1
	local fat_target = DATA.fatten_province(province)
	if DATA.tile_get_is_land(fat_target.center) then
		local path = require "game.ai.pathfinding"
		local cost, r = path.pathfind(DATA.realm_get_capitol(realm), province, nil, DATA.realm_get_known_provinces(realm))
		if r then
			return cost * mulp
		else
			return math.huge
		end
	else
		return fat_target.movement_cost
	end
end

---@param realm Realm
---@return number
function realm_utils.Realm.get_speechcraft_efficiency(realm)
	local cc = 0.5 + realm_utils.Realm.get_court_efficiency(realm)
	return cc
end

---@param realm Realm
---@return number
function realm_utils.Realm.get_average_mood(realm)
	local mood = 0
	local pop = 0
	DATA.for_each_realm_provinces_from_realm(realm, function (item)
		local province = DATA.realm_provinces_get_province(item)
		local po = province_utils.local_population(province)
		mood = mood + DATA.province_get_mood(province) * po
		pop = pop + po
	end)
	return mood / pop
end

---@param realm Realm
---@return number
function realm_utils.Realm.get_average_needs_satisfaction(realm)
	local sum = 0
	local total_population = 1
	DATA.for_each_realm_provinces_from_realm(realm, function (location)
		local province = DATA.realm_provinces_get_province(location)
		DATA.for_each_pop_location_from_location(province, function (item)
			local pop = DATA.pop_location_get_pop(item)
			local fat = DATA.fatten_pop(pop)
			sum = sum + fat.basic_needs_satisfaction + fat.life_needs_satisfaction
			total_population = total_population + 1
		end)
	end)
	return sum / total_population
end

---@param realm Realm
---@return number
function realm_utils.Realm.get_realm_population(realm)
	local total = 0
	DATA.for_each_realm_provinces_from_realm(realm, function (location)
		local province = DATA.realm_provinces_get_province(location)
		total = total + province_utils.home_population(province)
	end)
	return total
end

function realm_utils.Realm.get_active_armies_size(realm)
	local total = 0
	DATA.for_each_realm_armies_from_realm(realm, function (item)
		local army = DATA.realm_armies_get_army(item)
		total = total + army_utils.size(army)
	end)
	return total
end

---@param realm Realm
---@return number
function realm_utils.Realm.get_realm_ready_military(realm)
	local total = 0
	DATA.for_each_realm_provinces_from_realm(realm, function (location)
		local province = DATA.realm_provinces_get_province(location)
		total = total + province_utils.military(province)
	end)
	return total
end

---@param realm Realm
---@return number
function realm_utils.Realm.get_realm_military(realm)
	return realm_utils.Realm.get_realm_ready_military(realm) + realm_utils.Realm.get_active_armies_size(realm)
end

---@param realm Realm
---@return number
function realm_utils.Realm.get_realm_military_target(realm)
	local total = 0
	DATA.for_each_realm_provinces_from_realm(realm, function (location)
		local province = DATA.realm_provinces_get_province(location)
		total = total + province_utils.military_target(province)
	end)
	return total
end


---@param realm Realm
---@return number
function realm_utils.Realm.get_realm_active_army_size(realm)
	local total = 0
	DATA.for_each_realm_armies_from_realm(realm, function (item)
		local army = DATA.realm_armies_get_army(item)
		total = total + army_utils.size(army)
	end)
	return total
end

---Checks is this realm is a subject
---@param realm Realm
---@return boolean
function realm_utils.Realm.is_subject(realm)
	local pays_tribute = false
	DATA.for_each_realm_subject_relation_from_subject(realm, function (item)
		pays_tribute = true
	end)
	return pays_tribute
end

---@param realm Realm
---@param sources? table<Realm, Realm>
---@param depth? number
function realm_utils.Realm.get_top_realm(realm, sources, depth)
	local depth = depth or 0
	---@type table<Realm, Realm>
	local sources = sources or {}

	if tabb.size(sources) == 0 then sources[realm] = realm end

	---@type table<Realm, Realm>
	local result = {}

	local pays_tribute = realm_utils.Realm.is_subject(realm)

	if not pays_tribute or (sources[realm] and depth > 0) then
		result[realm] = realm
		return result
	else
		sources[realm] = realm
		DATA.for_each_realm_subject_relation_from_subject(realm, function (item)
			local top_dog = DATA.realm_subject_relation_get_overlord(item)
			local top_dogs = realm_utils.Realm.get_top_realm(top_dog, sources, depth + 1)
			for k, v in pairs(top_dogs) do
				result[k] = v
			end
		end)
		return result
	end
end

---@param realm Realm
---@param realm_to_check_for Realm
---@param sources? table<Realm, Realm>
---@param depth? number
function realm_utils.Realm.is_realm_in_hierarchy(realm, realm_to_check_for, sources, depth)
	if realm == realm_to_check_for then
		return true
	end

	local depth = depth or 0
	local sources = sources or {}
	if tabb.size(sources) == 0 then sources[realm] = realm end

	local pays_tribute = realm_utils.Realm.is_subject(realm)

	if not pays_tribute or (sources[realm] and depth > 0) then
		return false
	else
		sources[realm] = realm

		local result = false

		DATA.for_each_realm_subject_relation_from_subject(realm, function (item)
			local top_dog = DATA.realm_subject_relation_get_overlord(item)
			result = result or realm_utils.Realm.is_realm_in_hierarchy(top_dog, realm_to_check_for, sources, depth + 1)
		end)

		return result
	end
end

---@param realm Realm
---@return number
function realm_utils.Realm.get_realm_militarization(realm)
	local population = realm_utils.Realm.get_realm_population(realm)
	if population then
		return 0
	end
	return realm_utils.Realm.get_realm_military(realm) / population
end

---@param realm Realm
---@param warband Warband
function realm_utils.Realm.raise_warband(realm, warband)
	DATA.for_each_warband_unit_from_warband(warband, function (item)
		local pop = DATA.warband_unit_get_unit(item)
		-- print(pop.name, "raised from province")
		local location = DATA.get_pop_location_from_pop(pop)
		local province = DATA.pop_location_get_location(location)
		province_utils.take_away_pop(province, pop)
	end)
end

---Raise local army
---@param realm Realm
---@param province Province
---@return Army
function realm_utils.Realm.raise_local_army(realm, province)
	local army = DATA.create_army()
	DATA.force_create_realm_armies(realm, army)

	if realm_utils.Realm.size(realm) == 0 then
		return army
	end

	DATA.for_each_warband_location_from_location(province, function (item)
		local warband = DATA.warband_location_get_warband(item)
		local status = DATA.warband_get_current_status(warband)
		if status == WARBAND_STATUS.IDLE then
			DATA.force_create_army_membership(army, warband)
			realm_utils.Realm.raise_warband(realm, warband)
		end
		if status == WARBAND_STATUS.PATROL then
			DATA.force_create_army_membership(army, warband)
			realm_utils.Realm.raise_warband(realm, warband)
		end
	end)

	return army
end

---@param realm Realm
---@param warbands table<Warband, Warband>
---@return Army
function realm_utils.Realm.raise_army(realm, warbands)
	--print("army")
	local army = DATA.create_army()
	DATA.force_create_realm_armies(realm, army)

	for _, warband in pairs(warbands) do
		DATA.force_create_army_membership(army, warband)
		realm_utils.Realm.raise_warband(realm, warband)
	end

	return army
end

---Disbands an army and returns pops to their provinces.
---@param realm Realm
---@param army Army
---@return table<Warband, Warband>
function realm_utils.Realm.disband_army(realm, army)
	---@type table<Warband, Warband>
	local warbands = {}
	DATA.for_each_army_membership_from_army(army, function (item)
		local warband = DATA.army_membership_get_member(item)

		---@type pop_id[]
		local to_return = {}

		DATA.for_each_warband_unit_from_warband(warband, function (unit_membership)
			local pop = DATA.warband_unit_get_unit(unit_membership)
			table.insert(to_return, pop)
		end)

		for _, pop in pairs(to_return) do
			local pop_location = DATA.get_pop_location_from_pop(pop)
			local province = DATA.pop_location_get_location(pop_location)
			province_utils.return_pop_from_army(province, pop)
		end

		-- if warband was patrolling, keep the patrol status
		local fat = DATA.fatten_warband(warband)
		if fat.status ~= WARBAND_STATUS.PATROL then
			fat.status = WARBAND_STATUS.IDLE
		end

		warbands[warband] = warband
	end)

	return warbands
end

-- commenting as unused

-- ---@param realm Realm
-- ---@return table<Province, number>
-- function realm_utils.Realm.get_province_pop_weights(realm)
-- 	---@type table<Province, number>
-- 	local weights = {}
-- 	local total = 0
-- 	for _, p in pairs(self.provinces) do
-- 		local po = p:home_population()
-- 		total = total + po
-- 		weights[p] = po
-- 	end
-- 	for p, v in pairs(weights) do
-- 		weights[p] = v / total
-- 	end
-- 	return weights
-- end

-- ---@param realm Realm
-- function realm_utils.Realm.get_province_from_weights(realm, weights)
-- 	local w = love.math.random()
-- 	local sum = 0
-- 	for k, v in pairs(weights) do
-- 		sum = sum + v
-- 		if sum > w then
-- 			return k
-- 		end
-- 	end
-- 	return tabb.nth(self.provinces, 1)
-- end

-- ---@param realm Realm
-- ---@return Province
-- function realm_utils.Realm.get_random_pop_weighted_province(realm)
-- 	local ws = self:get_province_pop_weights()
-- 	return self:get_province_from_weights(ws)
-- end

-- ---@param realm Realm
-- ---@return table<number, Province>
-- function realm_utils.Realm.get_n_random_pop_weighted_provinces(realm, n)
-- 	---@type table<number, Province>
-- 	local returns = {}
-- 	local ws = self:get_province_pop_weights()
-- 	for i = 1, n do
-- 		returns[#returns + 1] = self:get_province_from_weights(ws)
-- 	end
-- 	return returns
-- end

---@param realm Realm
---@return number
function realm_utils.Realm.get_total_population(realm)
	return realm_utils.Realm.get_realm_population(realm) + realm_utils.Realm.get_realm_ready_military(realm)
end

---@param realm Realm
---@return Warband[]
function realm_utils.Realm.get_warbands(realm)
	local res = {}

	DATA.for_each_realm_provinces_from_realm(realm, function (item)
		local part_of_the_realm = DATA.realm_provinces_get_province(item)
		DATA.get_warband_location_from_location(part_of_the_realm)
		DATA.for_each_warband_location_from_location(part_of_the_realm, function (location)
			table.insert(res, DATA.warband_location_get_warband(location))
		end)
	end)

	return res
end

---Returns true if the realm neighbors other
---@param realm Realm
---@param other Realm
---@return boolean
function realm_utils.Realm.neighbors_realm(realm, other)
	local check = false
	DATA.for_each_realm_provinces_from_realm(realm, function (item)
		local part_of_the_realm = DATA.realm_provinces_get_province(item)
		if province_utils.neighbors_realm(part_of_the_realm, other) then
			check = true
		end
	end)
	return check
end

---Returns whether or not a province borders a given realm
---@param province province_id
---@param realm Realm
---@return boolean
function realm_utils.Realm.neighbors_realm_tributary(province, realm)
	for _, n in pairs(DATA.get_province_neighborhood_from_origin(province)) do
		local neighbor = DATA.province_neighborhood_get_target(n)
		local neighbor_realm = province_utils.realm(neighbor)

		if neighbor_realm and realm_utils.Realm.is_realm_in_hierarchy(neighbor_realm, realm) then
			return true
		end
	end
	return false
end

---Returns whether or not a realm is at war with another.
---@param realm Realm
---@param other Realm
---@return boolean
function realm_utils.Realm.at_war_with(realm, other)
	return false
	-- for war, _ in pairs(self.wars) do
	-- 	-- Find if we're attacking or defending
	-- 	local attacking = false
	-- 	for r, _ in pairs(war.attackers) do
	-- 		if r == self then
	-- 			attacking = true
	-- 			break
	-- 		end
	-- 	end
	-- 	if attacking then
	-- 		for r, _ in pairs(war.defenders) do
	-- 			if r == other then
	-- 				return true
	-- 			end
	-- 		end
	-- 	else
	-- 		for r, _ in pairs(war.attackers) do
	-- 			if r == other then
	-- 				return true
	-- 			end
	-- 		end
	-- 	end
	-- end
	-- return false
end

return realm_utils
