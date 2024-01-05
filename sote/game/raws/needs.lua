local JOBTYPE = require "game.raws.job_types"

---@class Need
---@field goods TradeGoodReference[]
---@field age_independent boolean?
---@field life_need boolean?
---@field time_to_satisfy number Represents amount of time a pop should spend to satisfy a unit of this need.
---@field job_to_satisfy JOBTYPE represents a job type required to satisfy the need on your own

---@enum NEED
NEED = {
	WATER = 'water',
	FOOD = 'food',
	CLOTHING = 'clothing',
	TOOLS = 'tools',
	FURNITURE = 'furniture',
	HEALTHCARE = 'healthcare',
	STORAGE = 'storage',
	LUXURY = 'luxury'
}


---@type table<NEED, Need>
NEEDS = {
	water = {
		goods = {"water", "liquors"},
		life_need = true,
		job_to_satisfy = JOBTYPE.FORAGER,
		time_to_satisfy = 0.05,
	},
	food = {
		goods = {"food", "meat", "liquors"},
		-- age_independent = true,
		life_need = true,
		job_to_satisfy = JOBTYPE.FORAGER,
		time_to_satisfy = 1.5,
	},
	clothing = {
		goods = {"hide", "leather", "clothes"},
		job_to_satisfy = JOBTYPE.FORAGER,
		time_to_satisfy = 0.3
	},
	tools = {
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
	healthcare = {
		goods = {"healthcare"},
		job_to_satisfy = JOBTYPE.CLERK,
		time_to_satisfy = 0.3
	},
	furniture = {
		goods = {"furniture", "timber", "stone"},
		job_to_satisfy = JOBTYPE.ARTISAN,
		time_to_satisfy = 0.3
	},
	storage = {
		goods = {"containers", "clay", "timber"},
		job_to_satisfy = JOBTYPE.ARTISAN,
		time_to_satisfy = 0.3
	},

	luxury = {
		goods = {"copper-bars"},
		job_to_satisfy = JOBTYPE.ARTISAN,
		time_to_satisfy = 2.0
	}
}