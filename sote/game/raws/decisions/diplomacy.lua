local tabb = require "engine.table"
local path = require "game.ai.pathfinding"
local economical = require "game.raws.values.economical"

local Decision = require "game.raws.decisions"
local dt = require "game.raws.triggers.diplomacy"
local et = require "game.raws.triggers.economy"
local ot = require "game.raws.triggers.offices"
local pv = require "game.raws.values.political"
local ut = require "game.ui-utils"

local pretriggers = require "game.raws.triggers.tooltiped_triggers".Pretrigger
local triggers = require "game.raws.triggers.tooltiped_triggers".Targeted

local OR = pretriggers.OR
local NOT_BUSY = pretriggers.not_busy
local SETTLED = triggers.settled
local IS_LEADER = pretriggers.leader
local IS_LOCAL_LEADER = pretriggers.leader_of_local_territory



local IS_OVERLORD_OF_TARGET = triggers.is_overlord_of_target
local NOT_IN_NEGOTIATIONS = triggers.is_not_in_negotiations

local economic_effects = require "game.raws.effects.economic"
local character_values = require "game.raws.values.character"

local TRAIT = require "game.raws.traits.generic"

local function load()
	Decision.Character:new {
		name = 'request-tribute',
		ui_name = "Request tribute",
		tooltip = function(root, primary_target)
			if root.busy then
				return "You are busy."
			end
			return "Suggest " .. primary_target.name .. " to become your tributary."
		end,
		sorting = 1,
		primary_target = 'character',
		secondary_target = 'none',
		base_probability = 1 / 12, -- Once every year on average
		pretrigger = function(root)
			if not ot.decides_foreign_policy(root, root.realm) then return false end
			if root.realm.prepare_attack_flag then return false end
			if root.busy then return false end

			return true
		end,
		clickable = function(root, primary_target)
			---@type Character
			local primary_target = primary_target
			if not dt.valid_negotiators(root, primary_target) then return false end
			if primary_target.realm.paying_tribute_to[root.realm] then return false end

			return true
		end,
		available = function(root, primary_target)
			if not dt.valid_negotiators(root, primary_target) then return false end
			if primary_target.realm.paying_tribute_to[root.realm] then return false end

			return true
		end,
		ai_target = function(root)
			--print("ait")
			---@type Realm
			local realm = root.realm
			if realm == nil then
				return nil, false
			end

			---@type fun(province:Province):boolean
			local function valid_realm_check(province)
				if province then
					if province.realm then
						if province.realm ~= root.realm then
							return true
						end
					end
				end
				return false
			end

			-- select random province
			local random_realm_province = realm:get_random_province()
			if random_realm_province then
				-- Once you target a province, try selecting a random neighbor
				local neighbor_province = random_realm_province:get_random_neighbor()
				if neighbor_province then
					if valid_realm_check(neighbor_province) then
						return neighbor_province.realm.leader, true
					end
				end
			end

			-- if that still fails, try targetting a random tributaries neighbor
			local tributary_count = tabb.size(realm.tributaries)
			if tributary_count > 0 then
				local random_tributary = tabb.nth(realm.tributaries, love.math.random(tributary_count))
				local random_tributary_province = random_tributary:get_random_province()
				if random_tributary_province then
					if valid_realm_check(random_tributary_province) then
						return random_tributary_province.realm.leader, true
					end
				end
			end
			return nil, false
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			---@type Character
			primary_target = primary_target

			local _, root_power = pv.military_strength(root)
			local _, target_power = pv.military_strength(primary_target)
			local trait_modifier = 0
			if root.traits[TRAIT.WARLIKE] then
				trait_modifier = 2.0
			end
			if root.traits[TRAIT.LAZY] then
				trait_modifier = trait_modifier * 0.25
			end
			if root.traits[TRAIT.CONTENT] then
				trait_modifier = trait_modifier * 0.25
			end
			if root.traits[TRAIT.AMBITIOUS] then
				trait_modifier = trait_modifier * 1.5
			end

			if target_power == 0 and root_power > 0 then
				return trait_modifier
			end

			return (root_power - target_power) / target_power * trait_modifier
		end,
		effect = function(root, primary_target, secondary_target)
			if WORLD.player_character == root then
				WORLD:emit_notification("I requested " .. primary_target.name .. " to become my tributary.")
			elseif WORLD:does_player_see_realm_news(root.realm) then
				WORLD:emit_notification("Our chief requested " .. primary_target.name .. " to become his tributary.")
			end

			WORLD:emit_event('request-tribute', primary_target, root, 10)
		end
	}

	-- negotiation rough blueprint

	---@class (exact) NegotiationTradeData
	---@field goods_transfer_from_initiator_to_target table<TradeGoodReference, number?>
	---@field wealth_transfer_from_initiator_to_target number

	---@class (exact) NegotiationRealmToRealm
	---@field root Realm
	---@field target Realm
	---@field subjugate boolean
	---@field free boolean
	---@field demand_freedom boolean
	---@field trade NegotiationTradeData

	---@class (exact) NegotiationCharacterToRealm
	---@field target Realm
	---@field trade_permission boolean
	---@field building_permission boolean

	---@class (exact) NegotiationCharacterToCharacter
	---@field trade NegotiationTradeData

	---@class (exact) NegotiationData
	---@field initiator Character
	---@field target Character
	---@field negotiations_terms_realms NegotiationRealmToRealm[]
	---@field negotiations_terms_character_to_realm NegotiationCharacterToRealm[]
	---@field selected_realm_origin Realm?
	---@field selected_realm_target Realm?
	---@field negotiations_terms_characters NegotiationCharacterToCharacter
	---@field days_of_travel number

	Decision.CharacterCharacter:new_from_trigger_lists(
		'start-negotiations',
		"Start negotiations",
		function(root, primary_target)
			return "Start negotiations with " .. primary_target.name
		end,
		0, -- never
		{
			NOT_BUSY
		},
		{

		},
		{

		},

		function(root, primary_target, secondary_target)
			---@type NegotiationData
			local negotiation_data = {
				initiator = root,
				target = primary_target,
				negotiations_terms_characters = {
					trade = {
						wealth_transfer_from_initiator_to_target = 0,
						goods_transfer_from_initiator_to_target = {}
					}
				},
				negotiations_terms_character_to_realm = {},
				negotiations_terms_realms = {},
				days_of_travel = 10
			}

			root.current_negotiations[primary_target] = primary_target
			primary_target.current_negotiations[root] = root

			WORLD:emit_immediate_event('negotiation-initiator', root, negotiation_data)
		end,

		--- AI SHOULD HAVE SEPARATE DECISIONS WITH PRESET NEGOTIATION PROPOSALS
		function(root, primary_target, secondary_target)
			return 0
		end,
		function(root)
			return nil, false
		end
	)


	Decision.CharacterProvince:new_from_trigger_lists(
		'start-negotiations-province',
		"Start negotiations",
		function(root, primary_target)
			return "Start negotiations with a leader of " .. primary_target.realm.name
		end,
		0, -- never
		{
			NOT_BUSY
		},
		{
			SETTLED
		},
		{

		},

		function(root, primary_target, secondary_target)
			---@type Character
			local leader = primary_target.realm.leader

			---@type NegotiationData
			local negotiation_data = {
				initiator = root,
				target = leader,
				negotiations_terms_characters = {
					trade = {
						wealth_transfer_from_initiator_to_target = 0,
						goods_transfer_from_initiator_to_target = {}
					}
				},
				negotiations_terms_character_to_realm = {},
				negotiations_terms_realms = {},
				days_of_travel = 10
			}

			root.current_negotiations[leader] = leader
			leader.current_negotiations[root] = root

			WORLD:emit_immediate_event('negotiation-initiator', root, negotiation_data)
		end,

		--- AI SHOULD HAVE SEPARATE DECISIONS WITH PRESET NEGOTIATION PROPOSALS
		function(root, primary_target, secondary_target)
			return 0
		end,
		function(root)
			return nil, false
		end
	)

	-- migrate decision

	Decision.CharacterProvince:new {
		name = 'migrate-realm',
		ui_name = "Migrate to targeted province",
		tooltip = function(root, primary_target)
			if root.busy then
				return "You are too busy to consider it."
			end
			if not ot.decides_foreign_policy(root, root.realm) then
				return "You have no right to order your tribe to do this"
			end
			if root.province ~= root.realm.capitol then
				return "You has to be with your people during migration"
			end
			if primary_target.realm then
				return "Migrate to "
					.. primary_target.name
					.. " controlled by "
					.. primary_target.realm.name
					.. ". Our tribe will be merged into their if they agree."
			else
				return "Migrate to "
					.. primary_target.name
					.. "."
			end
		end,
		path = function(root, primary_target)
			return path.pathfind(
				root.realm.capitol,
				primary_target,
				character_values.travel_speed_race(root.realm.primary_race),
				root.realm.known_provinces
			)
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 0.9, -- Almost every month
		pretrigger = function(root)
			if not ot.decides_foreign_policy(root, root.realm) then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if not primary_target.center.is_land then
				return false
			end
			if root.realm.capitol.neighbors[primary_target] then
				return true
			end
			return false
		end,
		available = function(root, primary_target)
			if root.busy then
				return false
			end
			if not ot.decides_foreign_policy(root, root.realm) then
				return false
			end
			if root.province ~= root.realm.capitol then
				return false
			end
			if primary_target.realm == root.realm then
				return false
			end
			return true
		end,
		ai_target = function(root)
			return tabb.random_select_from_set(root.realm.capitol.neighbors), true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			root.busy = true

			local travel_time, _ = path.hours_to_travel_days(
				path.pathfind(
					root.realm.capitol,
					primary_target.realm.capitol,
					character_values.travel_speed_race(root.realm.primary_race),
					root.realm.known_provinces
				)
			)
			if travel_time == math.huge then
				travel_time = 150
			end

			if primary_target.realm == nil then
				---@type MigrationData
				local migration_data = {
					organizer = root,
					origin_province = root.realm.capitol,
					target_province = primary_target,
					invasion = false
				}
				WORLD:emit_immediate_action('migration-merge', root, migration_data)
			else
				WORLD:emit_event('migration-request', primary_target.realm.leader, root, travel_time)
			end
		end
	}

	Decision.CharacterProvince:new {
		name = 'migrate-realm-invasion',
		ui_name = "Invade targeted province",
		tooltip = function(root, primary_target)
			if root.busy then
				return "You are too busy to consider it."
			end
			if not ot.decides_foreign_policy(root, root.realm) then
				return "You have no right to order your tribe to do this"
			end
			if root.province ~= root.realm.capitol then
				return "You has to be with your people during migration"
			end
			return "Migrate to "
				.. primary_target.name
				.. " controlled by "
				.. primary_target.realm.name
				.. ". Their tribe will be merged into our if we succeed."
		end,
		path = function(root, primary_target)
			return path.pathfind(
				root.realm.capitol,
				primary_target.realm.capitol,
				character_values.travel_speed_race(root.realm.primary_race),
				root.realm.known_provinces
			)
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 0.9, -- Almost every month
		pretrigger = function(root)
			if not ot.decides_foreign_policy(root, root.realm) then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if primary_target.realm == nil then
				return false
			end
			if root.realm.capitol.neighbors[primary_target] then
				return true
			end
			return false
		end,
		available = function(root, primary_target)
			if root.busy then
				return false
			end
			if not ot.decides_foreign_policy(root, root.realm) then
				return false
			end
			if root.province ~= root.realm.capitol then
				return false
			end
			if primary_target.realm == root.realm then
				return false
			end
			return true
		end,
		ai_target = function(root)
			return tabb.random_select_from_set(root.realm.capitol.neighbors), true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			root.busy = true
			WORLD:emit_immediate_event('migration-invasion-preparation', root, primary_target.realm)
		end
	}

	local colonisation_cost = 10 -- base 10 per family unit transfered

	Decision.CharacterProvince:new {
		name = 'colonize-province',
		ui_name = "Colonize targeted province",
		tooltip = function(root, primary_target)
			-- need at least so many family units to migrate
			local home_family_units = tabb.accumulate(root.realm.capitol.home_to, 0, function (a, k, v)
				if not v:is_character() and v.age >= v.race.teen_age then
					return a + 1
				end
				return a
			end)
			local expedition_size = math.min(6, math.floor(home_family_units / 2))
			-- colonizing cost calories for travel
			local travel_time = path.pathfind(
				root.province,
				primary_target,
				character_values.travel_speed_race(root.realm.primary_race),
				root.realm.known_provinces
			)
			travel_time = path.hours_to_travel_days(travel_time)
			local calorie_cost = ((100 * root.realm.primary_race.female_needs[NEED.FOOD]['calories'])
				+ root.realm.primary_race.males_per_hundred_females * root.realm.primary_race.male_needs[NEED.FOOD]['calories'])
				/ (100 + root.realm.primary_race.males_per_hundred_females) * travel_time * expedition_size / 30
			local character_calories_in_inventory = economic_effects.available_use_case_from_inventory(root.inventory, 'calories')
			local remaining_calories_needed = math.max(0, calorie_cost - character_calories_in_inventory)
			local can_buy_calories, buy_reasons = et.can_buy_use(root.realm.capitol, root.savings, 'calories', remaining_calories_needed + 0.01)


			-- convincing people to move takes money but amount d epends on pops willingness to move, base payment the price of upto 10 units of food per family
			local pop_payment =  colonisation_cost * expedition_size * root.realm:get_average_needs_satisfaction() * economical.get_local_price_of_use(root.realm.capitol, 'calories')
			local calorie_price_expectation = economical.get_local_price_of_use(root.realm.capitol, 'calories')

			local expected_calorie_cost = math.max(0, calorie_cost - character_calories_in_inventory) * calorie_price_expectation

			if root.busy then
				return "You are too busy to consider it."
			end
			if root.province ~= root.realm.capitol then
				return "You has to be in your home province to organize colonisation."
			end
			if home_family_units < 11 then
				return "Your population is too low, you need at least " .. 6 .. " families while you only have " .. home_family_units .. "."
			end
			if character_calories_in_inventory < calorie_cost and not can_buy_calories then
				return "You need " .. ut.to_fixed_point2(calorie_cost) .. " calories to move enough people to a new province and only has "
					.. ut.to_fixed_point2(character_calories_in_inventory) .. " in you inventory and cannot buy the remaning because:"
					.. tabb.accumulate(buy_reasons, "", function (tooltip, _, reason)
						return tooltip .. "\n - " .. reason
					end)
			end
			if character_calories_in_inventory < calorie_cost and can_buy_calories and root.realm.budget.treasury <  expected_calorie_cost + pop_payment then
				return "The realm needs " .. ut.to_fixed_point2(calorie_cost) .. " calories to move enough people to a new province and only has "
					.. ut.to_fixed_point2(character_calories_in_inventory) .. " in storage and you do not have enough money to purchase the remaining " .. ut.to_fixed_point2(remaining_calories_needed)
					.. " calories " .. " at an expected cost of " .. ut.to_fixed_point2(expected_calorie_cost) .. MONEY_SYMBOL
					.. " and a gift to the colonists of " .. ut.to_fixed_point2(pop_payment) .. MONEY_SYMBOL .. "."
			end

			if not ot.decides_foreign_policy(root, root.realm) then
				return "Request permision to colonize " .. primary_target.name .." from " .. root.realm.leader.name
				.. ". If approved, we will form a new tribe which will pay tribute to " .. root.realm.leader.name
				.. ". It will cost " .. ut.to_fixed_point2(pop_payment) .. MONEY_SYMBOL
				.. " to convince " .. expedition_size .. " families to move and " .. ut.to_fixed_point2(calorie_cost) .. " calories for their journey."
			end

			return "Colonize " .. primary_target.name
				.. ". Our realm will organise a new tribe which will pay tribute to us. It will cost " .. ut.to_fixed_point2(pop_payment) .. MONEY_SYMBOL
				.. " to convince " .. expedition_size .. " families to move and " .. ut.to_fixed_point2(calorie_cost) .. " calories for their journey."
		end,
		path = function(root, primary_target)
			return path.pathfind(
				root.realm.capitol,
				primary_target,
				character_values.travel_speed_race(root.realm.primary_race),
				root.realm.known_provinces
			)
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 0.9, -- Almost every month
		pretrigger = function(root)
			-- need at least so many family units to migrate
			local home_family_units = tabb.accumulate(root.realm.capitol.home_to, 0, function (a, k, v)
				if not v:is_character() and v.age >= v.race.teen_age and not v.parent then
					return a + 1
				end
				return a
			end)
			local expedition_size = math.min(6, math.floor(home_family_units / 2))

			if root.province ~= root.realm.capitol then
				return false
			end
			if home_family_units < expedition_size then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			-- need at least so many family units to migrate
			local home_family_units = tabb.accumulate(root.realm.capitol.home_to, 0, function (a, k, v)
				if not v:is_character() and v.age >= v.race.teen_age and not v.parent then
					return a + 1
				end
				return a
			end)
			if not primary_target.center.is_land then
				return false
			end
			if home_family_units < 11 then
				return false
			end
			if primary_target.realm ~= nil then
				return false
			end
			if not primary_target:neighbors_realm_tributary(root.realm) then
				return false
			end
			return true
		end,
		available = function(root, primary_target)
			-- need at least so many family units to migrate
			local home_family_units = tabb.accumulate(root.realm.capitol.home_to, 0, function (a, k, v)
				if not v:is_character() and v.age >= v.race.teen_age and not v.parent then
					return a + 1
				end
				return a
			end)
			local expedition_size = math.min(6, math.floor(home_family_units / 2))
			-- colonizing cost calories for travel
			local travel_time = path.pathfind(
				root.province,
				primary_target,
				character_values.travel_speed_race(root.realm.primary_race),
				root.realm.known_provinces
			)
			travel_time = path.hours_to_travel_days(travel_time)
			local calorie_cost = ((100 * root.realm.primary_race.female_needs[NEED.FOOD]['calories'])
				+ root.realm.primary_race.males_per_hundred_females * root.realm.primary_race.male_needs[NEED.FOOD]['calories'])
				/ (100 + root.realm.primary_race.males_per_hundred_females) * travel_time * expedition_size / 30
			local character_calories_in_inventory = economic_effects.available_use_case_from_inventory(root.inventory, 'calories')
			local remaining_calories_needed = math.max(0, calorie_cost - character_calories_in_inventory)
			local can_buy_calories, _ = et.can_buy_use(root.realm.capitol, root.savings, 'calories', remaining_calories_needed + 0.01)

			-- convincing people to move takes money but amount d epends on pops willingness to move, base payment the price of upto 10 units of food per family
			local pop_payment =  colonisation_cost * expedition_size * root.realm:get_average_needs_satisfaction() * economical.get_local_price_of_use(root.realm.capitol, 'calories')
			local calorie_price_expectation = economical.get_local_price_of_use(root.realm.capitol, 'calories')

			local expected_calorie_cost = math.max(0, calorie_cost - character_calories_in_inventory) * calorie_price_expectation

			if root.busy then
				return false
			end
			if root.province ~= root.realm.capitol then
				return false
			end
			if home_family_units < 11 then
				return false
			end
			if character_calories_in_inventory < calorie_cost and not can_buy_calories then
				return false
			end
			if character_calories_in_inventory < calorie_cost and can_buy_calories and root.realm.budget.treasury < (expected_calorie_cost + pop_payment) then
				return false
			end
			return true
		end,
		ai_target = function(root)
			return tabb.random_select_from_set(root.realm.capitol.neighbors), true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			-- need at least so many family units to migrate
			local home_family_units = tabb.accumulate(root.realm.capitol.home_to, 0, function (a, k, v)
				if not v:is_character() and v.age >= v.race.teen_age and not v.parent then
					return a + 1
				end
				return a
			end)
			--- don't let traders settle down since leaders refuse to move
			if not ot.decides_foreign_policy(root, root.realm) and root.traits[TRAIT.TRADER] then
				return 0
			end
			-- will only try to colonize if it can get all 6 families
			if home_family_units < 11 then
				return 0
			end
			local base = 0.125
			if root.realm.capitol:home_population() > 20 and primary_target.realm == nil then
				base = base * 2
			end
			-- more inclination to colonize when over foraging more than CC allows
			if root.realm.capitol.foragers_limit < root.realm.capitol.foragers then
				base = base * 2
			-- less likely to spread if well uncer CC allows
			elseif root.realm.capitol.foragers_limit > root.realm.capitol.foragers * 2 then
				base = base * 0.5
			end
			-- trait based variance
			if root.traits[TRAIT.AMBITIOUS] then
				base = base * 2
			end
			if root.traits[TRAIT.CONTENT] then
				base = base * 0.5
			end
			if root.traits[TRAIT.HARDWORKER] then
				base = base * 2
			end
			if root.traits[TRAIT.LAZY] then
				base = base * 0.5
			end
			return base
		end,
		effect = function(root, primary_target, secondary_target)
			root.busy = true

			-- need at least so many family units to migrate
			local home_family_units = tabb.accumulate(root.realm.capitol.home_to, 0, function (a, k, v)
				if not v:is_character() and not v.parent then
					return a + 1
				end
				return a
			end)
			local expedition_size = math.min(6, math.floor(home_family_units / 2))
			-- colonizing cost calories for travel
			local travel_time = path.pathfind(
				root.province,
				primary_target,
				character_values.travel_speed_race(root.realm.primary_race),
				root.realm.known_provinces
			)
			travel_time = path.hours_to_travel_days(travel_time)
			local calorie_cost = ((100 * root.realm.primary_race.female_needs[NEED.FOOD]['calories'])
				+ root.realm.primary_race.males_per_hundred_females * root.realm.primary_race.male_needs[NEED.FOOD]['calories'])
				/ (100 + root.realm.primary_race.males_per_hundred_females) * travel_time * expedition_size / 30
			local character_calories_in_inventory = economic_effects.available_use_case_from_inventory(root.inventory, 'calories')
			local remaining_calories_needed = math.max(0, calorie_cost - character_calories_in_inventory)

			-- convincing people to move takes money but amount depends on pops willingness to move, base payment of upto 2 units of food per family
			local pop_payment =  colonisation_cost * expedition_size * root.realm:get_average_needs_satisfaction() * economical.get_local_price_of_use(root.realm.capitol, 'calories')

			local leader = nil
			local organizer = root
			if not ot.decides_foreign_policy(root, root.realm) then
				leader = root
				organizer = root.realm.leader
			end

			---@type MigrationData
			local migration_data = {
				invasion = false,
				organizer = organizer,
				leader = leader,
				expedition_size = expedition_size,
				travel_cost = calorie_cost,
				pop_payment = pop_payment,
				origin_province = root.province,
				target_province = primary_target
			}
			if ot.decides_foreign_policy(root, root.realm) then
				-- buy remaining calories from market
				economic_effects.character_buy_use(root, 'calories', remaining_calories_needed)
				-- consume food from character inventory
				economic_effects.consume_use_case_from_inventory(root.inventory, 'calories', calorie_cost)
				-- give out payment to expedition
				economic_effects.change_treasury(root.realm, -pop_payment, economic_effects.reasons.Colonisation)
				WORLD:emit_immediate_action('migration-colonize', root, migration_data)
			else
				WORLD:emit_immediate_event('request-migration-colonize', migration_data.organizer, migration_data)
			end
		end
	}
end

return load
