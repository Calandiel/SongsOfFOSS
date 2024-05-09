local tabb = require "engine.table"

local TRAIT = require "game.raws.traits.generic"
local trade_good = require "game.raws.raws-utils".trade_good
local use_case = require "game.raws.raws-utils".trade_good_use_case

local AiPreferences = {}

local pv = require "game.raws.values.political"
local ev = require "game.raws.values.economical"


---comment
---@param character Character
---@return number
function AiPreferences.percieved_inflation(character)
	local use = use_case('calories')
	local base_price = tabb.accumulate(use.goods, 0, function (a, k, v)
		return a + trade_good(k).base_price * v
	end) / math.min(tabb.size(use.goods), 1)
	local price = ev.get_local_price_of_use(character.province, 'calories')
	if price == 0 then
		price = base_price
	end
	return price / base_price
end

---comment
---@param character Character
function AiPreferences.money_utility(character)
	local base = 0.1
	if character.traits[TRAIT.GREEDY] then
		base = 1
	end
	return base / AiPreferences.percieved_inflation(character)
end

function AiPreferences.saving_goal(character)
	return AiPreferences.money_utility(character) * 10
end

function AiPreferences.construction_funds(character)
	return math.max(0, character.savings - AiPreferences.saving_goal(character))
end

---comment
---@param character Character
---@param candidate Character
---@return number
function AiPreferences.worthy_successor_score(character, candidate)
	local loyalty_bonus = 0
	if candidate.loyalty == character then
		loyalty_bonus = 10
	end

	local score =
		pv.popularity(candidate, character.realm)
		+ loyalty_bonus

	return score
end

---comment
---@param character Character
function AiPreferences.best_successor(character)
	---@type Character?
	local best_candidate = nil
	for _, candidate in pairs(character.province.characters) do
		if best_candidate == nil then
			best_candidate = candidate
		else
			local best_score = AiPreferences.worthy_successor_score(character, best_candidate)
			local score = AiPreferences.worthy_successor_score(character, candidate)
			if score > best_score then
				best_candidate = candidate
			end
		end
	end
	return best_candidate
end

---comment
---@param character Character
---@return number
function AiPreferences.loyalty_price(character)
	local popularity = pv.popularity(character, character.realm)

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

		if income + character.savings < 0 then
			return -9999
		end

		local base_value = income * AiPreferences.money_utility(character)

		if flags.treason then
			base_value = base_value + character.culture.culture_group.view_on_treason
		end
		if flags.treason and character.traits[TRAIT.LOYAL] then
			base_value = base_value - 100
		end

		if flags.submission then
			base_value = base_value - 10
		end

		if flags.submission and character.traits[TRAIT.AMBITIOUS] then
			base_value = base_value - 50
		end

		if flags.ambition and character.traits[TRAIT.AMBITIOUS] then
			base_value = base_value + 50
		end

		if flags.ambition and character.traits[TRAIT.CONTENT] then
			base_value = base_value - 10
		end

		if flags.work and character.traits[TRAIT.LAZY] then
			base_value = base_value - 20
		end

		if flags.work and character.traits[TRAIT.HARDWORKER] then
			base_value = base_value + 20
		end

		if flags.aggression and character.traits[TRAIT.WARLIKE] then
			base_value = base_value + 20
		end

		if flags.aggression and character.traits[TRAIT.CONTENT] then
			base_value = base_value - 20
		end

		if flags.aggression and character.traits[TRAIT.LAZY] then
			base_value = base_value - 20
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

		if income + character.savings < 0 then
			return -9999
		end
		-- print(character.name)

		local base_value = income * AiPreferences.money_utility(character)

		-- print(base_value)

		if flags.treason then
			base_value = base_value + character.culture.culture_group.view_on_treason
		end

		-- print(base_value)

		if flags.treason and character.traits[TRAIT.LOYAL] then
			base_value = base_value - 100
		end

		-- print(base_value)

		if flags.help and character.traits[TRAIT.LOYAL] and character.loyalty == associated_data then
			base_value = base_value + 10
		end

		-- print(base_value)

		if flags.submission then
			base_value = base_value - 10
		end

		-- print(base_value)

		if flags.submission and character.traits[TRAIT.AMBITIOUS] then
			base_value = base_value - 50
		end

		-- print(base_value)

		if flags.ambition and character.traits[TRAIT.AMBITIOUS] then
			base_value = base_value + 50
		end

		if flags.ambition and character.traits[TRAIT.CONTENT] then
			base_value = base_value - 10
		end

		if flags.work and character.traits[TRAIT.LAZY] then
			base_value = base_value - 20
		end

		if flags.work and character.traits[TRAIT.HARDWORKER] then
			base_value = base_value + 20
		end

		if flags.aggression and character.traits[TRAIT.WARLIKE] then
			base_value = base_value + 20
		end

		if flags.aggression and character.traits[TRAIT.CONTENT] then
			base_value = base_value - 20
		end

		if flags.aggression and character.traits[TRAIT.LAZY] then
			base_value = base_value - 20
		end

		if flags.power_abuse then
			base_value = base_value - 10
		end

		-- print(base_value)

		-- print('______________________________')

		return base_value
	end
end

return AiPreferences
