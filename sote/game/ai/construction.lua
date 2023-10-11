local tabb = require "engine.table"
local ai = require "game.raws.values.ai_preferences"
local effects = require "game.raws.effects.economic"
local eco_values = require "game.raws.values.economical"
local pv = require "game.raws.values.political"

local co = {}

---@param province Province
---@param funds number
---@param excess number
---@param owner POP?
---@param overseer POP?
---@return number
local function construction_in_province(province, funds, excess, owner, overseer)
	---@type number
	local total_weight = 0
	for _, ty in pairs(province.buildable_buildings) do
		total_weight = total_weight + ty.ai_weight
	end

	if total_weight > 0 then
		local w = love.math.random() * total_weight
		local acc = 0
		---@type BuildingType
		local to_build = tabb.nth(province.buildable_buildings, 0) -- default to the first building
		for _, ty in pairs(province.buildable_buildings) do
			acc = acc + ty.ai_weight
			if acc > w then
				to_build = ty
				break
			end
		end

		-- pops should not be able to build government buildings
		if to_build.government and owner then
			return funds
		end

		-- Only build if there are unemployed pops...
		if to_build.production_method:total_jobs() <= province:get_unemployment() then
			local tile = nil
			if to_build.tile_improvement then
				local tt = tabb.size(province.tiles)
				tile = tabb.nth(province.tiles, love.math.random(tt))
			end

			local public_flag = false			
			if owner then
				public_flag = false
			else
				public_flag = true
			end

			if province.can_build(province, math.huge, to_build, tile, overseer, public_flag) then
				local construction_cost = eco_values.building_cost(to_build, overseer, public_flag)

				
				--- Calandiel comment:
				-- If we don't have enough money, just adjust the likelihood (this will be easier on the AI and accurate on long term averages)
				--- Peter's comment:
				-- sounds strange, someone should consider changing it in a future
				-- changing it, because otherwise ai builds things far too fast
				-- if love.math.random() < funds / construction_cost then
				if funds >= construction_cost then
					-- We can build! But only build if we have enough excess money to pay for the upkeep...

					if excess >= to_build.upkeep then
						--Only build if the efficiency isn't tiny (otherwise we could pull productive hunter gatherers from their jobs to unproductive farming jobs...)
						if to_build.production_method:get_efficiency(tile) > 0.65 then
							EconomicEffects.construct_building(to_build, province, tile, owner)
							funds = math.max(0, funds - construction_cost)
						end
					end
				end
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
				province.local_wealth = construction_in_province(province, prov, 0) -- 0 "excess" so that pops dont bankrupt player controlled states with building upkeep...
			
				-- local characters want to build too!
				-- select random character:
				local builder = tabb.random_select_from_set(province.characters)
				if builder and (WORLD.player_character ~= builder) then
					local char_funds = ai.construction_funds(builder)
					local result = construction_in_province(province, char_funds, builder.savings * 0.1, builder, builder)

					local spendings = char_funds - result
					effects.add_pop_savings(builder, -spendings, effects.reasons.Building)
				end
			end
		end
	end

	EconomicEffects.change_treasury(realm, funds - realm.budget.treasury, EconomicEffects.reasons.Building)
end

return co
