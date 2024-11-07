local ui = require "engine.ui";
local uit = require "game.ui-utils"

local portait = require "game.scenes.game.widgets.portrait"

local political_values = require "game.raws.values.politics"


---comment
---@param rect Rect
---@param realm Realm
---@param gam GameScene
---@return function
local function info(rect, realm, gam)
    return function()
        local panel_rect = rect:subrect(0, uit.BASE_HEIGHT, uit.BASE_HEIGHT * 12, uit.BASE_HEIGHT, "left", "up")

        -- leader info
        local leader = LEADER(realm)
        if leader then
            local portrait_rect = panel_rect:subrect(0, 0, uit.BASE_HEIGHT * 4, uit.BASE_HEIGHT * 4, "left", "up")
            portait(portrait_rect, leader)
            if ui.invisible_button(portrait_rect) then
                gam.selected.character = leader
                gam.inspector = "character"
            end
            ui.tooltip("Click the portrait to open character screen", portrait_rect)

            portrait_rect.x = portrait_rect.x + uit.BASE_HEIGHT * 5
            portrait_rect.width = portrait_rect.width + uit.BASE_HEIGHT * 5
            uit.data_entry("Leader: ", NAME(LEADER(realm)), portrait_rect)
            panel_rect.y = panel_rect.y + uit.BASE_HEIGHT * 4
        end


        -- general info
        uit.data_entry("Culture: ", DATA.culture_get_name(DATA.realm_get_primary_culture(realm)), panel_rect, REALM_NAME(realm)
            .. " follows the customs of " .. DATA.culture_get_name(DATA.realm_get_primary_culture(realm)) .. ".\n" .. require "game.economy.diet-breadth-model".culture_target_tooltip(DATA.realm_get_primary_culture(realm)))
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT
        uit.data_entry("Faith: ", DATA.faith_get_name(DATA.realm_get_primary_faith(realm)), panel_rect)
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT
        uit.data_entry("Race: ", DATA.race_get_name(DATA.realm_get_primary_race(realm)), panel_rect)
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        -- major offices:
        ui.text("Overseer:", panel_rect, "left", "up")
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        local overseer = political_values.overseer(realm)
        local overseer_name = "Vacant"
        if overseer ~= INVALID_ID then
            overseer_name = NAME(overseer)
        end
        if uit.text_button(overseer_name, panel_rect, "", overseer ~= nil) then
            gam.selected.character = overseer
            gam.inspector = "character"
        end
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        ui.text("Guard leader:", panel_rect, "left", "up")
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT

        local guard_leader = political_values.guard_leader(realm)
        local guard_leader_name = "Vacant"
        if guard_leader ~= INVALID_ID then
            guard_leader_name = NAME(guard_leader)
        end
        if uit.text_button(guard_leader_name, panel_rect, "", guard_leader ~= nil) then
            gam.selected.character = guard_leader
            gam.inspector = "character"
        end
        panel_rect.y = panel_rect.y + uit.BASE_HEIGHT
    end
end


return info