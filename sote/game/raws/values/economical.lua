local tabb = require "engine.table"

local good = require "game.raws.raws-utils".trade_good

local traits = require "game.raws.traits.generic"

local eco_values = {}

---comment
---@param realm Realm
function eco_values.potential_monthly_tribute_size(realm)
    return realm.budget.saved_change * 0.1
end

---comment
---@param realm Realm?
function eco_values.raidable_treasury(realm)
    if realm == nil then return 0 end
    return math.max(0, realm.budget.treasury * 0.1)
end

---comment
---@param building_type BuildingType
---@param public boolean
---@param overseer Character?
---@return number
function eco_values.building_cost(building_type, overseer, public)
    local cost_multiplier = 1

    -- overseer effect
    if overseer == nil then
        cost_multiplier = 2
    else
        if overseer.traits[traits.BAD_ORGANISER] then
            cost_multiplier = cost_multiplier * 1.5
        end
        if overseer.traits[traits.GOOD_ORGANISER] then
            cost_multiplier = cost_multiplier * 0.5
        end
    end

    if public then
        cost_multiplier = cost_multiplier * 0.8
    end

    return building_type.construction_cost * cost_multiplier
end

---comment
---@param realm Realm
---@param trade_good TradeGoodReference
---@return number price
function eco_values.get_realm_price(realm, trade_good)
	local bought = realm.bought[trade_good] or 0
	local sold = realm.sold[trade_good] or 0
	local data = good(trade_good)
	return data.base_price * bought / (sold + 0.25) -- the "plus" is there to prevent division by 0
end

