local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

local function render_action(index, rect)
    ---@type ActionData
    local action = tabb.nth(WORLD.player_deferred_actions, index)
    if action == nil then
        return
    end
    ui.left_text(action[1], rect)
    ui.right_text(tostring(math.floor(action[4])), rect)
    ui.centered_text(action[2].name, rect)
end

return function(rect, slider)
    if slider == nil then
        slider = 0
    end
    ui.panel(rect)
    return ui.scrollview(
        rect,
        render_action,
        ut.BASE_HEIGHT * 1,
        tabb.size(WORLD.player_deferred_actions),
        10,
        slider
    )
end