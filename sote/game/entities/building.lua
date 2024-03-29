---@class (exact) Building
---@field __index Building
---@field type BuildingType
---@field x number?
---@field y number?
---@field workers table<POP, POP>
---@field owner POP?
---@field province Province
---@field subsidy number
---@field subsidy_last number
---@field income_mean number
---@field last_income number
---@field spent_on_inputs table<TradeGoodReference, number>
---@field earn_from_outputs table<TradeGoodReference, number>
---@field work_ratio number a number in (0, 1) interval representing a ratio of time workers spend on a job compared to maximal
---@field last_donation_to_owner number
---@field unused number
------@field employ fun(self:Building, pop:POP, province:Province)

local bld = {}

---@class Building
bld.Building = {}
bld.Building.__index = bld.Building
---@param province Province province to build the building in
---@param building_type BuildingType
---@return Building
function bld.Building:new(province, building_type)
	---@type Building
	local o = {}

	o.type = building_type
	o.workers = {}

	o.income_mean = 0
	o.last_income = 0
	o.last_donation_to_owner = 0
	o.spent_on_inputs = {}
	o.earn_from_outputs = {}
	o.unused = 0

	o.subsidy = 0
	o.subsidy_last = 0

	o.work_ratio = 1

	setmetatable(o, bld.Building)

	o.province = province
	province.buildings[o] = o -- add a new building!

	return o
end

---Removes a building from the province and other relevant data structures.
function bld.Building:remove_from_province()
	local province = self.province

	-- Fire current workers
	for _, pop in pairs(self.workers) do
		province:fire_pop(pop)
	end

	-- Remove yourself from provincial data structures
	province.buildings[self] = nil
end

return bld
