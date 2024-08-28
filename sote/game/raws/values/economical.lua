local tabb = require "engine.table"

local good = require "game.raws.raws-utils".trade_good
local use_case = require "game.raws.raws-utils".trade_good_use_case

local traits = require "game.raws.traits.generic"

local eco_values = {}

---comment
---@param realm Realm
function eco_values.potential_monthly_tribute_size(realm)
    return realm.budget.saved_change * 0.1
end

---Returns amount of wealth character would want in exchange for paying tribute \
---It's calculated as a part of savings of pops of his tribe which somewhat represents wellbeing of it
---@param realm Realm
function eco_values.realm_independence_price(realm)
    local total = 0

    for _, pop in pairs(realm.capitol.all_pops) do
        total = total + pop.savings
    end

    return total * 0.5 + 50
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
---@param province Province
---@param trade_good trade_good_id
---@return number price
function eco_values.get_local_price(province, trade_good)
    if province.local_prices[trade_good] == nil then
        province.local_prices[trade_good] = 0.0001
    end
    return province.local_prices[trade_good]
end

---commenting
---@param province Province
---@param use use_case_id
---@return number sum_of_exponents
---@return number min_price
local function soft_max_data_for_use(province, use)
    local min_price = nil
    for _, weight_id in pairs(DATA.use_weight_from_use_case[use]) do
        local trade_good = DATA.use_weight_get_trade_good(weight_id)
        local price = eco_values.get_local_price(province, trade_good)
        if min_price == nil then
            min_price = price
        elseif min_price > price then
            min_price = price
        end
    end

    local sum = 0
    for _, weight_id in pairs(DATA.use_weight_from_use_case[use]) do
        local trade_good = DATA.use_weight_get_trade_good(weight_id)
        local price = eco_values.get_local_price(province, trade_good)
        sum = sum + math.exp(-price + min_price)
    end

    return sum, min_price
end

---calculates price estimation of unit of use
---@param province Province
---@param use use_case_id
---@return number price
function eco_values.get_local_price_of_use(province, use)
    -- local sold = (province.local_production[trade_good] or 0) + (province.local_storage[trade_good] or 0) / 12
    -- local bought = province.local_consumption[trade_good] or 0

    local sum_of_exponents, min_price = soft_max_data_for_use(province, use)

    -- calculate cost
    local total_cost = 0
    for _, weight_id in pairs(DATA.use_weight_from_use_case[use]) do
        local trade_good = DATA.use_weight_get_trade_good(weight_id)
        local weight = DATA.use_weight_get_weight(weight_id)
        local price = eco_values.get_local_price(province, trade_good)
        local prob_density = math.exp(-price + min_price) / sum_of_exponents
        local bought = 1 / weight * prob_density
        total_cost = total_cost + bought * price
    end

    return total_cost
end

---calculates price estimation of unit of use given a price table
---@param province Province
---@param use use_case_id
---@param prices table<trade_good_id, number>
---@return number price
function eco_values.get_local_price_of_use_with_prices(province, use, prices)
    -- calculate min of prices:
    local min_price = nil

    for _, weight_id in pairs(DATA.use_weight_from_use_case[use]) do
        local trade_good = DATA.use_weight_get_trade_good(weight_id)
        local price = prices[trade_good]
        if min_price == nil then
            min_price = price
        else
            min_price = math.min(prices[trade_good], min_price)
        end
    end

    -- calculate sum of exponents
    local sum_of_exponents = 0
    for _, weight_id in pairs(DATA.use_weight_from_use_case[use]) do
        local trade_good = DATA.use_weight_get_trade_good(weight_id)
        local price = prices[trade_good]
        sum_of_exponents = sum_of_exponents + math.exp(
            -price + min_price
        )
    end

    sum_of_exponents = sum_of_exponents

    -- calculate cost
    local total_cost = 0
    for _, weight_id in pairs(DATA.use_weight_from_use_case[use]) do
        local trade_good = DATA.use_weight_get_trade_good(weight_id)
        local price = prices[trade_good]
        local weight = DATA.use_weight_get_weight(weight_id)
        local prob_density = math.exp(-price + min_price) / sum_of_exponents
        local bought = 1 / weight * prob_density
        total_cost = total_cost + bought * price
    end

    return total_cost
