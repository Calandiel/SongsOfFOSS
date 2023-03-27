local tabb = require 'engine.table'
local emp = {}

---Employs pops in the province.
---@param province Province
function emp.run(province)

	-- Calculate needed job counters
	---@type table<Job, number>
	local jobs_needed_counters = {}
	local total_jobs_needed = 0
	for _, building in pairs(province.buildings) do
		for job, amount in pairs(building.type.production_method.jobs) do
			local old = jobs_needed_counters[job] or 0
			jobs_needed_counters[job] = old + amount
			total_jobs_needed = total_jobs_needed + amount
		end
	end

	-- Calculate present job counters
	---@type table<Job, number>
	local jobs_present_counters = {}
	local total_jobs_present = 0
	local unemployed = 0
	local working_population = 0
	for _, pop in pairs(province.all_pops) do
		if pop.age > pop.race.teen_age then
			if pop.job then
				local old = jobs_present_counters[pop.job] or 0
				jobs_present_counters[pop.job] = old + 1
				total_jobs_present = total_jobs_present + 1
			else
				-- Drafted pops ARE employed
				if not pop.drafted then
					unemployed = unemployed + 1
				end
			end
			working_population = working_population + 1
		end
	end

	---@type table<Job, number>
	local jobs_deltas = {}
	for job, amount in pairs(jobs_needed_counters) do
		local current = jobs_deltas[job] or 0
		jobs_deltas[job] = current + amount
	end
	for job, amount in pairs(jobs_present_counters) do
		local current = jobs_deltas[job] or 0
		if current == 0 then
			jobs_deltas[job] = 0 -- this is set to 0 because job deltas is there for detecting hires
			--	jobs_deltas[job] = -amount
			--else
			--	jobs_deltas[job] = current - amount
		end
	end
	---@type table<Job, number>
	local fair_shares = {} -- proportional employments per job type
	for job, _ in pairs(jobs_deltas) do
		local needed = jobs_needed_counters[job] or 0
		if total_jobs_needed == 0 then
			fair_shares[job] = 0
		else
			fair_shares[job] = working_population * (needed / total_jobs_needed)
		end
		--print(job.name, fair_shares[job])
	end

	-- Loop through all pops and fire the ones with jobs that have negative deltas
	for _, pop in pairs(province.all_pops) do
		if pop.job then
			local delta = jobs_deltas[pop.job] or 0
			local fair_share = math.ceil(fair_shares[pop.job] or 0)
			local current = jobs_present_counters[pop.job] or 0
			--print("Current: ", current, "/", fair_share, 'Job', pop.job.name, 'Delta', delta)
			if delta < 0 then
				jobs_deltas[pop.job] = delta + 1
				province:fire_pop(pop)
				current = current - 1
			elseif current > 0 then
				-- Tho, also fire if we're above our fair share!
				if fair_share < current then
					-- A chance to be fired -- we don't want to fire too many people after all...
					local chance = math.max(0, 1 - fair_share / current)
					if love.math.random() < chance then
						jobs_deltas[pop.job] = delta + 1
						province:fire_pop(pop)
						current = current - 1
					end
				end
			end
			if pop.job then
				jobs_present_counters[pop.job] = current
			end
		end
	end

	-- Lastly, hire new workers
	for _, pop in pairs(province.all_pops) do
		if not pop.drafted then
			if pop.job == nil then
				-- Find an employer
				for _, bld in pairs(province.buildings) do
					local potential_job = province:potential_job(bld)
					if potential_job then
						-- A worker is needed, check if we're not "over" our fair share and hire this pop
						-- Tho, also fire if we're above our fair share!
						local fair_share = math.ceil(fair_shares[potential_job] or 0)
						local current = jobs_present_counters[potential_job] or 0
						if fair_share > current then
							province:employ_pop(pop, bld)
							local old = jobs_deltas[pop.job] or 0
							if old > 0 then
								jobs_deltas[pop.job] = old - 1
							end
							jobs_present_counters[pop.job] = current + 1
							break -- break the loop over buildings, the pop will be employed by this point
						end
					end
				end
			end
		end
	end

end

return emp
