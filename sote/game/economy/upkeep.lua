local economic_effects = require "game.raws.effects.economic"
local upk = {}

---Runs upkeep on buildings in a province and destroys buildings if upkeep needs aren't met!
---@param province_id province_id
function upk.run(province_id)
	local province = DATA.fatten_province(province_id)
	province.local_building_upkeep = 0

	---@type table<pop_id, number>
	local upkeep_owners = {}
	local government_upkeep = 0

	for _, building in pairs(province.buildings) do
		local up = building.type.upkeep

		if building.type.government then
			government_upkeep = government_upkeep + up
			-- Destroy this building if necessary...
			if province.realm.budget.treasury < 0 then
				if love.math.random() < 0.1 then
					building:remove_from_province()
				end
			end
		else
			local owner = building.owner
			if owner == nil then
				economic_effects.change_local_wealth(
					province_id,
					-up,
					economic_effects.reasons.Upkeep
				)
				province.local_building_upkeep = province.local_building_upkeep + up

				-- Destroy this building if necessary...
				if province.local_wealth < 0 then
					province.local_wealth = 0
					if love.math.random() < 0.1 then
						building:remove_from_province()
					end
				end
			else
				if upkeep_owners[owner] == nil then
					upkeep_owners[owner] = 0
				end
				upkeep_owners[owner] = upkeep_owners[owner] + up
				local savings = DATA.pop_get_savings(owner)
				if savings < upkeep_owners[owner] then
					if love.math.random() < 0.1 then
						building:remove_from_province()
					end
				end
			end
		end
	end

	for owner, upkeep in pairs(upkeep_owners) do
		economic_effects.add_pop_savings(owner, -upkeep, economic_effects.reasons.Upkeep)
	end

	economic_effects.change_treasury(province.realm, -government_upkeep, economic_effects.reasons.Upkeep)
end

return upk
