local tabb = require "engine.table"

local JOBTYPE = require "game.raws.job_types"

local dbm = {}

dbm.JOB_ACTIVITY = {
    [JOBTYPE.FORAGER] = "foraging",
    [JOBTYPE.FARMER] = "farming",
    [JOBTYPE.LABOURER] = "labouring",
    [JOBTYPE.ARTISAN] = "artisianship",
    [JOBTYPE.CLERK] = "telling", -- communication of ideas? knowing things?
    [JOBTYPE.WARRIOR] = "fighting",
    [JOBTYPE.HAULING] = "hauling",
    [JOBTYPE.HUNTING] = "hunting",
}

---@param race Race
---@param jobtype JOBTYPE
---@return number efficiency scalar multiplier
function dbm.mean_race_job_efficiency(race, jobtype)
    local male_to_female_ratio = race.males_per_hundred_females / (100 + race.males_per_hundred_females)
    return male_to_female_ratio * race.male_efficiency[jobtype] + (1 - male_to_female_ratio) * race.female_efficiency[jobtype]
end

-- TODO USE CLIMATE TO FIGURE OUT BETTER WEIGHTS FOR FORAGING RESOURCE AMOUNTS

--- Returns total potential amount of foragable good amounts from tile data
---@param province Province
---@return number tile_count number of tiles in province
---@return number[] fruit_plants from 0 to 1 for broadleaf and shrub flora per tile
---@return number[] seed_plants from 0 to 1 for conifer and grass per tile
---@return number timber from 0 to 1 per tile
---@return number mushrooms from 0 to 1 per tile
---@return number shellfish from 0 to 2 per tile
---@return number fish from 0 to 2 per tile
---@return number blanks from 0 to 1 per tile
function dbm.foraging_potentials(province)
	-- return 1, { 1, 1 }, { 1, 1 }, 1, 1, 1, 1
	local tile_count, fruit_plants, seed_plants, timber, mushrooms, shellfish, fish = 0, { 0, 0 }, { 0, 0 }, 0, 0, 0, 0
	local blanks = tabb.accumulate(province.tiles, 0, function (a, _, v)
		tile_count = tile_count + 1
		if v.has_river then -- rivers give more fish
			shellfish = shellfish + 0.25
			fish = fish + 0.75
		end
		if v.has_marsh then -- marshes have more shellfish
			shellfish = shellfish + 0.75
			fish = fish + 0.25
		end
		for i = 1, 4 do -- coastal tiles have extra seafood poduction
			-- completely surrounding a single water tile will give an extra + 1 to fish and shellfish
			-- effectively allow you to harvest entire tile's seafood output
			if not v:get_neighbor(i).is_land then
				shellfish = shellfish + 0.25
				fish = fish + 0.25
			end
		end
		timber = timber + v.conifer * 0.25 + v.broadleaf * 0.0625 + v.shrub * 0.015625
		fruit_plants = { fruit_plants[1] + v.broadleaf, fruit_plants[2] + v.shrub }
		seed_plants =  { seed_plants[1] + v.conifer, seed_plants[2] + v.grass }
		mushrooms = mushrooms + v.soil_organics * 0.5 + (v.broadleaf + v.conifer + v.shrub + v.grass) * 0.125 -- mix of soil organics and flora to decompose
		local bedrock = v.bedrock
		if v.resource == RAWS_MANAGER.resources_by_name["flint"] then
			return a + 1
		elseif bedrock == RAWS_MANAGER.bedrocks_by_name["quartzite"]
			or bedrock ==  RAWS_MANAGER.bedrocks_by_name["chert"]
		then
			return a + 0.5
		elseif v.resource == RAWS_MANAGER.resources_by_name["quality-clay"] and (bedrock == RAWS_MANAGER.bedrocks_by_name["shale"]
			or bedrock == RAWS_MANAGER.bedrocks_by_name["siltstone"] or bedrock == RAWS_MANAGER.bedrocks_by_name["mudstone"]
			or bedrock == RAWS_MANAGER.bedrocks_by_name["sandstone"] or bedrock == RAWS_MANAGER.bedrocks_by_name["limestone"])
		then
			return a + 0.25
		elseif bedrock == RAWS_MANAGER.bedrocks_by_name["andesite"]
			or bedrock == RAWS_MANAGER.bedrocks_by_name["basalt"]
			or bedrock == RAWS_MANAGER.bedrocks_by_name["dacite"]
			or bedrock == RAWS_MANAGER.bedrocks_by_name["rhyolite"]
		then
			return a + 0.125
		else
			return a
		end
	end)
	return tile_count, fruit_plants, seed_plants, timber, mushrooms, shellfish, fish, blanks
end

---@param province Province
function dbm.foragable_targets(province)
	local JOBTYPE = require "game.raws.job_types"
	-- determine amount of foragable goods
