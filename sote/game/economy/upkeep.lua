local upk = {}

---Runs upkeep on buildings in a province and destroys buildings if upkeep needs aren't met!
---@param province Province
function upk.run(province)
	province.local_building_upkeep = 0
	for _, building in pairs(province.buildings) do
		local up = building.type.upkeep

		if building.type.government then
			province.realm.treasury = province.realm.treasury - up
			province.realm.building_upkeep = province.realm.building_upkeep + up

			-- Destroy this building if necessary...
			if province.realm.treasury < 0 then
				province.realm.treasury = 0
				if love.math.random() < 0.1 then
					building:remove_from_province(province)
				end
			end
		else
			province.local_wealth = province.local_wealth - up
			province.local_building_upkeep = province.local_building_upkeep + up

			-- Destroy this building if necessary...
			if province.local_wealth < 0 then
				province.local_wealth = 0
				if love.math.random() < 0.1 then
					building:remove_from_province(province)
				end
			end
		end
	end
end

return upk
