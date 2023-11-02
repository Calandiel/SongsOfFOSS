local tabb = require "engine.table"

local mi = {}

---@param realm Realm
function mi.run(realm)
	--print("mil")
	-- local pop = realm:get_realm_population()
	-- -- local target_mil = math.floor(pop * 7.5 / 100.0)
	-- local target_mil = math.floor(pop * 15  / 100.0)

	-- local delta = realm.budget.military.budget - realm.budget.military.target
	-- if delta < 0 then
	-- 	target_mil = target_mil * 0.5
	-- end

	-- local mil = realm:get_realm_military_target() + realm:get_realm_active_army_size()
	-- if target_mil > mil * 1.1 then
	-- 	--print("---")
	-- 	--print("Trying to recruit")
	-- 	local delta = realm.budget.military.budget - realm.budget.military.target
	-- 	if delta >= 0.5 * 24 then
	-- 		-- Enough money to pay to unit for a year or two
	-- 		-- We'll recruit units by targetting random provinces and recruiting a random unit in them using our cultural weights.
	-- 		local to_add = target_mil - mil
	-- 		if to_add > 0 then
	-- 			--print("need to add moe than 0")
	-- 			local provs = realm:get_n_random_pop_weighted_provinces(to_add)
	-- 			for _, prov in pairs(provs) do
	-- 				-- Try recruiting new troops
	-- 				-- Do it by randomly selecting from your cultural preferences...
	-- 				---@type UnitType
	-- 				local unit = tabb.random_select(realm.primary_culture.traditional_units)
	-- 				prov.units_target[unit] = (prov.units_target[unit] or 0) + 1
	-- 			end
	-- 		end
	-- 	end
	-- elseif target_mil < mil * 0.9 then
	-- 	-- We need to shrink the military
	-- 	-- We'll do it by targetting random units in random provinces
	-- 	-- That approach should be rather fast in executionb
	-- 	local to_shrink = mil - target_mil
	-- 	--print("Shrinking: ", to_shrink)
	-- 	if to_shrink > 0 then
	-- 		local provs = realm:get_n_random_pop_weighted_provinces(to_shrink)
	-- 		for _, prov in pairs(provs) do
	-- 			-- Select a random unit and decrease the counter for it
	-- 			---@type UnitType
	-- 			local unit = tabb.random_select(prov.units_target)
	-- 			if unit then
	-- 				if prov.units_target[unit] < 1 then
	-- 					prov.units_target[unit] = 0
	-- 				elseif prov.units_target[unit] == 1 then
	-- 					prov.units_target[unit] = 0 -- nil?
	-- 				else
	-- 					prov.units_target[unit] = prov.units_target[unit] - 1
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end
	--print("done")
end

return mi
