local tabb = require "engine.table"
local tile = require "game.entities.tile"
local province_utils = require "game.entities.province".Province

local retrieve_good = require "game.raws.raws-utils".trade_good

local dbm = {}

---@param culture culture_id
---@return string tooltip
function dbm.culture_target_tooltip(culture)
	local ut = require "game.ui-utils"
	local result = "\n · Gathering (in % of total foraging time): \n"

	DATA.for_each_forage_resource(function (item)
		local ratio = DATA.culture_get_traditional_forager_targets(culture, item)
		result = result .. "\n    · "
			.. DATA.forage_resource_get_description(item)
			.. " (" .. ut.to_fixed_point2(ratio * 100) .. "%)"
	end)

	return result
end

---@param race race_id
---@param jobtype JOBTYPE
---@return number efficiency scalar multiplier
function dbm.mean_race_job_efficiency(race, jobtype)
	local males_ratio = DATA.race_get_males_per_hundred_females(race)
    local male_to_female_ratio = males_ratio / (100 + males_ratio)
    return
		male_to_female_ratio * DATA.race_get_male_efficiency(race, jobtype)
		+ (1 - male_to_female_ratio) * DATA.race_get_female_efficiency(race, jobtype)
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
		---@type number, number
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
---@param tile_id tile_id
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
		---@type number
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
---@param province province_id
---@return {net_pp: number, fruit: number, seeds: number, wood: number, shell: number, fish: number, game: number, fungi: number}
function dbm.total_foraging_amounts(province)
	local accumulate = {net_pp=0 ,fruit=0, seeds=0, wood=0, shell=0, fish=0, game=0, fungi=0}
	accumulate = tabb.accumulate(
		tabb.map_array(
			DATA.get_tile_province_membership_from_province(province),
			DATA.tile_province_membership_get_tile
		),
		accumulate,
		dbm.accumulate_foraging_production
	)
	return accumulate
end

-- todo: ask squealing to rebalance the thing
local global_multiplier = 1.0

---commenting
---@param province province_id
---@param forage FORAGE_RESOURCE
---@param output trade_good_id
---@param output_value number
---@param available_amount number
local function set_province_data(province, index, forage, output, output_value, available_amount)
	DATA.province_set_foragers_targets_forage(province, index, forage)
	DATA.province_set_foragers_targets_amount(province, index, available_amount)
	DATA.province_set_foragers_targets_output_good(province, index, output)
	DATA.province_set_foragers_targets_output_value(province, index, output_value * global_multiplier)
end

---@param province province_id
---@param amounts {net_pp: number, fruit: number, seeds: number, wood: number, shell: number, fish: number, game: number, fungi: number}
---Calculate and set a province's forager limit (CC) and foraging targets
function dbm.set_foraging_targets(province, amounts)
	local hydration = DATA.province_get_hydration(province)
	set_province_data(province, 1, FORAGE_RESOURCE.WATER, retrieve_good("water"), 80, hydration)
	set_province_data(province, 2, FORAGE_RESOURCE.FRUIT, retrieve_good("berries"), 1.6, amounts.fruit)
	set_province_data(province, 3, FORAGE_RESOURCE.GRAIN, retrieve_good("grain"), 2, amounts.seeds)
	set_province_data(province, 4, FORAGE_RESOURCE.WOOD, retrieve_good("bark"), 1.25, amounts.wood)
	set_province_data(province, 5, FORAGE_RESOURCE.WOOD, retrieve_good("timber"), 0.25, amounts.wood)
	set_province_data(province, 6, FORAGE_RESOURCE.GAME, retrieve_good("meat"), 1, amounts.game)
	set_province_data(province, 7, FORAGE_RESOURCE.GAME, retrieve_good("hide"), 0.25, amounts.game)
	set_province_data(province, 8, FORAGE_RESOURCE.FUNGI, retrieve_good("mushrooms"), 1.25, amounts.fungi)
	set_province_data(province, 9, FORAGE_RESOURCE.SHELL, retrieve_good("shellfish"), 1, amounts.shell)
	set_province_data(province, 10, FORAGE_RESOURCE.SHELL, retrieve_good("seaweed"), 2, amounts.shell)
	set_province_data(province, 11, FORAGE_RESOURCE.FISH, retrieve_good("fish"), 1.25, amounts.fish)
	DATA.province_set_foragers_limit(province, amounts.net_pp)
