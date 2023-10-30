local path = require "game.ai.pathfinding"
local ui_utils = require "game.ui-utils"

local RewardFlag = require "game.entities.realm".RewardFlag

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

---comment
---@param leader Character
function MilitaryEffects.dissolve_warband(leader)
    local warband = leader.leading_warband
    leader.leading_warband = nil

    if warband == nil then
        return
    end

    ---@type POP[]
    local to_unregister = {}
    for _, pop in pairs(warband.pops) do
        table.insert(to_unregister, pop)
    end

    for _, pop in pairs(to_unregister) do
        leader.province:unregister_military_pop(pop)
    end
    leader.province.warbands[warband] = nil

    if WORLD:does_player_see_realm_news(leader.province.realm) then
        WORLD:emit_notification(leader.name .. " dissolved his warband.")
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
        "patrol-province", 
        root.leader,
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
        "covert-raid",
        primary_target.owner,
        raid_data,
        travel_time, false
    )
end


---comment
---@param root Character
---@param primary_target Province
function MilitaryEffects.covert_raid_no_reward(root, primary_target)
    local warband = root.leading_warband
    if warband == nil then return end

    local target = RewardFlag:new({
        flag_type = 'raid',
        owner = root,
        reward = 0,
        target = primary_target
    })

    local travel_time, _ = path.hours_to_travel_days(path.pathfind(root.province, primary_target))

    if WORLD:does_player_see_realm_news(root.realm) then
        WORLD:emit_notification(root.name .. " is leading his warriors move toward " ..
            primary_target.name ..
            ", they should arrive in " ..
            math.floor(travel_time + 0.5) .. " days. We can expect to hear back from them in " .. math.floor(travel_time * 2 + 0.5) .. " days.")
    end

    -- A raid will raise up to a certain number of troops
    -- local max_covert_raid_size = 10
    ---@type table<Warband, Warband>
    local warbands = {}
    warbands[warband] = warband
    local army = root.realm:raise_army(warbands)
    army.destination = primary_target

    for _, warband in pairs(army.warbands) do
        warband.status = "raiding"
    end

    ---@type RaidData
    local raid_data = {
        raider = root,
        target = target,
        travel_time = travel_time,
        army = army,
        origin = root.realm
    }


    WORLD:emit_action(
        "covert-raid",
        root,
        raid_data,
        travel_time, false
    )
end

---Sends army toward target and calls one argument callback with army and travel time toward province 
---@param army Army
---@param origin Province
---@param target Province
---@param callback fun(army: Army, travel_time: number)
function MilitaryEffects.send_army(army, origin, target, callback)
    local travel_time, _ = path.hours_to_travel_days(path.pathfind(origin, target))
    army.destination = target

    for _, warband in pairs(army.warbands) do
        warband.status = "attacking"
    end

    callback(army, travel_time)
end

---comment
---@param character Character
---@return Army?
function MilitaryEffects.gather_loyal_army(character)
    local province = character.province
    if province == nil then return nil end

    ---@type table<Warband, Warband>
    local idle_loyal_warbands = {}
    for _, warband in pairs(province.warbands) do
        if warband.status == "idle" and (warband.leader == character) or (warband.leader.loyalty == character) then
            idle_loyal_warbands[warband] = warband
        end
    end

    return province.realm:raise_army(idle_loyal_warbands)
end

return MilitaryEffects