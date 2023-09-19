InterpersonalEffects = {}

---Sets the loyalty of an actor to a target
---@param actor Character
---@param target Character
function InterpersonalEffects.set_loyalty(actor, target)
    if target.loyalty == actor then
        target.loyalty = nil
    end
    if actor.loyalty ~= target then
        if WORLD:does_player_see_realm_news(actor.province.realm) and actor.loyalty ~= nil then
            WORLD:emit_notification(actor.name .. " stopped being loyal to " .. actor.loyalty.name .. ".")
        end
    end
    actor.loyalty = target
    if WORLD:does_player_see_realm_news(actor.province.realm) and target ~= nil then
        WORLD:emit_notification(actor.name .. " is now loyal to " .. target.name .. ".")
    end
end

return InterpersonalEffects