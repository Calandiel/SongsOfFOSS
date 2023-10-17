local effects = {}

function effects.to_observer()
    WORLD.player_character = nil
    WORLD.player_realm = nil
    WORLD.player_province = nil
end


---take control over character
---@param character Character
function effects.take_control(character)
    WORLD.player_character = character
    WORLD.player_realm = character.realm
    WORLD.player_province = character.province
end

return effects