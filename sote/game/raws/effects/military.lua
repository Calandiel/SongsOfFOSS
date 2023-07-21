local path = require "game.ai.pathfinding"
local ui_utils = require "game.ui-utils"

MilitaryEffects = {}

---Starts a patrol in primary_target province
---@param root Realm
---@param primary_target Province
function MilitaryEffects.patrol(root, primary_target)
    if WORLD:does_player_see_realm_news(root) then
        WORLD:emit_notification("Our warriors will patrol " ..
            primary_target.name ..
            " for a few months.")
    end

    local patrol = {}

    for _, warband in pairs(root.patrols[primary_target]) do
        patrol[warband] = warband
    end

    for _, warband in pairs(patrol) do
         root:remove_patrol(primary_target, warband)
         warband.status = "patrol"
    end

    WORLD:emit_action(
        WORLD.events_by_name["patrol-province"], root,
        primary_target.realm,
        { target = primary_target, defender = root, travel_time = 29, patrol = patrol },
        90, false
    )
end

---Starts a raid from root to primary_target
---@param root Realm
---@param primary_target Province
function MilitaryEffects.covert_raid(root, primary_target)

    local travel_time, _ = path.hours_to_travel_days(path.pathfind(root.capitol, primary_target))

    if WORLD:does_player_see_realm_news(root) then
        WORLD:emit_notification("Our warriors move toward " ..
            primary_target.name ..
            ", they should arrive in " ..
            math.floor(travel_time + 0.5) .. " days. We can expect to hear back from them in " .. math.floor(travel_time * 2 + 0.5) .. " days.")
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
        WORLD.events_by_name["covert-raid"], root,
        primary_target.realm,
        { target = primary_target, raider = root, travel_time = travel_time, army = army },
        travel_time, false
    )
end

return MilitaryEffects