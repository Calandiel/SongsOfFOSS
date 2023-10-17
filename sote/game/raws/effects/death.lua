local effects = {}

---comment
---@param character Character
function effects.death(character)
    if WORLD:does_player_see_realm_news(character.realm) then
        WORLD:emit_notification(character.name .. " had died.")
    end

    character.dead = true
    character.province.characters[character] = nil
end


return effects