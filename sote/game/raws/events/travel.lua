local ut = require "game.ui-utils"

local warband_utils = require "game.entities.warband"

local Event = require "game.raws.events"
local event_utils = require "game.raws.events._utils"
local ge = require "game.raws.effects.generic"

local economy_effects = require "game.raws.effects.economy"
local economy_values = require "game.raws.values.economy"
local et = require "game.raws.triggers.economy"

local retrieve_use_case = require "game.raws.raws-utils".trade_good_use_case

local function load()
    Event:new {
        name = "travel-start-action",
        automatic = false,
        event_background_path = "data/gfx/backgrounds/background.png",
        base_probability = 0,

        on_trigger = function (self, root, associated_data)
            ---@type TravelData
            associated_data = associated_data
            local party = LEADER_OF_WARBAND(root)
            assert(party ~= INVALID_ID)
            DATA.warband_set_current_status(party, WARBAND_STATUS.TRAVELLING)
            economy_effects.consume_supplies(party, associated_data.travel_time)
            WORLD:emit_action("travel", root, associated_data.destination, associated_data.travel_time, true)
        end
    }

    Event:new {
        name = "travel-start",
        automatic = false,
        event_background_path = "data/gfx/backgrounds/background.png",
        base_probability = 0,

        event_text = function (self, root, associated_data)
            ---@type TravelData
            associated_data = associated_data

            local action = "travel"
            if associated_data.goal == "migration" then
                action = "migrate"
            end

            local text =
                "We plan to " .. action .. " toward " .. PROVINCE_NAME(associated_data.destination) .. ". " ..
                "We will spend " .. ut.to_fixed_point2(associated_data.travel_time) .. " days. " ..
                "We have enough supplies to travel for " .. ut.to_fixed_point2(economy_values.days_of_travel(LEADER_OF_WARBAND(root))) .. " days."

            return text
        end,

        options = function (self, root, associated_data)
            ---@type TravelData
            associated_data = associated_data

            ---@type EventOption
            local option_proceed = {
                text = "Start the journey.",
                tooltip = "We depart from the province",
                ai_preference = function ()
                    return 1
                end,
                outcome = function ()
                    local party = LEADER_OF_WARBAND(root)
                    assert(party ~= INVALID_ID)
                    DATA.warband_set_current_status(party, WARBAND_STATUS.TRAVELLING)
                    economy_effects.consume_supplies(party, associated_data.travel_time)
                    WORLD:emit_action("travel", root, associated_data.destination, associated_data.travel_time, true)
                end,
                viable =function ()
                    return true
                end
            }

            return {
                option_proceed,
                event_utils.option_stop("I am not ready", "Abandon the journey", 0, root)
            }
        end
    }

    Event:new {
		name = "travel",
		automatic = false,
        base_probability = 0,
        event_background_path = "data/gfx/backgrounds/background.png",
		on_trigger = function(self, root, associated_data)
			---@type Province
			associated_data = associated_data

            if DEAD(root) then
                return
            end

            ge.travel(root, associated_data)

            if LEADER_OF_WARBAND(root) ~= INVALID_ID then
                DATA.warband_set_current_status(LEADER_OF_WARBAND(root), WARBAND_STATUS.IDLE)
            end
            UNSET_BUSY(root)

            if root == WORLD.player_character and OPTIONS["travel-end"] == 0 then
                WORLD:emit_immediate_event('travel-end-notification', root, associated_data)
            end

            if root == WORLD.player_character and OPTIONS["travel-end"] == 2 then
                PAUSE_REQUESTED = true
            end
		end,
	}

    event_utils.notification_event(
        "travel-end-notification",
        function (self, root, data)
            ---@type Province
            data = data
            return "I have arrived at " .. PROVINCE_NAME(data) .. ". "
                .. "This land is controlled by people of " .. REALM_NAME(PROVINCE_REALM(data)) .. ". "
                .. F_RACE(LEADER(PROVINCE_REALM(data))).name .. " " .. NAME(LEADER(PROVINCE_REALM(data))) .. " rules over them."
        end,
        function (root, data)
            return "Finally!"
        end,
        function (root, data)
            return "What should I do now?"
        end
    )


    Event:new {
        name = "buy-goods",
        automatic = false,
        event_background_path = "data/gfx/backgrounds/background.png",
        base_probability = 0,

        options = function(self, root, associated_data)
            local options_list = {}
            local province = PROVINCE(root)

            if province == nil then
                return {
                    {
                        text = "Something is wrong",
                        tooltip = "Province is nil",
                        viable = function() return true end,
                        outcome = function()
                        end,
                        ai_preference = function()
                            return 0.5
                        end
                    }
                }
            end

            local function generate_option(trade_good)
                local price = economy_values.get_local_price(province, trade_good)
                local known_price = DATA.pop_get_price_memory(root, trade_good)

                local bought_amount = math.max(
                    1,
                    (math.floor(
                        SAVINGS(root) * 0.25
                        / (known_price + 0.01)
                        * math.random()
                    ))
                )

                bought_amount = math.min(bought_amount, DATA.province_get_local_storage(province, trade_good))

                local can_buy, _ = et.can_buy(root, trade_good, bought_amount)
                if can_buy then
                    ---@type EventOption
                    local option = {
                        text = "Buy " .. DATA.trade_good_get_name(trade_good) .. " for " .. ut.to_fixed_point2(price) .. MONEY_SYMBOL,
                        -- tooltip = "Buy " .. name .. " for " .. ut.to_fixed_point2(price) .. MONEY_SYMBOL,
                        tooltip = "Ai_pref " .. (known_price - price - 0.05) / (known_price + 0.05),
                        viable = function() return true end,
                        outcome = function()
                            economy_effects.buy(root, trade_good, bought_amount)
                        end,
                        ai_preference = function()
                            return (known_price - price - 0.05) / (known_price + 0.05)
                        end
                    }
                    table.insert(options_list, option)
                end
            end

            DATA.for_each_trade_good(generate_option)

            local nothing_option = {
                text = "Nothing",
                tooltip = "Nothing",
                viable = function() return true end,
                outcome = function() end,
                ai_preference = function()
                    return 0
                end
            }
            table.insert(options_list, nothing_option)

            return options_list
        end
    }

    Event:new {
        name = "sell-goods",
        automatic = false,
        event_background_path = "data/gfx/backgrounds/background.png",
        base_probability = 0,

        options = function(self, root, associated_data)
            local options_list = {}
            local province = PROVINCE(root)

            if province == nil then
                return {
                    {
                        text = "Something is wrong",
                        tooltip = "Province is nil",
                        viable = function() return true end,
                        outcome = function()
                        end,
                        ai_preference = function()
                            return 0.5
                        end
                    }
                }
            end

            local function generate_option(trade_good)
                local price = economy_values.get_pessimistic_local_price(province, trade_good, 1, true)
                local known_price = DATA.pop_get_price_memory(root, trade_good)

                local current_amount = DATA.pop_get_inventory(root, trade_good)
                local sold_amount = current_amount
                local can_sell, _ = et.can_sell(root, trade_good, sold_amount)

                while
                    not can_sell
                    and _ == et.TRADE_FAILURE_REASONS.LOCAL_WEALTH_IS_TOO_LOW
                    and sold_amount > 1
                do
                    sold_amount = math.floor(sold_amount / 2)
                    can_sell, _ = et.can_sell(root, trade_good, sold_amount)
                end

                local good_reserve = 0

                local weight = USE_WEIGHT[trade_good][CALORIES_USE_CASE]
                if LEADER_OF_WARBAND(root) ~= INVALID_ID and weight ~= 0 then
                    good_reserve = warband_utils.daily_supply_consumption(LEADER_OF_WARBAND(root)) * 60 / weight
                end

                sold_amount = math.max(0, math.min(math.max(1, sold_amount), current_amount - good_reserve))

                can_sell, _ = et.can_sell(root, trade_good, sold_amount)
                local desire_to_get_rid_of_goods = math.max(1, current_amount / 10)

                if can_sell and sold_amount > 0 then
                    ---@type EventOption
                    local option = {
                        text = "Sell " .. DATA.trade_good_get_name(trade_good) .. " for " .. ut.to_fixed_point2(price) .. MONEY_SYMBOL,
                        -- tooltip = "Sell " .. name .. " for " .. ut.to_fixed_point2(price) .. MONEY_SYMBOL,
                        tooltip = "AI_pref: " .. (price - known_price) / (known_price + 0.05) * desire_to_get_rid_of_goods - 0.02,
                        viable = function() return true end,
                        outcome = function()
                            economy_effects.sell(root, trade_good, sold_amount)
                        end,
                        ai_preference = function()
                            return (price - known_price) / (known_price + 0.05) * desire_to_get_rid_of_goods - 0.05
                        end
                    }
                    table.insert(options_list, option)
                end
            end

            DATA.for_each_trade_good(generate_option)

            local nothing_option = {
                text = "Nothing",
                tooltip = "Nothing",
                viable = function() return true end,
                outcome = function() end,
                ai_preference = function()
                    return 0
                end
            }
            table.insert(options_list, nothing_option)

            return options_list
        end
    }

end

return load