---@class (exact) Building
---@field __index Building
---@field type BuildingType
---@field x number?
---@field y number?
---@field workers table<pop_id, pop_id>
---@field worker_income table<pop_id, number>
---@field owner pop_id?
---@field province Province
---@field subsidy number
---@field subsidy_last number
---@field income_mean number
---@field last_income number
---@field spent_on_inputs table<trade_good_id, number>
---@field earn_from_outputs table<trade_good_id, number>
---@field amount_of_inputs table<trade_good_id, number>
---@field amount_of_outputs table<trade_good_id, number>
---@field last_donation_to_owner number
---@field unused number
---@field work_ratio number
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
	o.worker_income = {}

	o.income_mean = 0
	o.last_income = 0
	o.last_donation_to_owner = 0
	o.spent_on_inputs = {}
	o.earn_from_outputs = {}
	o.amount_of_inputs = {}
	o.amount_of_outputs = {}
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
