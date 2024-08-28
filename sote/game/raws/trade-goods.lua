---@alias TradeGoodCategory "good" | "service" | "capacity"


local TradeGood = {}
---Creates a new trade good
---@param o trade_good_id_data_blob
---@return trade_good_id
function TradeGood:new(o)
	if RAWS_MANAGER.do_logging then
		print("Trade Good: " .. tostring(o.name))
	end

	local r = DATA.fatten_trade_good(DATA.create_trade_good())

	r.name = "<trade good>"
	r.icon = "uncertainty.png"
	r.description = "<trade good description>"
	r.r = 0
	r.g = 0
	r.b = 0
	r.category = "good"
	r.base_price = 10

	for k, v in pairs(o) do
		r[k] = v
	end

	if RAWS_MANAGER.trade_goods_by_name[r.name] ~= nil then
		local msg = "Failed to load a trade good (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end

	RAWS_MANAGER.trade_goods_by_name[r.name] = r.id

	return r.id
end

return TradeGood
