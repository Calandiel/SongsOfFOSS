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
--	local mean_annual_temperature = (warmest + coldest) * 0.5
--	local temperture_weighting = 3 / (1 + math.exp(-(mean_annual_temperature * 0.5 - 6) / 3))
--	local annual_percipitation = (jan_rain + jul_rain) * 6
--	local percipitation_weighting = 4 * annual_percipitation / ( annual_percipitation + 1) - 0.5
	local gross_primary_production = temperture_weighting
	-- weight net production by 'biomass' assimilation efficiency
	local net_primary_production = gross_primary_production * (0.6 * tile.grass + 0.5 * tile.shrub + 0.4 * tile.broadleaf + 0.3 * tile.conifer)
	-- some remove primary production from growing structural material and foliage
	local timber_production = net_primary_production * (tile.conifer * 0.25 + tile.broadleaf * 0.125 + tile.shrub * 0.0625 + tile.grass * 0.03125)
	net_primary_production = net_primary_production - timber_production
	-- check for marine resources
	local fish_production, shellfish_production = 0, 0
	if tile.has_marsh then
		fish_production = fish_production + 0.0625
		shellfish_production = shellfish_production + 0.125
	end
	if tile.has_river then
		fish_production = fish_production + 0.125
		shellfish_production = shellfish_production + 0.0625
	end
	for i = 1, 4 do
		if not tile:get_neighbor(i).is_land then
			fish_production = fish_production + 0.125
			shellfish_production = shellfish_production + 0.125
		end
	end
	local marine_temperature_weight = 1 + effective_temperature / (effective_temperature - 70 )
	fish_production = fish_production * marine_temperature_weight
	shellfish_production = shellfish_production * marine_temperature_weight
	-- marine life is an inverted pyramid by 'standing crop' biomass
	fish_production = fish_production + shellfish_production * 0.2
	shellfish_production = shellfish_production * 0.8
	-- determine herbavore energy from eating folliage and reduce from net_primary_production
	local herbivores = 0.2 * (net_primary_production + timber_production)
	net_primary_production = net_primary_production * 0.8
	timber_production = timber_production * 0.8
	-- deterine carinvore energy from eating herbavores and marine life and reduce amounts
	local carinvores = 0.1 * (herbivores + fish_production + shellfish_production)
	herbivores = herbivores * 0.9
	fish_production = fish_production * 0.9
	shellfish_production = shellfish_production * 0.9
	local animal_production = herbivores + carinvores
	-- determine decomposer energy from available biomass
	local mushroom_production = (net_primary_production + animal_production + timber_production) * 0.1
	timber_production = timber_production * 0.9
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
		local flora_total = 3 * (fruit_plants + seed_plants)
		if flora_total > 0 then
			-- weighting such that food production isn't too skewed towards one resource
			local fruit = tile_pp * (2 * fruit_plants + seed_plants) / (flora_total)
			local seeds = tile_pp * (2 * seed_plants + fruit_plants) / (flora_total)
			fruit_production = fruit_production + fruit
			seed_production = seed_production + seeds
			--- add tile timber amount
			timber_amount = timber_amount + timber
		end
		-- calculate aquatic food sources
		shellfish_amount = shellfish_amount + shellfish
		fish_amount = fish_amount + fish
		-- calculate game size ratios using effective_temperature and fauna spread
		local flora_cover = (v.broadleaf + v.conifer) / 1
		local terrestrial_flora_weight = 0.25 + flora_cover / (flora_cover + 1)
		local terrestrial_temperature_weight = 1 - 1 / (1 + math.exp(-0.1 * effective_temperature)) -- cold weights towards larger animals
		local small_animals = game * (1 - terrestrial_temperature_weight) * terrestrial_flora_weight
		local large_animals = game * terrestrial_temperature_weight * (1 - terrestrial_flora_weight)
		small_game = small_game + small_animals
		large_game = large_game + large_animals
		-- calculate mushroom energy by total biomass
		mushroom_amount = mushroom_amount + mushroom
	end)
	return net_pp, fruit_production, seed_production, timber_amount, shellfish_amount, fish_amount, small_game, large_game, mushroom_amount
end

---@param province Province
function dbm.foragable_targets(province)
	local JOBTYPE = require "game.raws.job_types"
	-- determine amount of foragable goods
	local net_pp, fruit_production, seed_production, timber_amount, shellfish_amount,
		fish_amount, small_game, large_game, mushroom_amount = dbm.foraging_potentials(province)
	---@type {resource: string, output: table<TradeGoodReference, number>, amount: number, search: JOBTYPE, handle: JOBTYPE}[]
	local products = {}
	-- FORAGER SEARCH
	if fruit_production > 0 then
		products['Finding Berries'] = {
			output = { ['berries'] = 2 },
			amount = fruit_production,
			search = JOBTYPE.FORAGER,
			handle = JOBTYPE.FORAGER,
		}
	end
	if seed_production > 0 then
		products['Collecting Seeds'] = {
			output = { ['grain'] = 2 },
			amount = seed_production,
			search = JOBTYPE.FORAGER,
			handle = JOBTYPE.FARMER,
		}
	end
	if mushroom_amount > 0 then
		products['Foraging Mushrooms'] = {
			output = { ['mushrooms'] = 2 },
			amount = mushroom_amount,
			search = JOBTYPE.FORAGER,
			handle = JOBTYPE.CLERK,
		}
	end
	if shellfish_amount > 0 then
		products['Gathering Shellfish'] = {
			output = { ['shellfish'] = 2 },
			amount = shellfish_amount,
			search = JOBTYPE.FORAGER,
			handle = JOBTYPE.HAULING,
		}
	end
--	if trappable > 0 then
--		products['Trapping Animals'] = {
--			output = { ['meat'] = 0.5 },
--			amount = math.max(0, small_game * 0.5) + math.max(0, large_game * 0.25),
--			search = JOBTYPE.FORAGER,
--			handle = JOBTYPE.ARTISAN,
--		}
--	end
	-- HUNTING SEARCH
	-- HUNTING LAND ANIMALS
	if small_game > 0 then
		products['Hunting Critters'] = {
			output = { ['meat'] = 1 },
			amount = small_game, --*0.5
			search = JOBTYPE.HUNTING,
			handle = JOBTYPE.HUNTING,
		}
	end
	if large_game > 0 then
		products['Stalking Game'] = {
			output = { ['meat'] = 1 },
			amount = large_game, --*0.75
			search = JOBTYPE.HUNTING,
			handle = JOBTYPE.WARRIOR,
		}
	end
	if fish_amount > 0 then
		products['Catching Fish'] = {
			output = { ['fish'] = 1 },
			amount = fish_amount,
			search = JOBTYPE.HUNTING,
			handle = JOBTYPE.LABOURER,
		}
	end
	-- NONCALORIC TARGET
	if timber_amount > 0 then
		products['Harvesting Timber'] = {
			output = { ['timber'] = 0.5 },
			amount = timber_amount,
			search = JOBTYPE.CLERK,
			handle = JOBTYPE.LABOURER,
		}
	end
	province.foragers_limit = net_pp
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