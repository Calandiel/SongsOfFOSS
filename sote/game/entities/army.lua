local pop_utils = require "game.entities.pop".POP

---@class (exact) ArmyData
---@field destination Province|nil
---@field warbands table<Warband, Warband>

---@class (exact) Army
---@field __index Army
---@field destination Province|nil
---@field warbands table<Warband, Warband>

---@class Army
local army = {
	warbands = {}, ---@type Warband[]
	destination = nil, ---@type Province|nil
}
army.__index = army

---@return Army
function army:new()
	---@type ArmyData
	local o = {
		destination = nil,
		warbands = {}
	}

	setmetatable(o, army)
	return o
end

---@return number
function army:get_visibility()
	local vis = 0
	for pop, unit in pairs(self:units()) do
		vis = vis + pop_utils.pop_get_visibility(pop, unit)
	end
	return vis
end

---@return number
function army:get_loot_capacity()
	local cap = 0
	for _, warband in pairs(self.warbands) do
		cap = cap + warband:get_loot_capacity()
	end
	return cap
end

---Kill everyone in the army
function army:decimate()
	for _, warband in pairs(self.warbands) do
		warband:decimate()
	end
end

---Returns the units in the army
---@return table<pop_id, UnitType>
function army:units()
	---@type table<pop_id, UnitType>
	local res = {}
	for _, warband in pairs(self.warbands) do
		for pop, unit in pairs(warband.units) do
			res[pop] = unit
		end
	end

	return res
end

---Returns pops in the army
---@return table<pop_id, Province>
function army:pops()
	---@type table<pop_id, Province>
	local res = {}
	for _, warband in pairs(self.warbands) do
		for _, pop in pairs(warband.pops) do
			res[pop] = DATA.pop_get_home_province(pop)
		end
	end
	return res
end

---kills of a ratio of army and returns the losses
---@param ratio number
---@return number
function army:kill_off(ratio)
	local losses = 0
	for _, warband in pairs(self.warbands) do
		losses = losses + warband:kill_off(ratio)
	end
	return losses
end

---Fights a location, returns whether or not the attack was a success.
---@param prov Province
---@param spotted boolean Set it to true if the army was spotted before battle, false otherwise.
---@param defender Army The opposing defending army.
---@return boolean success, number attacker_losses, number defender_losses
function army:attack(prov, spotted, defender)
	local atk_armor = 0
	local atk_speed = 0
	local atk_attack = 0
	local atk_hp = 0
	local atk_stack = 0
	for _, warband in pairs(self.warbands) do
		local health, attack, armor, speed, count = warband:get_total_strength()
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
	for _, warband in pairs(defender.warbands) do
		local health, attack, armor, speed, count = warband:get_total_strength()
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
	local losses = self:kill_off(1 - frac)
	local def_losses = defender:kill_off(1 - def_frac)
	return victory, losses, def_losses
end

return army
