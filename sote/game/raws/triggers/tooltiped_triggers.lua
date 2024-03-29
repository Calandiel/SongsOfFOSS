local office_triggers = require "game.raws.triggers.offices"
local economy_triggers = require "game.raws.triggers.economy"

local ut = require "game.ui-utils"

local Trigger = {}

Trigger.Pretrigger = {}
Trigger.Targeted = {}

CHECKBOX_POSITIVE = " v "
CHECKBOX_NEGATIVE = " x "

---@class (exact) Trigger
---@field tooltip_on_condition_failure fun(root: Character, primary_target:any): string[]
---@field condition fun(root: Character, primary_target:any): boolean

---@class (exact) Pretrigger : Trigger
---@field tooltip_on_condition_failure fun(root: Character, primary_target:any): string[]
---@field condition fun(root: Character): boolean

---@class (exact) TriggerCharacter : Trigger
---@field tooltip_on_condition_failure fun(root: Character, primary_target:Character): string[]
---@field condition fun(root: Character, primary_target:Character): boolean

---@class (exact) TriggerProvince : Trigger
---@field tooltip_on_condition_failure fun(root: Character, primary_target:Province): string[]
---@field condition fun(root: Character, primary_target:Province): boolean

---@type Pretrigger
Trigger.Pretrigger.not_busy = {
	tooltip_on_condition_failure = function(root, primary_target)
		return { "You are too busy" }
	end,
	condition = function(root)
		return not root.busy
	end
}

---Prepares a trigger which is true if one of list_of_pretriggers is true
---@param list_of_pretriggers Pretrigger[]
---@return Pretrigger
function Trigger.Pretrigger.OR(list_of_pretriggers)
	return {
		tooltip_on_condition_failure = function(root, primary_target)
			local tooltip = { "You failed one of prerequisites:" }
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
		condition = function(root)
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
	tooltip_on_condition_failure = function(root, primary_target)
		return { "You do not lead any idle party." }
	end,
	condition = function(root)
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
	tooltip_on_condition_failure = function(root, primary_target)
		return { "You do not lead idle tribal guard." }
	end,
	condition = function(root)
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
	tooltip_on_condition_failure = function(root, primary_target)
		return { "You do not lead any idle party or guard" }
	end,
	condition = function(root)
		return office_triggers.valid_patrol_participant(root, root.province)
	end
}

---@type Pretrigger
Trigger.Pretrigger.leader = {
	tooltip_on_condition_failure = function(root, primary_target)
		return { "You are not a leader of the tribe" }
	end,
	condition = function(root)
		return office_triggers.is_ruler(root)
	end
}

---@type Pretrigger
Trigger.Pretrigger.leader_of_local_territory = {
	tooltip_on_condition_failure = function(root, primary_target)
		return { "You are not a leader of local tribe" }
	end,
	condition = function(root)
		local local_realm = root.province.realm

		if local_realm == nil then
			return false
		end

		return root.leader_of[local_realm] ~= nil
	end
}

---@type TriggerCharacter
Trigger.Targeted.is_overlord_of_target = {
	tooltip_on_condition_failure = function(root, primary_target)
		return { "They are not your subject" }
	end,
	condition = function(root, primary_target)
		return false
	end
}

---@type TriggerCharacter
Trigger.Targeted.is_not_in_negotiations = {
	tooltip_on_condition_failure = function(root, primary_target)
		return { "You are already in negotiations with this target" }
	end,
	condition = function(root, primary_target)
		return root.current_negotiations[primary_target] == nil
	end
}

---@type TriggerProvince
Trigger.Targeted.settled = {
	tooltip_on_condition_failure = function(root, primary_target)
		return { "This province is not settled" }
	end,
	condition = function(root, primary_target)
		return primary_target.realm ~= nil
	end
}

---@type TriggerProvince
Trigger.Targeted.has_local_trade_permit = {
	tooltip_on_condition_failure = function(root, primary_target)
		return { "You are allowed to trade in this province" }
	end,
	condition = function(root, primary_target)
		if primary_target.realm == nil then return false end
		return economy_triggers.allowed_to_trade(root, primary_target.realm)
	end
}

---@type TriggerProvince
Trigger.Targeted.has_no_local_trade_permit = {
	tooltip_on_condition_failure = function(root, primary_target)
		return { "You are not allowed to trade in this province" }
	end,
	condition = function(root, primary_target)
		if primary_target.realm == nil then return false end
		return not economy_triggers.allowed_to_trade(root, primary_target.realm)
	end
}

---commenting
---@param x number
---@return Pretrigger
function Trigger.Pretrigger.savings_at_least(x)
	---@type Pretrigger
	local result = {
		tooltip_on_condition_failure = function(root, primary_target)
			return { "You don't have " .. ut.to_fixed_point2(x) .. MONEY_SYMBOL }
		end,
		condition = function(root)
			return root.savings >= x
		end
	}
	return result
end

---@type TriggerProvince
Trigger.Targeted.has_no_local_building_permit = {
	tooltip_on_condition_failure = function(root, primary_target)
		return { "You are not allowed to trade in this province" }
	end,
	condition = function(root, primary_target)
		if primary_target.realm == nil then return false end
		return not economy_triggers.allowed_to_build(root, primary_target.realm)
	end
}

return Trigger
