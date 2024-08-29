local TradeGood = {}
---Creates a new trade good
---@param o trade_good_id_data_blob_definition
---@return trade_good_id
function TradeGood:new(o)
	if RAWS_MANAGER.do_logging then
		print("Trade Good: " .. tostring(o.name))
	end

	local r = DATA.create_trade_good()
	DATA.setup_trade_good(r, o)

	if RAWS_MANAGER.trade_goods_by_name[o.name] ~= nil then
		local msg = "Failed to load a trade good (" .. tostring(o.name) .. ")"
		print(msg)
		error(msg)
	end

	RAWS_MANAGER.trade_goods_by_name[o.name] = r

	return r
end

return TradeGood
