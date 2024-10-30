local tabb = require "engine.table"
local province_utils = require "game.entities.province".Province
local ai = require "game.raws.values.ai"
local eco_values = require "game.raws.values.economy"
local demography_values = require "game.raws.values.demography"
local economy_effects = require "game.raws.effects.economy"
local pv = require "game.raws.values.politics"

local co = {}

---@param province Province
---@param funds number
---@param excess number
---@param owner pop_id
---@param overseer pop_id
---@return number
local function construction_in_province(province, funds, excess, owner, overseer)
	if funds < 50 then
		return funds
	end

	-- if infrastructure is too low, do not build, invest into infra instead
	if province_utils.get_infrastructure_efficiency(province) < 0.75 then
		if funds - excess > 20 then
			DATA.province_inc_infrastructure_investment(province, 20)
			funds = funds - 20
		end
		return funds
	end

	local public_flag = false
	if owner then
		public_flag = false
	else
		public_flag = true
	end


	local random_pop_location = tabb.random_select_from_set(DATA.filter_pop_location_from_location(province, ACCEPT_ALL))

	-- if pop is nil, then buildings are the last thing we need
	if random_pop_location == nil then
		return funds
	end

	local random_pop = DATA.pop_location_get_pop(random_pop_location)

	local random_pop = demography_values.sample_character_from_province

	-- calculate time to get back your investments
	---@type table<BuildingType, number>
	local time_per_building_type = {}
	local min_time = math.huge

	DATA.for_each_building_type(function (building_type)
		if DATA.province_get_buildable_buildings(province, building_type) == 0 then
			return
		end

		local predicted_profit = eco_values.projected_income_building_type(
			province,
			building_type,
			DATA.pop_get_race(random_pop),
			DATA.pop_get_female(random_pop)
		)

		-- sanity scaling + clamping
		predicted_profit = math.max(0.001, predicted_profit)

		-- select random tile because it's cheaper
		-- and check if building is possible:
		local can_build, reason = province_utils.can_build(province, funds, building_type, overseer, public_flag)
		if (not can_build) and (reason ~= 'not_enough_funds') then
			predicted_profit = 0.001
		end

		local upkeep = DATA.building_type_get_upkeep(building_type)
		if excess < upkeep then
			predicted_profit = 0.001
		end

		local construction_cost = DATA.building_type_get_construction_cost(building_type)
		local payback_time = construction_cost / predicted_profit

		time_per_building_type[building_type] = payback_time

		if payback_time < min_time then
			min_time = payback_time
		end
	end)

	-- set weigths based on predicted profits
	---@type table<BuildingType, number>
	local exp_feature = {}
	local sum_of_exponents = 0
	DATA.for_each_building_type(function (building_type)
		if DATA.province_get_buildable_buildings(province, building_type) == 0 then
			return
		end

		local time = time_per_building_type[building_type]

		local feature = nil

		-- do not consider buildings with expected time to return investments over half of your life...

		local race = DATA.pop_get_race(owner)
		local max_age = DATA.race_get_max_age(race)

		if max_age / 2 * 12 > time then
			feature = -time + min_time
		end

		if feature then
			sum_of_exponents = sum_of_exponents + math.exp(feature)
			exp_feature[building_type] = math.exp(feature)
		else
			sum_of_exponents = sum_of_exponents + 0
			exp_feature[building_type] = 0
		end

		if sum_of_exponents ~= sum_of_exponents then
			error(
				"INVALID EXP IN CONSTRUCTION LOGIC: "
				.. "\n time = "
				.. tostring(time)
				.. "\n exp_feature[building_type] = "
				.. tostring(exp_feature[building_type])
				.. "\n feature = "
				.. tostring(feature)
				.. "\n sum_of_exponents = "
				.. tostring(sum_of_exponents)
			)
		end
	end)

	---@type number
	local total_weight = sum_of_exponents

	if total_weight > 0 then
		local w = love.math.random() * total_weight
		local acc = 0
		---@type BuildingType
		local to_build = INVALID_ID -- default to the invalid id

		DATA.for_each_building_type(function (building_type)
			if exp_feature[building_type] == nil then
				return
			end

			---@type number
			acc = acc + exp_feature[building_type]
			if acc >= w and building_type == INVALID_ID then
				to_build = building_type
			end
		end)

		-- if there's nothing to build, do not build
		if to_build == INVALID_ID then
			return funds
		end

		local is_gov = DATA.building_type_get_government(to_build)

		-- pops should not be able to build government buildings
		if is_gov and owner ~= INVALID_ID then
			return funds
		end

		-- Only build if there are unemployed pops...
		-- Actually let's build anyway, because simulation is much more robust now

		if province_utils.can_build(province, funds, to_build, overseer, public_flag) then
			local construction_cost = eco_values.building_cost(to_build, overseer, public_flag)
			-- We can build! But only build if we have enough excess money to pay for the upkeep...
			if excess >= DATA.building_type_get_upkeep(to_build) then
				economy_effects.construct_building(to_build, province, owner)
				funds = math.max(0, funds - construction_cost)
			end
		end
	end
	return funds
end

---@param realm Realm
function co.run(realm)
	---#logging LOGS:write("construction " .. tostring(realm) .."\n")
	---#logging LOGS:flush()
	local base_tick_spending = DATA.realm_get_budget_budget(realm, BUDGET_CATEGORY.EDUCATION)

	local excess = base_tick_spending -- Treat monthly education investments as an indicator of "free" income
	local funds = DATA.realm_get_budget_treasury(realm)

	if excess > 0 then
		DATA.for_each_realm_provinces_from_realm(realm, function (membership)
			local province = DATA.realm_provinces_get_province(membership)
			if WORLD:does_player_control_realm(realm) then
				-- Player realms shouldn't run their AI for building construction... unless...
			else
				funds = construction_in_province(province, funds, excess, INVALID_ID, pv.overseer(realm))
			end

			-- Run construction using the AI for local wealth too!
			local wealth = DATA.province_get_local_wealth(province)

			local province_funds = construction_in_province(province, wealth, 0, INVALID_ID, INVALID_ID) -- 0 "excess" so that pops dont bankrupt player controlled states with building upkeep...
			local change = province_funds - wealth
			economy_effects.change_local_wealth(province, change, ECONOMY_REASON.BUILDING)

			-- local characters want to build too!
			-- select random character:
			local builder_location = tabb.random_select_from_set(DATA.filter_character_location_from_location(province, ACCEPT_ALL))

			if builder_location == nil then
				return
			end

			local builder = DATA.character_location_get_character(builder_location)

			if WORLD.player_character ~= builder then
				local char_funds = ai.construction_funds(builder)
				local result = construction_in_province(province, char_funds, 0, builder, builder)

				local spendings = char_funds - result
				economy_effects.add_pop_savings(builder, -spendings, ECONOMY_REASON.BUILDING)
			end
		end)
	end

	local old_treasury = DATA.realm_get_budget_treasury(realm)
	economy_effects.change_treasury(realm, funds - old_treasury, ECONOMY_REASON.BUILDING)
end

return co
