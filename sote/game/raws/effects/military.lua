local path = require "game.ai.pathfinding"
local ui_utils = require "game.ui-utils"

MilitaryEffects = {}

---Starts a raid from root to primary_target
---@param root Realm
---@param primary_target Province
function MilitaryEffects.covert_raid(root, primary_target)

    local travel_time, _ = path.hours_to_travel_days(path.pathfind(root.capitol, primary_target))

    if root == WORLD.player_realm then
        WORLD:emit_notification("Our warriors move toward " ..
            primary_target.name ..
            ", they should arrive in " ..
            math.floor(travel_time + 0.5) .. " days. We can expect to hear back from them in " .. math.floor(travel_time + 0.5) .. " days.")
    end

    -- A raid will raise up to a certain number of troops
    -- local max_covert_raid_size = 10
    local army = root:raise_army(root.raiders_preparing[primary_target])
    army.destination = primary_target

    for _, warband in pairs(army.warbands) do
        root:remove_raider(primary_target, warband)
        warband.status = "raiding"
    end

    WORLD:emit_action(
        WORLD.events_by_name["covert-raid"],
        primary_target.realm,
        { target = primary_target, raider = root, travel_time = travel_time, army = army },
        travel_time
    )



end

return MilitaryEffects