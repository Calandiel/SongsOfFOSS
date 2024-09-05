local pop_utils = require "game.entities.pop".POP
local warband_utils = require "game.entities.warband"

local army_utils = {}

---@param army army_id
---@return number
function army_utils.get_visibility(army)
	local vis = 0
	for _, army_membership in pairs(DATA.get_army_membership_from_army(army)) do
		local warband = DATA.army_membership_get_member(army_membership)

		vis = vis + warband_utils.visibility(warband)
	end
	return vis
end

---@param army army_id
---@return number
function army_utils.size(army)
	local result = 0
	for _, army_membership in pairs(DATA.get_army_membership_from_army(army)) do
		local warband = DATA.army_membership_get_member(army_membership)
		result = result + warband_utils.size(warband)
	end
	return result
end

---@param army army_id
---@return number
function army_utils.loot_capacity(army)
	local cap = 0
	for _, army_membership in pairs(DATA.get_army_membership_from_army(army)) do
		local warband = DATA.army_membership_get_member(army_membership)

		cap = cap + warband_utils.loot_capacity(warband)
	end
	return cap
end

---Kill everyone in the army
---@param army army_id
function army_utils.decimate(army)
	for _, army_membership in pairs(DATA.get_army_membership_from_army(army)) do
		local warband = DATA.army_membership_get_member(army_membership)
		warband_utils.decimate(warband)
	end
end

---Returns the pop membership in the army
---@param army army_id
---@return warband_unit_id[]
function army_utils.pops(army)
	local res = {}
	for _, army_membership in pairs(DATA.get_army_membership_from_army(army)) do
		for _, unit in pairs(DATA.get_warband_unit_from_warband(DATA.army_membership_get_member(army_membership))) do
			table.insert(res, unit)
		end
	end
	return res
end

---kills of a ratio of army and returns the losses
---@param army army_id
---@param ratio number
---@return number
function army_utils.kill_off(army, ratio)
	local losses = 0
	for _, army_membership in pairs(DATA.get_army_membership_from_army(army)) do
		local warband = DATA.army_membership_get_member(army_membership)
		losses = losses + warband_utils.kill_off(warband, ratio)
	end
	return losses
end

---Fights a location, returns whether or not the attack was a success.
---@param attacker army_id
---@param prov province_id
---@param spotted boolean Set it to true if the army was spotted before battle, false otherwise.
---@param defender army_id The opposing defending army_utils.
---@return boolean success, number attacker_losses, number defender_losses
function army_utils.attack(attacker, prov, spotted, defender)
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
	local losses = army_utils.kill_off(attacker, 1 - frac)
	local def_losses = army_utils.kill_off(defender, 1 - def_frac)
	return victory, losses, def_losses
end

return army_utils
