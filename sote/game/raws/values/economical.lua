local good = require "game.raws.raws-utils".trade_good

local traits = require "game.raws.traits.generic"

local eco_values = {}

---comment
---@param realm Realm
function eco_values.potential_monthly_tribute_size(realm)
    return realm.budget.saved_change * 0.1
end

---comment
---@param realm Realm
function eco_values.raidable_treasury(realm)
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
	return data.base_price * bought / (sold + 0.25) -- the "plus" is there to prevent division by 0
end

---comment
---@param province Province
---@param trade_good TradeGoodReference
---@return number price
function eco_values.get_local_price(province, trade_good)
    local sold = (province.local_production[trade_good] or 0) + (province.local_storage[trade_good] or 0) / 12
    local bought = province.local_consumption[trade_good] or 0
    local data = good(trade_good)
    return data.base_price * bought / (sold + 0.25) -- the "plus" is there to prevent division by 0
end

---comment
---@param province Province
---@param trade_good TradeGoodReference
---@param amount number
---@return number price
function eco_values.get_pessimistic_local_price(province, trade_good, amount)
    local sold = (province.local_production[trade_good] or 0) + amount + (province.local_storage[trade_good] or 0) / 12
    local bought = province.local_consumption[trade_good] or 0
    local data = good(trade_good)
    return data.base_price * bought / (sold + 0.25) -- the "plus" is there to prevent division by 0
end

return eco_values