local path = require "game.ai.pathfinding"

local warband_utils = require "game.entities.warband"
local province_utils = require "game.entities.province".Province
local realm_utils = require "game.entities.realm".Realm

local economy_effects = require "game.raws.effects.economy"
local military_values = require "game.raws.values.military"
local demography_utils = require "game.raws.effects.demography"

local MilitaryEffects = {}

---Sets character as a recruiter of warband
---@param character Character
---@param warband Warband
function MilitaryEffects.set_recruiter(warband, character)
	local recruiter_warband = DATA.get_warband_recruiter_from_warband(warband)
	if recruiter_warband ~= INVALID_ID then
		DATA.warband_recruiter_set_recruiter(recruiter_warband, character)
	else
		DATA.force_create_warband_recruiter(character, warband)
	end
end

---unets character as a recruiter of warband
---@param character Character
---@param warband Warband
function MilitaryEffects.unset_recruiter(warband, character)
	local recruiter_warband = DATA.get_warband_recruiter_from_warband(warband)

	if recruiter_warband ~= INVALID_ID then
		DATA.delete_warband_recruiter(recruiter_warband)
	end
end

---Gathers new warband in the name of *leader*
---@param leader Character
function MilitaryEffects.gather_warband(leader)
	local province = PROVINCE(leader)
	local leadership = DATA.get_warband_leader_from_leader(leader)

	if leadership ~= INVALID_ID then
		return
	end

	local warband = province_utils.new_warband(province)
	DATA.warband_set_name(warband, "Warband of " .. NAME(leader))

	DATA.force_create_warband_leader(leader, warband)
	MilitaryEffects.set_recruiter(warband, leader)

	if WORLD:does_player_see_realm_news(PROVINCE_REALM(province)) then
		WORLD:emit_notification(NAME(leader) .. " is gathering his own warband.")
	end
end

---Gathers new warband to guard the realm
---@param realm Realm
function MilitaryEffects.gather_guard(realm)
	local province = CAPITOL(realm)
	local warband = province_utils.new_warband(province)
	DATA.warband_set_name(warband, "Guard of " .. DATA.realm_get_name(realm))

	DATA.force_create_realm_guard(warband, realm)

	if WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification("Guard was organised.")
	end
end

---Dissolve realm's guard
---@param realm Realm
function MilitaryEffects.dissolve_guard(realm)
	local guard = DATA.get_realm_guard_from_realm(realm)

	if guard == INVALID_ID then
		return
	end

	DATA.delete_warband(DATA.realm_guard_get_guard(guard))
	if WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification("Realm's guard was dissolved.")
	end
end

---comment
---@param leader Character
function MilitaryEffects.dissolve_warband(leader)
	local leadership = DATA.get_warband_leader_from_leader(leader)

	if leadership == INVALID_ID then
		return
	end

	local warband = DATA.warband_leader_get_warband(leadership)
	economy_effects.gift_to_warband(warband, leader, -DATA.warband_get_treasury(warband))
	DATA.delete_warband(warband)

	if WORLD:does_player_see_realm_news(PROVINCE_REALM(PROVINCE(leader))) then
		WORLD:emit_notification(NAME(leader) .. " dissolved his warband.")
	end
end

---Starts a patrol in primary_target province
---@param root Realm
---@param primary_target Province
function MilitaryEffects.patrol(root, primary_target)
	if WORLD:does_player_see_realm_news(root) then
		WORLD:emit_notification("Our warriors will patrol " ..
			DATA.province_get_name(primary_target) ..
			" for a few months.")
	end

	---@type table<Warband, Warband>
	local patrol = {}

	DATA.realm_get_patrols(root)

	for _, warband in pairs(DATA.realm_get_patrols(root)[primary_target]) do
		patrol[warband] = warband
	end

	for _, warband in pairs(patrol) do
		realm_utils.remove_patrol(root, primary_target, warband)
		DATA.warband_set_status(warband, WARBAND_STATUS.PATROL)
	end

	---@type PatrolData
	local patrol_data = { target = primary_target, defender = LEADER(root), travel_time = 29, patrol = patrol, origin = root }

	WORLD:emit_action(
		"patrol-province",
		LEADER(root),
		patrol_data,
		90, false
	)
end


---comment
---@param root Character
---@param primary_target Province
function MilitaryEffects.covert_raid(root, primary_target)
	local leadership = DATA.get_warband_leader_from_leader(root)
	assert(leadership ~= INVALID_ID)
	local warband = DATA.warband_leader_get_warband(leadership)

	---@type table<Warband, Warband>
	local warbands = {}
	warbands[warband] = warband

	local army = realm_utils.raise_army(REALM(root), warbands)
	DATA.army_set_destination(army, primary_target)

	local travel_time, _ = path.hours_to_travel_days(path.pathfind(
		PROVINCE(root),
		primary_target,
		military_values.army_speed(army),
		DATA.realm_get_known_provinces(REALM(root))
	))

	if WORLD:does_player_see_realm_news(REALM(root)) then
		WORLD:emit_notification(NAME(root) .. " is leading his warriors move toward " ..
			DATA.province_get_name(primary_target) ..
			", they should arrive in " ..
			math.floor(travel_time + 0.5) .. " days. We can expect to hear back from them in " .. math.floor(travel_time * 2 + 0.5) .. " days.")
	end

	DATA.warband_set_status(warband, WARBAND_STATUS.RAIDING)

	---@type RaidData
	local raid_data = {
		raider = root,
		target = primary_target,
		travel_time = travel_time,
		army = army,
		origin = REALM(root)
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
		DATA.realm_get_known_provinces(PROVINCE_REALM(origin))
	))

	DATA.army_set_destination(army, target)

	DATA.for_each_army_membership_from_army(army, function (item)
		local warband = DATA.army_membership_get_member(item)
		DATA.warband_set_status(warband, WARBAND_STATUS.ATTACKING)
	end)

	callback(army, travel_time)
end

---comment
---@param character Character
---@return Army?
function MilitaryEffects.gather_loyal_army_attack(character)

	local province = PROVINCE(character)
	assert(province ~= INVALID_ID)

	---@type table<Warband, Warband>
	local idle_loyal_warbands = {}

	DATA.for_each_warband_location_from_location(province, function (item)
		local warband = DATA.warband_location_get_warband(item)
		local leadership = DATA.get_warband_leader_from_warband(warband)
		local leader = DATA.warband_leader_get_leader(leadership)
		local loyal_to = LOYAL_TO(leader)

		if
			DATA.warband_get_status(warband) == WARBAND_STATUS.IDLE
			and (
				(leader == character)
				or
				(loyal_to == character)
			)
		then
			idle_loyal_warbands[warband] = warband
		end
	end)

	return realm_utils.raise_army(PROVINCE_REALM(province), idle_loyal_warbands)
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