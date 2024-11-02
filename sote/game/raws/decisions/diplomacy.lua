local tabb = require "engine.table"
local path = require "game.ai.pathfinding"
local economical = require "game.raws.values.economy"

local realm_utils = require "game.entities.realm".Realm
local province_utils = require "game.entities.province".Province

local retrieve_use_case = require "game.raws.raws-utils".trade_good_use_case
local retrieve_trade_good = require "game.raws.raws-utils".trade_good

local Decision = require "game.raws.decisions"
local dt = require "game.raws.triggers.diplomacy"
local diplomacy_values = require "game.raws.values.diplomacy"
local et = require "game.raws.triggers.economy"
local ot = require "game.raws.triggers.offices"
local pv = require "game.raws.values.politics"
local ut = require "game.ui-utils"

local economy_values = require "game.raws.values.economy"

local pretriggers = require "game.raws.triggers.tooltiped_triggers".Pretrigger
local triggers = require "game.raws.triggers.tooltiped_triggers".Targeted

local OR = pretriggers.OR
local NOT_BUSY = pretriggers.not_busy
local SETTLED = triggers.settled
local NOT_SETTLED = triggers.not_settled
local IS_LEADER = pretriggers.leader
local IS_LOCAL_LEADER = pretriggers.leader_of_local_territory
local IS_DECISION_MAKER = pretriggers.decision_maker_local
local IS_NEIGHBOR = triggers.is_neigbor_to_capitol
local AT_CAPITOL = pretriggers.at_capitol
local DIFFERENT_REALM = triggers.different_realm



local IS_OVERLORD_OF_TARGET = triggers.is_overlord_of_target
local NOT_IN_NEGOTIATIONS = triggers.is_not_in_negotiations

local economic_effects = require "game.raws.effects.economy"
local character_values = require "game.raws.values.character"


