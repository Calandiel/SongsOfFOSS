---@class Need
---@field goods TradeGoodReference[]
---@field age_independent boolean?
---@field life_need boolean?

---@enum NEED
NEED = {
	WATER = 'water',
	FOOD = 'food',
	CLOTHING = 'clothing',
	TOOLS = 'tools',
	FURNITURE = 'furniture',
	HEALTHCARE = 'healthcare',
	STORAGE = 'storage'
}

NEEDS = {
	water = {
		goods = {"water", "liquors"},
		life_need = true
	},
	food = {
		goods = {"food", "meat", "liquors"},
		age_independent = true,
		life_need = true
	},
	clothing = {
		goods = {"hide", "leather", "clothes"}
	},
	tools = {
		goods = {"knapping-blanks", "tools"}
	},
	healthcare = {
		goods = {"healthcare"}
	},
	furniture = {
		goods = {"furniture", "timber"}
	},
	storage = {
		goods = {"containers"}
	}
}