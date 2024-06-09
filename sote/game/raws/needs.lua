local JOBTYPE = require "game.raws.job_types"

---@class (exact) Need
---@field age_independent boolean?
---@field life_need boolean?
---@field time_to_satisfy number Represents amount of time a pop should spend to satisfy a unit of this need.
---@field job_to_satisfy JOBTYPE represents a job type required to satisfy the need on your own

---@enum NEED
NEED = {
	FOOD = 0,
	TOOLS = 1,
	CLOTHING = 2,
	FURNITURE = 3,
	HEALTHCARE = 4,
	LUXURY = 5,
}

NEED_NAME = {
	[NEED.FOOD] = 'food',
	[NEED.TOOLS] = 'tools',
	[NEED.CLOTHING] = 'clothing',
	[NEED.FURNITURE] = 'furniture',
	[NEED.HEALTHCARE] = 'healthcare',
	[NEED.LUXURY] = 'luxury',
}

---@type table<NEED, Need>
NEEDS = {
	[NEED.FOOD] = {
		-- age_independent = true,
		life_need = true,
		job_to_satisfy = JOBTYPE.FORAGER,
		time_to_satisfy = 1.5,
	},
	[NEED.TOOLS] = {
		job_to_satisfy = JOBTYPE.ARTISAN,
		time_to_satisfy = 1.0
	},
	[NEED.CLOTHING] = {
		job_to_satisfy = JOBTYPE.LABOURER,
		time_to_satisfy = 0.5
	},
	[NEED.FURNITURE] = {
		job_to_satisfy = JOBTYPE.LABOURER,
		time_to_satisfy = 2.0
	},
	[NEED.HEALTHCARE] = {
		job_to_satisfy = JOBTYPE.CLERK,
		time_to_satisfy = 1.0
	},
	[NEED.LUXURY] = {
		job_to_satisfy = JOBTYPE.ARTISAN,
		time_to_satisfy = 3.0
	},
}
