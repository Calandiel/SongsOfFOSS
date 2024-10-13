local effects = {}

function effects.to_observer()
	WORLD.player_character = INVALID_ID
end


---take control over character
---@param character Character
function effects.take_control(character)
	WORLD.player_character = character
end

return effects