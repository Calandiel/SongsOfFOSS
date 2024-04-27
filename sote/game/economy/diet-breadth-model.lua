local tabb = require "engine.table"

local JOBTYPE = require "game.raws.job_types"

local dbm = {}

---@enum ForageResource
dbm.ForageResource = {
	Fruit = 0,
	Grain = 1,
	Wood = 2,
	Small = 3,
	Large = 4,
	Fungi = 5,
	Shell = 6,
	Fish = 7,
}

dbm.ForageResourceName = {
	[dbm.ForageResource.Fruit] = 'berries',
	[dbm.ForageResource.Grain] = 'seeds',
	[dbm.ForageResource.Wood] = 'timber',
	[dbm.ForageResource.Small] = 'small game',
	[dbm.ForageResource.Large] = 'large game',
	[dbm.ForageResource.Fungi] = 'mushrooms',
	[dbm.ForageResource.Shell] = 'shellfish',
	[dbm.ForageResource.Fish] = 'fish',
}

dbm.ForageActionWord = {
    [JOBTYPE.FORAGER] = 'foraging',
    [JOBTYPE.FARMER] = 'farming',
    [JOBTYPE.LABOURER] = 'labouring',
    [JOBTYPE.ARTISAN] = 'artisianship',
    [JOBTYPE.CLERK] = 'recalling', -- communication of ideas? knowing things?
    [JOBTYPE.WARRIOR] = 'fighting',
    [JOBTYPE.HAULING] = 'hauling',
    [JOBTYPE.HUNTING] = 'hunting',
}

---@param culture Culture
---@return string tooltip
function dbm.culture_target_tooltip(culture)
	local ut = require "game.ui-utils"
	return "\n · Traditional Foraging Targets: ".. tabb.accumulate(culture.traditional_forager_targets, "", function (a, use_case, resources)
			return a .. "\n    · Foraging " .. use_case .. " targets (" .. ut.to_fixed_point2(resources.search * 100) .. "%):".. tabb.accumulate(resources.targets, "", function (text, resource, value)
				if value > 0.01 then
					return text .. "\n       · " .. dbm.ForageResourceName[resource] .. " (" .. ut.to_fixed_point2(value * 100) .. "%)"
				end
				return text
			end)
		end)
end

---@param race Race
---@param jobtype JOBTYPE
---@return number efficiency scalar multiplier
function dbm.mean_race_job_efficiency(race, jobtype)
    local male_to_female_ratio = race.males_per_hundred_females / (100 + race.males_per_hundred_females)
    return male_to_female_ratio * race.male_efficiency[jobtype] + (1 - male_to_female_ratio) * race.female_efficiency[jobtype]
end

---@param carrying_capacity number
---@param foragers number
function dbm.foraging_efficiency(carrying_capacity, foragers)
	-- when over CC, divide available goods by foragers
	if foragers > carrying_capacity then
		return carrying_capacity / foragers
	else -- give a boost from being under CC to represent increasing in standing crop/stock
		return 2 - math.exp(-0.25*(carrying_capacity - foragers)/carrying_capacity)
	end
end

---calculate the net primary production (NPP) of a tile 
---@param tile Tile
---@return number net_primary_production
---@return number timber
---@return number shellfish_production
---@return number fish_production
---@return number animal_production
---@return number mushroom_production
---@return number effective_temperature
function dbm.net_primary_production(tile)
	local  _, warmest, _, coldest = tile:get_climate_data()
	if coldest > warmest then
		warmest, coldest = coldest, warmest
	end
	local effective_temperature = (18 * warmest - 10 * coldest) / (warmest - coldest + 8)
	local temperture_weighting =  1 / (1 + math.exp(-0.2 * (effective_temperature - 10)))
	local gross_primary_production = temperture_weighting
	-- weight net production by 'biomass' assimilation efficiency
	local net_primary_production = gross_primary_production * (0.5 * tile.grass + 0.4 * tile.shrub + 0.3 * tile.broadleaf + 0.2 * tile.conifer)
	-- some of assimilation efficiency goes towards structural material: timber
	local timber_production = gross_primary_production * (tile.conifer * 0.3 + tile.broadleaf * 0.2 + tile.shrub * 0.1)
	-- check for marine resources
	local fish_production, shellfish_production = 0, 0
	if tile.has_marsh then
		shellfish_production = shellfish_production + 0.375
		fish_production = fish_production + 0.125
	end
	if tile.has_river then
		shellfish_production = shellfish_production + 0.125
		fish_production = fish_production + 0.375
	end
	for i = 1, 4 do
		if not tile:get_neighbor(i).is_land then
			fish_production = fish_production + 0.25
			shellfish_production = shellfish_production + 0.25
		end
	end
	-- determine herbavore energy from eating folliage and reduce from net_primary_production
	local herbivores = 0.25 * (net_primary_production + timber_production)
	net_primary_production = net_primary_production * 0.75
	timber_production = timber_production * 0.5
	-- deterine carinvore energy from eating herbavores and marine life and reduce amounts
	local carinvores = 0.25 * (herbivores + fish_production + shellfish_production)
	herbivores = herbivores * 0.75
	fish_production = fish_production * 0.75
	shellfish_production = shellfish_production * 0.75
	local animal_production = herbivores + carinvores
	-- determine energy gain from decomposers
	local mushroom_production = (net_primary_production + timber_production + shellfish_production + fish_production + animal_production) * 0.125
	return net_primary_production, timber_production, shellfish_production, fish_production, animal_production, mushroom_production, effective_temperature
