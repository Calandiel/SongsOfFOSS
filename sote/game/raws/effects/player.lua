local effects = {}

function effects.to_observer()
	if WORLD.player_character ~= INVALID_ID then
		DATA.pop_set_is_player(WORLD.player_character, false)
	end
	WORLD.player_character = INVALID_ID
end


---take control over character
---@param character Character
function effects.take_control(character)
	WORLD.player_character = character
	DATA.pop_set_forage_ratio(WORLD.player_character, OPTIONS["needs-hunt"])
	DATA.pop_set_work_ratio(WORLD.player_character, 1 - OPTIONS["needs-hunt"])
	DATA.pop_set_spend_savings_ratio(WORLD.player_character, OPTIONS["needs-savings"])
	DATA.pop_set_is_player(WORLD.player_character, true)
end

return effects