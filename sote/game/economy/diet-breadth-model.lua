local tabb = require "engine.table"
local tile = require "game.entities.tile"

local JOBTYPE = require "game.raws.job_types"

local dbm = {}

---@enum ForageResource
dbm.ForageResource = {
	Water = 0,
	Fruit = 1,
	Grain = 2,
	Game = 3,
	Fungi = 4,
	Shell = 5,
	Fish = 6,
	Wood = 7,
}

dbm.ForageResourceName = {
	[dbm.ForageResource.Water] = 'water',
	[dbm.ForageResource.Fruit] = 'berries',
	[dbm.ForageResource.Grain] = 'seeds',
	[dbm.ForageResource.Game] = 'game',
	[dbm.ForageResource.Fungi] = 'mushrooms',
	[dbm.ForageResource.Shell] = 'shellfish',
	[dbm.ForageResource.Fish] = 'fish',
	[dbm.ForageResource.Wood] = 'timber',
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
		return 2 - math.exp(-0.7*(carrying_capacity - foragers)/carrying_capacity)
	end
end

---@param tile_id tile_id
---@return number primary_production
---@return number marine_production
---@return number wood_production
---@return number effective_temperature
function dbm.total_production(tile_id)
	local  _, warmest, _, coldest = tile.get_climate_data(tile_id)
	if coldest > warmest then
		warmest, coldest = coldest, warmest
	end

	local grass = DATA.tile_get_grass(tile_id)
	local shrub = DATA.tile_get_shrub(tile_id)
	local broadleaf = DATA.tile_get_broadleaf(tile_id)
	local conifer = DATA.tile_get_conifer(tile_id)


	local effective_temperature = (18 * warmest - 10 * coldest) / (warmest - coldest + 8)
	local temperture_weighting =  1 / (1 + math.exp(-0.2 * (effective_temperature - 10)))
	-- weight net production by 'biomass' assimilation efficiency
	local primary_production = temperture_weighting * (0.5 * grass + 0.4 * shrub + 0.3 * broadleaf + 0.2 * conifer)
	-- some of assimilation efficiency goes towards structural material: timber
	local wood_production = temperture_weighting * (0.3 * conifer + 0.2 * broadleaf + 0.1 * shrub)
	-- check for marine resources
	local marine_production = 0
	if DATA.tile_get_has_marsh(tile_id) then
		marine_production = marine_production + 0.5
	end
	if DATA.tile_get_has_river(tile_id) then
		marine_production = marine_production + 0.5
	end
	for i = 1, 4 do
		if not DATA.tile_get_is_land(tile.get_neighbor(tile_id, i)) then
			marine_production = marine_production + 0.25
		end
	end
	return primary_production, marine_production, wood_production, effective_temperature
end

---calculate the net primary production (NPP) of a tile, sums to CC
---@param tile tile_id
---@return number net_production
---@return number fruit
---@return number seeds
---@return number wood
---@return number shell
---@return number fish
---@return number game
---@return number fungi
function dbm.net_foraging_production(tile_id)
	local primary_production, marine_production, wood, effective_temperature =
		dbm.total_production(tile_id)
	local fruit, seeds, shell, fish, game = 0, 0, 0, 0, 0
	if primary_production > 0 then
		-- determine animal energy from eating folliage and reduce from plant output
		game = 0.125 * (primary_production + wood)
		primary_production = primary_production * 0.875
		wood = wood * 0.875

		local grass = DATA.tile_get_grass(tile_id)
		local shrub = DATA.tile_get_shrub(tile_id)
		local broadleaf = DATA.tile_get_broadleaf(tile_id)
		local conifer = DATA.tile_get_conifer(tile_id)

		-- determine plant food from remaining pp
		local fruit_plants = shrub + broadleaf
		local seed_plants = conifer + grass
		local flora_total = fruit_plants + seed_plants
		if flora_total > 0 then
			local fruit_percentage = 0.5 / (1 + math.exp(-10 * (fruit_plants / flora_total - 0.5)))
			fruit = primary_production * (0.25 + fruit_percentage)
			seeds = primary_production * (0.75 - fruit_percentage)
		end
	end
	if marine_production > 0 then
		-- determine animal energy from marine output
		game = game + 0.125 * (marine_production)
		marine_production = marine_production * 0.875
		-- determine marine food spread from climate
		local temperature_weight = 0.75 / (1 + math.exp(-0.125*(effective_temperature - 16)))
		shell = marine_production * (0.25 + temperature_weight * 0.25)
		fish = marine_production * (0.75 - temperature_weight * 0.25)
	end
	local net_production = fruit + seeds + shell + fish + game
	-- determine energy available in decomposers
	local fungi = net_production * 0.125
	return net_production, fruit, seeds, wood, shell, fish, game, fungi
end

---comment
---@param a {net_pp: number, fruit: number, seeds: number, wood: number, shell: number, fish: number, game: number, fungi: number}
---@param _ any
---@param v tile_id
---@return {net_pp: number, fruit: number, seeds: number, wood: number, shell: number, fish: number, game: number, fungi: number}
function dbm.accumulate_foraging_production(a, _, v)
	local net_production, fruit, seeds, wood, shell, fish, game, fungi = dbm.net_foraging_production(v)
	-- get climate weighted resources from production
	return {
		net_pp = a.net_pp + net_production,
		fruit = a.fruit + fruit,
		seeds = a.seeds + seeds,
		wood = a.wood + wood,
		shell = a.shell + shell,
		fish = a.fish + fish,
		game = a.game + game,
		fungi = a.fungi + fungi
	}
end

--- Returns individual potential amount of foragable good targets
--- from each tile's net primary production (NPP), effective temperature,
--- and flora spread
---@param province Province
---@return {net_pp: number, fruit: number, seeds: number, wood: number, shell: number, fish: number, game: number, fungi: number}
function dbm.total_foraging_amounts(province)
	local accumulate = {net_pp=0 ,fruit=0, seeds=0, wood=0, shell=0, fish=0, game=0, fungi=0}
	accumulate = tabb.accumulate(province.tiles, accumulate, dbm.accumulate_foraging_production)
	return accumulate
end

---@param province Province
---@param amounts {net_pp: number, fruit: number, seeds: number, wood: number, shell: number, fish: number, game: number, fungi: number}
---Calculate and set a province's forager limit (CC) and foraging targets
function dbm.set_foraging_targets(province, amounts)
	local JOBTYPE = require "game.raws.job_types"
	---@type {resource: string, output: table<TradeGoodReference, number>, amount: number, handle: JOBTYPE}[]
	local products = {}
	products[dbm.ForageResource.Water] = {
		icon = "droplets.png",
		output = { ['water'] = 2 },
		amount = province.hydration,
		handle = JOBTYPE.HAULING,
	}
	products[dbm.ForageResource.Fruit] = {
		icon = "berries-bowl.png",
		output = { ['berries'] = 1.6 },
		amount = amounts.fruit,
		handle = JOBTYPE.FORAGER,
	}
	products[dbm.ForageResource.Grain] = {
		icon = "wheat.png",
		output = { ['grain'] = 2 },
		amount = amounts.seeds,
		handle = JOBTYPE.FARMER,
	}
	products[dbm.ForageResource.Wood] = {
		icon = "pine-tree.png",
		output = { ['bark'] = 1.25, ['timber'] = 0.25 },
		amount = amounts.wood,
		handle = JOBTYPE.ARTISAN,
	}
	products[dbm.ForageResource.Game] = {
		icon = "bison.png",
		output = { ['meat'] = 1, ['hide'] = 0.25 },
		amount = amounts.game,
		handle = JOBTYPE.HUNTING,
	}
	products[dbm.ForageResource.Fungi] = {
		icon = "chanterelles.png",
		output = { ['mushrooms'] = 1.25 },
		amount = amounts.fungi,
		handle = JOBTYPE.CLERK,
	}
	products[dbm.ForageResource.Shell] = {
		icon = "oyster.png",
		output = { ['shellfish'] = 1, ['seaweed'] = 2 },
		amount = amounts.shell,
		handle = JOBTYPE.HAULING,
	}
	products[dbm.ForageResource.Fish] = {
		icon = "salmon.png",
		output = { ['fish'] = 1.25 },
		amount = amounts.fish,
		handle = JOBTYPE.LABOURER,
	}
	province.foragers_limit = amounts.net_pp
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

---@alias TargetResourceTable {search: number, handle: number, output: number, energy: number}
---@alias TargetNeedsTable {need: number, total_search: number, total_output: number, total_handle: number, targets: table<ForageResource, TargetResourceTable>}

---Use Diet-Breadth Model to weight, pick and normalize targets
--- and search times for when foraging for food and water
---@param province Province
function dbm.cultural_foragable_targets(province)
--	print("CULTURE: " .. culture.name)
	-- get average life needs from realm primary race
	local food_needs_by_case = dbm.cultural_food_needs(province.realm.primary_race)
	local province_size = province.size
--	print("  FINDING FOOD USE TARGETS...")
	---@param targets_by_use table<TradeGoodUseCaseReference, TargetNeedsTable>
	---@type table<TradeGoodUseCaseReference, TargetNeedsTable>
	local targets_by_use = tabb.accumulate(food_needs_by_case, {}, function (targets_by_use, use, needed)
--		print("    USE: " .. use .. ", NEEDED: " .. needed)
		targets_by_use[use] = tabb.accumulate(province.foragers_targets, {need = needed, total_search = 0, total_output = 0, total_handle = 0, targets = {}},
			function (target_use, resource, values)
--			print("     CHECKING: " .. dbm.ForageResourceName[resource])
			if values.amount > 0 then
				local energy = tabb.accumulate(values.output, 0, function (total_value, good, output)
					local weight = RAWS_MANAGER.trade_goods_use_cases_by_name[use].goods[good]
					if weight then
						local weighted_output = weight * output
--						print("       VALID GOOD: " .. good .. ", AMOUNT: " .. values.amount .. ", OUTPUT: " .. weighted_output .. ", ENERGY: " .. weighted_output * values.amount)
						total_value = total_value + weighted_output
					end
					return total_value
				end)
				if energy > 0 then
					local search_time = values.amount / province_size
					local handle_time = values.amount / dbm.mean_race_job_efficiency(province.realm.primary_race, values.handle) * search_time
					local output = energy * values.amount * search_time
					target_use.targets[resource] = {search = search_time, handle = handle_time, output = output, energy = energy}
					target_use.total_search = target_use.total_search + search_time
					target_use.total_handle = target_use.total_handle + handle_time
					target_use.total_output = target_use.total_output + output
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
		weighted_targets_by_use[use] = tabb.accumulate(values.targets, {}, function (weighted_targets, resource, results)
			local dividend = results.output
			local divisor = results.search + results.handle
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
			local search = targets_by_use[use].targets[resource].search
			local resource_return = weighted_targets_by_use[use][resource] * search
			total_use_return = total_use_return + resource_return
			total_use_time = total_use_time + search
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
			targets.search = targets.search * 0.95
			for _, value in pairs(targets.targets) do
				value = value * 0.95
			end
		end
		-- add new targets
		local total_search = 0
		for use, targets in pairs(traditional_forager_targets) do
			local old_search = (province.realm.primary_culture.traditional_forager_targets[use].search or 0)
			local new_search = old_search + targets.search * 0.05
			province.realm.primary_culture.traditional_forager_targets[use].search = new_search
			total_search = total_search + new_search
			for resource, value in pairs(targets.targets) do
				local old_value = province.realm.primary_culture.traditional_forager_targets[use][resource] or 0
				local new_value = old_value + value * 0.05
				province.realm.primary_culture.traditional_forager_targets[use][resource] = new_value
			end
		end
		-- normalize use case search times to equally satisfy each use case
		for _, values in pairs(province.realm.primary_culture.traditional_forager_targets) do
			values.search = values.search / total_search
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