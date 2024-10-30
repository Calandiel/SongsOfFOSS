local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

---comment
---@param gam GameScene
---@param rect Rect
---@param realm Realm
local function render_realm(gam, rect, realm)
    local portrait_subrect = rect:subrect(0, 0, rect.height, rect.height, "left", "center"):shrink(5)

    require "game.scenes.game.widgets.portrait"(portrait_subrect, LEADER(realm))

    local realm_name_rect = rect:subrect(rect.height, 0, rect.width - rect.height, rect.height / 2, "left", "up")
    local leader_name_rect = rect:subrect(rect.height, rect.height / 2, rect.width - rect.height, rect.height / 2, "left", "up")

    require "game.scenes.game.widgets.realm-name"(gam, realm, realm_name_rect, "immediate")
    if ut.text_button(NAME(LEADER(realm)), leader_name_rect) then
        gam.inspector = "character"
        gam.selected.character = LEADER(realm)
    end
end

local slider_overlords = 0
local slider_tributaries = 0

---Draws demography data
---@param gam GameScene
---@param realm Realm
---@param ui_panel Rect
local function diplomacy(gam, realm, ui_panel)
    return function()
        local overlords_label = ui_panel:subrect(0, 0, ui_panel.width / 2, UI_STYLE.table_header_height, "left", "up")
        local overlords_rect = ui_panel:subrect(0, UI_STYLE.table_header_height, ui_panel.width / 2, ui_panel.height - UI_STYLE.table_header_height, "left", "up")

        ui.centered_text("We are paying tribute to: ", overlords_label)

        local overlords = DATA.get_realm_subject_relation_from_subject(realm)

        slider_overlords = ut.scrollview(
            overlords_rect,
            function(i, rect)
                if i > 0 then
                    render_realm(gam, rect, DATA.realm_subject_relation_get_overlord(overlords[i]))
                end
            end,
            UI_STYLE.scrollable_list_widget_item_height,
            #overlords,
            UI_STYLE.slider_width,
            slider_overlords
        )

        local tributaries_label = ui_panel:subrect(ui_panel.width / 2, 0, ui_panel.width / 2, UI_STYLE.table_header_height, "left", "up")
        local tributaries_rect = ui_panel:subrect(ui_panel.width / 2, UI_STYLE.table_header_height, ui_panel.width / 2, ui_panel.height - UI_STYLE.table_header_height, "left", "up")

        ui.centered_text("We are receiving tribute from: ", tributaries_label)

        local subjects = DATA.get_realm_subject_relation_from_overlord(realm)

        slider_tributaries = ut.scrollview(
            tributaries_rect,
            function(i, rect)
                if i > 0 then
                    local tributary = DATA.realm_subject_relation_get_subject(subjects[i])
                    render_realm(gam, rect, tributary)
                end
            end,
            UI_STYLE.scrollable_list_widget_item_height,
            #subjects,
            UI_STYLE.slider_width,
            slider_tributaries
        )
    end
end

return diplomacy