local tabb = require "engine.table"

local values = require "game.raws.values.ai_preferences"
local ef = require "game.raws.effects.economic"
local pe = require "game.raws.effects.political"
local co = {}

---@param realm Realm
function co.run(realm)
	-- First, calculate court needs
	---@type number
	local con = 0
	-- Your court is nobles of your capital
	for _, character in pairs(realm.capitol.characters) do
		if character.province == nil then

			error("CHARACTER DOES NOT HAVE A PROVINCE .. \n"
			.. character.name .. "\n"
			.. tostring(character.age) .. "\n"
			.. tostring(character.dead) .. "\n"
			.. tostring(character.former_pop))
		end
		con = con + values.money_utility(character)
	end
	con = con * 10
	realm.budget.court.target = con

	-- Once we know the needed investment, handle investments
	local inv = realm.budget.court.to_be_invested
	local spillover = 0
	if inv > con then
		spillover = inv - con
	end
	-- If we're overinvested, remove a fraction above the invested amount
	inv = inv - spillover * 0.85

	-- Lastly, invest a fraction of the investment into actual investment
	local invested = inv * (1 / (12 * 7.5)) -- 7.5 years to invest everything
	realm.budget.court.to_be_invested 	= inv - invested
	realm.budget.court.budget 			= realm.budget.court.budget + invested

	-- Nobles get their share of a court wealth
	-- At the very end, apply some decay to present investment to prevent runaway growth
	local wealth_decay_rate = 1 - 1 / (12 * 2) -- 2 years to decay everything
	if realm.budget.court.budget > con then
		wealth_decay_rate = 1 - 1 / (12 * 1) -- 1 years to decay the part above the needed amount
	end
	local total_decay = (1 - wealth_decay_rate) * realm.budget.court.budget

	local real_overseer_wage = total_decay * 0.1

	if realm.overseer then
		ef.add_pop_savings(realm.overseer, real_overseer_wage, ef.reasons.Court)

		total_decay = total_decay - real_overseer_wage
		realm.budget.court.budget = realm.budget.court.budget - real_overseer_wage
	end

	local nobles_amount = tabb.size(realm.capitol.characters)
	local nobles_wage = total_decay / (nobles_amount + 1)

	for _, character in pairs(realm.capitol.characters) do
		ef.add_pop_savings(character, nobles_wage, ef.reasons.Court)
	end

	-- raise new nobles
	local NOBLES_RATIO = 0.15
	for _, prov in pairs(realm.provinces) do
		local p = {nobles = 0, population = 0, elligible = {}}
		tabb.accumulate(prov.home_to, p, function (a, k, v)
			if v:is_character() then
				a.nobles = a.nobles + 1
			else
				a.population = a.population + 1
				a.elligible[k] = v
			end
			return a
		end)
		if (p.nobles < NOBLES_RATIO * p.population) and (p.population > 5) and (p.nobles < 15) then
			local pop = tabb.random_select_from_set(tabb.filter(p.elligible, function (a)
				return a.province == prov
			end))
			if pop then
				pe.grant_nobility(pop,prov, pe.reasons.POPULATION_GROWTH)
			end
		end
	end

	realm.budget.court.budget = realm.budget.court.budget - total_decay
end

return co
