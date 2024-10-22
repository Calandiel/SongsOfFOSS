local effects = {}

---comment
---@param character Character
function effects.death(character)
	-- print('character', NAME(character), 'died')

	if WORLD:does_player_see_realm_news(REALM(character)) then
		WORLD:emit_notification(DATA.pop_get_name(character) .. " had died.")
	end

	DATA.pop_set_dead(character, true)
end


return effects