local tabb = require "engine.table"
local Decision = require "game.raws.decisions"
local gift_cost_per_pop = require "game.gifting".gift_cost_per_pop
local utils = require "game.raws.raws-utils"
local economic_effects = require "game.raws.effects.economic"
local economic_values = require "game.raws.values.economical"
local MilitaryEffects = require "game.raws.effects.military"
local TRAIT = require "game.raws.traits.generic"
local ranks = require "game.raws.ranks.character_ranks"

local path = require "game.ai.pathfinding"

local pe = require "game.raws.effects.political"

local office_triggers = require "game.raws.triggers.offices"

local military_values = require "game.raws.values.military"


local function load()

	local base_gift_size = 20
	local base_raiding_reward = 50

	---@type DecisionCharacter
	Decision.Character:new {
		name = 'debug-wealth-character',
		ui_name = "DEBUG: wealth cheat",
		tooltip = utils.constant_string("Get wealth."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			if not OPTIONS.debug_mode then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if not OPTIONS.debug_mode then
				return false
			end
			return true
		end,
		available = function(root, primary_target)
			return true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			---@type Character
			local root = root
			local province = root.province
			if province == nil then return end

			root.savings = root.savings + 1000
			if WORLD:does_player_see_realm_news(province.realm) then
				WORLD:emit_notification(root.name .. " IS CHEATER!!! But nobody cares.")
			end
		end
	}

		---@type DecisionCharacter
	Decision.Character:new {
		name = 'debug-kill-character',
		ui_name = "DEBUG: kill",
		tooltip = utils.constant_string("Kill."),
		sorting = 1,
		primary_target = "character",
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			if not OPTIONS.debug_mode then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if not OPTIONS.debug_mode then
				return false
			end
			return true
		end,
		available = function(root, primary_target)
			return true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			WORLD:emit_immediate_event('death', primary_target, nil)
			WORLD:emit_notification(root.name .. " kills " .. primary_target.name)
		end
	}

	---@type DecisionCharacter
	Decision.Character:new {
		name = 'gather-warband',
		ui_name = "Gather my own warband",
		tooltip = utils.constant_string("I have decided to gather my own warband."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 1 / 12 , -- Once every year on average
		pretrigger = function(root)
			if root.busy then return false end
			if root.province.realm ~= root.realm then return false end
			if root.leading_warband then return false end
			if root.recruiter_for_warband then return false end
			if WORLD.player_character ~= root then
				if not root.traits[TRAIT.WARLIKE] and not root.traits[TRAIT.TRADER] and not (root.rank == ranks.CHIEF) then
					return false
				end
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
			root = root
			if root.leading_warband == nil and root.traits[TRAIT.WARLIKE] then
				return 1
			end

			if root.leading_warband == nil and root.traits[TRAIT.TRADER] then
				return 1
			end

			if root.leading_warband == nil and root.rank == ranks.CHIEF then
				return 1
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			MilitaryEffects.gather_warband(root)
		end
	}

	---@type DecisionCharacter
	Decision.Character:new {
		name = 'disband-warband',
		ui_name = "Disband my warband",
		tooltip = utils.constant_string("I have decided to disband my warband."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 0 , -- AI never disbands
		pretrigger = function(root)
			if root.busy then return false end
			if root.leading_warband then return true end
			return false
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
			return 0 -- AI never disbands
		end,
		effect = function(root, primary_target, secondary_target)
			MilitaryEffects.dissolve_warband(root)
		end
	}

	---@type DecisionCharacter
	Decision.Character:new {
		name = 'raid-warband',
		ui_name = "Raid",
		tooltip = utils.constant_string("I will raid the province."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 0.9 , -- Almost every month
		pretrigger = function(root)
			if root.busy then return false end
			if root.leading_warband == nil then return false end
			if root.leading_warband.status ~= 'idle' then return false end
			return false
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
			root = root
			if root.realm.prepare_attack_flag == true and (root.loyalty == root.realm.leader or root.realm.leader == root) then
				return 0
			end
			if root.traits[TRAIT.AMBITIOUS] or root.traits[TRAIT.WARLIKE] then
				return 0.9
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			local realm = root.province.realm
			if realm == nil then return end

			local target = realm:roll_reward_flag()
			realm:add_raider(target, root.leading_warband)
		end
	}

	---@type DecisionCharacter
	Decision.Character:new {
		name = 'patrol-warband',
		ui_name = "Patrol",
		tooltip = utils.constant_string("I will protect the home province against raiders."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 0.9 , -- Almost every month
		pretrigger = function(root)
			return office_triggers.valid_patrol_participant(root, root.province)
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if office_triggers.guard_leader(root, root.province.realm) then
				return 1
			end

			if root.realm.prepare_attack_flag == true and (root.loyalty == root.realm.leader or root.realm.leader == root) then
				return 0
			end

			if root.traits[TRAIT.AMBITIOUS] or root.traits[TRAIT.WARLIKE] then
				return 0.2
			end

			return 0.6
		end,
		effect = function(root, primary_target, secondary_target)
			local realm = root.province.realm
			local province = root.province
			local warband = root.leading_warband
			if realm ~= nil then
				if office_triggers.guard_leader(root, root.province.realm) then
					warband = realm.capitol_guard
				end
				if warband then
					realm:add_patrol(province, warband)
				else error("Character is not leading a warband!") end
			else error("Character has no realm!") end
		end
	}

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

			province.mood = math.min(10, province.mood + base_gift_size / province:population() / 2)
			economic_effects.change_local_wealth(province, base_gift_size, EconomicEffects.reasons.Donation)
			economic_effects.add_pop_savings(root, -base_gift_size, EconomicEffects.reasons.Donation)

			pe.small_popularity_boost(root, province.realm)

			if WORLD:does_player_see_realm_news(province.realm) then
				WORLD:emit_notification(root.name .. " donates money to population of " .. province.name .. "! His popularity grows...")
			end
		end
	}

	---@type DecisionCharacter
	Decision.Character:new {
		name = 'donate-wealth-warband',
		ui_name = "Donate wealth to your warband.",
		tooltip = utils.constant_string("Donate wealth (" .. tostring(base_gift_size) .. ") to your warband treasury."),
		sorting = 1,
		primary_target = "none",
		secondary_target = 'none',
		base_probability = 1 / 3 , -- Once every 3 months on average
		pretrigger = function(root)
			if root.busy then return false end
			if root.savings < base_gift_size then
				return false
			end
			if root.leading_warband == nil then return false end
			return true
		end,
		clickable = function(root, primary_target)
			if root.leading_warband == nil then return false end
			if WORLD:is_player(root) then return false end
			return true
		end,
		available = function(root, primary_target)
			if root.savings < 5 then
				return false
			end
			return true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if root.leading_warband.treasury < root.savings / 2 then
				return 1
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			economic_effects.gift_to_warband(root, root.savings / 3)
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

			if WORLD:does_player_see_realm_news(realm) then
				WORLD:emit_notification(root.name .. " donates money to the tribe of " .. realm.name .. "!")
			end
		end
	}

	-- War related events
	---@type DecisionCharacter
	Decision.Character:new {
		name = 'covert-raid',
		ui_name = "Covert raid",
		tooltip = utils.constant_string("Declare province as target for future raids. Can avoid diplomatic issues. Loots only from the local provincial wealth pool."),
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 1 / 25,
		pretrigger = function(root)
			if root.busy then return false end
			if WORLD:is_player(root) then
				return false
			end
			if root.savings < base_raiding_reward or root.province.realm:get_realm_ready_military() == 0 then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			--print("cli")
			---@type Character
			local root = root
			---@type Province
			local primary_target = primary_target
			if primary_target.realm == root then
				return false
			end
			if WORLD:is_player(root) then
				return false
			end

			return primary_target:neighbors_realm(root.province.realm)
		end,
		available = function(root, primary_target)
			--print("avl")
			---@type Character
			local root = root
			---@type Province
			local primary_target = primary_target
			if primary_target.realm.paying_tribute_to[root.realm] then
				return false
			end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			--print("aiw")
			return 0.1
		end,
		ai_targetting_attempts = 2,
		ai_target = function(root)
			--print("ait")
			---@type Character
			local root = root
			---@type Province
			local p = root.province
			if p then
				-- Once you target a province, try selecting a random neighbor
				local s = tabb.size(p.neighbors)
				---@type Province
				local ne = tabb.nth(p.neighbors, love.math.random(s))
				if ne then
					if ne.realm and ne.realm ~= p.realm then
						return ne, true
					end
				end
			end
			return nil, false
		end,
		ai_secondary_target = function(root, primary_target)
			--print("ais")
			return nil, true
		end,
		effect = function(root, primary_target, secondary_target)
			---@type Character
			local root = root
			---@type Province
			local primary_target = primary_target

			local reward_flag = require "game.entities.realm".RewardFlag:new {
				owner = root,
				reward = base_raiding_reward,
				target = primary_target,
				flag_type = 'raid'
			}
			economic_effects.add_pop_savings(root, -base_raiding_reward, "reward flag")

			root.province.realm:add_reward_flag(reward_flag)
		end
	}

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

			WORLD:emit_immediate_event('attempt-coup', root)
		end
	}


	Decision.Character:new {
		name = 'buy-something',
		ui_name = "(AI) Buy some goods",
		tooltip = function (root, primary_target)
			if root.busy then
				return "You are too busy to consider it."
			end
			return "Buy some goods on the local market"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 1 / 4 ,
		pretrigger = function(root)
			if root.busy then return false end
			if WORLD:is_player(root) then
				return false
			end
			if root.savings < 5 then
				return false
			end
			if (not root.traits[TRAIT.TRADER]) then
				return false
			end
			return true
		end,
		clickable = function(root)
			if WORLD:is_player(root) then
				return false
			end
			return true
		end,
		available = function(root)
			if root.busy then return false end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if root.traits[TRAIT.TRADER] then
				return 1
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			WORLD:emit_immediate_event('buy-goods', root, nil)
		end
	}

	Decision.Character:new {
		name = 'update-price-beliefs',
		ui_name = "(AI) Check local prices",
		tooltip = function (root, primary_target)
			if root.busy then
				return "You are too busy to consider it."
			end
			return "???"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 1 / 2 ,
		pretrigger = function(root)
			if root.busy then return false end
			if WORLD:is_player(root) then
				return false
			end
			if (not root.traits[TRAIT.TRADER]) then
				return false
			end
			return true
		end,
		clickable = function(root)
			if WORLD:is_player(root) then
				return false
			end
			return true
		end,
		available = function(root)
			if root.busy then return false end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if root.traits[TRAIT.TRADER] then
				return 1
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			for name, good in pairs(RAWS_MANAGER.trade_goods_by_name) do
                local price = economic_values.get_local_price(root.province, name)
                if root.price_memory[name] == nil then
                    root.price_memory[name] = price
                else
                    if WORLD.player_character ~= root then
                        root.price_memory[name] = root.price_memory[name] * (3 / 4) + price * (1 / 4)
                    end
                end
            end
		end
	}

	Decision.Character:new {
		name = 'sell-something',
		ui_name = "(AI) Sell some goods",
		tooltip = function (root, primary_target)
			if root.busy then
				return "You are too busy to consider it."
			end
			return "Sell some goods on the local market"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 1 / 4,
		pretrigger = function(root)
			if root.busy then return false end
			if WORLD:is_player(root) then
				return false
			end
			if (not root.traits[TRAIT.TRADER]) then
				return false
			end
			return true
		end,
		clickable = function(root)
			if WORLD:is_player(root) then
				return false
			end
			return true
		end,
		available = function(root)
			if root.busy then return false end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if root.traits[TRAIT.TRADER] then
				return 1
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			WORLD:emit_immediate_event('sell-goods', root, nil)
		end
	}


	---@type DecisionCharacterProvince
	Decision.CharacterProvince:new {
		name = 'personal-raid',
		ui_name = "Raid",
		tooltip = function (root, primary_target)
			if root.busy then
				return "You are too busy to consider it."
			end
			local warband = root.leading_warband
			if warband == nil then
				return "You are not a leader of a warband."
			end
			if warband and warband.status ~= 'idle' then
				return "Your warband is busy."
			end
			if primary_target.realm == nil then
				return "Invalid province"
			end
			return "Raid the province " .. primary_target.name
		end,
		path = function (root, primary_target)
			return path.pathfind(
				root.province,
				primary_target,
				military_values.warband_speed(root.leading_warband),
				root.realm.known_provinces
			)
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 1 / 6,
		pretrigger = function(root)
			if root.busy then return false end
			if root.leading_warband == nil then return false end
			if root.leading_warband.status ~= 'idle' then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			return true
		end,
		available = function(root, primary_target)
			if primary_target.realm == nil then
				return false
			end
			return true
		end,
		ai_target = function(root)
			---@type Province[]
			local targets = {}
			for _, province in pairs(root.realm.known_provinces) do
				if province.realm and root.realm.tributaries[province.realm] == nil then
					table.insert(targets, province)
				end
			end

			local index, prov =  tabb.random_select_from_set(targets)
			if prov then
				return prov, true
			end

			return nil, false
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if root.realm.tributaries[primary_target] then
				return 0
			end

			if root.traits[TRAIT.WARLIKE] then
				return 1
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			MilitaryEffects.covert_raid_no_reward(root, primary_target)
		end
	}

	---@type DecisionCharacterProvince
	Decision.CharacterProvince:new {
		name = 'patrol-target',
		ui_name = "Patrol targeted province",
		tooltip = function (root, primary_target)
			if root.busy then
				return "You are too busy to consider it."
			end
			local warband = root.leading_warband
			if warband == nil then
				return "You are not a leader of a warband."
			end
			if warband and warband.status ~= 'idle' then
				return "Your warband is busy."
			end
			if primary_target.realm == nil then
				return "Invalid province"
			end
			if primary_target.realm ~= root.realm then
				return'You can\'t patrol provinces of other realms'
			end
			return "Patrol the province " .. primary_target.name
		end,
		path = function (root, primary_target)
			return path.pathfind(
				root.province,
				primary_target,
				military_values.warband_speed(root.leading_warband),
				root.realm.known_provinces
			)
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 0.9 , -- Almost every month
		pretrigger = function(root)
			if root.busy then
				return false
			end
			local warband = root.leading_warband
			if warband == nil then
				return false
			end
			if warband and warband.status ~= 'idle' then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			return true
		end,
		available = function(root, primary_target)
			if primary_target.realm == nil then
				return false
			end
			if primary_target.realm ~= root.realm then
				return false
			end
			return true
		end,
		ai_target = function(root)
			return root.province, true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if root.leading_warband then
				return 0.2
			end

			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			root.realm:add_patrol(primary_target, root.leading_warband)
		end
	}
end

return load
