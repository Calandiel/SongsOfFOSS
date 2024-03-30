local ranks = require "game.raws.ranks.character_ranks"

---@type table<CHARACTER_RANK, string>
local rank_names = {
    [ranks.NOBLE] = "Noble",
    [ranks.CHIEF] = "Chief",
}

local function rank_namef(character)
	return character.culture.language.ranks[character.rank] .. " (" .. rank_names[character.rank] .. ")"
end

return rank_namef