end

--- Returns total potential amount of foragable good amounts from tile data
---@param province Province
---@return number net_pp
---@return number fruit_production
---@return number seed_production
---@return number timber
---@return number shellfish_amount
---@return number fish_amount
---@return number small_game
---@return number large_game
---@return number mushrooms
function dbm.foraging_potentials(province)
	local net_pp, fruit_production, seed_production, timber_amount, shellfish_amount, fish_amount, small_game, large_game, mushroom_amount
		= 0, 0, 0, 0, 0, 0, 0, 0, 0
	tabb.accumulate(province.tiles, nil, function (_, _, v)
		local tile_pp, timber, shellfish, fish, game, mushroom, effective_temperature = dbm.net_primary_production(v)
		-- set net_pp first so province cc mapmode lines up with tile cc mapmode
		net_pp = net_pp + tile_pp + shellfish + fish + game + mushroom
		-- determine spread of plant food based on tile flora
		local fruit_plants = v.shrub + v.broadleaf
		local seed_plants = v.conifer + v.grass
		-- if there is plants on the tile add its potential
		local flora_total = fruit_plants + seed_plants
		if flora_total > 0 then
			-- weighting such that food production isn't too skewed towards one resource
			local fruit = tile_pp * 0.5 --fruit_plants / flora_total
			local seeds = tile_pp * 0.5 --seed_plants / flora_total
			fruit_production = fruit_production + fruit
			seed_production = seed_production + seeds
			--- add tile timber amount
			timber_amount = timber_amount + timber
		end
		-- calculate aquatic food sources
		shellfish_amount = shellfish_amount + shellfish
		fish_amount = fish_amount + fish
		-- calculate game size ratios using effective_temperature and fauna spread
		local flora_cover = 0.1 + v.conifer * 0.5 + v.broadleaf * 0.4 + v.shrub * 0.3 + v.grass * 0.2
		local terrestrial_temperature_weight = 1 - 1 / (1 + math.exp(-0.1 * effective_temperature)) -- cold weights towards larger animals
		local small_animals = 0.5 * game --* flora_cover * (1 - terrestrial_temperature_weight)
		local large_animals = 0.5 * game --* (1 - flora_cover) * terrestrial_temperature_weight
		small_game = small_game + small_animals
		large_game = large_game + large_animals
		-- calculate mushroom energy by total biomass
		mushroom_amount = mushroom_amount + mushroom
	end)
	return net_pp, fruit_production, seed_production, timber_amount, shellfish_amount, fish_amount, small_game, large_game, mushroom_amount
end

---@param province Province
function dbm.foragers_targets(province)
	local JOBTYPE = require "game.raws.job_types"
	-- determine amount of foragable goods
	local net_pp, fruit_production, seed_production, timber_amount, shellfish_amount,
		fish_amount, small_game, large_game, mushroom_amount = dbm.foraging_potentials(province)
	---@type {resource: string, output: table<TradeGoodReference, number>, amount: number, handle: JOBTYPE}[]
	local products = {}
	-- PLANT PRODUCTION
	products[dbm.ForageResource.Fruit] = {
		icon = "berries-bowl.png",
		output = { ['berries'] = 2 },
		amount = fruit_production,
		handle = JOBTYPE.FORAGER,
	}
	products[dbm.ForageResource.Grain] = {
		icon = "wheat.png",
		output = { ['grain'] = 2 },
		amount = seed_production,
		handle = JOBTYPE.FARMER,
	}
	products[dbm.ForageResource.Wood] = {
		icon = "pine-tree.png",
		output = { ['timber'] = 1 },
		amount = timber_amount,
		handle = JOBTYPE.ARTISAN,
	}
	-- ANIMAL PRODUCTION
	products[dbm.ForageResource.Small] = {
		icon = "squirrel.png",
		output = { ['meat'] = 1, ['hide'] = 0.125 },
		amount = small_game,
		handle = JOBTYPE.HUNTING,
	}
	products[dbm.ForageResource.Large] = {
		icon = "deer.png",
		output = { ['meat'] = 1, ['hide'] = 0.25 },
		amount = large_game,
		handle = JOBTYPE.WARRIOR,
	}
	-- DECOMPOSER PRODUCTION
	products[dbm.ForageResource.Fungi] = {
		icon = "chanterelles.png",
		output = { ['mushrooms'] = 2 },
		amount = mushroom_amount,
		handle = JOBTYPE.CLERK,
	}
	-- MARINE PRODUCTION
	products[dbm.ForageResource.Shell] = {
		icon = "oyster.png",
		output = { ['shellfish'] = 2 },
		amount = shellfish_amount,
		handle = JOBTYPE.HAULING,
	}
	products[dbm.ForageResource.Fish] = {
		icon = "salmon.png",
		output = { ['fish'] = 1 },
		amount = fish_amount,
		handle = JOBTYPE.LABOURER,
	}
	province.foragers_limit = net_pp
	province.foragers_targets = products
