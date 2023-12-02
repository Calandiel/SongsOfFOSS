local messages = require "game.raws.effects.messages"

InterpersonalEffects = {}

---Sets the loyalty of an actor to a target
---@param actor Character
---@param target Character
function InterpersonalEffects.set_loyalty(actor, target)
    if target.loyalty == actor then
        target.loyalty = nil
    end
    if actor.loyalty ~= target then
        InterpersonalEffects.remove_loyalty(actor)
    end
    actor.loyalty = target
    target.loyal[actor] = actor
    if WORLD:does_player_see_realm_news(actor.province.realm) and target ~= nil then
        WORLD:emit_notification(actor.name .. " is now loyal to " .. target.name .. ".")
    end
end

---@param actor Character
function InterpersonalEffects.remove_loyalty(actor)
    local target = actor.loyalty
    if target == nil then
        return
    end

    if WORLD:does_player_see_realm_news(actor.realm) and actor.loyalty ~= nil then
        WORLD:emit_notification(actor.name .. " stopped being loyal to " .. actor.loyalty.name .. ".")
    end
    actor.loyalty.loyal[actor] = nil
    actor.loyalty = nil
end

---unset loyalty to target of all actors loyal to them
---@param target Character
function InterpersonalEffects.remove_all_loyal(target)
    ---@type Character[]
    local to_remove = {}
    for _, actor in pairs(target.loyal) do
        table.insert(to_remove, actor)
    end

    for _, actor in pairs(to_remove) do
        InterpersonalEffects.remove_loyalty(actor)
    end
end


---comment
---@param character Character
---@param target Character
function InterpersonalEffects.set_successor(character, target)
    if character.successor then
        character.successor.successor_of[character] = nil
    end

    character.successor = target
    target.successor_of[character] = character
    messages.successor_set(character, target)
end

return InterpersonalEffects