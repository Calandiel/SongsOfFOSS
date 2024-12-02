local effects = {}

---comment
---@param character Character
function effects.death(character)
	-- print('character', NAME(character), 'died')

	if WORLD:does_player_see_realm_news(REALM(character)) then
		WORLD:emit_notification(DATA.pop_get_name(character) .. " had died.")
	end

	-- LOGS:write(
	-- 	"\n Setting death flag for: \n" ..
	-- 	"root: " .. NAME(character) .. "(".. tostring(character) .. ")" .. "\n"
	-- )

	-- print("???")
	-- print(character, DATA.pop_get_dead(character))
	DATA.pop_set_dead(character, true)
	-- print(character, DATA.pop_get_dead(character))
end


return effects