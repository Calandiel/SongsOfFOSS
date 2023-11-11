---@class Building
---@field new fun(self:Building, province:Province, building_type:BuildingType, tile: Tile?):Building
---@field type BuildingType
---@field x number?
---@field y number?
---@field workers table<POP, POP>
---@field owner POP?
---@field province Province
---@field income_mean number
---@field last_income number
---@field spent_on_inputs table<TradeGoodReference, number>
---@field earn_from_outputs table<TradeGoodReference, number>
---@field work_ratio number a number in (0, 1) interval representing a ratio of time workers spend on a job compared to maximal
---@field last_donation_to_owner number
---@field remove_from_province fun(self:Building)
---@field unused number
---@field tile Tile?
------@field employ fun(self:Building, pop:POP, province:Province)

local bld = {}

---@class Building
bld.Building = {}
bld.Building.__index = bld.Building
---@param province Province province to build the building in
---@param building_type BuildingType
---@param tile Tile?
---@return Building
function bld.Building:new(province, building_type, tile)
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

	o.work_ratio = 1

	setmetatable(o, bld.Building)

	o.province = province
	province.buildings[o] = o -- add a new building!
	if tile and building_type.tile_improvement then
		-- Remove the previous building!
		if tile.tile_improvement then
			tile.tile_improvement:remove_from_province()
		end
		o.tile = tile
		tile.tile_improvement = o
	end

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

	if self.tile then
		self.tile.tile_improvement = nil
		self.tile = nil
	end
end

--[[
---Employs a POP and handles removal from the previous employer.
---@param pop POP
---@param province Province
function bld.Building:employ(pop, province)
	if pop.employer then
		pop.employer.workers[pop] = nil
		pop.job
	end
	pop.employer = self
	self.workers[pop] = pop
end
--]]

return bld
