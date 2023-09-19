local realm = require "game.entities.realm"
local cult = require "game.entities.culture"
local rel = require "game.entities.religion"
local pop = require "game.entities.pop"
local tabb = require "engine.table"

local TRAIT = require "game.raws.traits.generic"

local st = {}

local function generate_test_army(x, race, faith, culture, capitol)
	local warband = require "game.entities.warband":new()
	for i = 1, x do
		local army_pop = require "game.entities.pop".POP:new(race, faith, culture, true, 20)
		local unit_type = RAWS_MANAGER.unit_types_by_name['raiders']
		warband.pops[army_pop] = capitol
		warband.units[army_pop] = unit_type
	end
	local army = require "game.entities.army":new()
	army.warbands[warband] = warband
	return army
end


local function make_new_noble(race, faith, culture)
	local contender = pop.POP:new(race, faith, culture,
	love.math.random() > race.males_per_hundred_females / (100 + race.males_per_hundred_females),
	love.math.random(race.adult_age, race.max_age))
	contender.popularity = contender.age / 15

	if love.math.random() > 0.7 then
		contender.traits[TRAIT.AMBITIOUS] = TRAIT.AMBITIOUS
	end

	if love.math.random() > 0.7 then
		contender.traits[TRAIT.GREEDY] = TRAIT.GREEDY
	end

	if love.math.random() > 0.7 then
		contender.traits[TRAIT.WARLIKE] = TRAIT.WARLIKE
	end

	if love.math.random() > 0.7 and not contender.traits[TRAIT.AMBITIOUS] then
		contender.traits[TRAIT.LOYAL] = TRAIT.LOYAL
	end

	if love.math.random() > 0.7 and not contender.traits[TRAIT.AMBITIOUS] then
		contender.traits[TRAIT.CONTENT] = TRAIT.CONTENT
	end

	return contender
end

---Makes a new realm, one province large.
---@param race Race
---@param capitol Province
---@param culture Culture
---@param faith Faith
local function make_new_realm(capitol, race, culture, faith)
	local r = realm.Realm:new()
	r.capitol = capitol
	r:add_province(capitol)
	r:explore(capitol)
	r.primary_race = race
	r.primary_culture = culture
	r.primary_faith = faith

	-- Initialize realm colors
	r.r = math.max(0, math.min(1, (culture.r + (love.math.random() * 0.4 - 0.2))))
	r.g = math.max(0, math.min(1, (culture.g + (love.math.random() * 0.4 - 0.2))))
	r.b = math.max(0, math.min(1, (culture.b + (love.math.random() * 0.4 - 0.2))))

	r.name = culture.language:get_random_realm_name()
	for _, neigh in pairs(capitol.neighbors) do
		r:explore(neigh)
	end
	-- Mark the province as settled for processing...
	WORLD.settled_provinces[capitol] = capitol
	local _, lon = capitol.center:latlon()
	lon = lon + math.pi
	lon = lon / math.pi
	lon = lon / 2
	local timz = math.ceil(math.min(30, math.max(0.001, lon * 30)))
	WORLD.settled_provinces_by_identifier[timz][capitol] = capitol

	-- We also need to spawn in some population...
	local pop_to_spawn = math.max(5, capitol.foragers_limit)
	for _ = 1, pop_to_spawn do
		local p = pop.POP:new(
			race,
			faith,
			culture,
			love.math.random() > race.males_per_hundred_females / (100 + race.males_per_hundred_females),
			love.math.random(race.max_age)
		)
		capitol:add_pop(p)
	end

	-- spawn leader
	local elite_character = make_new_noble(race, faith, culture)
	elite_character.popularity = elite_character.age / 10
	capitol:add_character(elite_character)
	r.leader = elite_character


	-- spawn nobles
	for i = 1, pop_to_spawn / 4 do
		local contender = make_new_noble(race, faith, culture)
		capitol:add_character(contender)
	end

	-- set up capitol
	capitol.name = culture.language:get_random_province_name()
	capitol:research(RAWS_MANAGER.technologies_by_name['paleolithic-knowledge']) -- initialize technology...


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
	if not province.center.is_land then return false end
	if province.realm ~= nil then return false end
	if (not province.on_a_river) and race.requires_large_river then return false end
	local ja_r, ja_t, ju_r, ju_t = province.center:get_climate_data()
	if race.minimum_comfortable_temperature > (ja_t + ju_t) / 2 then return false end
	if race.minimum_absolute_temperature > ja_r then return false end

	return true