end

---@param province Province
function dbm.update_foraging_targets(province)
	DCON.update_foraging_data(
		province,
		retrieve_good("water"),
		retrieve_good("berries"),
		retrieve_good("grain"),
		retrieve_good("bark"),
		retrieve_good("timber"),
		retrieve_good("meat"),
		retrieve_good("hide"),
		retrieve_good("mushrooms"),
		retrieve_good("shellfish"),
		retrieve_good("seaweed"),
		retrieve_good("fish"),
		WORLD.world_size
	)
end

---@alias NeedUseCaseAmount {need: NEED, use_case: use_case_id, amount: number}

-- TODO change to target a culture and find mean value across all pops based on race and culture needs
---@param race race_id
---@return NeedUseCaseAmount[] food_needs_by_use
function dbm.cultural_food_needs(race)
	local males_per_hundred_females = DATA.race_get_males_per_hundred_females(race)
	local male_to_female_ratio = males_per_hundred_females / (100 + males_per_hundred_females)

	---@type table<use_case_id, number>
	local food_needs = {}

	for i = 1, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
		local need = DATA.race_get_male_needs_need(race, i)
		local use_case = DATA.race_get_male_needs_use_case(race, i)
		if (need == NEED.FOOD) then
			local male_value = DATA.race_get_male_needs_required(race, i)
			local female_value = DATA.race_get_female_needs_required(race,i)
			local average_gendered_use_case_need =
				male_value * male_to_female_ratio
				+ (1 - male_to_female_ratio) * female_value

			-- overestimate needed water:
			if use_case == WATER_USE_CASE then
				average_gendered_use_case_need = average_gendered_use_case_need * 80
			end

			table.insert(food_needs, {use_case = use_case, need = need, amount = average_gendered_use_case_need})
		end
	end

	return food_needs
end


---@class (exact) TargetResourceTable
---@field forage_resource FORAGE_RESOURCE
---@field search_time number
---@field handle_time number
---@field output number
---@field output_energy number
---@field energy_return_per_unit_of_time number

---@class (exact) TargetNeedsTable
---@field use_case use_case_id
---@field required_amount_of_use number
---@field total_search_time number
---@field total_handle_time number
---@field total_energy_output number
---@field average_energy_return_per_unit_of_time number
---@field data_per_forage_target TargetResourceTable[]

---commenting
---@param good trade_good_id
---@param use_case use_case_id
---@param amount number
---@return number
local function turn_output_to_energy(good, use_case, amount)
	local weight = USE_WEIGHT[good][use_case]
	return weight * amount
--	print("       VALID GOOD: " .. good .. ", AMOUNT: " .. values.amount .. ", OUTPUT: " .. weighted_output .. ", ENERGY: " .. weighted_output * values.amount)
end

