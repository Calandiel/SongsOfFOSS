---Returns true if pop is a character
---@param pop_id pop_id
function IS_CHARACTER(pop_id)
	return DATA.pop_get_rank(pop_id) ~= CHARACTER_RANK.POP
end

--- update these values when you change description in according generator descriptors
MAX_TRAIT_INDEX = 19
MAX_NEED_SATISFACTION_POSITIONS_INDEX = 19

---@alias Character pop_id
---@alias POP pop_id