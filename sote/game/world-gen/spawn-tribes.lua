local realm_utils = require "game.entities.realm".Realm
local cult = require "game.entities.culture"
local rel = require "game.entities.religion"
local pop_utils = require "game.entities.pop".POP
local language_utils = require "game.entities.language".Language
local tabb = require "engine.table"
local tile      = require "game.entities.tile"

local tec = require "game.raws.raws-utils".technology

local politics_values = require "game.raws.values.politics"

local province_utils = require "game.entities.province".Province
local pe = require "game.raws.effects.politics"

local st = {}


---Makes a new realm, one province large.
---@param capitol_id Province
---@param race_id race_id
---@param culture culture_id
---@param faith faith_id
local function make_new_realm(capitol_id, race_id, culture, faith)
	-- print("new realm")

	local r = realm_utils.new()

	local fat = DATA.fatten_realm(r)
	fat.capitol = capitol_id
	realm_utils.add_province(r, capitol_id)
	realm_utils.explore(r, capitol_id)
	fat.primary_race = race_id

	local capitol = DATA.fatten_province(capitol_id)
	local race = DATA.fatten_race(race_id)

	fat.primary_culture = culture
	fat.primary_faith = faith

	-- Initialize realm colors
	fat.r = math.max(0, math.min(1, (DATA.culture_get_r(culture) + (love.math.random() * 0.4 - 0.2))))
	fat.g = math.max(0, math.min(1, (DATA.culture_get_g(culture) + (love.math.random() * 0.4 - 0.2))))
	fat.b = math.max(0, math.min(1, (DATA.culture_get_b(culture) + (love.math.random() * 0.4 - 0.2))))

	fat.name = language_utils.get_random_realm_name(DATA.culture_get_language(culture))


	--[[
	for _, neigh in pairs(capitol.neighbors) do
		r:explore(neigh)
	end
	]]
	--

	-- Mark the province as settled for processing...
	WORLD:set_settled_province(capitol_id)

	--calculate average ratial foraging_efficiency from males per 100 females
	local male_percentage = race.males_per_hundred_females / (100 + race.males_per_hundred_females)

	-- We also need to spawn in some population...
	local pop_to_spawn = math.max(5, capitol.foragers_limit / race.carrying_capacity_weight * race.fecundity * 0.5)
	for _ = 1, pop_to_spawn do
		local age = math.floor(math.abs(love.math.randomNormal(race.adult_age, race.adult_age)) + 1)
		local new_pop = pop_utils.new(
			race_id,
			faith,
			culture,
			love.math.random() > male_percentage,
			age
		)
		province_utils.add_pop(capitol_id, new_pop)
		province_utils.set_home(capitol_id, new_pop)
	end

	-- spawn leader

	do
		local elite_character = pe.generate_new_noble(r, capitol_id, race_id, faith, culture)
		local popularity = DATA.force_create_popularity(elite_character, r)
		local fat_popularity = DATA.fatten_popularity(popularity)
		fat_popularity.value = DATA.pop_get_age(elite_character) / 10
		pe.transfer_power(r, elite_character, POLITICS_REASON.INITIALRULER)
	end

	-- spawn nobles
	for i = 1, pop_to_spawn / 5 + 1 do
		local contender = pe.generate_new_noble(r, capitol_id, race_id, faith, culture)
		local popularity = DATA.force_create_popularity(contender, r)
		local fat_popularity = DATA.fatten_popularity(popularity)
		fat_popularity.value = DATA.pop_get_age(contender) / 15
	end

	-- set up capitol
	capitol.name = language_utils.get_random_province_name(DATA.culture_get_language(culture))
	province_utils.research(capitol_id, tec('paleolithic-knowledge')) -- initialize technology...

	-- give some stuff to capitol
	capitol.infrastructure = love.math.random() * 10 + 10
	capitol.local_wealth = love.math.random() * 10 + 10
	capitol.trade_wealth = love.math.random() * 10 + 10

	-- give initial research budget
	DATA.realm_set_budget_budget(r, BUDGET_CATEGORY.EDUCATION, 1)

	-- starting treasury
	DATA.realm_set_budget_budget(r, BUDGET_CATEGORY.EDUCATION, 1)
	fat.budget_treasury = love.math.random() * 20 + 20 * pop_to_spawn

	-- give some realms early tech advantage to reduce waiting:
	for i = 0, 4 do
		---@type technology_id[]
		local to_research = {}
		DATA.for_each_technology(function (item)
			if DATA.province_get_technologies_researchable(capitol_id, item) == 1 then
				if love.math.random() < 0.3 then
					DATA.realm_inc_budget_budget(r, BUDGET_CATEGORY.EDUCATION, 1)
					table.insert(to_research, item)
				end
			end
		end)

		for _, item in pairs(to_research) do
			province_utils.research(capitol_id, item)
		end
	end

	-- match children pop to some possible parent
	DATA.for_each_pop_location_from_location(capitol_id, function (item)
		local child = DATA.pop_location_get_pop(item)
		local fat_child = DATA.fatten_pop(child)

		if fat_child.age > race.teen_age then
			return
		end
		if IS_CHARACTER(child) then
			return
		end


		---@type pop_id[]
		local parents = {}

		DATA.for_each_pop_location_from_location(capitol_id, function (parent_location)
			local potential_parent_id = DATA.pop_location_get_pop(parent_location)
			local fat_potential_parent = DATA.fatten_pop(potential_parent_id)
			if fat_potential_parent.age <= fat_child.age + race.adult_age then
				return
			end
			if fat_potential_parent.age >= fat_child.age + race.elder_age then
				return
			end
			table.insert(parents, potential_parent_id)
		end)

		local parent = tabb.random_select_from_array(parents)

		if parent then
			DATA.force_create_parent_child_relation(parent, child)
		end
	end)

	-- capitol:validate_population()

	-- print("test battle")
	-- local size_1, size_2 = love.math.random(50) + 10, love.math.random(50) + 10
	-- local army_1 = generate_test_army(size_1, race, faith, culture, capitol)
	-- local army_2 = generate_test_army(size_2, race, faith, culture, capitol)

	-- print(size_2, size_1)
	-- local victory, losses, def_losses = army_2:attack(capitol, true, army_1)
	-- print(victory, losses, def_losses)
