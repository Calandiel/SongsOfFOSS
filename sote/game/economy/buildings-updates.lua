local tabb = require "engine.table"
local bld = {}

local economy_values = require "game.raws.values.economical"
local economy_effects = require "game.raws.effects.economic"

---Employs pops in the province.
---@param province Province
function bld.run(province)
    -- destroy unused building
	---@type Building[]
	local to_destroy = {}
	for _, building in pairs(province.buildings) do
		if tabb.size(building.workers) == 0 then
			building.unused = building.unused + 1
		else
			building.unused = 0
		end

		if building.unused > 12 then
			table.insert(to_destroy, building)
		end
	end

	for _, building in pairs(to_destroy) do
		-- print(building.type.description .. " was destroyed due to being unused for a long time")
		economy_effects.destroy_building(building)
	end

	-- update building type of buildings:
	for _, building in pairs(province.buildings) do
		if building.unused > 2 then
			local group = building.type.building_group

			if group then
				local candidate = tabb.random_select_from_set(GROUP_TO_BUILDING_TYPES[group])

				if candidate and province.buildable_buildings[candidate] then
					local income = economy_values.projected_income_building_type_unknown_pop(
						province,
						candidate
					)

					local current = economy_values.projected_income_building_type_unknown_pop(
						province,
						building.type
					)

					if income > current then
						building.type = candidate
					end
				end
			end
		end
	end
end

return bld