---Calculates a "pessimistic" prise (that is, the price that we'd get if we tried to sell more goods after selling the goods given)
---@param realm Realm
---@param trade_good TradeGoodReference
---@param amount number
---@return number price
function eco_values.get_pessimistic_realm_price(realm, trade_good, amount)
	local bought = realm.bought[trade_good] or 0
	bought = bought + amount
	local sold = realm.sold[trade_good] or 0
	local data = good(trade_good)

    -- the "plus" is there to prevent division by 0 and smooth prices when supply or demand is far too low
    local pessimistic_price = data.base_price * (bought + 1) / (sold + 1)
    local optimistic_price = eco_values.get_realm_price(realm, trade_good)

    -- We need to take an average because otherwise selling by one will be far
    -- more profitable. Which rewards boring micromanagement.
	return (optimistic_price + pessimistic_price) / 2
end

---comment
---@param province Province
---@param trade_good TradeGoodReference
---@return number price
function eco_values.get_local_price(province, trade_good)
    -- local sold = (province.local_production[trade_good] or 0) + (province.local_storage[trade_good] or 0) / 12
    -- local bought = province.local_consumption[trade_good] or 0
    local data = good(trade_good)

    -- the "plus" is there to prevent division by 0 and smooth prices when supply or demand is far too low
    -- local price =  data.base_price * (bought + 1) / (sold + 1)

    if province.local_prices[trade_good] == nil then
        province.local_prices[trade_good] = 0.01
    end
    return province.local_prices[trade_good]
end

---comment
---@param province Province
---@param trade_good TradeGoodReference
---@param amount number
---@param stockpile boolean
---@return number price
function eco_values.get_pessimistic_local_price(province, trade_good, amount, stockpile)
    local sold = province.local_production[trade_good] or 0
    local bought = province.local_consumption[trade_good] or 0
    local trade_volume = sold + bought + 0.001 + amount

    local sale_price_decrease = PRICE_SIGNAL_PER_STOCKPILED_UNIT * amount / trade_volume
    if not stockpile then
        sale_price_decrease = PRICE_SIGNAL_PER_UNIT * amount / (trade_volume + amount)
    end

    local pessimistic_price = math.max(0, (eco_values.get_local_price(province, trade_good) - sale_price_decrease))
    local optimistic_price = eco_values.get_local_price(province, trade_good)

    -- We need to take an average because otherwise selling by one will be far
    -- more profitable. Which rewards boring micromanagement.
    return (optimistic_price + pessimistic_price) / 2
end

---@param race Race
---@param female boolean
---@param building_type BuildingType
function eco_values.race_throughput_multiplier(race, female, building_type)
    local job = tabb.nth(building_type.production_method.jobs, 1)
    if job == nil then
        return 1
    end

    if female then
        return race.female_efficiency[building_type.production_method.job_type]
    end
    return race.male_efficiency[building_type.production_method.job_type]
end

---@param race Race
---@param female boolean
---@param building_type BuildingType
function eco_values.race_output_multiplier(race, female, building_type)
    local job = tabb.nth(building_type.production_method.jobs, 1)
    if job == nil then
        return 1
    end

    if female then
        return race.female_efficiency[building_type.production_method.job_type]
    end
    return race.male_efficiency[building_type.production_method.job_type]
end

---@param province Province
---@param building_type BuildingType
---@param race Race
---@param female boolean
function eco_values.projected_income_building_type(province, building_type, race, female)
    local income = 0
    for input, amount in pairs(building_type.production_method.inputs) do
        local price = eco_values.get_local_price(province, input)
        local spent = price * amount
        income = income - spent
    end
    for input, amount in pairs(building_type.production_method.outputs) do
        local price = eco_values.get_pessimistic_local_price(province, input, amount, false)
        local earnt = price * amount * eco_values.race_output_multiplier(race, female, building_type)
        ---@type number
        income = income + earnt
    end

    return income
end

---comment
---@param building Building
---@param race Race
---@param female boolean
---@param prices table<TradeGoodReference, number>
---@param efficiency number
---@param update_building_stats boolean
---@return number income, number input_boost, number output_boost, number throughput_boost
function eco_values.projected_income(building, race, female, prices, efficiency, update_building_stats)
    local province = building.province
    local production_method = building.type.production_method

    local throughput_boost =
        (1 + (province.throughput_boosts[production_method] or 0))
        * eco_values.race_throughput_multiplier(race, female, building.type)

    local input_boost =
        math.max(0, 1 - (province.input_efficiency_boosts[production_method] or 0))

    local output_boost =
        (1 + (province.output_efficiency_boosts[production_method] or 0))
        * eco_values.race_output_multiplier(race, female, building.type)

    -- if depends on forests, then reduce local forest coverage over time
    -- sample random tile from province to avoid weird looking pimples
    if production_method.forest_dependence > 0 then
        local years_to_deforestate = 50
        local days_to_deforestate = years_to_deforestate * 360
        local total_power = production_method.forest_dependence * efficiency * throughput_boost * input_boost / days_to_deforestate
        if update_building_stats then
            require "game.raws.effects.geography".deforest_random_tile(province, total_power)
        end
    end

    local income = 0
    for input, amount in pairs(building.type.production_method.inputs) do
        local price = prices[input]
        local spent = price * amount * efficiency * throughput_boost * input_boost

        income = income - spent
        if update_building_stats then
            building.spent_on_inputs[input] = (building.spent_on_inputs[input] or 0) + spent
        end
    end

    income = income
    for output, amount in pairs(building.type.production_method.outputs) do
        local price = prices[output]
        local earnt = price * amount * efficiency * throughput_boost * output_boost
        income = income + earnt

        if update_building_stats then
            building.earn_from_outputs[output] = (building.earn_from_outputs[output] or 0) + earnt
        end
    end

    return income, input_boost, output_boost, throughput_boost
end

---Estimates shortage_modifier
---@param prod ProductionMethod
function eco_values.estimate_shortage(province, prod)
    local input_satisfaction = 0
    for input, amount in pairs(prod.inputs) do
        local required_input = amount
        local available =
            (province.local_production[input] or 0)
            - (province.local_consumption[input] or 0)
            + (province.local_storage[input] or 0)

        local ratio = math.max(0, available) / required_input
        input_satisfaction = math.min(input_satisfaction, ratio)
    end
    local shortage_modifier =
        (1 - prod.self_sourcing_fraction) * (1 - input_satisfaction)
        + 1 * input_satisfaction

    return shortage_modifier
end

return eco_values