end

-- TODO change to target a culture and find mean value across all pops based on race and culture needs
---@param race Race
---@return table<TradeGoodUseCaseReference, number> food_needs_by_use
function dbm.cultural_food_needs(race)
	local  males_per_hundred_females = race.males_per_hundred_females
	local male_to_female_ratio = males_per_hundred_females / (100 + males_per_hundred_females)
	local food_needs_by_use = tabb.accumulate(race.male_needs[NEED.FOOD], {}, function (accumulated_food_needs, use_case, value)
--		print("  FOOD NEED: " .. use_case)
		local average_gendered_use_case_need = value * male_to_female_ratio + (1 - male_to_female_ratio) * race.female_needs[NEED.FOOD][use_case]
		accumulated_food_needs[use_case] = (accumulated_food_needs[use_case] and accumulated_food_needs[use_case].amount or 0) + average_gendered_use_case_need
		return accumulated_food_needs
	end)
	return food_needs_by_use
end

--- use Diet-Breadth Model to pick and weight products for culture
---@param province Province
function dbm.cultural_foragable_targets(province)
--	print("CULTURE: " .. culture.name)
	-- get average life needs from realm primary race
	local food_needs_by_case = dbm.cultural_food_needs(province.realm.primary_race)
--	print("  FINDING FOOD USE TARGETS...")
	---@param targets_by_use table<TradeGoodUseCaseReference, {need: number, total_search: number, total_output: number, total_handle: number, targets: table<ForageResource, number>}>
	---@type table<TradeGoodUseCaseReference, {need: number, total_search: number, total_output: number, total_handle: number, targets: table<ForageResource, number>}>
	local targets_by_use = tabb.accumulate(food_needs_by_case, {}, function (targets_by_use, use, needed)
--		print("    USE: " .. use .. ", NEEDED: " .. needed)
		targets_by_use[use] = tabb.accumulate(province.foragers_targets, {need = needed, total_search = 0, total_output = 0, total_handle = 0, targets = {}},
			function (target_use, resource, values)
--			print("     CHECKING: " .. dbm.ForageResourceName[resource])
			if values.amount > 0 then
				local targets = tabb.accumulate(values.output, 0, function (total_value, good, output)
					local weight = RAWS_MANAGER.trade_goods_use_cases_by_name[use].goods[good]
					if weight then
						local weighted_output = weight * output
--						print("       VALID GOOD: " .. good .. ", AMOUNT: " .. values.amount .. ", OUTPUT: " .. weighted_output .. ", ENERGY: " .. weighted_output * values.amount)
						total_value = total_value + weighted_output
					end
					return total_value
				end)
				if targets > 0 then
					local search_time = values.amount / province.foragers_limit
					target_use.targets[resource] = targets
					target_use.total_search = target_use.total_search + search_time
					target_use.total_output = target_use.total_output + targets * values.amount * search_time
					target_use.total_handle = target_use.total_handle + values.amount / dbm.mean_race_job_efficiency(province.realm.primary_race, values.handle) * search_time
				end
			end
			return target_use
		end)
		return targets_by_use
	end)
	-- find average return for each use target and filter by greater than or equal to average
	local total_targets_by_use, average_return_per_use = {}, {}