---commenting
---@param race race_id
---@param province province_id
---@param use_case use_case_id
---@param needed number
---@return TargetNeedsTable
local function forage_targets_for_a_given_use_case(race, province, use_case, needed)
--		print("    USE: " .. use .. ", NEEDED: " .. needed)
	local province_size = DATA.province_get_size(province)

	local total_search = 0
	local total_output = 0
	local total_handle = 0
	local total_energy_output = 0

	---@type TargetResourceTable[]
	local data_per_forage_target = {}

	-- print("update use case", use_case)

	for i = 1, MAX_RESOURCES_IN_PROVINCE_INDEX do
		local forage_case = DATA.province_get_foragers_targets_forage(province, i)
		local required_job =  DATA.forage_resource_get_handle(forage_case)
		local amount = DATA.province_get_foragers_targets_amount(province, i)
		local output_good = DATA.province_get_foragers_targets_output_good(province, i)
		local output_value = DATA.province_get_foragers_targets_output_value(province, i)

		if output_good == INVALID_ID then
			break
		end

		-- print("forage resource")

		---@type number
		local energy = turn_output_to_energy(output_good, use_case, output_value) -- per collected unit
		local search_time = province_size -- total searching time to find everything
		local efficiency = dbm.mean_race_job_efficiency(race, required_job) -- efficiency of actually collecting the thing
		local handle_time = amount / efficiency -- time spent to collect everything
		local total_energy = energy * amount -- total collected "energy"

		assert(handle_time == handle_time, tostring(handle_time))
		assert(efficiency > 0, tostring(efficiency) .. " " .. DATA.race_get_name(race) .. " " .. DATA.jobtype_get_name(required_job))

		data_per_forage_target[i] = {
			forage_resource = forage_case,
			search_time = search_time,
			handle_time = handle_time,
			output = amount,
			output_energy = total_energy,
			energy_return_per_unit_of_time = total_energy / (search_time + handle_time)
		}

		---@type number
		total_search = total_search + search_time
		---@type number
		total_handle = total_handle + handle_time
		---@type number
		total_output = total_output + amount
		---@type number
		total_energy_output = total_energy_output + total_energy
	end

	---@type TargetNeedsTable
	local result = {
		use_case = use_case,
		required_amount_of_use = needed,
		total_handle_time = total_handle,
		total_search_time = total_search,
		total_energy_output = total_energy_output,
		average_energy_return_per_unit_of_time = total_energy_output / (total_handle + total_search),
		data_per_forage_target = data_per_forage_target
	}

	return result
end


---Sets weights of targets below average return to 0
---Sets weights of other targets to their return
---@param forage_targets_data TargetNeedsTable
---@return number[]
local function use_case_data_to_weights(forage_targets_data)
	---@type number[]
	local weights = {}


	for i, data in pairs(forage_targets_data.data_per_forage_target) do
		local return_this = data.energy_return_per_unit_of_time
		if return_this < return_average * 0.5 then
			weights[i] = 0
		else
			weights[i] = return_this
		end

		-- if weights[i] ~= weights[i] then
		-- 	tabb.print(data)
		-- end

		assert(weights[i] == weights[i], "INVALID WEIGHT")
	end

	return weights
end

