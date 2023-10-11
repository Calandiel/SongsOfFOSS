local ranks = require "game.raws.ranks.character_ranks"

---@type table<CHARACTER_RANK, string>
local rank_names = {
    [ranks.NOBLE] = "Noble",
    [ranks.CHIEF] = "Chief",
}

return rank_names