--	print("  CHOOSING TARGETS:")
	local weighted_targets_by_use = tabb.accumulate(targets_by_use, {}, function (weighted_targets_by_use, use, values)
		average_return_per_use[use] = values.total_output / (values.total_search + values.total_handle)
--		print("    TOTAL OUTPUT: " .. values.total_output .. " TOTAL HANDLE: " .. values.total_handle)
--		print("    AVERAGE RETURN: " .. average_return_per_use[use] .. " TOTAL SEARCH: " .. targets_by_use[use].total_search)
		weighted_targets_by_use[use] = tabb.accumulate(values.targets, {}, function (weighted_targets, resource, energy)
			local amount = (province.foragers_targets[resource].amount or 0)
			local search_time = amount / province.foragers_limit
        	local handle = dbm.mean_race_job_efficiency(province.realm.primary_race, province.foragers_targets[resource].handle)
			local handle_cost = 1 / handle
			local dividend = amount * energy * search_time
			local divisor = search_time + amount * handle_cost * search_time
			local return_for_resource = dividend / divisor
--			print("      RESOURCE: " .. dbm.ForageResourceName[resource] .. " AMOUNT: " .. amount .. " ENERGY: " .. energy)
--			print("        SEARCH: " .. search_time .. " HANDLE: " .. handle .. " RETURN: " .. return_for_resource)
			if return_for_resource >= average_return_per_use[use] then
				weighted_targets[resource] = return_for_resource
				total_targets_by_use[use] = (total_targets_by_use[use] or 0) + return_for_resource
			end
			return weighted_targets
		end)
		return weighted_targets_by_use
	end)
	-- normalize use target list to sum to 1
--	print("  PREFERED FOOD USE TARGETS:")
	local prefered_targets_by_use = tabb.accumulate(weighted_targets_by_use, {}, function(prefered_targets_by_use, use, targets)
--		print("    USE: " .. use .. ", TOTAL: " .. total_targets_by_use[use] .. ", SEARCH: " .. targets_by_use[use].total_search)
		prefered_targets_by_use[use] = tabb.accumulate(targets, {}, function (prefer_target, resource, amount)
			local normalized_amount = amount / total_targets_by_use[use]
--			print("      RESOURCE: " .. dbm.ForageResourceName[resource] .. " " .. amount .. " -> " .. normalized_amount)
			prefer_target[resource] = normalized_amount
			return prefer_target
		end)
		return prefered_targets_by_use
	end)
	-- use new prefered targets to set or shift culture's traditional targets
	local total_search = 0
	---@param traditional_foraging_target table<TradeGoodUseCaseReference, {search: number, targets: table<ForageResource, number>}>
	local traditional_forager_targets = tabb.accumulate(prefered_targets_by_use, {}, function (traditional_foraging_target, use, targets)
		local need = targets_by_use[use].need
		local total_use_return, total_use_time = 0, 0
		-- collect average expected time to satisfy use case
		traditional_foraging_target[use] = {search = 0, targets = tabb.accumulate(targets, {}, function (prefered_target, resource, value)
			local amount = (province.foragers_targets[resource].amount or 0)
			local search_time = amount / province.foragers_limit
			local resource_return = weighted_targets_by_use[use][resource] * search_time
			total_use_return = total_use_return + resource_return
			total_use_time = total_use_time + search_time
			prefered_target[resource] = value
			return prefered_target
		end)}
		-- calculate average expected time to statisfy use case and normalize resource amounts
		local average_expected_time = need / (total_use_return / total_use_time)
		traditional_foraging_target[use].search = average_expected_time
		total_search = total_search + average_expected_time
		return traditional_foraging_target
	end)
	-- normalize use case search times to equally satisfy each use case
	for _, values in pairs(traditional_forager_targets) do
		values.search = values.search / total_search
	end
	if province.realm.primary_culture.traditional_forager_targets then
		-- reduce old targets
		for _, targets in pairs(province.realm.primary_culture.traditional_forager_targets) do
			targets.search = targets.search * 0.99
			for _, value in pairs(targets.targets) do
				value = value * 0.99
			end
		end
		-- add new targets
		for use, targets in pairs(traditional_forager_targets) do
			province.realm.primary_culture.traditional_forager_targets[use].search =
				(province.realm.primary_culture.traditional_forager_targets[use].search or 0) + targets.search * 0.01
			for resource, value in pairs(targets.targets) do
				local old_value = province.realm.primary_culture.traditional_forager_targets[use][resource] or 0
				province.realm.primary_culture.traditional_forager_targets[use][resource] = old_value + value * 0.01
			end
		end
	else -- initial setting to first spawn of culture since traditional_foraging_target starts undeclared
		province.realm.primary_culture.traditional_forager_targets = traditional_forager_targets
    end

--	print("  TRADITIONAL FORAGER TARGETS:")
--	for use, resources in pairs(culture.traditional_forager_targets) do
--		print("    USE: " .. use .. ", TIME: " .. resources.search)
--		for resource, amount in pairs(resources.targets) do
--			print("      RESOURCE: " .. dbm.ForageResourceName[resource] .. " " .. amount)
--		end
--	end
end

return dbm