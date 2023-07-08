local path = require "game.ai.pathfinding"

MilitaryEffects = {}

---Starts a raid from root to primary_target
---@param root Realm
---@param primary_target Province
function MilitaryEffects.covert_raid(root, primary_target)

    local travel_time, _ = path.hours_to_travel_days(path.pathfind(root.capitol, primary_target))

    if root == WORLD.player_realm then
        WORLD:emit_notification("We sent out our warriors to " ..
            primary_target.name ..
            ", they should arrive in " ..
            travel_time .. " days. We can expect to hear back from them in " .. (travel_time * 2) .. " days.")
    end

    -- A raid will raise up to a certain number of troops
    local max_covert_raid_size = 10
    local army = root:raise_army_of_size(max_covert_raid_size)
    army.destination = primary_target

    WORLD:emit_action(
        WORLD.events_by_name["covert-raid"],
        primary_target.realm,
        { target = primary_target, raider = root, travel_time = travel_time, army = army },
        travel_time
    )
end

return MilitaryEffects