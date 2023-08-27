local path = require "game.ai.pathfinding"
local ui_utils = require "game.ui-utils"

MilitaryEffects = {}

---Gathers new warband in the name of *leader*
---@param leader Character
function MilitaryEffects.gather_warband(leader)
    local province = leader.province
    if leader.leading_warband ~= nil then return end
    if province == nil then return end
    local warband = province:new_warband()
    warband.name = "Warband of " .. leader.name

    warband.leader = leader
    leader.leading_warband = warband

    if WORLD:does_player_see_realm_news(leader.province.realm) then
        WORLD:emit_notification(leader.name .. " is gathering his own warband.")
    end
end

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

    ---@type PatrolData
    local patrol_data = { target = primary_target, defender = root.leader, travel_time = 29, patrol = patrol, origin = root }

    WORLD:emit_action(
        WORLD.events_by_name["patrol-province"], root.leader,
        primary_target.realm.leader,
        patrol_data,
        90, false
    )
end

---Starts a raid from root to primary_target
---@param root Realm
---@param primary_target RewardFlag
function MilitaryEffects.covert_raid(root, primary_target)
    local target_province = primary_target.target

    local travel_time, _ = path.hours_to_travel_days(path.pathfind(root.capitol, target_province))

    if WORLD:does_player_see_realm_news(root) then
        WORLD:emit_notification("Our warriors move toward " ..
            target_province.name ..
            ", they should arrive in " ..
            math.floor(travel_time + 0.5) .. " days. We can expect to hear back from them in " .. math.floor(travel_time * 2 + 0.5) .. " days.")
    end

    -- A raid will raise up to a certain number of troops
    -- local max_covert_raid_size = 10
    local army = root:raise_army(root.raiders_preparing[primary_target])
    army.destination = target_province

    for _, warband in pairs(army.warbands) do
        root:remove_raider(primary_target, warband)
        warband.status = "raiding"
    end

    ---@type RaidData
    local raid_data = {
        raider = primary_target.owner,
        target = primary_target,
        travel_time = travel_time,
        army = army,
        origin = root
    }

    WORLD:emit_action(
        WORLD.events_by_name["covert-raid"], root.leader,
        target_province.realm.leader,
        raid_data,
        travel_time, false
    )
end

return MilitaryEffects