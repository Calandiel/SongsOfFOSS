local warband_utils = require "game.entities.warband"

local demo = {}

---Kills a single pop and removes it from all relevant references.
---@param pop pop_id
function demo.kill_pop(pop)
	-- print("kill " .. pop.name)
	demo.fire_pop(pop)
	warband_utils.unregister_military(pop)
	DATA.delete_pop(pop)
end

---Fires an employed pop and adds it to the unemployed pops list.
---It leaves the "job" set so that inference of social class can be performed.
---@param pop pop_id
function demo.fire_pop(pop)
	local employment = DATA.get_employment_from_worker(pop)
	if DATA.employment_get_building(employment) ~= INVALID_ID then
		DATA.delete_employment(employment)
		local building = DATA.employment_get_building(employment)
		if #DATA.get_employment_from_building(building) == 0 then
			local fat = DATA.fatten_building(building)
			fat.last_income = 0
			fat.last_donation_to_owner = 0
			fat.subsidy_last = 0
		end
	end
end

---@param province province_id
---@param pop pop_id
function demo.outlaw_pop(province, pop)
	-- ignore pops which are already outlawed
	if DATA.get_outlaw_location_from_outlaw(pop) then
		return
	end

	demo.fire_pop(pop)
	warband_utils.unregister_military(pop)
	DATA.force_create_outlaw_location(province, pop)

	local pop_location = DATA.get_pop_location_from_pop(pop)
	if pop_location then
		return
	end
	DATA.delete_pop_location(pop_location)
end

---Marks a pop as a soldier of a given type in a given warband.
---@param pop pop_id
---@param unit_type unit_type_id
---@param warband warband_id
function demo.recruit(pop, unit_type, warband)
	local membership = DATA.get_warband_unit_from_unit(pop)
	-- if pop is already drafted, do nothing
	if membership ~= INVALID_ID then
		return
	end

	-- clean pop and set his unit type
	demo.fire_pop(pop)
	warband_utils.unregister_military(pop)

	-- set warband
	warband_utils.hire_unit(warband, pop, unit_type)
end

---Kills ratio of army
---@param warband warband_id
---@param ratio number
function demo.kill_off_warband(warband, ratio)
	local losses = 0
	---@type POP[]
	local pops_to_kill = {}

	for _, membership in ipairs(DATA.get_warband_unit_from_warband(warband)) do
		local pop = DATA.warband_unit_get_unit(membership)
		if not IS_CHARACTER(pop) and love.math.random() < ratio then
			table.insert(pops_to_kill, pop)
			losses = losses + 1
		end
	end

	for i, pop in ipairs(pops_to_kill) do
		demo.kill_pop(pop)
	end

	return losses
end

---kills of a ratio of army and returns the losses
---@param army army_id
---@param ratio number
---@return number
function demo.kill_off_army(army, ratio)
	local losses = 0
	for _, army_membership in pairs(DATA.get_army_membership_from_army(army)) do
		local warband = DATA.army_membership_get_member(army_membership)
		losses = losses + demo.kill_off_warband(warband, ratio)
	end
	return losses
end

return demo