local cl = {}

---@class (exact) CultureGroup
---@field __index CultureGroup
---@field name string
---@field r number
---@field g number
---@field b number
---@field language Language
---@field view_on_treason number

---@class CultureGroup
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

	o.view_on_treason = love.math.random(-20, 0)

	setmetatable(o, cl.CultureGroup)
	return o
end

cl.Culture = {}
cl.Culture.__index = cl.Culture
---@param group CultureGroup
---@return culture_id
function cl.Culture:new(group)
	local id = DATA.create_culture()

	DATA.culture_set_r(id, group.r)
	DATA.culture_set_g(id, group.g)
	DATA.culture_set_b(id, group.b)

	DATA.culture_set_culture_group(id, group)
	DATA.culture_set_language(id, group.language)

	DATA.culture_set_name(id, group.language:get_random_culture_name())

	return id
end

return cl
