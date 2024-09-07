local path = require "game.ai.pathfinding"
local warband_utils = require "game.entities.warband"

local economy_effects = require "game.raws.effects.economy"
local military_values = require "game.raws.values.military"
local demography_utils = require "game.raws.effects.demography"

local MilitaryEffects = {}

---Sets character as a recruiter of warband
---@param character Character
---@param warband Warband
function MilitaryEffects.set_recruiter(warband, character)
    character.recruiter_for_warband = warband
    warband.recruiter = character
end

---unets character as a recruiter of warband
---@param character Character
---@param warband Warband
function MilitaryEffects.unset_recruiter(warband, character)
    character.recruiter_for_warband = nil
    warband.recruiter = nil
end

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

    MilitaryEffects.set_recruiter(warband, leader)

    if WORLD:does_player_see_realm_news(leader.province.realm) then
        WORLD:emit_notification(leader.name .. " is gathering his own warband.")
    end
end

---Gathers new warband to guard the realm
---@param realm Realm
function MilitaryEffects.gather_guard(realm)
    local province = realm.capitol
    local warband = province:new_warband()
    warband.name = "Guard of " .. realm.name

    warband.guard_of = realm
    realm.capitol_guard = warband

    if WORLD:does_player_see_realm_news(realm) then
        WORLD:emit_notification("Guard was organised.")
    end
end

---Dissolve realm's guard
---@param realm Realm
function MilitaryEffects.dissolve_guard(realm)
    local warband = realm.capitol_guard
    local province = realm.capitol

    if warband == nil then
        return
    end

    realm.budget.treasury = realm.budget.treasury + warband.treasury
    warband.treasury = 0

    if warband.recruiter then
        MilitaryEffects.unset_recruiter(warband, warband.recruiter)
    end

    warband:unset_commander()

    ---@type POP[]
    local to_unregister = {}
    for _, pop in pairs(warband.pops) do
        table.insert(to_unregister, pop)
    end

    for _, pop in pairs(to_unregister) do
        pop:unregister_military()
    end
    province.warbands[warband] = nil

    if WORLD:does_player_see_realm_news(realm) then
        WORLD:emit_notification("Realm's guard was dissolved.")
    end
end

---comment
---@param leader Character
function MilitaryEffects.dissolve_warband(leader)
    local warband = leader.leading_warband

    if warband == nil then
        return
    end

    economy_effects.gift_to_warband(warband, leader, -warband.treasury)
    leader.leading_warband = nil

    warband.leader = nil
    warband:unset_commander()

    if warband.recruiter then
        MilitaryEffects.unset_recruiter(warband, warband.recruiter)
    end

    ---@type POP[]
    local to_unregister = {}
    for _, pop in pairs(warband.pops) do
        table.insert(to_unregister, pop)
    end

    for _, pop in pairs(to_unregister) do
        pop:unregister_military()
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

    ---@type table<Warband, Warband>
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