end

---Spawns initial tribes and initializes their data (such as characters, cultures, religions, races, etc)
function st.run()
	love.math.setRandomSeed(1)
	---@type Queue<Province>
	local queue = require "engine.queue":new()
	local civs = 500 / tabb.size(RAWS_MANAGER.races_by_name) -- one per race...
	for _ = 1, civs do
		for _, r in pairs(RAWS_MANAGER.races_by_name) do
			-- First, find a land province that isn't owned by any realm...
			local prov = WORLD:random_tile().province
			while not ProvinceCheck(r, prov) do prov = WORLD:random_tile().province end

			-- An unowned province -- it means we can spawn a new realm here!
			local cg = cult.CultureGroup:new()
			local culture = cult.Culture:new(cg)

			local max_unit_weight = 0
			local weights = {}
			for _, unit in pairs(RAWS_MANAGER.unit_types_by_name) do
				if unit.unlocked_by == RAWS_MANAGER.technologies_by_name['paleolithic-knowledge'] then
					local v = love.math.random()
					max_unit_weight = max_unit_weight + v
					weights[unit] = v
				end
			end
			for unit, weight in pairs(weights) do
				culture.traditional_units[unit] = weight / max_unit_weight
			end
			culture.traditional_militarization = 0.05 + 0.1 * love.math.random()

			local rg = rel.Religion:new(culture)
			local faith = rel.Faith:new(rg, culture)
			faith.burial_rites = tabb.select_one(love.math.random(), {
				{
					weight = 1,
					entry = 'burial'
				},
				{
					weight = 0.8,
					entry = 'cremation'
				},
				{
					weight = 0.2,
					entry = 'none'
				}
			})
			make_new_realm(prov, r, culture, faith)
			queue:enqueue(prov)
		end
	end
	-- Loop through all entries in the queue and flood fill out
	while queue:length() > 0 do
		---@type Province
		local prov = queue:dequeue()
		-- First, check for rng based on movement cost.
		-- This will make it so culture "expand" slowly through mountains and such.
		if (love.math.random() > 0.001 + prov.movement_cost / 1000.0) or prov.on_a_river then
			for _, neigh in pairs(prov.neighbors) do
				local river_bonus = 1
				if prov.on_a_river and neigh.on_a_river then
					river_bonus = 0.25
				end
				if prov.realm.primary_race.requires_large_river then
				 	if neigh.on_a_river then
						river_bonus = 0.001
					else
						river_bonus = 1000
					end
				end
				if (love.math.random() > 0.001 + neigh.movement_cost / 1000.0 * river_bonus) then
					if neigh.center.is_land == prov.center.is_land and neigh.realm == nil and neigh.foragers_limit > 5.5 then
						-- We can spawn a new realm in this province! It's unused!
						make_new_realm(neigh, prov.realm.primary_race, prov.realm.primary_culture, prov.realm.primary_faith)
						queue:enqueue(neigh)
					end
				end
			end
		else
			-- queue:enqueue(prov)
		end
	end

	-- At the end, print the amount of spawned tribes
	print("Spawned tribes:", tabb.size(WORLD.realms))
	local pp = 0
	for _, prov in pairs(WORLD.provinces) do
		pp = pp + prov:population()
	end
	print("Spawned population: " .. tostring(pp))
end

return st
