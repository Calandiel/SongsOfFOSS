local uit = require "game.ui-utils"
local Event = require "game.raws.events"
local AiPreferences = require "game.raws.values.ai_preferences"

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

            -- get all unit types
            ---@type table<UnitType, UnitType>
            local unit_types = {}

            for _, unit in pairs(province.unit_types) do
                unit_types[unit] = unit
            end

            for _, unit in pairs(associated_data.units) do
                unit_types[unit] = unit
            end

            for _, unit in pairs(unit_types) do
                local TRAIT = require "game.raws.traits.generic"
                print(  "FOUND " .. unit.name)
                local health, attack, armor, speed = root:get_strength(unit)
                local spotting, visibility, supply, capacity = root:get_spotting(unit), root:get_visibility(unit), root:get_supply_use(unit), root:get_supply_capacity(unit)

                ---@type EventOption
                local option = {
                    text =  unit.name .. " (" .. uit.to_fixed_point2(unit.base_price) .. MONEY_SYMBOL .. ")",
                    tooltip = "Price: " .. uit.to_fixed_point2(unit.base_price) .. MONEY_SYMBOL .. " (" .. uit.to_fixed_point2(unit.upkeep) .. MONEY_SYMBOL .. ")\n"
                        .. "Health: " .. uit.to_fixed_point2(health) .. " Attack: " .. uit.to_fixed_point2(attack)
                        .. " Armor: " .. uit.to_fixed_point2(armor) .. " Speed: " .. uit.to_fixed_point2(speed)
                        .. "\nSpotting: " .. uit.to_fixed_point2(spotting) .. " Visibility: " .. uit.to_fixed_point2(visibility)
                        .. " Travel cost: " .. uit.to_fixed_point2(supply) .. " Hauling capacity: " .. uit.to_fixed_point2(capacity),
                    viable = function() return true end,
                    outcome = function()
                        print("    PICKED " .. unit.name)
                        associated_data:set_commander(root, unit)
                    end,
                    ai_preference = function()
                        -- TODO FIGURE OUT BETTER WEIGHTING THE FOLLOWING IS A PLACEHOLDER
                        local base = health + attack + armor + speed + spotting + visibility + supply + capacity
                        -- greedy characters care more about upkeep cost (payment) and loot capacity
                        if root.traits[TRAIT.GREEDY] then
                            base = base + capacity * 8 + 12 * unit.upkeep * AiPreferences.money_utility(root)
                        end
                        -- aggressive characters care more about combat stats
                        if root.traits[TRAIT.WARLIKE] then
                            base = base + health + attack + armor
                        end
                        -- weight by unit cultural preference or 1%
                        local weight = root.culture.traditional_units[unit] or 0.01
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

            return options_list
        end

    }

	Event:new {
		name = "war-declaration",
		automatic = false,
		on_trigger = function(self, root, associated_data)
			---@type Realm
			local realm = root.province.realm
			---@type Realm
			local agg = associated_data.aggresor
			if WORLD:does_player_see_realm_news(realm) then
				WORLD:emit_notification(agg.name .. " declared war against us!")
			end
		end,
	}

end

return load
