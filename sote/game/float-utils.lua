local fu = {}

local default_eps = 1e-6

---@param a number
---@param b number
---@param eps? number
---@return boolean
function fu.eq(a, b, eps)
	return math.abs(a - b) < (eps or default_eps)
end

---@param a number
---@param b number
---@param eps? number
---@return boolean
function fu.lt(a, b, eps)
	return a < b - eps
end

return fu