--	local tile_count, fruit_plants, seed_plants, timber, mushrooms, shellfish, fish, blanks = dbm.foraging_potentials(province)
	---@type {resource: string, output: table<TradeGoodReference, number>, amount: number, search: JOBTYPE, handle: JOBTYPE}[]
	local products = {}

	-- BASIC PLANT PRODUCE
--	if fruit_production > 0 then
		table.insert(products,{
			resource = 'Finding Berries',
			output = { ['berries'] = 1.0 },
			amount = 1,
			search = JOBTYPE.FORAGER,
			handle = JOBTYPE.FORAGER,
		})
--	end
--	if seed_production > 0 then
		table.insert(products,{
			resource = 'Harvesting Seeds',
			output = { ['grain'] = 1.0 },
			amount = 1,
			search = JOBTYPE.FORAGER,
			handle = JOBTYPE.LABOURER,
		})
--	end
--	if mushrooms > 0 then
		table.insert(products,{
			resource = 'Foraging Mushrooms',
			output = { ['mushroom'] = 1.0 },
			amount = 1,
			search = JOBTYPE.FORAGER,
			handle = JOBTYPE.CLERK,
		})
--	end
	-- FORAGING FOR MEAT USE CASE
--	if small_game > 0 then
		table.insert(products,{
			resource = 'Trapping Animals',
			output = { ['meat'] = 0.5 },
			amount = 1,
			search = JOBTYPE.FORAGER,
			handle = JOBTYPE.ARTISAN,
		})
		-- HUNTING LAND ANIMALS
		table.insert(products,{
			resource = 'Hunting Critters',
			output = { ['meat'] = 1 },
			amount = 1,
			search = JOBTYPE.HUNTING,
			handle = JOBTYPE.HAULING,
		})
--	end
--	if large_game > 0 then
		table.insert(products,{
			resource = 'Stalking Game',
			output = { ['meat'] = 2 },
			amount = 1,
			search = JOBTYPE.HUNTING,
			handle = JOBTYPE.WARRIOR,
		})
--	end
	-- NON FOOD ITEMS
--	if timber > 0 then
		table.insert(products,{
			resource = 'Collecting Timber',
			output = { ['timber'] = 1 },
			amount = 1,
			search = JOBTYPE.LABOURER,
			handle = JOBTYPE.HAULING,
		})
--	end
--	if blanks > 0 then
		table.insert(products,{
			resource = 'Knapping blanks',
			output = { ['blanks-flint'] = 1 },
			amount = 1,
			search = JOBTYPE.CLERK,
			handle = JOBTYPE.ARTISAN,
		})
--	end
	-- MARINE FOOD
--	if shellfish > 0 then
		table.insert(products,{
			resource = 'Gathering Shellfish',
			output = { ['shellfish'] = 1},
			amount = 1,
			search = JOBTYPE.FORAGER,
			handle = JOBTYPE.HAULING,
		})
--	end
--	if fish > 0 then
		table.insert(products,{
			resource = 'Catching Fish',
			output = { ['fish'] = 1 },
			amount = 1,
			search = JOBTYPE.HUNTING,
			handle = JOBTYPE.LABOURER,
		})
--	end
	province.foraging_targets = products
end

---@param realm Realm
function dbm.cultural_foragable_targets(realm)
    -- get realm's dominant cutlure and race to operate on
    local race = realm.primary_race
    local culture = realm.primary_culture
    -- use Diet-Breadth Model to pick and weight products
    -- find average return rate of all products to deterime optimal foraging targets
    local total_goods_cost, total_goods_return = 0, 0
    local potentials = tabb.accumulate(realm.capitol.foraging_targets, {}, function (potentials, product, values)
        local handling_cost = 1 / dbm.mean_race_job_efficiency(race, values.handle)
        total_goods_cost = total_goods_cost + values.amount * handling_cost
        local price = tabb.accumulate(values.output, 0, function (a, k, v)
            return a + (realm.capitol.local_prices[k] or RAWS_MANAGER.trade_goods_by_name[k].base_price) * v * values.amount
        end)
        total_goods_return = total_goods_return + values.amount * price
        potentials[product] = price * handling_cost
--			print("  return_per_cost: " .. tostring(products[product]))
        return potentials
    end)
    -- only harvest products with a value better than average
    local average_return_per_cost = total_goods_return / (1 + total_goods_cost)
--	print("  average_return_per_cost: " .. tostring(average_return_per_cost))
    if culture.traditional_foraging_returns then
    -- shifts a culture foraging targets by new ideal for each tribe with primary culture
        culture.traditional_foraging_returns = culture.traditional_foraging_returns * 0.99 + average_return_per_cost * 0.01
        culture.traditional_foraging_targets = tabb.accumulate(potentials, culture.traditional_foraging_targets, function (a, k, v)
            a[k] = (a[k] or 0) * 0.99 + v * 0.01
            return a
        end)
    else -- initial setting
        culture.traditional_foraging_returns = average_return_per_cost
        culture.traditional_foraging_targets = tabb.accumulate(potentials, {}, function (a, k, v)
            a[k] = v
            return a
        end)
    end
end

return dbm