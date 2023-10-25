local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

---@type Queue<string>
local notifications = require "engine.queue":new()

return function(rect, scroll, hidden)
    ui.panel(rect)
    if scroll == nil then
        scroll = 1
    end
    while notifications:length() > 100 do
        notifications:dequeue()
    end
    while WORLD.notification_queue:length() > 0 do
        local item = WORLD.notification_queue:dequeue()
        notifications:enqueue(item)
    end
    local function render_notification(index, rect)
        local first = notifications.first
        local item = notifications.data[first + index]
        ui.panel(rect)
        rect:shrink(5)
        if item then
            ui.left_text(item, rect)
        end
    end

    return ui.scrollview(
        rect,
        render_notification,
        ut.BASE_HEIGHT * 3,
        notifications:length(),
        10,
        scroll)
end