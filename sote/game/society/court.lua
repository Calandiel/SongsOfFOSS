local tabb = require "engine.table"

local values = require "game.raws.values.ai_preferences"
local ef = require "game.raws.effects.economy"
local pe = require "game.raws.effects.political"
local province_utils = require "game.entities.province".Province

local co = {}

---@param realm Realm
function co.run(realm)
	-- First, calculate court needs
	---@type number
	local con = 0
	local capitol = DATA.realm_get_capitol(realm)
	-- Your court is nobles of your capital
	DATA.for_each_character_location_from_location(capitol, function (item)
		local character = DATA.character_location_get_character(item)
		con = con + values.money_utility(character)
	end)

	con = con * 10
	DATA.realm_set_budget_target(realm, BUDGET_CATEGORY.COURT, con)

	-- Once we know the needed investment, handle investments
	local inv = DATA.realm_get_budget_to_be_invested(realm, BUDGET_CATEGORY.COURT)
	local spillover = 0
	if inv > con then
		spillover = inv - con
	end
	-- If we're overinvested, remove a fraction above the invested amount
	inv                               = inv - spillover * 0.85

	-- Lastly, invest a fraction of the investment into actual investment
	local invested                    = inv * (1 / (12 * 7.5)) -- 7.5 years to invest everything

	DATA.realm_inc_budget_to_be_invested(realm, BUDGET_CATEGORY.COURT, -invested)
	DATA.realm_inc_budget_budget(realm, BUDGET_CATEGORY.COURT, invested)


	-- Nobles get their share of a court wealth

	local budget = DATA.realm_get_budget_budget(realm, BUDGET_CATEGORY.COURT)
	local wealth_decay_rate           = 1 - 1 / (12 * 1) -- 1 year to decay everything
	if budget > con then
		wealth_decay_rate = 1 - 1 / (12 * 0.5) -- 0.5 years to decay the part above the needed amount
	end
	local total_decay = (1 - wealth_decay_rate) * budget

	local real_overseer_wage = total_decay * 0.1
	local overseer = PoliticalValues.overseer(realm)

	ef.add_pop_savings(overseer, real_overseer_wage, ECONOMY_REASON.COURT)
	total_decay = total_decay - real_overseer_wage
	DATA.realm_inc_budget_budget(realm, BUDGET_CATEGORY.COURT, -real_overseer_wage)

	local nobles_amount = province_utils.local_characters(capitol)
	local nobles_wage = total_decay / (nobles_amount + 1)

	DATA.for_each_character_location_from_location(capitol, function (item)
		local character = DATA.character_location_get_character(item)
		ef.add_pop_savings(character, nobles_wage, ECONOMY_REASON.COURT)
	end)
	DATA.realm_inc_budget_budget(realm, BUDGET_CATEGORY.COURT, -total_decay)


	-- raise new nobles
	local NOBLES_RATIO = 0.15
	DATA.for_each_realm_provinces_from_realm(realm, function (item)
		local province = DATA.realm_provinces_get_province(item)
		---@type {nobles: number, population:number, elligible: pop_id[]}
		local p = { nobles = 0, population = 0, elligible = {} }
		DATA.for_each_home_from_home(province, function (home_location)
			local pop = DATA.home_get_pop(home_location)
			if IS_CHARACTER(pop) then
				p.nobles = p.nobles + 1
			else
				p.population = p.population + 1
				table.insert(p.elligible, pop)
			end
		end)

		if (p.nobles < NOBLES_RATIO * p.population) and (p.population > 5) and (p.nobles < 15) then
			local pop = tabb.random_select_from_array(tabb.filter_array(p.elligible, function(a)
				return PROVINCE(a) == province
			end))

			if pop then
				pe.grant_nobility(pop, province, pe.reasons.PopulationGrowth)
			end
		end
	end)
end

return co
