local tabb = require "engine.table"
local rec = {}

---Runs recruitment logic on a province, matching pops to needed units
---@param province Province
function rec.run(province)
	--print("rec")
	for unit, target in pairs(province.units_target) do
		local current_count = 0
		local current = province.units[unit]
		if current then
			current_count = tabb.size(province.units[unit])
		end

		local payment = province.realm.budget.military.target
		local current_budget = province.realm.budget.military.budget
		
		if (current_count > target) or (payment * love.math.random() > current_budget) then
			-- Too many soldiers, fire some
			local delta = current_count - target
			for _ = 1, delta do
				local pop = tabb.nth(province.units[unit], 1)
				if pop then
					province:unregister_military_pop(pop)
				end
			end
		elseif current_count < target then
			-- Too few soldiers hire some
			local delta = target - current_count
			for pop, _ in pairs(province.all_pops) do
				if (not pop.drafted) and (pop.age > pop.race.teen_age) and (pop.age < pop.race.elder_age) then
					province:recruit(pop, unit)
					delta = delta - 1
				end
				if delta == 0 then
					break
				end
			end
		end
	end
	--print("done")
end

return rec