end

---comment
---@param province Province
---@param trade_good trade_good_id
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
function eco_values.projected_income_building_type_unknown_pop(province, building_type)
    local shortage_modifier = eco_values.estimate_shortage(province, building_type.production_method)
    local income = 0
    for input, amount in pairs(building_type.production_method.inputs) do
        local price = eco_values.get_local_price_of_use(province, input)
        local spent = price * amount
        income = income - spent
    end
    for output, amount in pairs(building_type.production_method.outputs) do
        local price = eco_values.get_pessimistic_local_price(province, output, amount, false)
        local earnt = price * amount
        ---@type number
        income = income + earnt
    end

    return income * shortage_modifier
end

---@param province Province
---@param building_type BuildingType
---@param race Race
---@param female boolean
function eco_values.projected_income_building_type(province, building_type, race, female)
    local shortage_modifier = eco_values.estimate_shortage(province, building_type.production_method)
    local income = 0
    for input, amount in pairs(building_type.production_method.inputs) do
        local price = eco_values.get_local_price_of_use(province, input)
        local spent = price * amount
        income = income - spent
    end
    for input, amount in pairs(building_type.production_method.outputs) do
        local price = eco_values.get_pessimistic_local_price(province, input, amount, false)
        local earnt = price * amount * eco_values.race_output_multiplier(race, female, building_type)
        ---@type number
        income = income + earnt
    end

    return income * shortage_modifier
end


---Does not account for shortages: displays info based only on prices
---@param building Building
---@param race Race
---@param female boolean
---@param prices table<trade_good_id, number>
---@param efficiency number
---@return number income, number input_boost, number output_boost, number throughput_boost
function eco_values.projected_income(building, race, female, prices, efficiency)
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

    local income = 0
    for input, amount in pairs(building.type.production_method.inputs) do
        local price = eco_values.get_local_price_of_use_with_prices(province, input, prices)
        local spent = price * amount * efficiency * throughput_boost * input_boost
        income = income - spent
    end

    income = income
    for output, amount in pairs(building.type.production_method.outputs) do
        local price = prices[output]
        local earnt = price * amount * efficiency * throughput_boost * output_boost
        income = income + earnt
    end

    return income, input_boost, output_boost, throughput_boost
end

---commenting
---@param province Province
---@param use use_case_id
---@return number
function eco_values.available_use(province, use)
    -- calculate min of prices:
    local sum_of_exponents, min_price = soft_max_data_for_use(province, use)

    -- calculate total amount available for this distribution
    local available_use = 0
    -- use is divided between
    for _, weight_id in pairs(DATA.use_weight_from_use_case[use]) do
        local trade_good = DATA.use_weight_get_trade_good(weight_id)
        local weight = DATA.use_weight_get_weight(weight_id)

        local price = eco_values.get_local_price(province, trade_good)
        local ratio_of_good = math.exp(-price + min_price) / sum_of_exponents
        local available = (province.local_production[trade_good] or 0)
                        - (province.local_consumption[trade_good] or 0)
                        + (province.local_storage[trade_good] or 0)

        local upped_bound = available * weight / ratio_of_good


        available_use = available_use + upped_bound
    end

    return available_use
end

---returns total amount of unit of use in local stockpile
---@param province Province
---@param use use_case_id
---@return number total_amount
function eco_values.get_local_amount_of_use(province, use)
    local total_amount = 0
    for _, weight_id in pairs(DATA.use_weight_from_use_case[use]) do
        local trade_good = DATA.use_weight_get_trade_good(weight_id)
        local weight = DATA.use_weight_get_weight(weight_id)
        total_amount = total_amount + (province.local_storage[trade_good] or 0) * weight
    end

    return total_amount
end

---Estimates shortage_modifier
---@param prod ProductionMethod
function eco_values.estimate_shortage(province, prod)
    local input_satisfaction = 1
    for input, amount in pairs(prod.inputs) do
        local required_input = amount
        local available = eco_values.available_use(province, input)
        local ratio = math.max(0, available) / required_input
        input_satisfaction = math.min(input_satisfaction, ratio)
    end

    return math.min(1, input_satisfaction)
end

return eco_values