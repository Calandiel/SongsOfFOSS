local tabb = require "engine.table"
local ui = require "engine.ui"
local uit = require "game.ui-utils"

local window = {}

local slider_warbands = 0
local slider_raiding_targets = 0


---@return Rect
function window.rect()
    local unit = uit.BASE_HEIGHT
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

---Draw military window
---@param game GameScene
function window.draw(game)
    local player_character = WORLD.player_character
    if player_character == nil then
        return
    end
    local realm = player_character.realm

    if realm == nil then
        return
    end

    local ui_panel = window.rect()
    -- draw a panel
    ui.panel(ui_panel)

    -- display warbands
    -- header
    ui_panel.height = ui_panel.height - uit.BASE_HEIGHT
    ui.text("Warbands", ui_panel, "left", "up")

    if uit.icon_button(ASSETS.icons["cancel.png"], ui_panel:subrect(0, 0, uit.BASE_HEIGHT, uit.BASE_HEIGHT, "right", "up")) then
        game.inspector = nil
    end

    -- substance
    ui_panel.y = ui_panel.y + uit.BASE_HEIGHT
    local warbands = realm:get_warbands()
    slider_warbands = uit.scrollview(ui_panel, function(i, rect)
        if i > 0 then
            ---@type Rect
            local r = rect
            local width_unit = r.width / 4
            local x = r.x

            r.width = width_unit * 2
            ---@type Warband
            local warband = warbands[i]
            ui.left_text(warband.name, r)

            r.width = width_unit
            r.x = x + width_unit * 2
            ui.left_text(warband.status, r)

            r.x = x + width_unit * 3
            ui.left_text("units: ", r)
            ui.right_text(" " .. warband:size(), r)
        end
    end, uit.BASE_HEIGHT, tabb.size(warbands), uit.BASE_HEIGHT, slider_warbands)
end

return window