local Event = require "game.raws.events"
local pe = require "game.raws.effects.player"
local de = require "game.raws.effects.death"

function load()
    Event:new({
        name = "death",
        automatic = true,
        event_background_path = "data/gfx/backgrounds/background.png",
        base_probability = 1 / 24,
        trigger = function(self, character)
            return character.age > character.race.max_age
        end,
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
end


return load