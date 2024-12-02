local tabb = require "engine.table"
local economic_effects = require "game.raws.effects.economy"


local tr = {}

---@param realm Realm
function tr.run(realm)
	---#logging LOGS:write("treasury " .. tostring(realm).."\n")
	---#logging LOGS:flush()
	-- for now ai will be pretty static
	-- it would be nice to tie it to external threats/conditions

	local pays_tribute = false

	DATA.for_each_realm_subject_relation_from_subject(realm, function (item)
		if DATA.realm_subject_relation_get_wealth_transfer(item) then
			pays_tribute = true
		end
	end)

	if not pays_tribute then
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
	local education_target = DATA.realm_get_budget_target(realm, BUDGET_CATEGORY.EDUCATION)

	local fat = DATA.fatten_realm(realm)

	fat.budget_tax_target = 10 + education_target
	fat.budget_treasury_target = 250

	local leader = LEADER(realm)

	if leader ~= INVALID_ID then
		-- if ruler is gready, he doubles the tax
		for i = 1, MAX_TRAIT_INDEX do
			local trait = DATA.pop_get_traits(leader, i)

			if trait == 0 then
				break
			end

			if trait == TRAIT.GREEDY then
				fat.budget_tax_target = fat.budget_tax_target * 2
				fat.budget_treasury_target = 400
			end
		end
	end
end

return tr
