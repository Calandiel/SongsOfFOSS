local tabb = require "engine.table"

local tr = {}

---@param realm Realm
function tr.run(realm)
	-- for now ai will be pretty static
	-- it would be nice to tie it to external threats/conditions
	if tabb.size(realm.paying_tribute_to) == 0 then
		EconomicEffects.set_court_budget(realm, 0.1)
		EconomicEffects.set_infrastructure_budget(realm, 0.1)
		EconomicEffects.set_education_budget(realm, 0.3)
		EconomicEffects.set_military_budget(realm, 0.4)
	else
		EconomicEffects.set_court_budget(realm, 0.1)
		EconomicEffects.set_infrastructure_budget(realm, 0.1)
		EconomicEffects.set_education_budget(realm, 0.3)
		EconomicEffects.set_military_budget(realm, 0.2)
	end

	realm.budget.treasury_target = 100
end

return tr
