local effects = {}

---comment
---@param overlord Realm
---@param tributary Realm
function effects.set_tributary(overlord, tributary)
    tributary.paying_tribute_to = overlord

    tributary.capitol.mood = tributary.capitol.mood - 0.5
    overlord.capitol.mood = overlord.capitol.mood + 0.5

    if WORLD:does_player_see_realm_news(overlord) then
        WORLD:emit_notification(tributary.name .. " now pays tribute to our tribe! Our people are rejoicing!")
    end

    if WORLD:does_player_see_realm_news(tributary) then
        WORLD:emit_notification("Our tribe now pays tribute to " .. overlord.name .. ". Outrageous!")
    end
end


return effects