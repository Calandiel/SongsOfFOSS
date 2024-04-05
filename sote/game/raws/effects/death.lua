local effects = {}

---comment
---@param character Character
function effects.death(character)
    -- print('character', character.name, 'died')

    if WORLD:does_player_see_realm_news(character.realm) then
        WORLD:emit_notification(character.name .. " had died.")
    end

    if character.unit_of_warband then
        if character == character.unit_of_warband.commander then
            character.unit_of_warband:unset_commander()
        else
            character.unit_of_warband:unset_character_as_unit(character)
        end
    end

    if character.parent then character.parent.children[character] = nil end
    for _,c in pairs(character.children) do
        c.parent = nil
        character.children[c] = nil
    end

    for _, target in pairs(character.successor_of) do
        target.successor = nil
        character.successor_of[target] = nil
    end

    character.dead = true
end


return effects