---@param use_cases_data TargetNeedsTable[]
---@return number[][] weights
local function calculate_weights(use_cases_data)

	---@type number[][]
	local weights = {}

	-- init weights with filtered returns + smoothing:
	local sum_of_weights = 0
	for i, targets_table in pairs(use_cases_data) do
		weights[i] = {}
		local return_average = targets_table.average_energy_return_per_unit_of_time
		for j, target_data in pairs(targets_table.data_per_forage_target) do
			local return_this = target_data.energy_return_per_unit_of_time
			-- if return_this < return_average * 0.5 then
			-- 	weights[i][j] = 0 + 0.01
			-- else
			-- 	weights[i][j] = return_this + 0.01
			-- end
			-- sum_of_weights = sum_of_weights + weights[i][j]
			weights[i][j] = 0
		end
	end

	local smoothing = 0.00001

	--- do several epochs to get close to solution: writing proper solver of such equations is out of question... for now
	local num_of_iterations = 100000
	LOGS:write("?????????????\n")
	for i, targets_table in pairs(use_cases_data) do
		LOGS:write(DATA.use_case_get_name(targets_table.use_case) .. "\n")
		local step = 0.1
		---@type nil|number
		local last = nil
		for iteration = 1, num_of_iterations do
			--- we want to maximize needs satisfaction and avoid overproduction
			--- so we use this pretty dumb "walk"
			--- decide if we want to reduce production or increase it:

			local required = targets_table.required_amount_of_use
			local provided = 0

			for j, target_data in pairs(targets_table.data_per_forage_target) do
				provided = provided
					+ weights[i][j]
					* (target_data.handle_time + target_data.search_time)
					* target_data.energy_return_per_unit_of_time
			end

			LOGS:write(tostring(iteration) .. "\t" .. tostring(required - provided).. "\t" .. tostring(provided) .. "/" .. tostring(required) .. "\n")
			--- next we reduce/increase weights depending on their efficiency
			--- obviously we want to get rid of weak sources and increase reliance on strong
			--- but without being overzealous
			local current_loss = required - provided
			if last == nil then
				last = current_loss
			else
				if math.abs(math.abs(current_loss) - math.abs(last)) < 0.001 then
					step = 2 * step
				elseif math.abs(math.abs(current_loss) - math.abs(last)) < 0.01 then
					step = 1.2 * step
				elseif current_loss * last < 0 then
					step = step / 2
				end
			end

			last = current_loss

			if math.abs(current_loss) < 0.01 then
				break
			end

			if provided < required then
				for j, target_data in pairs(targets_table.data_per_forage_target) do
					weights[i][j] =
						weights[i][j]
						+ math.min(0.01,
							(required - provided)
							* step
							/ (target_data.handle_time + target_data.search_time + 1)
							/ (target_data.energy_return_per_unit_of_time + 1)
							* target_data.output_energy
						)

					-- assert(weights[i][j] == weights[i][j])
				end
			else
				for j, target_data in pairs(targets_table.data_per_forage_target) do
					weights[i][j] = math.max(
						0,
						weights[i][j]
						- math.min(0.01,
							(provided - required)
							* step
							/ (target_data.handle_time + target_data.search_time + 1)
							/ (target_data.energy_return_per_unit_of_time + 1)
							* math.exp(-target_data.output_energy / 1000)
						)
					)

					-- assert(weights[i][j] == weights[i][j],
					-- 	"(provided - required) " .. tostring(provided - required) ..
					-- 	"\n* step " .. tostring(step) ..
					-- 	"\n/ (target_data.handle_time + target_data.search_time + 1)" .. tostring((target_data.handle_time + target_data.search_time + 1)) ..
					-- 	"\n/ (target_data.energy_return_per_unit_of_time + 1)" .. tostring(target_data.energy_return_per_unit_of_time + 1)..
					-- 	"\n* math.exp(-target_data.output_energy / 1000)" .. tostring(math.exp(-target_data.output_energy / 1000)).. "\n"
					-- )
				end
			end
		end
	end

	--- calculate norm: total time required to gather according to weights
	--- and then normalize out timetable
	--- spice up with smoothing so it's not too boring

	local norm = 0
	local smooth_sum = 0
	for i, targets_table in pairs(use_cases_data) do
		for j, target_data in pairs(targets_table.data_per_forage_target) do
			---@type number
			norm = norm + (weights[i][j] + smoothing) * (target_data.handle_time + target_data.search_time)
		end
	end

	-- tabb.deep_print(weights)
	assert(norm > 0, norm)
	sum_of_weights = 0
	for i, targets_table in pairs(use_cases_data) do
		for j, target_data in pairs(targets_table.data_per_forage_target) do
			---@type number
			weights[i][j] = (weights[i][j] + smoothing) / norm
			sum_of_weights = sum_of_weights + weights[i][j]
		end
	end

	return weights
end

---@param use_cases_data TargetNeedsTable[]
---@param weights number[][]
---@return table<FORAGE_RESOURCE, number>
local function weights_to_forage_time_distribution(use_cases_data, weights)
	---@type table<FORAGE_RESOURCE, number>
	local distribution = {}

	DATA.for_each_forage_resource(function (item)
		distribution[item] = 0
	end)

	for i, targets_table in pairs(use_cases_data) do
		for j, target_data in pairs(targets_table.data_per_forage_target) do
			local forage_resource = target_data.forage_resource
			distribution[forage_resource] = distribution[forage_resource] + weights[i][j] * (target_data.handle_time + target_data.search_time)
		end
	end

	return distribution
end

---Use Diet-Breadth Model to weight, pick and normalize targets
--- and search times for when foraging for food and water
---@param province province_id
function dbm.cultural_foragable_targets(province)
--	print("CULTURE: " .. culture.name)
	-- get average life needs from realm primary race
	local realm = province_utils.realm(province)
	assert(realm ~= nil)
	local race = DATA.realm_get_primary_race(realm)
	local food_use_cases_needs = dbm.cultural_food_needs(race)

	local food_use_cases_data = tabb.map_array(
		food_use_cases_needs,
		function (use_case_amount)
			return forage_targets_for_a_given_use_case(race, province, use_case_amount.use_case, use_case_amount.amount)
		end
	)

	local weights = calculate_weights(food_use_cases_data)
	return weights_to_forage_time_distribution(food_use_cases_data, weights)
end

return dbm