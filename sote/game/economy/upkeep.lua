local ef = require "game.raws.effects.economic"
local upk = {}

---Runs upkeep on buildings in a province and destroys buildings if upkeep needs aren't met!
---@param province Province
function upk.run(province)
	province.local_building_upkeep = 0

	---@type table<POP, number>
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
			if building.owner == nil then
				province.local_wealth = province.local_wealth - up
				province.local_building_upkeep = province.local_building_upkeep + up

				-- Destroy this building if necessary...
				if province.local_wealth < 0 then
					province.local_wealth = 0
					if love.math.random() < 0.1 then
						building:remove_from_province()
					end
				end
			else
				if upkeep_owners[building.owner] == nil then
					upkeep_owners[building.owner] = 0
				end
				upkeep_owners[building.owner] = upkeep_owners[building.owner] + up
				if building.owner.savings < upkeep_owners[building.owner] then
					if love.math.random() < 0.1 then
						building:remove_from_province()
					end
				end
			end
		end
	end

	for owner, upkeep in pairs(upkeep_owners) do
		ef.add_pop_savings(owner, -upkeep, ef.reasons.Upkeep)
	end

	EconomicEffects.change_treasury(province.realm, -government_upkeep, EconomicEffects.reasons.Upkeep)
end

return upk
