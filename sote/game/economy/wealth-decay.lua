local dec = {}

---Runs production on a single province!
---@param province Province
function dec.run(province)
	province.local_wealth = province.local_wealth * 0.999
end

return dec
