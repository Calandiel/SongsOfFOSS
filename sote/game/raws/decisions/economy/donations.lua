local utils = require "game.raws.raws-utils"

local Decision = require "game.raws.decisions"
local TRAIT = require "game.raws.traits.generic"

local economic_effects = require "game.raws.effects.economic"
local political_effects = require "game.raws.effects.political"

local base_gift_size = 20

return function ()
	---@type DecisionCharacter
	Decision.Character:new {
		name = 'donate-wealth-local-wealth',
		ui_name = "Donate wealth to locals.",
		tooltip = utils.constant_string("I will donate (" .. tostring(base_gift_size) .. MONEY_SYMBOL .. ") to local wealth pool in exchange for popularity."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			if root.busy then return false end
			if root.savings < base_gift_size then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			return true
		end,
		available = function(root, primary_target)
			return true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			---@type Character
			local root = root
			if root.savings > base_gift_size * 20 then
				return 0.1
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			--print("eff")
			---@type Character
			local root = root
			local province = root.province
			if province == nil then return end

			province.mood = math.min(10, province.mood + base_gift_size / province:home_population() / 2)
			economic_effects.change_local_wealth(province, base_gift_size, economic_effects.reasons.Donation)
			economic_effects.add_pop_savings(root, -base_gift_size, economic_effects.reasons.Donation)
			political_effects.small_popularity_boost(root, province.realm)

			if WORLD:does_player_see_realm_news(province.realm) then
				WORLD:emit_notification(root.name .. " donates money to population of " .. province.name .. "! His popularity grows...")
			end
		end
	}

	---@type DecisionCharacter
	Decision.Character:new {
		name = 'donate-wealth-realm',
		ui_name = "Donate wealth to your realm.",
		tooltip = utils.constant_string("Donate wealth (" .. tostring(base_gift_size) .. ") to your realm treasury."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			if root.busy then return false end
			if root.savings < base_gift_size then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			return true
		end,
		available = function(root, primary_target)
			--print("avl")
			---@type Character
			local root = root

			local province = root.province
			if province == nil then return false end
			local realm = province.realm
			if realm == nil then return false end

			if root.savings < base_gift_size then
				return false
			end
			return true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			---@type Character
			local root = root

			--- rich characters want to donate money to the state more
			if root.savings > base_gift_size then
				return ((root.savings / base_gift_size) - 1) * 0.001
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			--print("eff")
			---@type Character
			local root = root
			local province = root.province
			if province == nil then return end
			local realm = province.realm
			if realm == nil then return end

			economic_effects.gift_to_tribe(root, realm, base_gift_size)
			political_effects.small_popularity_boost(root, province.realm)

			if WORLD:does_player_see_realm_news(realm) then
				WORLD:emit_notification(root.name .. " donates money to the tribe of " .. realm.name .. "!")
			end
		end
	}
end