local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

local function render_action(index, rect)
    ---@type PendingEventDisplay
    local action = WORLD.player_deferred_actions[index]
    if action == nil then
        return
    end
    ui.left_text(action.display_name, rect)
    ui.right_text(tostring(math.floor(action.delay)), rect)
end

return function(rect, slider)
    if slider == nil then
        slider = 0
    end
    ui.panel(rect)
    return ut.scrollview(
        rect,
        render_action,
        ut.BASE_HEIGHT * 1,
        tabb.size(WORLD.player_deferred_actions),
        10,
        slider
    )
end