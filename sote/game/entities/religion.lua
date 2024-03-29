local cl = {}

---@alias BurialRites 'cremation' | 'burial' | 'none'

---@class (exact) Religion
---@field __index Religion
---@field name string
---@field r number
---@field g number
---@field b number

---@class (exact) Faith
---@field __index Faith
---@field name string
---@field r number
---@field g number
---@field b number
---@field religion Religion
---@field burial_rites BurialRites

---@class Religion
cl.Religion = {}
cl.Religion.__index = cl.Religion
---@param culture Culture
---@return Religion
function cl.Religion:new(culture)
	local o = {}

	o.r = love.math.random()
	o.g = love.math.random()
	o.b = love.math.random()
	o.name = culture.language:get_random_faith_name()

	setmetatable(o, cl.Religion)
	return o
end

---@class Faith
cl.Faith = {}
cl.Faith.__index = cl.Faith
---@param religion Religion
---@param culture Culture
---@return Faith
function cl.Faith:new(religion, culture)
	---@type Faith
	local o = {}

	o.r = religion.r
	o.g = religion.g
	o.b = religion.b
	o.religion = religion
	o.name = culture.language:get_random_faith_name()
	o.burial_rites = 'burial'

	setmetatable(o, cl.Faith)
	return o
end

return cl
