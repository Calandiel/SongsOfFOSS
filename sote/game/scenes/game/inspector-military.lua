local tabb = require "engine.table"
local ui = require "engine.ui"
local uit = require "game.ui-utils"
local ib = require "game.scenes.game.widgets.inspector-redirect-buttons"

local realm_utils = require "game.entities.realm".Realm
local warband_utils = require "game.entities.warband"

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

    local realm = PROVINCE_REALM(game.selected.province)
    if realm == INVALID_ID and player_character ~= INVALID_ID then
        realm = LOCAL_REALM(player_character)
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
    local warbands = realm_utils.get_warbands(realm)
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
            local leader = WARBAND_LEADER(warband)
            local warband_realm = warband_utils.realm(warband)

            if leader ~= INVALID_ID then
                ib.icon_button_to_character(game, leader, realm_icon_rect)
            else
                ib.icon_button_to_realm(game, warband_realm, realm_icon_rect)
            end

            ib.text_button_to_warband(game, warband, r,
                DATA.warband_get_name(warband))

            r.width = width_unit
            r.x = x + width_unit * 2

            ui.centered_text(DATA.warband_status_get_name(DATA.warband_get_current_status(warband)), r)

            r.x = x + width_unit * 3
            ui.left_text("units: ", r)
            ui.right_text(warband_utils.war_size(warband) .. " / " .. warband_utils.target_size(warband) .. " (" .. warband_utils.size(warband) .. ") ", r)
        end
    end, uit.BASE_HEIGHT, tabb.size(warbands), uit.BASE_HEIGHT, slider_warbands)
end

return window