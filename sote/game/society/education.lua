local tabb = require "engine.table"
local ed = {}

local province_utils = require "game.entities.province".Province
local realm_utils = require "game.entities.realm".Realm

---@param realm Realm
function ed.run(realm)
	-- First, calculate endowment needs
	local edu = 0

	-- From pops
	DATA.for_each_realm_provinces_from_realm(realm, function (province_in_realm)
		local province = DATA.realm_provinces_get_province(province_in_realm)
		local population = province_utils.local_population(province)
		DATA.for_each_technology(function (item)
			if DATA.province_get_technologies_present(province, item) == 0 then
				return
			end
			edu = edu + DATA.technology_get_research_cost(item) * population
		end)
	end)

	DATA.realm_set_budget_target(realm, BUDGET_CATEGORY.EDUCATION, edu)

	-- Once we know the needed endowment, handle investments
	local inv = DATA.realm_get_budget_to_be_invested(realm, BUDGET_CATEGORY.EDUCATION)
	local spillover = 0
	if inv > edu then
		spillover = inv - edu
	end
	-- If we're overinvested, remove a fraction above the invested amount
	inv = inv - spillover * 0.9

	-- Lastly, invest a fraction of the investment into actual endowment
	local invested = inv * (1 / (12 * 7.5)) -- 7.5 years to invest everything

	DATA.realm_inc_budget_to_be_invested(realm, BUDGET_CATEGORY.EDUCATION, -invested)
	DATA.realm_inc_budget_budget(realm, BUDGET_CATEGORY.EDUCATION, invested)

	local current_budget = DATA.realm_get_budget_budget(realm, BUDGET_CATEGORY.EDUCATION)

	-- At the very end, apply some decay to present endowment to prevent runaway growth
	local endowment_decay_rate = 1 - 1 / (12 * 50) -- 50 years to decay everything
	if current_budget > edu then
		endowment_decay_rate = 1 - 1 / (12 * 25) -- 25 years to decay the part above the needed amount
	end
	DATA.realm_set_budget_budget(realm, BUDGET_CATEGORY.EDUCATION, current_budget * endowment_decay_rate)
end

return ed
