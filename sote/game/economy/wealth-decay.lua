local dec = {}

---Runs production on a single province!
---@param province_id Province
function dec.run(province_id)
	local province = DATA.fatten_province(province_id)
	province.local_wealth = province.local_wealth * 0.999
	province.trade_wealth = province.trade_wealth * 0.999
end

return dec
