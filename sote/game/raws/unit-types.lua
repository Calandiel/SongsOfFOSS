---@class UnitType
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field new fun(self:UnitType, o:UnitType):UnitType
---@field base_price number
---@field upkeep number
---@field supply_useds number how much food does this unit consume each month
---@field trade_good_requirements table<TradeGood, number>
---@field base_health number
---@field base_attack number
---@field base_armor number
---@field speed number
---@field foraging number how much food does this unit forage from the local province?
---@field bonuses table<UnitType, number>
---@field supply_capacity number how much food can this unit carry
---@field unlocked_by Technology|nil
---@field spotting number
---@field visibility number

---@class UnitType
local UnitType = {}
UnitType.__index = UnitType
---Creates a new unit type
---@param o UnitType
---@return UnitType
function UnitType:new(o)
	print("Unit Type: " .. tostring(o.name))
	---@type UnitType
	local r = {}

	r.name = "<unit type>"
	r.icon = 'uncertainty.png'
	r.description = "<unit type description>"
	r.r = 0
	r.g = 0
	r.b = 0
	r.base_price = 10
	r.upkeep = 0.5
	r.supply_useds = 1
	r.trade_good_requirements = {}
	r.base_health = 50
	r.base_attack = 5
	r.base_armor = 1
	r.speed = 1
	r.foraging = 0.1
	r.bonuses = {}
	r.supply_capacity = 5
	r.unlocked_by = nil
	r.spotting = 1
	r.visibility = 1


	for k, v in pairs(o) do
		r[k] = v
	end
	setmetatable(r, UnitType)
	if WORLD.unit_types_by_name[r.name] ~= nil then
		local msg = "Failed to load a unit type (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end
	WORLD.unit_types_by_name[r.name] = r
	return o
end

return UnitType
