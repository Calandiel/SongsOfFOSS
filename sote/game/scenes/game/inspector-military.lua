local tabb = require "engine.table"
local ui = require "engine.ui"
local uit = require "game.ui-utils"
local ib = require "game.scenes.game.widgets.inspector-redirect-buttons"

local window = {}

local slider_warbands = 0


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

    local realm = game.selected.province.realm
    if realm == nil and player_character then
        realm = player_character.province.realm
    end

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
            local realm_icon_rect = rect:subrect(0, 0, rect.height, rect.height, "left", "up")

            ---@type Rect
            local r = rect
            r.x = r.x + rect.height
            r.width = r.width - r.height
            local width_unit = r.width / 4
            local x = r.x

            r.width = width_unit * 2
            ---@type Warband
            local warband = warbands[i]
            if warband.leader then
                ib.icon_button_to_character(game, warband.leader, realm_icon_rect)
            else
                ib.icon_button_to_realm(game, warband:realm(), realm_icon_rect)
            end

            ib.text_button_to_warband(game, warband, r,
                warband.name)

            r.width = width_unit
            r.x = x + width_unit * 2
            ui.centered_text(warband.status, r)

            r.x = x + width_unit * 3
            ui.left_text("units: ", r)
            ui.right_text(warband:war_size() .. " / " .. warband:target_size() .. " (" .. warband:size() .. ") ", r)
        end
    end, uit.BASE_HEIGHT, tabb.size(warbands), uit.BASE_HEIGHT, slider_warbands)
end

return window