---comment
---@param root Character
---@param primary_target Province
function MilitaryEffects.covert_raid(root, primary_target)
    local warband = root.leading_warband
    if warband == nil then return end

    -- A raid will raise up to a certain number of troops
    -- local max_covert_raid_size = 10
    ---@type table<Warband, Warband>
    local warbands = {}
    warbands[warband] = warband
    local army = root.realm:raise_army(warbands)
    army.destination = primary_target

    local travel_time, _ = path.hours_to_travel_days(path.pathfind(
        root.province,
        primary_target,
        military_values.army_speed(army),
        root.realm.known_provinces
    ))

    if WORLD:does_player_see_realm_news(root.realm) then
        WORLD:emit_notification(root.name .. " is leading his warriors move toward " ..
            primary_target.name ..
            ", they should arrive in " ..
            math.floor(travel_time + 0.5) .. " days. We can expect to hear back from them in " .. math.floor(travel_time * 2 + 0.5) .. " days.")
    end

    for _, warband in pairs(army.warbands) do
        warband.status = "raiding"
    end

    ---@type RaidData
    local raid_data = {
        raider = root,
        target = primary_target,
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
    local travel_time, _ = path.hours_to_travel_days(path.pathfind(
        origin,
        target,
        military_values.army_speed(army),
        origin.realm.known_provinces
    ))
    army.destination = target

    for _, warband in pairs(army.warbands) do
        warband.status = "attacking"
    end

    callback(army, travel_time)
end

---comment
---@param character Character
---@return Army?
function MilitaryEffects.gather_loyal_army_attack(character)
    local province = character.province
    if province == nil then return nil end

    ---@type table<Warband, Warband>
    local idle_loyal_warbands = {}
    for _, warband in pairs(province.warbands) do
        local leader = warband.leader
        if
            warband.status == "idle"
            and (
                (warband.leader == character)
                or (leader and leader.loyalty == character)
            )
        then
            idle_loyal_warbands[warband] = warband
        end
    end

    return province.realm:raise_army(idle_loyal_warbands)
end

---Fights a location, returns whether or not the attack was a success.
---@param attacker army_id
---@param defender army_id The opposing defending army_utils.
---@param spotted boolean Set it to true if the army was spotted before battle, false otherwise.
---@return boolean success, number attacker_losses, number defender_losses
function MilitaryEffects.attack(attacker, defender, spotted)
	local atk_armor = 0
	local atk_speed = 0
	local atk_attack = 0
	local atk_hp = 0
	local atk_stack = 0
	for _, army_membership in pairs(DATA.get_army_membership_from_army(attacker)) do
		local warband = DATA.army_membership_get_member(army_membership)
		local health, attack, armor, speed, count = warband_utils.total_strength(warband)
		atk_armor = atk_armor + armor
		atk_attack = atk_attack + attack
		atk_speed = atk_speed + speed
		atk_hp = atk_hp + health
		atk_stack = atk_stack + count
	end
	if atk_stack == 0 then
		return false, 0, 0
	end
	atk_stack = math.max(1, atk_stack)

	atk_armor = atk_armor / atk_stack
	atk_speed = atk_speed / atk_stack
	atk_attack = atk_attack / atk_stack
	atk_hp = atk_hp / atk_stack

	local def_armor = 0
	local def_speed = 0
	local def_attack = 0
	local def_hp = 0
	local def_stack = 0
	for _, army_membership in pairs(DATA.get_army_membership_from_army(defender)) do
		local warband = DATA.army_membership_get_member(army_membership)
		local health, attack, armor, speed, count = warband_utils.total_strength(warband)
		def_armor = def_armor + armor
		def_attack = def_attack + attack
		def_speed = def_speed + speed
		def_hp = def_hp + health
		def_stack = def_stack + count
	end
	if def_stack == 0 then
		return true, 0, 0
	end
	def_stack = math.max(1, def_stack)

	def_armor = def_armor / def_stack
	def_speed = def_speed / def_stack
	def_attack = def_attack / def_stack
	def_hp = def_hp / def_stack

	local defender_advantage = 1.1
	if spotted then
		defender_advantage = defender_advantage + love.math.random() * 0.65
	end
	-- Expressed as fraction of the opposing army killed per "turn"
	local damage_attacker = math.max(1, atk_attack - def_armor) / math.max(1, def_hp * def_stack)
	local damage_defender = defender_advantage * math.max(1, def_attack - atk_armor) / math.max(1, atk_hp * atk_stack)

	-- The fraction of the army at which it will run away
	local stop_battle_threshold = 0.7
	-- 1 for square law, 0 for linear law
	local exponent = 0.1
	-- Forward Euler integration
	local power = 1
	local defpower = def_stack / atk_stack
	local victory = true
	-- print(power, defpower)
	while true do
		local dt = 0.5
		local p = power
		local dp = defpower
		power = power - damage_defender * dt * dp ^ exponent
		defpower = defpower - damage_attacker * dt * p ^ exponent

		-- print(power, defpower)

		if power < stop_battle_threshold then
			victory = false
			break
		end
		if defpower < stop_battle_threshold then
			break
		end
	end
	power = math.max(0, power)
	defpower = math.max(0, defpower)

	-- After the battle, kill people!
	--- fraction of people who survived
	local frac = power
	local def_frac = defpower / (def_stack / atk_stack)

	--- kill dead ones
	local losses = demography_utils.kill_off_army(attacker, 1 - frac)
	local def_losses = demography_utils.kill_off_army(defender, 1 - def_frac)
	return victory, losses, def_losses
end


return MilitaryEffects