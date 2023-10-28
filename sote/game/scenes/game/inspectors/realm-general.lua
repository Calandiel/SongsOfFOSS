local ui = require "engine.ui";
local uit = require "game.ui-utils"

local portait = require "game.scenes.game.widgets.portrait"


---comment
---@param rect Rect
---@param realm Realm
---@param gam GameScene
---@return function
local function info(rect, realm, gam)
    return function()
        local panel_rect = rect:subrect(0, uit.BASE_HEIGHT, uit.BASE_HEIGHT * 12, uit.BASE_HEIGHT, "left", 'up')

        -- leader info
        local leader = realm.leader
        if leader then
            local portrait_rect = panel_rect:subrect(0, 0, uit.BASE_HEIGHT * 4, uit.BASE_HEIGHT * 4, "left", 'up')
            portait(portrait_rect, leader)
            if ui.invisible_button(portrait_rect) then
                gam.selected.character = leader
                gam.inspector = "character"
            end
            ui.tooltip("Click the portrait to open character screen", portrait_rect)

            portrait_rect.x = portrait_rect.x + uit.BASE_HEIGHT * 5
            portrait_rect.width = portrait_rect.width + uit.BASE_HEIGHT * 5
            uit.data_entry("Leader: ", realm.leader.name, portrait_rect)
            panel_rect.y = panel_rect.y + uit.BASE_HEIGHT * 4
        end

        
        -- general info
        uit.data_entry("Culture: ", realm.primary_culture.name, panel_rect)
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT
        uit.data_entry("Faith: ", realm.primary_faith.name, panel_rect)
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT
        uit.data_entry("Race: ", realm.primary_race.name, panel_rect)
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT
    end
end


return info