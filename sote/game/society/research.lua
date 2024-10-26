local tabb = require 'engine.table'
local province_utils = require "game.entities.province".Province
local realm_utils = require "game.entities.realm".Realm

local re = {}

---@param province Province
---@param tech Technology
---@param jobs table<job_id, number>
---@return number
local function get_probability_multiplier(province, tech, jobs)
	local pop = province_utils.local_population(province)
	local fat_tech = DATA.fatten_technology(tech)
	local cost = fat_tech.research_cost * pop
	local realm = province_utils.realm(province)
	assert(realm ~= INVALID_ID)
	local budget = DATA.realm_get_budget_budget(realm, BUDGET_CATEGORY.EDUCATION)

	-- We need to calculate the "fraction" of total endowment that this tech would end up using.
	-- Based on that we'll determine the chance for this tech to be researched per month.
	local frac = cost / budget

	local probability = math.min(1, math.max(0.01, 1 - frac))
	-- Scale the research probability by job (but only if one is needed!)
	if fat_tech.associated_job ~= INVALID_ID then
		local ratio = jobs[fat_tech.associated_job] or 1
		local multiplier = 0.05 + 0.95 * ratio
		probability = probability * multiplier
	end
	return probability * 0.5
end

---Handles tech research per province.
---@param province Province
function re.run(province)
	---#logging LOGS:write("province research " .. tostring(province).."\n")
	---#logging LOGS:flush()

	local realm = province_utils.realm(province)

	local perc = realm_utils.get_education_efficiency(realm)
	local jobs = province_utils.get_job_ratios(province)
	local budget = DATA.realm_get_budget_budget(realm, BUDGET_CATEGORY.EDUCATION)

	if perc > 1 and budget > 0 then
		-- Only research if we have more than 100% invested research...
		local n = 0

		local candidates = {}
		DATA.for_each_technology(function (item)
			if DATA.province_get_technologies_researchable(province, item) == 1 then
				n = n + 1
				table.insert(candidates, item)
			end
		end)

		if n > 0 then
			local i = love.math.random(n)

			---@type Technology
			local tech = candidates[i]
			local probability = 1.0 / (12 * 50) * get_probability_multiplier(province, tech, jobs)

			if love.math.random() < probability then
				province_utils.research(province, tech)
			end
		end

		-- After "novel" tech research, try to perform tech spread (once a year on average)
		if love.math.random() < 1 / 12.0 then
			DATA.for_each_province_neighborhood_from_origin(province, function (item)
				local neigh = DATA.province_neighborhood_get_target(item)

				DATA.for_each_technology(function (tech)
					if DATA.province_get_technologies_present(neigh, tech) == 0 then
						return
					end
					if DATA.province_get_technologies_present(province, tech) == 1 then
						return
					end

					local chance = 1 / 2 * get_probability_multiplier(province, tech, jobs)
					if love.math.random() < chance then
						province_utils.research(province, tech)
					end
				end)
			end)
		end
	end
end

return re
