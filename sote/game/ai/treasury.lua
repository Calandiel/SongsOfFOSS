local tabb = require "engine.table"
local economic_effects = require "game.raws.effects.economy"


local tr = {}

---@param realm Realm
function tr.run(realm)
	-- for now ai will be pretty static
	-- it would be nice to tie it to external threats/conditions
	if tabb.size(realm.paying_tribute_to) == 0 then
		economic_effects.set_court_budget(realm, 0.1)
		economic_effects.set_infrastructure_budget(realm, 0.1)
		economic_effects.set_education_budget(realm, 0.3)
		economic_effects.set_military_budget(realm, 0.4)
	else
		economic_effects.set_court_budget(realm, 0.1)
		economic_effects.set_infrastructure_budget(realm, 0.1)
		economic_effects.set_education_budget(realm, 0.3)
		economic_effects.set_military_budget(realm, 0.2)
	end

	-- for now ais will try to collect enough taxes to maintain eductation
	realm.tax_target = 10 + realm.budget.education.target
	realm.budget.treasury_target = 250


	-- if ruler is gready, he doubles the tax
	for i = 0, MAX_TRAIT_INDEX do
		local trait = DATA.pop_get_traits(realm.leader, i)

		if trait == 0 then
			break
		end

		if trait == TRAIT.GREEDY then
			realm.tax_target = realm.tax_target * 2
			realm.budget.treasury_target = 400
		end
	end
end

return tr
