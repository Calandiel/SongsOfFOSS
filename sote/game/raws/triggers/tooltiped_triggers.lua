local office_triggers = require "game.raws.triggers.offices"

local Trigger = {}

Trigger.Pretrigger = {}

CHECKBOX_POSITIVE = " v "
CHECKBOX_NEGATIVE = " x "

---@class Trigger
---@field tooltip_on_condition_failure fun(root: Character, primary_target:any): string[]
---@field condition fun(root: Character, primary_target:any): boolean

---@class Pretrigger : Trigger
---@field tooltip_on_condition_failure fun(root: Character, primary_target:any): string[]
---@field condition fun(root: Character): boolean

---@class TriggerCharacter : Trigger
---@field tooltip_on_condition_failure fun(root: Character, primary_target:Character): string[]
---@field condition fun(root: Character, primary_target:Character): boolean

---@class TriggerProvince : Trigger
---@field tooltip_on_condition_failure fun(root: Character, primary_target:Province): string[]
---@field condition fun(root: Character, primary_target:Province): boolean

---@type Pretrigger
Trigger.Pretrigger.not_busy = {
	tooltip_on_condition_failure = function (root, primary_target)
		return {"You are too busy"}
	end,
	condition = function (root)
		return not root.busy
	end
}

---Prepares a trigger which is true if one of list_of_pretriggers is true
---@param list_of_pretriggers Pretrigger[]
---@return Pretrigger
function Trigger.Pretrigger.OR(list_of_pretriggers)
	return {
		tooltip_on_condition_failure = function (root, primary_target)
			local tooltip = {"You failed one of prerequisites:"}
			for _, trigger in ipairs(list_of_pretriggers) do
				if trigger.condition(root) then
					return {}
				else
					for _, current_tooltip in ipairs(trigger.tooltip_on_condition_failure(root, primary_target)) do
						table.insert(tooltip, " " .. CHECKBOX_NEGATIVE .. current_tooltip)
					end
				end
			end
			return tooltip
		end,
		condition = function (root)
			for _, trigger in ipairs(list_of_pretriggers) do
				if trigger.condition(root) then
					return true
				end
			end
		end
	}
end

---@type Pretrigger
Trigger.Pretrigger.leading_idle_warband = {
	tooltip_on_condition_failure = function (root, primary_target)
		return {"You do not lead any idle party."}
	end,
	condition = function (root)
		local warband = root.leading_warband
		if warband == nil then
			return false
		end
		if warband.status ~= "idle" then
			return false
		end
		return true
	end
}

---@type Pretrigger
Trigger.Pretrigger.leading_idle_guard = {
	tooltip_on_condition_failure = function (root, primary_target)
		return {"You do not lead idle tribal guard."}
	end,
	condition = function (root)
		local warband = root.recruiter_for_warband
		if warband == nil then
			return false
		end
		if warband.status ~= "idle" then
			return false
		end
		if root.realm.capitol_guard ~= warband then
			return false
		end
		return true
	end
}

---@type Pretrigger
Trigger.Pretrigger.leading_idle_warband_or_guard = {
    tooltip_on_condition_failure = function (root, primary_target)
        return {"You do not lead any idle party or guard"}
    end,
    condition = function (root)
        return office_triggers.valid_patrol_participant(root, root.province)
    end
}

return Trigger