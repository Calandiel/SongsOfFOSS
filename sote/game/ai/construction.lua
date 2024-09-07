local tabb = require "engine.table"
local ai = require "game.raws.values.ai_preferences"
local eco_values = require "game.raws.values.economy"
local economy_effects = require "game.raws.effects.economy"
local pv = require "game.raws.values.political"

local co = {}

---@param province Province
---@param funds number
---@param excess number
---@param owner pop_id?
---@param overseer pop_id?
---@return number
local function construction_in_province(province, funds, excess, owner, overseer)
	if funds < 50 then
		return funds
	end


	-- if infrastructure is too low, do not build, invest into infra instead
	if province:get_infrastructure_efficiency() < 0.75 then
		if funds - excess > 20 then
			province.infrastructure_investment = province.infrastructure_investment + 20
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


	local random_pop = tabb.random_select_from_set(province.all_pops)
	-- if pop is nil, then buildings are the last thing we need
	if random_pop == nil then
		return funds
	end

	-- calculate ROI
	---@type table<BuildingType, number>
	local ROI_per_building_type = {}
	local min_ROI = nil
	for _, building_type in pairs(province.buildable_buildings) do
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
		local can_build, reason = province:can_build(funds, building_type, overseer, public_flag)
		if (not can_build) and (reason ~= 'not_enough_funds') then
			predicted_profit = 0.001
		end

		if excess < building_type.upkeep then
			predicted_profit = 0.001
		end

		ROI = building_type.construction_cost / predicted_profit

		ROI_per_building_type[building_type] = ROI

		if min_ROI == nil or ROI < min_ROI then
			min_ROI = ROI
		end
	end

	-- set weigths based on predicted profits
	---@type table<BuildingType, number>
	local exp_feature = {}
	local sum_of_exponents = 0
	for _, building_type in pairs(province.buildable_buildings) do
		local ROI = ROI_per_building_type[building_type]

		local feature = nil
		-- do not consider buildings with ROI over half of your life...
		if DATA.pop_get_race(random_pop).max_age / 2 * 12 > ROI then
			feature = -ROI + min_ROI
		end

		-- if WORLD.player_character then
		-- 	if WORLD.player_character.province == province then
		-- 		print(building_type.name)
		-- 		print(feature)
		-- 		print(ROI)
		-- 		print(min_ROI)
		-- 		print(eco_values.projected_income_building_type(
		-- 			province,
		-- 			building_type,
		-- 			random_pop.race,
		-- 			random_pop.female
		-- 		))
		-- 	end
		-- end

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
				.. "\n ROI = "
				.. tostring(ROI)
				.. "\n exp_feature[building_type] = "
				.. tostring(exp_feature[building_type])
				.. "\n feature = "
				.. tostring(feature)
				.. "\n sum_of_exponents = "
				.. tostring(sum_of_exponents)
			)
		end
	end

	---@type number
	local total_weight = sum_of_exponents

	if total_weight > 0 then
		local w = love.math.random() * total_weight
		local acc = 0
		---@type BuildingType
		local to_build = tabb.nth(province.buildable_buildings, 1) -- default to the first building
		for _, ty in pairs(province.buildable_buildings) do
			---@type number
			acc = acc + exp_feature[ty]
			if acc >= w then
				to_build = ty
				break
			end
		end

		-- if WORLD.player_character then
		-- 	if WORLD.player_character.province == province then
		-- 		print('____')
		-- 		print("building target: ")
		-- 		print(to_build.name)
		-- 		print(exp_feature[to_build])
		-- 		print(ROI_per_building_type[to_build])
		-- 	end
		-- end

		-- if there's nothing to build, do not build
		if to_build == nil then
			return funds
		end

		-- pops should not be able to build government buildings
		if to_build.government and owner then
			return funds
		end

		-- Only build if there are unemployed pops...
		-- Actually let's build anyway, because simulation is much more robust now

		if province:can_build(funds, to_build, overseer, public_flag) then
			local construction_cost = eco_values.building_cost(to_build, overseer, public_flag)
			-- We can build! But only build if we have enough excess money to pay for the upkeep...
			if excess >= to_build.upkeep then
				economic_effects.construct_building(to_build, province, owner)
				funds = math.max(0, funds - construction_cost)
			end
		end
	end
	return funds
end

---@param realm Realm
function co.run(realm)
	local excess = realm.budget.education.budget -- Treat monthly education investments as an indicator of "free" income
	local funds = realm.budget.treasury

	if excess > 0 then
		-- disabled for now, dunno if its worth making realm construction rare again
		if true or love.math.random() < 1.0 / 6.0 then
			for province in pairs(realm.provinces) do
				if WORLD:does_player_control_realm(realm) then
					-- Player realms shouldn't run their AI for building construction... unless...
				else
					funds = construction_in_province(province, funds, excess, nil, pv.overseer(realm))
				end

				-- Run construction using the AI for local wealth too!
				local prov = province.local_wealth

				local province_funds = construction_in_province(province, prov, 0) -- 0 "excess" so that pops dont bankrupt player controlled states with building upkeep...
				local change = province_funds - province.local_wealth
				effects.change_local_wealth(province, change, "building")

				-- local characters want to build too!
				-- select random character:
				local builder = tabb.random_select_from_set(province.characters)
				if builder and (WORLD.player_character ~= builder) then
					local char_funds = ai.construction_funds(builder)
					local result = construction_in_province(province, char_funds, 0, builder, builder)

					local spendings = char_funds - result
					effects.add_pop_savings(builder, -spendings, ECONOMY_REASON.BUILDING)
				end
			end
		end
	end

	economic_effects.change_treasury(realm, funds - realm.budget.treasury, ECONOMY_REASON.BUILDING)
end

return co