end


---Checks if province is eligible for spawn
---@param race Race
---@param province Province
function ProvinceCheck(race, province)
	-- local dbm = require "game.economy.diet-breadth-model"
	local center = DATA.province_get_center(province)
	local fat_province = DATA.fatten_province(province)
	local fat_center = DATA.fatten_tile(center)
	local fat_race = DATA.fatten_race(race)
	local realm = province_utils.realm(province)
	if not fat_center.is_land then return false end
	if fat_province.foragers_limit < (5 * fat_race.carrying_capacity_weight) then return false end
	if realm ~= INVALID_ID then return false end
	if (not fat_province.on_a_river) and fat_race.requires_large_river then return false end
	if (not fat_province.on_a_forest) and fat_race.requires_large_forest then return false end
	local ja_r, ja_t, ju_r, ju_t = tile.get_climate_data(center)
	if fat_race.minimum_comfortable_temperature > (ja_t + ju_t) / 2 then return false end
	if fat_race.minimum_absolute_temperature > ja_r then return false end
	local elev = fat_center.elevation
	if fat_race.minimum_comfortable_elevation > elev then return false end
	return true
end

---Spawns initial tribes and initializes their data (such as characters, cultures, religions, races, etc)
function st.run()
	---@type Queue<Province>
	local queue = require "engine.queue":new()


	-- order:
	-- river specialists races first
	-- forest specialists races second
	-- rest races at the end

	print("Decide spawn order for races")

	---@type Race[]
	local order = {}
	for _, r in pairs(RAWS_MANAGER.races_by_name) do
		if DATA.race_get_requires_large_river(r) then
			table.insert(order, r)
		end
	end

	for _, r in pairs(RAWS_MANAGER.races_by_name) do
		if DATA.race_get_requires_large_forest(r) and not DATA.race_get_requires_large_river(r) then
			table.insert(order, r)
		end
	end

	for _, r in pairs(RAWS_MANAGER.races_by_name) do
		if (not DATA.race_get_requires_large_forest(r)) and (not DATA.race_get_requires_large_river(r)) then
			table.insert(order, r)
		end
	end

	local civs = 500 / tabb.size(order) -- one per race...


	---@type table<culture_id, province_id[]>
	local provinces_per_cultures = {}

	print("Spawn starting races")

	-- print(civs)
	for _ = 1, civs do
		for _, r in ipairs(order) do
			-- print("spawn" .. DATA.race_get_name(r))
			-- First, find a land province that isn't owned by any realm...
			local sampled_tile = WORLD:random_tile()
			local prov = tile.province(sampled_tile)

			while not ProvinceCheck(r, prov) do
				sampled_tile = WORLD:random_tile()
				prov = tile.province(sampled_tile)
			end


			-- An unowned province -- it means we can spawn a new realm here!
			local cg = cult.CultureGroup:new()
			local culture = cult.Culture:new(cg)

			local max_unit_weight = 0
			---@type table<unit_type_id, number>
			local weights = {}
			for _, unit in pairs(RAWS_MANAGER.unit_types_by_name) do
				if DATA.get_technology_unit_from_unlocked(unit) == RAWS_MANAGER.technologies_by_name['paleolithic-knowledge'] then
					local v = love.math.random()
					max_unit_weight = max_unit_weight + v
					weights[unit] = v
				end
			end
			for unit, weight in pairs(weights) do
				DATA.culture_set_traditional_units(culture, unit, weight / max_unit_weight)
			end

			DATA.culture_set_traditional_militarization(culture, 0.05 + 0.1 * love.math.random())

			local rg = rel.Religion:new(culture)
			local faith = rel.Faith:new(rg, culture)
			DATA.faith_set_burial_rites(faith, tabb.select_one(love.math.random(), {
				{
					weight = 1,
					entry = BURIAL_RIGHTS.BURIAL
				},
				{
					weight = 0.8,
					entry = BURIAL_RIGHTS.CREMATION
				},
				{
					weight = 0.2,
					entry = BURIAL_RIGHTS.NONE
				}
			}))
			make_new_realm(prov, r, culture, faith)
			queue:enqueue(prov)
		end
	end

	print("Flood fill the rest of the world")
	-- Loop through all entries in the queue and flood fill out
	while queue:length() > 0 do
		---@type Province
		local prov = queue:dequeue()
		local fat_prov = DATA.fatten_province(prov)
		local realm = province_utils.realm(prov)
		local culture = DATA.realm_get_primary_culture(realm)
		local race = DATA.realm_get_primary_race(realm)
		local faith = DATA.realm_get_primary_faith(realm)

		if provinces_per_cultures[culture] == nil then
			provinces_per_cultures[culture] = {}
		end

		table.insert(provinces_per_cultures[culture], prov)

		-- First, check for rng based on movement cost.
		-- This will make it so culture "expand" slowly through mountains and such.
		if (love.math.random() > 0.001 + fat_prov.movement_cost / 1000.0) or fat_prov.on_a_river then
			DATA.for_each_province_neighborhood_from_origin(prov, function (item)
				local neigh = DATA.province_neighborhood_get_target(item)
				local fat_neigh = DATA.fatten_province(neigh)
				local neigh_realm = province_utils.realm(neigh)

				local river_bonus = 1
				if fat_prov.on_a_river and fat_neigh.on_a_river then
					river_bonus = 0.25
				end
				if DATA.race_get_requires_large_river(race) then
					if fat_neigh.on_a_river then
						river_bonus = 0.001
					else
						river_bonus = 1000
					end
				end
				if (love.math.random() > 0.001 + fat_neigh.movement_cost / 1000.0 * river_bonus) then
					if DATA.tile_get_is_land(fat_neigh.center) == DATA.tile_get_is_land(fat_prov.center)
						and neigh_realm == INVALID_ID
						and fat_neigh.foragers_limit > 8
					then -- formerly 5.5
						-- We can spawn a new realm in this province! It's unused!
						make_new_realm(
							neigh,
							race,
							culture,
							faith
						)
						queue:enqueue(neigh)
					end
				end
			end)
		else
			-- queue:enqueue(prov)
		end
	end

	--- recalculate dbm weights

	for culture, provs in pairs(provinces_per_cultures) do
		---@type table<FORAGE_RESOURCE, number>
		local total_weights = {}
		local total_population = 0
		DATA.for_each_forage_resource(function (i)
			total_weights[i] = 0
		end)

		for _, prov in pairs(provs) do
			local province_dbm_weights = require "game.economy.diet-breadth-model".cultural_foragable_targets(prov)
			local local_population = province_utils.local_population(prov)
			DATA.for_each_forage_resource(function (i)
				total_weights[i] = total_weights[i] + province_dbm_weights[i] * local_population
			end)
			total_population = total_population + local_population
		end

		DATA.for_each_forage_resource(function (i)
			total_weights[i] = total_weights[i] / total_population
			DATA.culture_set_traditional_forager_targets(culture, i, total_weights[i])
		end)
	end

	local realms = 0
	DATA.for_each_realm(function (item)
		realms = realms + 1
	end)

	-- At the end, print the amount of spawned tribes
	print("Spawned tribes:", realms)
	local pops = 0
	local characters = 0
	DATA.for_each_province(function (item)
		pops = pops + province_utils.local_population(item)
		characters = characters + province_utils.local_characters(item)
	end)
	print("Spawned population: " .. tostring(pops))
	print("Spawned characters: " .. tostring(characters))
end

return st
