local effects = {}

---comment
---@param character Character
function effects.death(character)
    if WORLD:does_player_see_realm_news(character.realm) then
        WORLD:emit_notification(character.name .. " had died.")
    end

    for _, target in pairs(character.successor_of) do
        target.successor = nil
        character.successor_of[target] = nil
    end

    character.dead = true
    character.province.characters[character] = nil
end


return effects