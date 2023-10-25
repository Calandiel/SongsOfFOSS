local effects = {}

---comment
---@param character Character
---@param province Province
function effects.travel(character, province)
    character.province.characters[character] = nil

    character.province = province
    character.province.characters[character] = character

    character.busy = false

    if WORLD.player_character == character then
        WORLD:emit_notification('I had arrived to ' .. province.name)
    end

    if WORLD:does_player_see_realm_news(province.realm) then
        WORLD:emit_notification(character.name .. " had arrived to " .. province.name)
    end
end

return effects