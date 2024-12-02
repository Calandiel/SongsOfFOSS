local tabb = require "engine.table"
local bld = {}

local economy_values = require "game.raws.values.economy"
local economy_effects = require "game.raws.effects.economy"

local building_utils = require "game.entities.building".Building
local method_utils = require "game.raws.production-methods"

---@class (exact) CandidateBuilding
---@field profit number
---@field cost number
---@field type building_type_id

---Employs pops in the province.
---@param province province_id
function bld.run(province)
	---#logging LOGS:write("province building " .. tostring(province).."\n")
	---#logging LOGS:flush()

    -- destroy unused building
	---@type Building[]
	local to_destroy = {}
	DATA.for_each_building_location_from_location(province, function (item)
		local building_id = DATA.building_location_get_building(item)
		local building_type = DATA.building_get_current_type(building_id)
		local production_method = DATA.building_type_get_production_method(building_type)
		local workers = building_utils.amount_of_workers(building_id)
		local max_amount_of_workers = method_utils.total_jobs(production_method)


		if (workers == 0) and (max_amount_of_workers > 0) then
			DATA.building_inc_unused(building_id, 1)
		else
			DATA.building_set_unused(building_id, 0)
		end

		if DATA.building_get_unused(building_id) > 24 then
			table.insert(to_destroy, building_id)
		end
	end)

	for _, building in pairs(to_destroy) do
		-- print(building.type.description .. " was destroyed due to being unused for a long time")
		economy_effects.destroy_building(building)
	end

	-- such replacement of building type doesn't work really well

	-- local primary_race = DATA.realm_get_primary_race(PROVINCE_REALM(province))

	-- ---@type CandidateBuilding[]
	-- local candidate_targets_for_replacement = {}
	-- DATA.for_each_building_type(function (candidate)
	-- 	if DATA.province_get_buildable_buildings(province, candidate) == 0 then
	-- 		return
	-- 	end

	-- 	local cost = DATA.building_type_get_construction_cost(candidate)

	-- 	local potential_income = economy_values.projected_income_building_type(
	-- 		province,
	-- 		candidate,
	-- 		primary_race,
	-- 		false
	-- 	)
	-- 	if potential_income < 0 then
	-- 		return
	-- 	end

	-- 	---@type CandidateBuilding
	-- 	local data = {
	-- 		cost = cost,
	-- 		profit = potential_income,
	-- 		type = candidate
	-- 	}

	-- 	table.insert(candidate_targets_for_replacement, data)
	-- end)

	-- local number_of_candidates = #candidate_targets_for_replacement

	-- -- update building type of buildings:
	-- DATA.for_each_building_location_from_location(province, function (item)
	-- 	local building_id = DATA.building_location_get_building(item)
	-- 	local building_type = DATA.building_get_current_type(building_id)
	-- 	local production_method = DATA.building_type_get_production_method(building_type)
	-- 	local unused = DATA.building_get_unused(building_id)
	-- 	local old_cost = DATA.building_type_get_construction_cost(building_type)
	-- 	if unused > 12 and number_of_candidates > 0 then
	-- 		local _, candidate = tabb.random_select_from_set(candidate_targets_for_replacement)
	-- 		local cost = candidate.cost
	-- 		if old_cost > cost then
	-- 			DATA.building_set_current_type(building_id, candidate.type)
	-- 		end
	-- 	end
	-- end)
end

return bld