local function load()
	Decision.Character:new {
		name = 'request-tribute',
		ui_name = "Request tribute",
		tooltip = function(root, primary_target)
			if DATA.pop_get_busy(root) then
				return "You are busy."
			end
			return "Suggest " .. primary_target.name .. " to become your tributary."
		end,
		sorting = 1,
		primary_target = 'character',
		secondary_target = 'none',
		base_probability = 1 / 12, -- Once every year on average
		pretrigger = function(root)
			local realm = REALM(root)
			if not ot.decides_foreign_policy(root, realm) then return false end

			local prepares_attack = DATA.realm_get_prepare_attack_flag(realm)
			if prepares_attack then return false end

			local busy = DATA.pop_get_busy(root)
			if busy then return false end

			return true
		end,
		clickable = function(root, primary_target)
			---@type Character
			local primary_target = primary_target
			if not dt.valid_negotiators(root, primary_target) then return false end
			if dt.pays_tribute_to(REALM(primary_target), REALM(root)) then return false end

			return true
		end,
		available = function(root, primary_target)
			if not dt.valid_negotiators(root, primary_target) then return false end
			if dt.pays_tribute_to(primary_target, REALM(root)) then return false end

			return true
		end,
		ai_target = function(root)
			--print("ait")
			---@type Realm
			local realm = REALM(root)
			if realm == INVALID_ID then
				return nil, false
			end

			-- select random province
			local random_realm_province = realm_utils.get_random_province(realm)


			if random_realm_province ~= INVALID_ID then
				-- Once you target a province, try selecting a random neighbor
				local neighbor_province = province_utils.get_random_neighbor(random_realm_province)

				if neighbor_province ~= nil then
					if PROVINCE_REALM(neighbor_province) ~= INVALID_ID then
						if not dt.province_controlled_by(neighbor_province, realm) then
							return pv.province_leader(neighbor_province), true
						end
					end
				end
			end

			-- if that still fails, try targetting a random tributaries neighbor

			local random_tributary = diplomacy_values.sample_tributary(realm)
			if random_tributary ~= nil then
				local random_tributary_province = DATA.realm_get_capitol(random_tributary)
				local neighbor_province = province_utils.get_random_neighbor(random_tributary_province)
				if neighbor_province ~= nil and PROVINCE_REALM(neighbor_province) ~= INVALID_ID then
					if not dt.province_controlled_by(neighbor_province, realm) then
						return pv.province_leader(neighbor_province), true
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
			local base = 0
			local multiplier = 1

			for i = 1, MAX_TRAIT_INDEX do
				local trait = DATA.pop_get_traits(root, i)
				if trait == TRAIT.INVALID then
					break
				end

				if trait == TRAIT.WARLIKE then
					---@type number
					base = base + 3
				end

				if trait == TRAIT.AMBITIOUS then
					---@type number
					base = base + 1
				end

				if trait == TRAIT.LAZY then
					---@type number
					multiplier = multiplier * 0.25
				end

				if trait == TRAIT.CONTENT then
					---@type number
					multiplier = multiplier * 0.1
				end
			end

			if target_power == 0 and root_power > 0 then
				--- bully the weak
				multiplier = multiplier * 100
			else
				multiplier = multiplier * (root_power - target_power) / target_power
			end

			return base * multiplier
		end,
		effect = function(root, primary_target, secondary_target)
			if WORLD.player_character == root then
				WORLD:emit_notification("I requested " .. NAME(primary_target) .. " to become my tributary.")
			elseif WORLD:does_player_see_realm_news(REALM(root)) then
				WORLD:emit_notification("Our chief requested " .. NAME(primary_target) .. " to become his tributary.")
			end

			WORLD:emit_event('request-tribute', primary_target, root, 10)
		end
	}

	-- negotiation rough blueprint

	---@class (exact) NegotiationTradeData
	---@field goods_transfer_from_initiator_to_target table<trade_good_id, number?>
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
	---@field id negotiation_id
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
			return "Start negotiations with " .. NAME(primary_target)
		end,
		0, -- never
		{
			NOT_BUSY,
		},
		{

		},
		{
			NOT_IN_NEGOTIATIONS
		},

		function(root, primary_target, secondary_target)
			local new = DATA.force_create_negotiation(root, primary_target)

			---@type NegotiationData
			local negotiation_data = {
				id = new,
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
			return "Start negotiations with a leader of " .. DATA.realm_get_name(province_utils.realm(primary_target))
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
			local realm = province_utils.realm(primary_target)

			---@type Character
			local leader = LEADER(realm)

			---@type NegotiationData
			local negotiation_data = {
				id = DATA.force_create_negotiation(root, leader),
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
			if DATA.pop_get_busy(root) then
				return "You are too busy to consider it."
			end
			if not ot.decides_foreign_policy(root, REALM(root)) then
				return "You have no right to order your tribe to do this"
			end
			if PROVINCE(root) ~= DATA.realm_get_capitol(REALM(root)) then
				return "You has to be with your people during migration"
			end
			if province_utils.realm(primary_target) ~= INVALID_ID then
				return "Migrate to "
					.. DATA.province_get_name(primary_target)
					.. " controlled by "
					.. DATA.realm_get_name(province_utils.realm(primary_target))
					.. ". Our tribe will be merged into their if they agree."
			else
				return "Migrate to "
					.. DATA.province_get_name(primary_target)
					.. "."
			end
		end,
		path = function(root, primary_target)
			local realm = REALM(root)
			return path.pathfind(
				DATA.realm_get_capitol(realm),
				primary_target,
				character_values.travel_speed_race(DATA.realm_get_primary_race(realm)),
				DATA.realm_get_known_provinces(realm)
			)
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 0.9, -- Almost every month
		pretrigger = function(root)
			if not ot.decides_foreign_policy(root, REALM(root)) then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if not DATA.tile_get_is_land(DATA.province_get_center(primary_target)) then
				return false
			end

			local capitol = DATA.realm_get_capitol(REALM(root))
			local is_neighbour = false

			DATA.for_each_province_neighborhood_from_origin(capitol, function (item)
				local province = DATA.province_neighborhood_get_target(item)
				if province == primary_target then
					is_neighbour = true
				end
			end)

			return is_neighbour
		end,
		available = function(root, primary_target)
			if DATA.pop_get_busy(root) then
				return false
			end
			if not ot.decides_foreign_policy(root, REALM(root)) then
				return false
			end
			if PROVINCE(root) ~= DATA.realm_get_capitol(REALM(root)) then
				return false
			end

			return not dt.province_controlled_by(primary_target, REALM(root))
		end,
		ai_target = function(root)
			local realm = REALM(root)
			local capitol = DATA.realm_get_capitol(realm)
			local neighbors = DATA.filter_array_province_neighborhood_from_origin(capitol, ACCEPT_ALL)
			local neighbor = tabb.random_select_from_array(neighbors)
			if neighbor == nil then
				return nil, false
			end
			return DATA.province_neighborhood_get_target(neighbor), true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			DATA.pop_set_busy(root, true)

			--- we assume that we are at capitol province

			local travel_time, _ = path.hours_to_travel_days(
				path.pathfind(
					PROVINCE(root),
					primary_target,
					character_values.travel_speed_race(DATA.realm_get_primary_race(REALM(root))),
					DATA.realm_get_known_provinces(REALM(root))
				)
			)
			if travel_time == math.huge then
				travel_time = 150
			end

			local target_realm = province_utils.realm(primary_target)

			if target_realm == INVALID_ID then
				---@type MigrationData
				local migration_data = {
					organizer = root,
					origin_province = PROVINCE(root),
					target_province = primary_target,
					invasion = false
				}
				WORLD:emit_immediate_action('migration-merge', root, migration_data)
			else
				WORLD:emit_event('migration-request', LEADER(province_utils.realm(primary_target)), root, travel_time)
			end
		end
	}

	Decision.CharacterProvince:new_from_trigger_lists(
		"migrate-realm-invasion",
		"Invade targeted province",
		function(root, primary_target)
			return "Migrate to "
				.. DATA.province_get_name(primary_target)
				.. " controlled by "
				.. DATA.realm_get_name(province_utils.realm(primary_target))
				.. ". Their tribe will be merged into our if we succeed."
		end,
		0.9,
		{
			IS_DECISION_MAKER,
			NOT_BUSY,
			AT_CAPITOL
		},
		{
			SETTLED,
			DIFFERENT_REALM
		},
		{
			IS_NEIGHBOR
		},
		function (root, primary_target, secondary_target)
			DATA.pop_set_busy(root, true)
			WORLD:emit_immediate_event('migration-invasion-preparation', root, province_utils.realm(primary_target))
		end,
		function(root, primary_target, secondary_target)
			return 0
		end,
		function(root)
			return province_utils.get_random_neighbor(DATA.realm_get_capitol(REALM(root))), true
		end
	)

	local colonisation_cost = 10 -- base 10 per family unit transfered

	---collect colonization information
	---@param province Province
	---@return table<POP, POP> valid_family_units
	---@return integer  valid_family_count
	local function valid_home_family_units(province)
		local all_pops = tabb.map_array(DATA.get_pop_location_from_location(province), DATA.pop_location_get_pop)
		local family_units = tabb.filter_array(all_pops, function (item)
			local a = DATA.fatten_pop(item)
			local race = DATA.fatten_race(a.race)
			local home_location = DATA.get_home_from_pop(item)
			local home = DATA.home_get_home(home_location)
			local unit_of_warband = DATA.get_warband_unit_from_unit(item)

			return home == province and a.age >= race.teen_age and a.age < race.middle_age and unit_of_warband == INVALID_ID
		end)
		local family_count = tabb.size(family_units)
		return family_units, family_count
	end

	Decision.CharacterProvince:new {
		name = 'colonize-province',
		ui_name = "Colonize targeted province",
		tooltip = function(root, primary_target)
			-- need at least so many family units to migrate
			local valid_family_units, valid_family_count = valid_home_family_units(DATA.realm_get_capitol(REALM(root)))
			-- colonizing cost calories for travel
			local travel_time = path.pathfind(
				PROVINCE(root),
				primary_target,
				character_values.travel_speed_race(DATA.realm_get_primary_race(REALM(root))),
				DATA.realm_get_known_provinces(REALM(root))
			)
			travel_time = path.hours_to_travel_days(travel_time)

			local calorie_cost = 0
			local realm = REALM(root)
			local capitol = DATA.realm_get_capitol(realm)
			local race = DATA.realm_get_primary_race(realm)
			local male_ratio = DATA.race_get_males_per_hundred_females(race)
			local savings = DATA.pop_get_savings(root)

			for i = 1, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
				local need = DATA.race_get_male_needs_need(race, i)
				if need == NEED.INVALID then
					break
				end
				local use = DATA.race_get_male_needs_use_case(race, i)

				if use == CALORIES_USE_CASE then
					local male_intake = DATA.race_get_male_needs_required(race, i)
					local female_intake = DATA.race_get_female_needs_required(race, i)

					calorie_cost = (
						100 * female_intake
						+ male_ratio * male_intake
					) / (100 + male_ratio) * travel_time / 5
				end
			end

			local character_calories_in_inventory = economy_values.available_use_case_from_inventory(root, CALORIES_USE_CASE)
			local remaining_calories_needed = math.max(0, calorie_cost - character_calories_in_inventory)
			local can_buy_calories, buy_reasons = et.can_buy_use(capitol, savings, CALORIES_USE_CASE, remaining_calories_needed + 0.01)

			-- convincing people to move takes money but amount d epends on pops willingness to move, base payment the price of upto 10 units of food per family
			local pop_payment =
				colonisation_cost * 6
				* realm_utils.get_average_needs_satisfaction(realm)
				* economical.get_local_price_of_use(capitol, CALORIES_USE_CASE)

			local calorie_price_expectation = economical.get_local_price_of_use(capitol, CALORIES_USE_CASE)

			local expected_calorie_cost = math.max(0, calorie_cost - character_calories_in_inventory) * calorie_price_expectation

			if DATA.pop_get_busy(root) then
				return "You are too busy to consider it."
			end
			if PROVINCE(root) ~= DATA.realm_get_capitol(realm) then
				return "You has to be in your home province to organize colonisation."
			end
			if valid_family_count < 11 then
				return "Your population is too low, there need to be at least " .. 11 .. " families that are not part of a warband while there are only " .. valid_family_count .. "."
			end
			if character_calories_in_inventory < calorie_cost and not can_buy_calories then
				return "You need " .. ut.to_fixed_point2(calorie_cost) .. " calories to move enough people to a new province and only has "
					.. ut.to_fixed_point2(character_calories_in_inventory) .. " in you inventory and cannot buy the remaning because:"
					.. tabb.accumulate(buy_reasons, "", function (tooltip, _, reason)
						return tooltip .. "\n - " .. reason
					end)
			end
			local budget = DATA.realm_get_budget_treasury(realm)
			if character_calories_in_inventory < calorie_cost and can_buy_calories and budget < expected_calorie_cost + pop_payment then
				return "The realm needs " .. ut.to_fixed_point2(calorie_cost) .. " calories to move enough people to a new province and only has "
					.. ut.to_fixed_point2(character_calories_in_inventory) .. " in storage and you do not have enough money to purchase the remaining " .. ut.to_fixed_point2(remaining_calories_needed)
					.. " calories " .. " at an expected cost of " .. ut.to_fixed_point2(expected_calorie_cost) .. MONEY_SYMBOL
					.. " and a gift to the colonists of " .. ut.to_fixed_point2(pop_payment) .. MONEY_SYMBOL .. "."
			end

			if not ot.decides_foreign_policy(root, realm) then
				return "Request permision to colonize " .. DATA.province_get_name(primary_target) .." from " .. NAME(LEADER(REALM(root)))
				.. ". If approved, we will form a new tribe which will pay tribute to " .. NAME(LEADER(REALM(root)))
				.. ". It will cost " .. ut.to_fixed_point2(pop_payment) .. MONEY_SYMBOL
				.. " to convince " .. 6 .. " families to move and " .. ut.to_fixed_point2(calorie_cost) .. " calories for their journey."
			end

			return "Colonize " .. DATA.province_get_name(primary_target)
				.. ". Our realm will organise a new tribe which will pay tribute to us. It will cost " .. ut.to_fixed_point2(pop_payment) .. MONEY_SYMBOL
				.. " to convince " .. 6 .. " families to move and " .. ut.to_fixed_point2(calorie_cost) .. " calories for their journey."
		end,
		path = function(root, primary_target)
			return path.pathfind(
				CAPITOL(REALM(root)),
				primary_target,
				character_values.travel_speed_race(MAIN_RACE(REALM(root))),
				DATA.realm_get_known_provinces(REALM(root))
			)
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 0.9, -- Almost every month
		pretrigger = function(root)
			-- need at least so many family units to migrate
			local realm = REALM(root)
			local age = DATA.pop_get_age(root)
			local race = RACE(root)
			local teen_age = DATA.race_get_teen_age(race)

			-- makes sure characters wanting to lead an expepedition are 'adults'
			if (not ot.decides_foreign_policy(root, realm)) or age < teen_age then
				return false
			end

			local province = PROVINCE(root)
			local capitol = CAPITOL(realm)
			if province ~= capitol then
				return false
			end

			local valid_family_units, valid_family_count = valid_home_family_units(capitol)
			if valid_family_count < 11 then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			-- need at least so many family units to migrate
			if not DATA.province_get_is_land(primary_target) then
				return false
			end
			local _, valid_family_count, _ = valid_home_family_units(CAPITOL(REALM(root)))
			if valid_family_count < 11 then
				return false
			end
			if province_utils.realm(primary_target) ~= INVALID_ID then
				return false
			end
			if not realm_utils.neighbors_realm_tributary(primary_target, REALM(root)) then
				return false
			end
			return true
		end,
		available = function(root, primary_target)
			-- need at least so many family units to migrate
			local _, valid_family_count = valid_home_family_units(CAPITOL(REALM(root)))
			-- colonizing cost calories for travel
			local travel_time = path.pathfind(
				PROVINCE(root),
				primary_target,
				character_values.travel_speed_race(MAIN_RACE(REALM(root))),
				DATA.realm_get_known_provinces(REALM(root))
			)
			travel_time = path.hours_to_travel_days(travel_time)

			local calorie_cost = 0
			local realm = REALM(root)
			local capitol = DATA.realm_get_capitol(realm)
			local race = DATA.realm_get_primary_race(realm)
			local male_ratio = DATA.race_get_males_per_hundred_females(race)
			local savings = DATA.pop_get_savings(root)

			for i = 1, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
				local need = DATA.race_get_male_needs_need(race, i)
				if need == NEED.INVALID then
					break
				end
				local use = DATA.race_get_male_needs_use_case(race, i)

				if use == CALORIES_USE_CASE then
					local male_intake = DATA.race_get_male_needs_required(race, i)
					local female_intake = DATA.race_get_female_needs_required(race, i)

					calorie_cost = (
						100 * female_intake
						+ male_ratio * male_intake
					) / (100 + male_ratio) * travel_time / 5
				end
			end

			local character_calories_in_inventory = economy_values.available_use_case_from_inventory(root, CALORIES_USE_CASE)
			local remaining_calories_needed = math.max(0, calorie_cost - character_calories_in_inventory)
			local can_buy_calories, buy_reasons = et.can_buy_use(capitol, savings, CALORIES_USE_CASE, remaining_calories_needed + 0.01)

			-- convincing people to move takes money but amount d epends on pops willingness to move, base payment the price of upto 10 units of food per family
			local pop_payment =
				colonisation_cost * 6
				* realm_utils.get_average_needs_satisfaction(realm)
				* economical.get_local_price_of_use(capitol, CALORIES_USE_CASE)

			local calorie_price_expectation = economical.get_local_price_of_use(capitol, CALORIES_USE_CASE)

			local expected_calorie_cost = math.max(0, calorie_cost - character_calories_in_inventory) * calorie_price_expectation

			if BUSY(root) then
				return false
			end
			if PROVINCE(root) ~= CAPITOL(REALM(root)) then
				return false
			end
			if valid_family_count < 11 then
				return false
			end
			if character_calories_in_inventory < calorie_cost and not can_buy_calories then
				return false
			end
			local budget = DATA.realm_get_budget_treasury(realm)
			if character_calories_in_inventory < calorie_cost and can_buy_calories and budget < (expected_calorie_cost + pop_payment) then
				return false
			end
			return true
		end,
		ai_target = function(root)
			return province_utils.get_random_neighbor(CAPITOL(REALM(root))), true
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)

			local realm = REALM(root)
			local capitol = CAPITOL(realm)
			local province = PROVINCE(root)
			local age = DATA.pop_get_age(root)
			local race = RACE(root)
			local teen_age = DATA.race_get_teen_age(race)

			if (not ot.decides_foreign_policy(root, realm))
				or age < teen_age
			then
				return 0
			end

			-- need at least so many family units to migrate
			local _, valid_family_count = valid_home_family_units(capitol)
			--- don't let children start new realms unless leader
			-- will only try to colonize if it can get all 6 families
			if valid_family_count < 11 then
				return 0
			end
			local base = 0.0625
			if province_utils.home_population(CAPITOL(REALM(root))) > 20 and province_utils.realm(primary_target) == INVALID_ID then
				base = base * 2
			end

			local foragers_limit = DATA.province_get_foragers_limit(capitol)

			-- more inclined to colonize when over foraging more than CC allows
			if foragers_limit < DATA.province_get_foragers(capitol) then
				base = base * 2
			-- less likely to spread if well uncer CC allows
			elseif foragers_limit > DATA.province_get_foragers(capitol) * 2 then
				base = base * 0.5
			end
			-- more inclined to colonize when over pop weight is higher than CC
			local pop_weight = province_utils.population_weight(capitol)
			if foragers_limit < pop_weight then
				base = base * 2
			-- less likely to spread if well uncer CC allows
			elseif foragers_limit >  DATA.province_get_foragers(capitol) * 2 then
				base = base * 0.5
			end

			-- trait based variance

			for i = 1, MAX_TRAIT_INDEX do
				local trait = DATA.pop_get_traits(root, i)
				if trait == TRAIT.INVALID then
					break
				end
				if trait == TRAIT.AMBITIOUS then
					base = base * 2
				end
				if trait == TRAIT.CONTENT then
					base = base * 0.5
				end
				if trait == TRAIT.HARDWORKER then
					base = base * 2
				end
				if trait == TRAIT.LAZY then
					base = base * 0.5
				end
			end

			return base
		end,
		effect = function(root, primary_target, secondary_target)
			DATA.pop_set_busy(root, true)

			-- colonizing cost calories for travel
			-- need at least so many family units to migrate

			-- colonizing cost calories for travel
			local travel_time = path.pathfind(
				PROVINCE(root),
				primary_target,
				character_values.travel_speed_race(MAIN_RACE(REALM(root))),
				DATA.realm_get_known_provinces(REALM(root))
			)
			travel_time = path.hours_to_travel_days(travel_time)

			local calorie_cost = 0
			local realm = REALM(root)
			local capitol = DATA.realm_get_capitol(realm)
			local race = DATA.realm_get_primary_race(realm)
			local male_ratio = DATA.race_get_males_per_hundred_females(race)
			local savings = DATA.pop_get_savings(root)

			for i = 1, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
				local need = DATA.race_get_male_needs_need(race, i)
				if need == NEED.INVALID then
					break
				end
				local use = DATA.race_get_male_needs_use_case(race, i)

				if use == CALORIES_USE_CASE then
					local male_intake = DATA.race_get_male_needs_required(race, i)
					local female_intake = DATA.race_get_female_needs_required(race, i)

					calorie_cost = (
						100 * female_intake
						+ male_ratio * male_intake
					) / (100 + male_ratio) * travel_time / 5
				end
			end

			local character_calories_in_inventory = economy_values.available_use_case_from_inventory(root, CALORIES_USE_CASE)
			local remaining_calories_needed = math.max(0, calorie_cost - character_calories_in_inventory)
			local can_buy_calories, buy_reasons = et.can_buy_use(capitol, savings, CALORIES_USE_CASE, remaining_calories_needed + 0.01)

			-- convincing people to move takes money but amount depends on pops willingness to move, base payment the price of upto 10 units of food per family
			local pop_payment =
				colonisation_cost * 6
				* realm_utils.get_average_needs_satisfaction(realm)
				* economical.get_local_price_of_use(capitol, CALORIES_USE_CASE)

			assert(pop_payment == pop_payment,
				tostring(colonisation_cost) .. " "
				.. tostring(realm_utils.get_average_needs_satisfaction(realm)) .. " "
				.. tostring(economical.get_local_price_of_use(capitol, CALORIES_USE_CASE))
			)

			local calorie_price_expectation = economical.get_local_price_of_use(capitol, CALORIES_USE_CASE)

			local expected_calorie_cost = math.max(0, calorie_cost - character_calories_in_inventory) * calorie_price_expectation

			local leader = nil
			local organizer = root
			if not ot.decides_foreign_policy(root, realm) then
				leader = root
				organizer = LEADER(realm)
			end

			---@type MigrationData
			local migration_data = {
				invasion = false,
				organizer = organizer,
				leader = leader,
				travel_cost = calorie_cost,
				pop_payment = pop_payment,
				origin_province = PROVINCE(root),
				target_province = primary_target
			}
			if ot.decides_foreign_policy(root, realm) then
				-- buy remaining calories from market
				economic_effects.character_buy_use(root, CALORIES_USE_CASE, remaining_calories_needed)
				-- consume food from character inventory
				economic_effects.consume_use_case_from_inventory(root, CALORIES_USE_CASE, calorie_cost)
				-- give out payment to expedition
				economic_effects.change_treasury(realm, -pop_payment, ECONOMY_REASON.COLONISATION)
				WORLD:emit_immediate_action('migration-colonize', root, migration_data)
			else
				WORLD:emit_immediate_event('request-migration-colonize', migration_data.organizer, migration_data)
			end
		end
	}
end

return load
