local JOBTYPE = require "game.raws.job_types"

---@class Job
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field new fun(self:Job, o:Job):Job

---@class Job
local Job = {}
Job.__index = Job
---Creates a new job
---@param o Job
---@return Job
function Job:new(o)
	---@type Job
	local r = {}

	r.name = "<job>"
	r.icon = 'uncertainty.png'
	r.description = "<job description>"
	r.r = 0
	r.g = 0
	r.b = 0

	for k, v in pairs(o) do
		r[k] = v
	end
	setmetatable(r, Job)
	if RAWS_MANAGER.jobs_by_name[r.name] ~= nil then
		local msg = "Failed to load a job (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end
	RAWS_MANAGER.jobs_by_name[r.name] = r
	return r
end

return Job
