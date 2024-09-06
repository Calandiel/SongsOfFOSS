---commenting
---@param character Character
---@return string
local function rank_namef(character)
	local rank = DATA.pop_get_rank(character)
	local culture = DATA.pop_get_culture(character)
	local culture_title = culture.language.ranks[rank]

	return culture_title .. " (" .. DATA.character_rank_get_localisation(rank) .. ")"
end

return rank_namef