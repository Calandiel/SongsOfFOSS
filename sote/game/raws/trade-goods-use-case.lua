---@alias TradeGoodUseCaseReference string

---@class (exact) TradeGoodUseCase
---@field __index TradeGoodUseCase
---@field name TradeGoodUseCaseReference
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field new fun(self:TradeGoodUseCase, o:TradeGoodUseCase):TradeGoodUseCase
---@field goods table<TradeGoodReference, number> Maps trade goods belonging to this use case to their weights


---@class TradeGoodUseCase
local TradeGoodUseCase = {}
TradeGoodUseCase.__index = TradeGoodUseCase
---Creates a new trade good
---@param o TradeGoodUseCase
---@return TradeGoodUseCase
function TradeGoodUseCase:new(o)
	if RAWS_MANAGER.do_logging then
		print("Trade Good Use Case: " .. tostring(o.name))
	end

	---@type TradeGoodUseCase
	local r = {}

	r.name = "<trade good use case>"
	r.icon = "uncertainty.png"
	r.description = "<trade good use case description>"
	r.r = 0
	r.g = 0
	r.b = 0
	r.goods = {}

	for k, v in pairs(o) do
		r[k] = v
	end
	setmetatable(r, TradeGoodUseCase)
	if RAWS_MANAGER.trade_goods_use_cases_by_name[r.name] ~= nil then
		local msg = "Failed to load a trade good use case (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end
	RAWS_MANAGER.trade_goods_use_cases_by_name[r.name] = r
	return o
end

return TradeGoodUseCase
