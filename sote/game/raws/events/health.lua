local Event = require "game.raws.events"
local event_utils = require "game.raws.events._utils"
local pe = require "game.raws.effects.player"
local de = require "game.raws.effects.death"
local ie = require "game.raws.effects.interpersonal"

function load()
    Event:new({
        name = "death",
        automatic = true,
        event_background_path = "data/gfx/backgrounds/background.png",
        base_probability = 1 / 24,
        trigger = function(self, character)
            local age = DATA.pop_get_age(character);
            local race = DATA.pop_get_race(character);
            local max_age = DATA.race_get_max_age(race)
            return age > max_age
        end,
        fallback = function(self, associated_data) end,
        event_text = function(self, character, associated_data)
            return "I am dying..."
        end,
        options = function(self, character)
            return {
                {
                    text = "Everything comes to an end.",
                    tooltip = "Return to the character selection screen.",
                    viable = function()
                        return true
                    end,
                    outcome = function()
                        if character == WORLD.player_character then
                            pe.to_observer()
                        end
                        de.death(character)
                        WORLD:emit_immediate_action("succession-death", character)
                    end,
                    ai_preference = function ()
                        return 1
                    end
                }
            }
        end
    })

    event_utils.notification_event(
        "character-child-birth-notification",
        ---@param root Character
        ---@param data Character
        function (self, root, data)
            local name = DATA.pop_get_name(data)
            return "I have a new child named " .. name .. ". "
        end,
        ---@param root Character
        ---@param data Character
        function (root, data)
            local province = PROVINCE(root)
            local name = DATA.province_get_name(province);
            return "Truely a wonderful day in " .. name .. "!"
        end,
        ---@param root Character
        ---@param data Character
        function (root, data)
            local s = "he"
            local female = DATA.pop_get_female(data)
            if female then
                s = "she"
            end
            return "May " .. s .. " live a long and prosperous life!"
        end,
        ---@param root Character
        ---@param data Character
        function(root, data)
            local succession = DATA.get_succession_from_successor_of(root)
            if succession == INVALID_ID then
                ie.set_successor(root, data)
                WORLD:emit_immediate_event('succession-set', data, root)
            end
        end
    )
end


return load