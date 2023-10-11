local tabb = require 'engine.table'
local re = {}

---@param province Province
---@param tech Technology
---@param jobs table<Job, number>
---@return number
local function get_probability_multiplier(province, tech, jobs)
	local pop = tabb.size(province.all_pops)
	local cost = tech.research_cost * pop
	-- We need to calculate the "fraction" of total endowment that this tech would end up using.
	-- Based on that we'll determine the chance for this tech to be researched per month.
	local frac = cost / province.realm.budget.education.budget
	local probability = math.min(1, math.max(0.01, 1 - frac))
	-- Scale the research probability by job (but only if one is needed!)
	if tech.associated_job then
		local ratio = jobs[tech.associated_job] or 1
		local multiplier = 0.05 + 0.95 * ratio
		probability = probability * multiplier
	end
	return probability * 0.5
end

---Handles tech research per province.
---@param province Province
function re.run(province)
	local perc = province.realm:get_education_efficiency()
	local jobs = province:get_job_ratios()

	if perc > 1 and province.realm.budget.education.budget > 0 then
		-- Only research if we have more than 100% invested research...
		local n = tabb.size(province.technologies_researchable)
		if n > 0 then
			local i = love.math.random(n)
			---@type Technology
			local tech = tabb.nth(province.technologies_researchable, i)
			local probability = 1.0 / (12 * 50) * get_probability_multiplier(province, tech, jobs)
			if love.math.random() < probability then
				province:research(tech)
			end
		end

		-- After "novel" tech research, try to perform tech spread (once a year on average)
		if love.math.random() < 1 / 12.0 then
			for _, neigh in pairs(province.neighbors) do
				for _, tech in pairs(neigh.technologies_present) do
					if province.technologies_present[tech] == nil then
						local chance = 1 / 2 * get_probability_multiplier(province, tech, jobs)
						if love.math.random() < chance then
							province:research(tech)
						end
					end
				end
			end
		end
	end
end

return re
