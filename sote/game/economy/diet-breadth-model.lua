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
	-- TODO weight foragable_targets by climate data
	return 1, { 1, 1 }, { 1, 1 }, 1, 1, 1, 1, 1
end
--[[
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
]]
---@param province Province
function dbm.foragable_targets(province)
	local JOBTYPE = require "game.raws.job_types"
	-- determine amount of foragable goods
	local tile_count, fruit_plants, seed_plants, timber, mushrooms, shellfish, fish, blanks = dbm.foraging_potentials(province)
	---@type {resource: string, output: table<TradeGoodReference, number>, amount: number, search: JOBTYPE, handle: JOBTYPE}[]
	local products = {}
	local fruit_production = (fruit_plants[1] + fruit_plants[2]) * 0.5
	-- BASIC PLANT PRODUCE
	if fruit_production > 0 then
		products['Finding Berries'] = {
			output = { ['berries'] = 1.5 },
			amount = fruit_production,
			search = JOBTYPE.FORAGER,
			handle = JOBTYPE.HAULING,
		}
	end
	local seed_production = (seed_plants[1] + seed_plants[2]) * 0.5
	if seed_production > 0 then
		products['Harvesting Seeds'] = {
			output = { ['grain'] = 1.5 },
			amount = seed_production,
			search = JOBTYPE.FORAGER,
			handle = JOBTYPE.LABOURER,
		}
	end
	-- FORAGING FOR MEAT USE CASE
	if mushrooms > 0 then
		products['Foraging Mushrooms'] = {
			output = { ['mushrooms'] = 1.0 },
			amount = mushrooms,
			search = JOBTYPE.FORAGER,
			handle = JOBTYPE.CLERK,
		}
	end
	-- TODO weight game amounts
	local small_game = 1
	local large_game = small_game / 2
	if small_game > 0 then
		products['Trapping Animals'] = {
			output = { ['meat'] = 0.5  },
			amount = small_game * 2,
			search = JOBTYPE.FORAGER,
			handle = JOBTYPE.ARTISAN,
		}
	-- HUNTING LAND ANIMALS
		products['Hunting Critters'] = {
			output = { ['meat'] = 1.0 },
			amount = small_game,
			search = JOBTYPE.HUNTING,
			handle = JOBTYPE.HAULING,
		}
	end
	if large_game > 0 then
		products['Stalking Game'] = {
			output = { ['meat'] = 2.0 },
			amount = large_game,
			search = JOBTYPE.HUNTING,
			handle = JOBTYPE.WARRIOR,
		}
	end
	-- MARINE FOOD
	if shellfish > 0 then
		products['Gathering Shellfish'] = {
			output = { ['shellfish'] = 2.0 },
			amount = 1,
			search = JOBTYPE.FORAGER,
			handle = JOBTYPE.LABOURER,
		}
	end
	if fish > 0 then
		products['Catching Fish'] = {
			output = { ['fish'] = 1.5 },
			amount = fish,
			search = JOBTYPE.HUNTING,
			handle = JOBTYPE.LABOURER,
		}
	end
	-- NONCALORIC TARGETS
	if timber > 0 then
		products['Collecting Timber'] = {
			output = { ['timber'] = 1.0 },
			amount = timber,
			search = JOBTYPE.CLERK,
			handle = JOBTYPE.LABOURER,
		}
	end
	if blanks > 0 then
		products['Knapping blanks'] = {
			output = { ['blanks-flint'] = 1.0 },
			amount = blanks,
			search = JOBTYPE.CLERK,
			handle = JOBTYPE.ARTISAN,
		}
	end
	province.foraging_targets = products
end
-- TODO change to target a culture and find mean value across all pops based on race and culture needs
---@param race Race
---@return number total_life_needs
---@return table<TradeGoodUseCase, {amount: number, life_need: boolean?}> life_needs_by_use
function dbm.cultural_life_needs(race)
	local total_life_needs, males_per_hundred_females = 0, race.males_per_hundred_females
	local male_to_female_ratio = males_per_hundred_females / (100 + males_per_hundred_females)
	local needs_by_use = tabb.accumulate(race.male_needs, {}, function (needs_by_use, need_index, use_cases)
		total_life_needs = total_life_needs + tabb.accumulate(use_cases, 0, function (accumulated_life_needs, use_case, value)
			local average_gendered_use_case_need = value * male_to_female_ratio + (1 - male_to_female_ratio) * race.female_needs[need_index][use_case]
			needs_by_use[use_case] = {amount = (needs_by_use[use_case] and needs_by_use[use_case].amount or 0) + average_gendered_use_case_need}
			if NEEDS[need_index].life_need then
				needs_by_use[use_case].life_need = true
			end
			return accumulated_life_needs + average_gendered_use_case_need
		end)
		return needs_by_use
	end)
	return total_life_needs, needs_by_use
