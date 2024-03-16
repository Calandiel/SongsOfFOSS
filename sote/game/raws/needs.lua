local JOBTYPE = require "game.raws.job_types"

---@class Need
---@field age_independent boolean?
---@field life_need boolean?
---@field time_to_satisfy number Represents amount of time a pop should spend to satisfy a unit of this need.
---@field job_to_satisfy JOBTYPE represents a job type required to satisfy the need on your own

---@enum NEED
NEED = {
	WATER = 0,
	FOOD = 1,
	CLOTHING = 2,
	TOOLS = 3,
	FURNITURE = 4,
	HEALTHCARE = 5,
	STORAGE = 6,
	LUXURY = 7
}

NEED_NAME = {
	[NEED.WATER] = "water",
	[NEED.FOOD] = 'food',
	[NEED.CLOTHING] = 'clothing',
	[NEED.TOOLS] = 'tools',
	[NEED.FURNITURE] = 'furniture',
	[NEED.HEALTHCARE] = 'healthcare',
	[NEED.STORAGE] = 'storage',
	[NEED.LUXURY] = 'luxury'
}

---@type table<NEED, Need>
NEEDS = {
	[NEED.WATER] = {
		life_need = true,
		job_to_satisfy = JOBTYPE.FORAGER,
		time_to_satisfy = 0.05,
	},
	[NEED.FOOD] = {
		-- age_independent = true,
		life_need = true,
		job_to_satisfy = JOBTYPE.FORAGER,
		time_to_satisfy = 1.5,
	},
	[NEED.CLOTHING] = {
		job_to_satisfy = JOBTYPE.FORAGER,
		time_to_satisfy = 0.3
	},
	[NEED.TOOLS] = {
		goods = {
			"blanks-flint",
			"blanks-obsidian",
			"tools-flint",
			"tools-obsidian",
			"tools-native-copper",
			"tools-cast-copper",
			"copper-native",
			"copper-ore",
		},
		job_to_satisfy = JOBTYPE.ARTISAN,
		time_to_satisfy = 0.3
	},
	[NEED.FURNITURE] = {
		job_to_satisfy = JOBTYPE.ARTISAN,
		time_to_satisfy = 0.3
	},
	[NEED.HEALTHCARE] = {
		job_to_satisfy = JOBTYPE.CLERK,
		time_to_satisfy = 0.3
	},
	[NEED.STORAGE] = {
		job_to_satisfy = JOBTYPE.ARTISAN,
		time_to_satisfy = 0.3
	},
	[NEED.LUXURY] = {
		job_to_satisfy = JOBTYPE.ARTISAN,
		time_to_satisfy = 2.0
	}
}