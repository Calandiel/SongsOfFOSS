local ut = require "game.ui-utils"

local Event = require "game.raws.events"
local Event_utils = require "game.raws.events._utils"
local ge = require "game.raws.effects.generic"

local ee = require "game.raws.effects.economic"
local ev = require "game.raws.values.economical"
local et = require "game.raws.triggers.economy"

local function load()
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
            WORLD:emit_immediate_event('travel-end-notification', root, associated_data)
		end,
	}

    Event_utils.notification_event(
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
                if root.price_memory[name] == nil then
                    root.price_memory[name] = price
                else
                    if WORLD.player_character ~= root then
                        root.price_memory[name] = root.price_memory[name] * (3 / 4) + price * (1 / 4)
                    end
                end
                local known_price = root.price_memory[name]
                local bought_amount = math.max(
                    1,
                    (math.floor(
                        root.savings * 0.25
                        / (known_price + 0.01)
                        * math.random()
                    ))
                )

                if et.can_buy(root, name, bought_amount) then
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

                local price = ev.get_pessimistic_local_price(province, name, 1)
                if root.price_memory[name] == nil then
                    root.price_memory[name] = price
                else
                    if WORLD.player_character ~= root then
                        root.price_memory[name] = root.price_memory[name] * (3 / 4) + price * (1 / 4)
                    end
                end
                local known_price = root.price_memory[name]
                local sold_amount = math.max(1, math.floor((root.inventory[name] or 0) * math.random() * 0.2))
                local desire_to_get_rid_of_goods = math.max(1, (root.inventory[name] or 0) / 10)

                if et.can_sell(root, name, sold_amount) then
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