end

--- use Diet-Breadth Model to pick and weight products for culture
---@param realm Realm
function dbm.cultural_foragable_targets(realm)
	-- TODO change to weight against average of cultural racial life needs instead of primary
    local race = realm.primary_race
	print(race.name)
    local culture = realm.primary_culture
	-- get average life needs from realm primary race
	local total_needs_divisor, needs_by_use_case = dbm.cultural_life_needs(race)
    -- find average return rate of all products to deterime optimal foraging targets
    local total_handle_time, total_energy_return = 0, 0
	---@param potentials table<string, number>
    local potentials = tabb.accumulate(realm.capitol.foraging_targets, {}, function (potentials, resource, values)
        local handling_time = 1 / dbm.mean_race_job_efficiency(race, values.handle)
        total_handle_time = total_handle_time + values.amount * handling_time
		---@param energy_return number
        local energy_return = tabb.accumulate(values.output, 0, function (energy_return, good, produced)
	--		print("looking at: " .. good)
			local caloric_good, life_need = nil, nil
			if RAWS_MANAGER.trade_goods_use_cases_by_name['calories'].goods[good] then
	--			print("  caloric_good set! " .. good)
				caloric_good = true
			else
	--			print("  noncaloric good! " .. good)
			end
			---@param potential_energy number
            energy_return = energy_return + tabb.accumulate(needs_by_use_case, 0, function (potential_energy, use_case, needed)
				local weight = RAWS_MANAGER.trade_goods_use_cases_by_name[use_case].goods[good]
				if weight then
					local amount = needed.amount * weight
					potential_energy = potential_energy + produced * amount
					-- set noncaloric_life_need flag for increasing desire weight of nonfood goods that satisfy life_needs
					if (not life_need) and needed.life_need == true then
	--					print("  life_need set! " .. good)
						life_need = true
					end
				end
				return potential_energy
			end)
			-- weight goods that satisfy life_needs more
			if life_need then
	--			print("  life_need " .. good .. " energy_return " .. energy_return)
				-- weight goods that statisfy life_need as if they also satisfied calories
	--				energy_return = energy_return + needs_by_use_case['calories'].amount
	--				print("    life_need " .. good .. " energy_return now: " .. energy_return)
				if not caloric_good then -- weight noncalorie goods that satisfy life needs like they have a caloric value of meat
					energy_return = energy_return + produced * needs_by_use_case['calories'].amount
						* RAWS_MANAGER.trade_goods_use_cases_by_name['calories'].goods['meat']
	--				print("    noncaloric life_need " .. good .. " energy_return now: " .. energy_return)
				end
	--		else
	--			print("  noncaloric basic need! " .. good .. " energy_return " .. energy_return)
			end
			return energy_return
        end) / total_needs_divisor * values.amount
        total_energy_return = total_energy_return + energy_return
        potentials[resource] = energy_return / handling_time
        return potentials
    end)
    -- only harvest products with a value better than average
    local average_return_per_cost = total_energy_return / (1 + total_handle_time)
    if culture.traditional_foraging_target then
    -- shifts a culture foraging targets by new ideal for each tribe with primary culture
        culture.traditional_foraging_return = culture.traditional_foraging_return * 0.99 + average_return_per_cost * 0.01
		---@param traditional_foraging_target table<string, number>
        culture.traditional_foraging_target = tabb.accumulate(potentials, culture.traditional_foraging_target, function (traditional_foraging_target, resource, value)
            traditional_foraging_target[resource] = (traditional_foraging_target[resource] or 0) * 0.99 + value * 0.01
            return traditional_foraging_target
        end)
    else -- initial setting to first spawn of culture since traditional_foraging_target starts undeclared
        culture.traditional_foraging_return = average_return_per_cost
		---@param traditional_foraging_target table<string, number>
        culture.traditional_foraging_target = tabb.accumulate(potentials, {}, function (traditional_foraging_target, resource, value)
            traditional_foraging_target[resource] = value
	--		print(" - " .. resource .. " " .. value)
            return traditional_foraging_target
        end)
    end
end

return dbm