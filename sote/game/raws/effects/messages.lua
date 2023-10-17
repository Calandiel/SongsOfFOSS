local messages = {}


local function generic_losses_function(att_losses, def_losses)
    return "We lost "
            .. tostring(def_losses)
            .. " warriors and our enemies lost "
            .. tostring(att_losses)
            .. ". "
end

---comment
---@param raider Character
---@param raid_target Realm
---@param success boolean
---@param att_losses number
---@param def_losses number
function messages.tribute_raid(raider, raid_target, success, att_losses, def_losses)
    if not WORLD:does_player_see_realm_news(raid_target) then
        return
    end

    local introduction =
        "Our neighbor, "
        .. raider.name
        .. ", sent warriors to extort tribute from us. "
    local losses_string = generic_losses_function(att_losses, def_losses)

    if success then
        WORLD:emit_notification(
            introduction
            .. losses_string
            .. "We lost and have to pay the tribute.")
    else
        WORLD:emit_notification(
            introduction
            .. losses_string
            .. "We managed to fight off the aggresors.")
    end
end

---comment
---@param realm Realm
---@param tributary Realm
function messages.tribute_raid_success(realm, tributary)
    if not WORLD:does_player_see_realm_news(realm) then
        return
    end

    WORLD:emit_notification("We succeeded! " .. tributary.name .. " now pays tribute to us.")
end

---comment
---@param realm Realm
---@param tributary Realm
function messages.tribute_raid_fail(realm, tributary)
    if not WORLD:does_player_see_realm_news(realm) then
        return
    end

    WORLD:emit_notification("We failed! " .. tributary.name .. " will not pay tribute to us.")
end

function messages.successor_set(character, successor)
    if not WORLD:does_player_see_realm_news(successor) then
        return
    end

    WORLD:emit_notification(
        successor.name .. " was chosen as the successor of " .. character.name .. "."
    )
end

return messages