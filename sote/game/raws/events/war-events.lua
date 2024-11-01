local uit = require "game.ui-utils"
local Event = require "game.raws.events"
local AiPreferences = require "game.raws.values.ai"

local pop_utils = require "game.entities.pop".POP
local warband_utils = require "game.entities.warband"

local function load()

    Event:new {
        name = "pick-commander-unit",
        automatic = false,
        event_background_path = "data/gfx/backgrounds/background.png",
        base_probability = 0,

        ---@param root Character
        ---@param associated_data Warband
        options = function(self, root, associated_data)
            local options_list = {}
            local province = PROVINCE(root)

            ---#logging LOGS:write("pick-commander-unit " .. tostring(root) .. " " .. tostring(province).. "\n")
            ---#logging LOGS:flush()

            if province == INVALID_ID then
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

            ---#logging LOGS:write("pick-commander-unit retrieve unlocked units\n")
            ---#logging LOGS:flush()
            -- get all unit types
            ---@type table<unit_type_id, unit_type_id>
            local unlocked_unit_types = {}

            DATA.for_each_unit_type(function (item)
                if DATA.province_get_unit_types(province, item) == 1 then
                    unlocked_unit_types[item] = item
                end
            end)

            ---#logging LOGS:write("pick-commander-unit generate options\n")
            ---#logging LOGS:flush()

            for _, unit in pairs(unlocked_unit_types) do

                local health, attack, armor, speed = pop_utils.get_strength(root, unit)
                local spotting = pop_utils.get_spotting(root, unit)
                local visibility = pop_utils.get_visibility(root, unit)
                local supply = pop_utils.get_supply_use(root, unit)
                local capacity = pop_utils.get_supply_capacity(root, unit)

                local fat = DATA.fatten_unit_type(unit)

                ---@type EventOption
                local option = {
                    text =  fat.name .. " (" .. uit.to_fixed_point2(fat.base_price) .. MONEY_SYMBOL .. ")",
                    tooltip = "Price: " .. uit.to_fixed_point2(fat.base_price) .. MONEY_SYMBOL .. " (" .. uit.to_fixed_point2(fat.upkeep) .. MONEY_SYMBOL .. ")\n"
                        .. "Health: " .. uit.to_fixed_point2(health) .. " Attack: " .. uit.to_fixed_point2(attack)
                        .. " Armor: " .. uit.to_fixed_point2(armor) .. " Speed: " .. uit.to_fixed_point2(speed)
                        .. "\nSpotting: " .. uit.to_fixed_point2(spotting) .. " Visibility: " .. uit.to_fixed_point2(visibility)
                        .. " Travel cost: " .. uit.to_fixed_point2(supply) .. " Hauling capacity: " .. uit.to_fixed_point2(capacity),
                    viable = function() return true end,
                    outcome = function()
                        warband_utils.set_commander(associated_data, root, unit)
                    end,
                    ai_preference = function()
                        -- TODO FIGURE OUT BETTER WEIGHTING THE FOLLOWING IS A PLACEHOLDER
                        local base = health + attack + armor + speed + spotting + visibility + supply + capacity
                        -- greedy characters care more about upkeep cost (payment) and loot capacity
                        if HAS_TRAIT(root, TRAIT.GREEDY) then
                            base = base + capacity * 8 + 12 * fat.upkeep * AiPreferences.money_utility(root)
                        end
                        -- aggressive characters care more about combat stats
                        if HAS_TRAIT(root, TRAIT.WARLIKE) then
                            base = base + health + attack + armor
                        end
                        -- weight by unit cultural preference or 1%
                        local culture = DATA.pop_get_culture(root)
                        local weight = DATA.culture_get_traditional_units(culture, unit) + 0.01
                        return base * weight
                    end
                }
                table.insert(options_list, option)
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

            ---#logging LOGS:write("pick-commander-unit there are " .. tostring(#options_list) .. " options\n")
            ---#logging LOGS:flush()

            return options_list
        end

    }

    --[[
	Event:new {
		name = "war-declaration",
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		on_trigger = function(self, root, associated_data)
			---@type Realm
			local realm = LOCAL_REALM(root)
			---@type Realm
			local agg = associated_data.aggresor
			if WORLD:does_player_see_realm_news(realm) then
				WORLD:emit_notification(agg.name .. " declared war against us!")
			end
		end,
	}
    --]]
end

return load
