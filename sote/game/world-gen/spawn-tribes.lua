local realm = require "game.entities.realm"
local cult = require "game.entities.culture"
local rel = require "game.entities.religion"
local pop = require "game.entities.pop"
local tabb = require "engine.table"

local st = {}

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
	r.r = math.max(0, math.min(1, (culture.r + (love.math.random() * 0.2 - 0.1))))
	r.g = math.max(0, math.min(1, (culture.g + (love.math.random() * 0.2 - 0.1))))
	r.b = math.max(0, math.min(1, (culture.b + (love.math.random() * 0.2 - 0.1))))

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
	capitol.name = culture.language:get_random_province_name()
	capitol:research(WORLD.technologies_by_name['paleolithic-knowledge']) -- initialize technology...
end

---Spawns initial tribes and initializes their data (such as characters, cultures, religions, races, etc)
function st.run()
	local queue = require "engine.queue":new()
	local civs = 500 / tabb.size(WORLD.races_by_name) -- one per race...
	for _ = 1, civs do
		for _, r in pairs(WORLD.races_by_name) do
			-- First, find a land province that isn't owned by any realm...
			local prov = WORLD:random_tile().province
			while not prov.center.is_land or prov.realm ~= nil do prov = WORLD:random_tile().province end
			-- An unowned province -- it means we can spawn a new realm here!
			local cg = cult.CultureGroup:new()
			local culture = cult.Culture:new(cg)

			local max_unit_weight = 0
			local weights = {}
			for _, unit in pairs(WORLD.unit_types_by_name) do
				if unit.unlocked_by == WORLD.technologies_by_name['paleolithic-knowledge'] then
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
		if love.math.random() < 0.001 + prov.movement_cost / 1000.0 then
			for _, neigh in pairs(prov.neighbors) do
				if neigh.center.is_land == prov.center.is_land and neigh.realm == nil and neigh.foragers_limit > 5.5 then
					-- We can spawn a new realm in this province! It's unused!
					make_new_realm(neigh, prov.realm.primary_race, prov.realm.primary_culture, prov.realm.primary_faith)
					queue:enqueue(neigh)
				end
			end
		else
			queue:enqueue(prov)
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
