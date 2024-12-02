local language_utils = require "game.entities.language".Language

local cl = {}

---@enum BURIAL_RITES
BURIAL_RIGHTS = {
	INVALID = 0,
	CREMATION = 1,
	BURIAL = 2,
	NONE = 3
}

---@alias BurialRites 'cremation' | 'burial' | 'none'


cl.Religion = {}
cl.Religion.__index = cl.Religion
---@param culture culture_id
---@return religion_id
function cl.Religion:new(culture)
	local religion = DATA.create_religion()

	DATA.religion_set_r(religion, love.math.random())
	DATA.religion_set_g(religion, love.math.random())
	DATA.religion_set_b(religion, love.math.random())

	DATA.religion_set_name(religion, language_utils.get_random_faith_name(DATA.culture_get_language(culture)))

	return religion
end

---@class Faith
cl.Faith = {}
cl.Faith.__index = cl.Faith

---@param religion religion_id
---@param culture culture_id
---@return faith_id
function cl.Faith:new(religion, culture)
	local faith = DATA.create_faith()

	DATA.faith_set_r(faith, DATA.religion_get_r(religion))
	DATA.faith_set_g(faith, DATA.religion_get_g(religion))
	DATA.faith_set_b(faith, DATA.religion_get_b(religion))

	DATA.force_create_subreligion(religion, faith)
	DATA.faith_set_name(faith, language_utils.get_random_faith_name(DATA.culture_get_language(culture)))
	DATA.faith_set_burial_rites(faith, BURIAL_RIGHTS.BURIAL)

	return faith
end

return cl
