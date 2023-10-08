local tr = {}

---@param realm Realm
function tr.run(realm)
	-- for now ai will be pretty static
	-- it would be nice to tie it to external threats/conditions
	EconomicEffects.set_court_budget(realm, 0.2)
	EconomicEffects.set_infrastructure_budget(realm, 0.2)
	EconomicEffects.set_education_budget(realm, 0.4)
	EconomicEffects.set_military_budget(realm, 0.1)

	realm.budget.treasury_target = 100
end

return tr
