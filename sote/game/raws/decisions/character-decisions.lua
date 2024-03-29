local Decision = require "game.raws.decisions"
local utils = require "game.raws.raws-utils"
local TRAIT = require "game.raws.traits.generic"

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
			if root.busy then return false end
			if root.province.realm == nil then
				return false
			end
			if root.province.realm.leader == root then
				return false
			end
			if root.province.realm.capitol ~= root.province then
				return false
			end
			if root.province.realm ~= root.realm then
				return false
			end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			---@type Character
			local root = root
			local court_efficiency = root.province.realm:get_court_efficiency()
			if root.traits[TRAIT.AMBITIOUS] then
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
