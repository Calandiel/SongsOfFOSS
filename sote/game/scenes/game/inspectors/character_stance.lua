local ui = require "engine.ui"
local ut = require "game.ui-utils"
local window = {}

---@return Rect
function window.rect()
    local unit = ut.BASE_HEIGHT
    local fs = ui.fullscreen()
    return fs:subrect(unit * 2, unit * 2, unit * (16 + 4), unit * 34, "left", "up")
end

function window.mask()
    if ui.trigger(window.rect()) then
		return false
	else
		return true
	end
end

local save = require "game.options".save

---Draw character stance window
---@param game GameScene
function window.draw(game)
    local ui_panel = window.rect()
    -- draw a panel
    ui.panel(ui_panel)

    if ut.icon_button(ASSETS.icons["cancel.png"], ui_panel:subrect(0, 0, ut.BASE_HEIGHT, ut.BASE_HEIGHT, "right", "up")) then
        game.inspector = nil
    end

    local unit = ut.BASE_HEIGHT
    local width = ui_panel.width

    local vertical_layout =  ui.layout_builder()
		:position(ui_panel.x, ui_panel.y)
		:vertical()
		:build()

    local rect_title = vertical_layout:next(width, unit * 2)
    ui.text("Your preferences", rect_title, "center", "up")

    ui.text("Exploration preparation:", vertical_layout:next(width, unit), "center", "up")
    local old_exploration_prep = OPTIONS["exploration"]
    if ui.named_checkbox("Depending on situation", vertical_layout:next(width, unit), OPTIONS["exploration"] == 0, 4)
        and old_exploration_prep ~= 0
    then
        OPTIONS["exploration"] = 0
        save()
    end
    if ui.named_checkbox("Explore by yourself", vertical_layout:next(width, unit), OPTIONS["exploration"] == 1, 4)
        and old_exploration_prep ~= 1
    then
        OPTIONS["exploration"] = 1
        save()
    end
    if ui.named_checkbox("Ask for help", vertical_layout:next(width, unit), OPTIONS["exploration"] == 2, 4)
        and old_exploration_prep ~= 2
    then
        OPTIONS["exploration"] = 2
        save()
    end

    ui.text("Travel start:", vertical_layout:next(width, unit), "center", "up")
    local old_travel_start = OPTIONS["travel-start"]
    if ui.named_checkbox("Requires confirmation", vertical_layout:next(width, unit), OPTIONS["travel-start"] == 0, 4)
        and old_travel_start ~= 0
    then
        OPTIONS["travel-start"] = 0
        save()
    end
    if ui.named_checkbox("Does not require confirmation", vertical_layout:next(width, unit), OPTIONS["travel-start"] == 1, 4)
        and old_travel_start ~= 1
    then
        OPTIONS["travel-start"] = 1
        save()
    end

    ui.text("Travel end:", vertical_layout:next(width, unit), "center", "up")
    local old_travel_end = OPTIONS["travel-end"]
    if ui.named_checkbox("Notify me", vertical_layout:next(width, unit), OPTIONS["travel-end"] == 0, 4)
        and old_travel_end ~= 0
    then
        OPTIONS["travel-end"] = 0
        save()
    end
    if ui.named_checkbox("Do not notify me", vertical_layout:next(width, unit), OPTIONS["travel-end"] == 1, 4)
        and old_travel_end ~= 1
    then
        OPTIONS["travel-end"] = 1
        save()
    end
    if ui.named_checkbox("Pause on travel end", vertical_layout:next(width, unit), OPTIONS["travel-end"] == 2, 4)
        and old_travel_end ~= 2
    then
        OPTIONS["travel-end"] = 2
        save()
    end

    -- CHARACTER SATISFY NEEDS OPTIONS
    ui.text("Needs Satisfaction:", vertical_layout:next(width, unit), "center", "up")
    -- slider to determine savings spent
    local old_needs_savings = OPTIONS["needs-savings"]
    OPTIONS["needs-savings"] = ui.named_slider("Amount of savings willing to spend on needs: " .. ut.to_fixed_point2(OPTIONS["needs-savings"] * 100)  .. "%",
        vertical_layout:next(width, 2 * unit), OPTIONS["needs-savings"], 0, 1, unit)
    if OPTIONS["needs-savings"] ~= old_needs_savings then
        save()
    end
    -- slider to determine time spent hunting
    local old_needs_hunt = OPTIONS["needs-hunt"]
    OPTIONS["needs-hunt"] = ui.named_slider("Minimum time to spend hunting: " .. ut.to_fixed_point2(OPTIONS["needs-hunt"] * 100)  .. "%",
        vertical_layout:next(width, 2 * unit), OPTIONS["needs-hunt"], 0, 1, unit)
    if OPTIONS["needs-hunt"] ~= old_needs_hunt then
        save()
    end
end

return window