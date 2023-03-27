---@class Army
local army = {
	pops = {}, ---@type table<POP, Province> A table mapping pops to their home provinces.
	units = {}, ---@type table<POP, UnitType> A table mapping pops to their unit types (as we don't store them on pops)
	destination = nil, ---@type Province|nil
}
army.__index = army

---@return Army
function army:new()
	local o = {}
	for k, v in pairs(self) do
		if type(v) == "table" then
			o[k] = {}
		elseif type(v) == "function" then
			-- nothing to do, we're setting a metatable
		else
			o[k] = v
		end
	end
	setmetatable(o, army)
	return o
end

---@return number
function army:get_visibility()
	local vis = 0
	for pop, unit in pairs(self.units) do
		vis = vis + pop.race.visibility * unit.visibility
	end
	return vis
end

---@return number
function army:get_loot_capacity()
	local cap = 0.01
	for pop, unit in pairs(self.units) do
		local c = pop.race.male_body_size
		if pop.female then
			c = pop.race.female_body_size
		end
		cap = cap + c
	end
	return cap
end

---Kill everyone in the army
function army:decimate()
	self.units = {}
	self.pops = {}
end

---Fights a location, returns whether or not the attack was a success.
---@param prov Province
---@param spotted boolean Set it to true if the army was spotted before battle, false otherwise.
---@param defender Army The opposing defending army.
---@return boolean success, number attacker_losses, number defender_losses
function army:attack(prov, spotted, defender)
	local armor = 0
	local speed = 0
	local attack = 0
	local hp = 0
	local stack = 0
	for pop, unit in pairs(self.units) do
		local size = pop.race.male_body_size
		if pop.female then
			size = pop.race.female_body_size
		end
		armor = armor + unit.base_armor
		attack = attack + unit.base_attack
		speed = speed + unit.speed
		hp = hp + unit.base_health * size
		stack = stack + 1
	end
	stack = math.max(1, stack)

	armor = armor / stack
	speed = speed / stack
	attack = attack / stack
	hp = hp / stack

	local def_armor = 0
	local def_speed = 0
	local def_attack = 0
	local def_hp = 0
	local def_stack = 0
	for pop, unit in pairs(defender.units) do
		local size = pop.race.male_body_size
		if pop.female then
			size = pop.race.female_body_size
		end
		def_armor = def_armor + unit.base_armor
		def_attack = def_attack + unit.base_attack
		def_speed = def_speed + unit.speed
		def_hp = def_hp + unit.base_health * size
		def_stack = def_stack + 1
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
	local damage_attacker = math.max(1, attack - def_armor) / math.max(1, def_hp * def_stack)
	local damage_defender = defender_advantage * math.max(1, def_attack - armor) / math.max(1, hp * stack)

	-- The fraction of the army at which it will run away
	local stop_battle_threshold = 0.7
	-- 1 for square law, 0 for linear law
	local exponent = 0.1
	-- Forward Euler integration
	local power = 1
	local defpower = def_stack / stack
	local victory = true
	while true do
		local dt = 0.5
		local p = power
		local dp = defpower
		power = power - damage_defender * dt * dp ^ exponent
		defpower = defpower - damage_attacker * dt * p ^ exponent

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
	local frac = power
	local def_frac = defpower / (def_stack / stack)
	local losses = 0
	local def_losses = 0
	for u in pairs(self.units) do
		if love.math.random() < frac then
			self.units[u] = nil
			self.pops[u] = nil
			losses = losses + 1
		end
	end
	for u in pairs(defender) do
		if love.math.random() < def_frac then
			self.units[u] = nil
			self.pops[u] = nil
			def_losses = def_losses + 1
		end
	end

	return victory, losses, def_losses
end

return army
