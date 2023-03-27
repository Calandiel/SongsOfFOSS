local ma = {}

---Returns true when x is NaN or -NaN
---@param x number
---@return boolean
function ma.is_nan(x)
	return x ~= x
end

return ma
