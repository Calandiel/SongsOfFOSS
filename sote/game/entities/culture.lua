local language_utils = require "game.entities.language".Language

local cl = {}



cl.CultureGroup = {}
cl.CultureGroup.__index = cl.CultureGroup

---@return culture_group_id
function cl.CultureGroup:new()
	local group = DATA.create_culture_group()
	local fat = DATA.fatten_culture_group(group)

	fat.r = love.math.random()
	fat.g = love.math.random()
	fat.b = love.math.random()
	fat.language = require "game.entities.language".random()
	fat.name = language_utils.get_random_culture_name(fat.language)
	fat.view_on_treason = love.math.random(-20, 0)

	return group
end


cl.Culture = {}
cl.Culture.__index = cl.Culture
---@param group culture_group_id
---@return culture_id
function cl.Culture:new(group)
	local id = DATA.create_culture()

	DATA.culture_set_r(id, DATA.culture_group_get_r(group))
	DATA.culture_set_g(id, DATA.culture_group_get_g(group))
	DATA.culture_set_b(id, DATA.culture_group_get_b(group))

	local language = DATA.culture_group_get_language(group)

	DATA.force_create_cultural_union(group, id)
	DATA.culture_set_language(id, language)

	DATA.culture_set_name(id, language_utils.get_random_culture_name(language))

	return id
end

return cl
