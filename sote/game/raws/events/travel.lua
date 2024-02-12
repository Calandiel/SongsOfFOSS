local ut = require "game.ui-utils"

local Event = require "game.raws.events"
local event_utils = require "game.raws.events._utils"
local ge = require "game.raws.effects.generic"

local ee = require "game.raws.effects.economic"
local ev = require "game.raws.values.economical"
local et = require "game.raws.triggers.economy"

local function load()
    Event:new {
        name = "travel-start-action",
        automatic = false,
        event_background_path = "data/gfx/backgrounds/background.png",
        base_probability = 0,

        on_trigger = function (self, root, associated_data)
            ---@type TravelData
            associated_data = associated_data

            local party = root.leading_warband
            if party ~= nil then
                party.status = "travelling"
                party:consume_supplies(associated_data.travel_time)
                WORLD:emit_action("travel", root, associated_data.destination, associated_data.travel_time, true)
            else error("Character trying to travel without a warband!") end
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
                "We plan to " .. action .. " toward " .. associated_data.destination.name .. ". " ..
                "We will spend " .. ut.to_fixed_point2(associated_data.travel_time) .. " days. " ..
                "We have enough supplies to travel for " .. ut.to_fixed_point2(root.leading_warband:days_of_travel()) .. " days."

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
                    local party = root.leading_warband
                    party.status = "travelling"
                    if party ~= nil then
                    party:consume_supplies(associated_data.travel_time)
                    WORLD:emit_action("travel", root, associated_data.destination, associated_data.travel_time, true)
                    else error("Character is traveling without a warband!") end
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
		on_trigger = function(self, root, associated_data)
			---@type Province
			associated_data = associated_data

            if root.dead then
                return
            end

            ge.travel(root, associated_data)

            if root.leading_warband then
                root.leading_warband.status = "idle"
            end
            root.busy = false

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
            return "I have arrived to " .. data.name .. ". "
                .. "This land is controlled by people of " .. data.realm.name .. ". "
                .. data.realm.leader.race.name .. " " .. data.realm.leader.name .. " rules over them."
        end,
        function (self, root, data)
            return "Finally!"
        end,
        function (self, root, data)
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
            local province = root.province

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

            for name, good in pairs(RAWS_MANAGER.trade_goods_by_name) do

                local price = ev.get_local_price(province, name)
                local known_price = root.price_memory[name] or price

                local bought_amount = math.max(
                    1,
                    (math.floor(
                        root.savings * 0.25
                        / (known_price + 0.01)
                        * math.random()
                    ))
                )

                local can_buy, _ = et.can_buy(root, name, bought_amount)
                if can_buy then
                    ---@type EventOption
                    local option = {
                        text = "Buy " .. name .. " for " .. ut.to_fixed_point2(price) .. MONEY_SYMBOL,
                        -- tooltip = "Buy " .. name .. " for " .. ut.to_fixed_point2(price) .. MONEY_SYMBOL,
                        tooltip = "Ai_pref " .. (known_price - price - 0.05) / (known_price + 0.05),
                        viable = function() return true end,
                        outcome = function()
                            ee.buy(root, name, bought_amount)
                        end,
                        ai_preference = function()
                            return (known_price - price - 0.05) / (known_price + 0.05)
                        end
                    }
                    table.insert(options_list, option)
                end
            end

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
            local province = root.province

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

            for name, good in pairs(RAWS_MANAGER.trade_goods_by_name) do
                local price = ev.get_pessimistic_local_price(province, name, 1, true)
                local known_price = root.price_memory[name] or price

                local current_amount = root.inventory[name] or 0
                local sold_amount = current_amount
                local can_sell, _ = et.can_sell(root, name, sold_amount)

                while
                    not can_sell
                    and _ == et.TRADE_FAILURE_REASONS.LOCAL_WEALTH_IS_TOO_LOW
                    and sold_amount > 1
                do
                    sold_amount = math.floor(sold_amount / 2)
                    can_sell, _ = et.can_sell(root, name, sold_amount)
                end

                local good_reserve = 0

                if root.leading_warband and name == "food" then
                    good_reserve = root.leading_warband:daily_supply_consumption() * 60
                end

                sold_amount = math.max(0, math.min(math.max(1, sold_amount), current_amount - good_reserve))

                can_sell, _ = et.can_sell(root, name, sold_amount)
                local desire_to_get_rid_of_goods = math.max(1, (root.inventory[name] or 0) / 10)

                if can_sell and sold_amount > 0 then
                    ---@type EventOption
                    local option = {
                        text = "Sell " .. name .. " for " .. ut.to_fixed_point2(price) .. MONEY_SYMBOL,
                        -- tooltip = "Sell " .. name .. " for " .. ut.to_fixed_point2(price) .. MONEY_SYMBOL,
                        tooltip = "AI_pref: " .. (price - known_price) / (known_price + 0.05) * desire_to_get_rid_of_goods - 0.02,
                        viable = function() return true end,
                        outcome = function()
                            ee.sell(root, name, sold_amount)
                        end,
                        ai_preference = function()
                            return (price - known_price) / (known_price + 0.05) * desire_to_get_rid_of_goods - 0.05
                        end
                    }
                    table.insert(options_list, option)
                end
            end

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