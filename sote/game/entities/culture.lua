local cl = {}

---@class CultureGroup
---@field name string
---@field r number
---@field g number
---@field b number
---@field language Language
---@field new fun():CultureGroup

---@class Culture
---@field name string
---@field r number
---@field g number
---@field b number
---@field language Language
---@field culture_group CultureGroup
---@field new fun(self:Culture, group:CultureGroup):Culture
---@field traditional_units table<UnitType, number> -- Defines "traditional" ratios for units recruited from this culture.
---@field traditional_militarization number A fraction of the society that cultures will try to put in military

---@type CultureGroup
cl.CultureGroup = {}
cl.CultureGroup.__index = cl.CultureGroup
---@return CultureGroup
function cl.CultureGroup:new()
	---@type CultureGroup
	local o = {}

	o.r = love.math.random()
	o.g = love.math.random()
	o.b = love.math.random()
	o.language = require "game.entities.language".random()
	o.name = o.language:get_random_culture_name()

	setmetatable(o, cl.CultureGroup)
	return o
end

---@type Culture
cl.Culture = {}
cl.Culture.__index = cl.Culture
---@param group CultureGroup
---@return Culture
function cl.Culture:new(group)
	---@type Culture
	local o = {}

	o.r = group.r
	o.g = group.g
	o.b = group.b
	o.culture_group = group
	o.language = group.language
	o.name = o.language:get_random_culture_name()
	o.traditional_units = {}
	o.traditional_militarization = 0.1

	setmetatable(o, cl.Culture)
	return o
end

return cl
