local tabb = require "engine.table"

local pop_utils = require "game.entities.pop".POP
local realm_utils = require "game.entities.realm".Realm

local diplomacy_triggers = require "game.raws.triggers.diplomacy"

local pv = require "game.raws.values.politics"
local ev = require "game.raws.values.economy"
local demography_values = require "game.raws.values.demography"
local character_values = require "game.raws.values.character"
local diplomacy_values = require "game.raws.values.diplomacy"


local AiPreferences = {}

---comment
---@param character Character
---@return number
function AiPreferences.percieved_inflation(character)
	local use = CALORIES_USE_CASE
	local base_price = 0
	local count = 0

	DATA.for_each_use_weight_from_use_case(use, function (item)
		local weighted_good = DATA.use_weight_get_trade_good(item)
		local weight = DATA.use_weight_get_weight(item)
		base_price = base_price + DATA.trade_good_get_base_price(weighted_good) * weight
		count = count + 1
	end)

	base_price = base_price / math.max(count, 1)

	local price = ev.get_local_price_of_use(PROVINCE(character), use)
	if price == 0 then
		price = base_price
	end
	return price / base_price
end

---comment
---@param character Character
function AiPreferences.money_utility(character)
	local base = 0.1
	if HAS_TRAIT(character, TRAIT.GREEDY) then
		base = 0.2
	end
	return base / AiPreferences.percieved_inflation(character)
end

function AiPreferences.saving_goal(character)
	return AiPreferences.money_utility(character) * 10
end

function AiPreferences.construction_funds(character)
	return math.max(0, DATA.pop_get_savings(character) - AiPreferences.saving_goal(character))
end

---comment
---@param character Character
---@param candidate Character
---@return number
function AiPreferences.worthy_successor_score(character, candidate)
	local loyalty_bonus = 0
	if LOYAL_TO(candidate) == character then
		loyalty_bonus = 10
	end

	local score =
		pv.popularity(candidate, REALM(character))
		+ loyalty_bonus

	return score
end

---comment
---@param character Character
function AiPreferences.best_successor(character)
	---@type Character?
	local best_candidate = nil
	local best_score = 0

	DATA.for_each_character_location_from_location(PROVINCE(character), function (item)
		local candidate = DATA.character_location_get_character(item)
		if best_candidate == nil then
			best_candidate = candidate
		else
			local score = AiPreferences.worthy_successor_score(character, candidate)
			if score > best_score then
				best_candidate = candidate
				best_score = score
			end
		end
	end)
	return best_candidate
end

---comment
---@param character Character
---@return number
function AiPreferences.loyalty_price(character)
	local popularity = pv.popularity(character, REALM(character))

	return AiPreferences.percieved_inflation(character) * (10 + popularity) * 2
end

---@class (exact) AIDecisionFlags
---@field treason boolean?
---@field ambition boolean?
---@field help boolean?
---@field submission boolean?
---@field work boolean?
---@field aggression boolean?
---@field power_abuse boolean?


---generates callback which calculates ai preference on demand
---@param character Character
---@param income number
---@param flags AIDecisionFlags
---@return fun(): number
function AiPreferences.generic_event_option_untargeted(character, income, flags)
	return function()
		---@type Character
		character = character

		if income + SAVINGS(character) then
			return -9999
		end

		local base_value = income * AiPreferences.money_utility(character)

		if flags.treason then
			base_value = base_value + DATA.pop_get_culture(character).culture_group.view_on_treason
		end

		if flags.treason and HAS_TRAIT(character, TRAIT.LOYAL) then
			base_value = base_value - 100
		end

		if flags.submission then
			base_value = base_value - 10
		end

		if flags.submission and HAS_TRAIT(character, TRAIT.AMBITIOUS) then
			base_value = base_value - 50
		end

		if flags.ambition then
			base_value = base_value + 100 * character_values.ambition_score(character)
		end

		if flags.work and HAS_TRAIT(character, TRAIT.LAZY) then
			base_value = base_value - 20
		end

		if flags.work and HAS_TRAIT(character, TRAIT.HARDWORKER) then
			base_value = base_value + 20
		end

		if flags.aggression then
			base_value = base_value + 100 * character_values.aggression_score(character)
		end

		if flags.power_abuse then
			base_value = base_value - 25
		end

		return base_value
	end
end

---generates callback which calculates ai preference on demand
---@param character Character
---@param associated_data Character
---@param income number
---@param flags AIDecisionFlags
---@return fun(): number
function AiPreferences.generic_event_option(character, associated_data, income, flags)
	return function()
		---@type Character
		character = character

		if income + SAVINGS(character) < 0 then
			return -9999
		end
		-- print(NAME(character))

		local base_value = income * AiPreferences.money_utility(character)

		-- print(base_value)

		if flags.treason then
			base_value = base_value + DATA.pop_get_culture(character).culture_group.view_on_treason
		end

		if flags.treason and HAS_TRAIT(character, TRAIT.LOYAL) then
			base_value = base_value - 100
		end

		if flags.help and LOYAL_TO(character) == associated_data then
			base_value = base_value + 10
			if HAS_TRAIT(character, TRAIT.LOYAL) then
				---@type number
				base_value = base_value + 10
			end
		end

		if flags.submission then
			base_value = base_value - 10
		end

		if flags.submission and HAS_TRAIT(character, TRAIT.AMBITIOUS) then
			base_value = base_value - 50
		end

		if flags.ambition then
			base_value = base_value + 100 * character_values.ambition_score(character)
		end

		if flags.work and HAS_TRAIT(character, TRAIT.LAZY) then
			base_value = base_value - 20
		end

		if flags.work and HAS_TRAIT(character, TRAIT.HARDWORKER) then
			base_value = base_value + 20
		end

		if flags.aggression then
			base_value = base_value + 100 * character_values.aggression_score(character)
		end

		if flags.power_abuse then
			base_value = base_value - 25
		end

		return base_value
	end
end

---commenting
---@param root Character
function AiPreferences.sample_random_candidate(root)
	local p = PROVINCE(root)
	assert(p ~= INVALID_ID)
	local candidate = demography_values.sample_character_from_province(p)
	if candidate == nil then
		return nil, false
	end
	return candidate, true
end

function AiPreferences.condition_to_sampler(condition)
	return function (root)
		local p = PROVINCE(root)
		assert(p ~= INVALID_ID)
		local candidate = demography_values.sample_character_from_province(p)
		if candidate == nil then
			return nil, false
		end
		if condition(candidate) then
			return candidate, true
		end
		return nil, false
	end
end

---commenting
---@param root Character
---@return Province|nil
function AiPreferences.sample_raiding_target(root)
	---@type Province[]
	local targets = {}

	for _, province in pairs(DATA.realm_get_known_provinces(REALM(root))) do
		if PROVINCE_REALM(province) == INVALID_ID then
			goto continue
		end

		if diplomacy_triggers.pays_tribute_to(REALM(root), PROVINCE_REALM(province)) then
			goto continue
		end

		if diplomacy_triggers.pays_tribute_to(PROVINCE_REALM(province), REALM(root)) then
			goto continue
		end

		if realm_utils.neighbors_realm(REALM(root), PROVINCE_REALM(province)) then
			table.insert(targets, province)
		end

		::continue::
	end

	for province, reward in pairs(DATA.realm_get_quests_raid(REALM(root))) do
		table.insert(targets, province)
	end

	return tabb.random_select_from_array(targets)
end

return AiPreferences
