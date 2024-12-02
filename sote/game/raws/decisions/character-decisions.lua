local Decision = require "game.raws.decisions"
local utils = require "game.raws.raws-utils"

local realm_utils = require "game.entities.realm".Realm

local function load()
	Decision.Character:new {
		name = 'attempt-coup',
		ui_name = "Attempt coup",
		tooltip = utils.constant_string("Attempt to overthrow the local ruler."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 1 / 12,
		pretrigger = function(root)
			if BUSY(root) then return false end
			if LOCAL_REALM(root)== nil then
				return false
			end
			if LEADER(LOCAL_REALM(root)) == root then
				return false
			end
			if CAPITOL(LOCAL_REALM(root)) ~= PROVINCE(root) then
				return false
			end
			if LOCAL_REALM(root)~= REALM(root)then
				return false
			end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			---@type Character
			local root = root
			local court_efficiency = realm_utils.get_court_efficiency(LOCAL_REALM(root))
			if HAS_TRAIT(root, TRAIT.AMBITIOUS) then
				return 0.8 - court_efficiency / 2
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			--print("eff")
			---@type Character
			local root = root

			WORLD:emit_immediate_event('attempt-coup', root, {})
		end
	}
end

return load
