local effects = {}

---comment
---@param character Character
---@param province Province
function effects.travel(character, province)
	---@type Province
	local initial_province = character.province

	character.province:transfer_character(character, province)

	local party = character.leading_warband

	if party then
		for _, pop in pairs(party.pops) do
			initial_province:fire_pop(pop)
			initial_province:transfer_pop(pop, province)
		end

		initial_province.warbands[party] = nil
		province.warbands[party] = party
	end

	if WORLD.player_character == character then
		WORLD:emit_notification('I had arrived to ' .. province.name)
	end

	if WORLD:does_player_see_realm_news(province.realm) then
		WORLD:emit_notification(character.name .. " had arrived to " .. province.name)
	end
end

return effects