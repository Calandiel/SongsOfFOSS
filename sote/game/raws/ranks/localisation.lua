local function rank_namef(character)
	return character.culture.language.ranks[character.rank] .. " (" .. DATA.character_rank_get_localisation(character.rank) .. ")"
end

return rank_namef