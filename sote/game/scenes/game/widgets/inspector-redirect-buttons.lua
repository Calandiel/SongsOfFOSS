local ui = require "engine.ui"
local ut = require "game.ui-utils"

local ib = {}


---@param gamescene GameScene
---@param rect Rect
function ib.icon_button_to_close(gamescene, rect)
    if ut.icon_button(ASSETS.icons["cancel.png"], rect) then
        gamescene.inspector = nil
    end
end

---@param gamescene GameScene
---@param realm Realm
---@param rect Rect
function ib.icon_button_to_realm(gamescene, realm, rect)
    rect:shrink(1)
    ui.panel(rect, 2, true)
    rect:shrink(1)
    if ut.coa(realm, rect) then
        gamescene.selected.realm = realm
        gamescene.inspector = "realm"
    end
end

---@param gamescene GameScene
---@param realm Realm
---@param rect Rect
---@param tooltip string?
---@param potential boolean?
---@param active boolean?
function ib.text_button_to_realm(gamescene, realm, rect, text, tooltip, potential, active)
    if ut.text_button(text, rect, tooltip, potential, active) then
        gamescene.selected.realm = realm
        gamescene.inspector = "realm"
    end
end

---@param gamescene GameScene
---@param character Character
---@param rect Rect
function ib.icon_button_to_character(gamescene, character, rect)
    ui.panel(rect, 1, true)
    rect:shrink(-1)
    require "game.scenes.game.widgets.portrait"(rect, character)
    if ui.invisible_button(rect) then
        gamescene.selected.character = character
        gamescene.inspector = "character"
    end
end

---@param gamescene GameScene
---@param character Character
---@param rect Rect
---@param tooltip string?
---@param potential boolean?
---@param active boolean?
function ib.text_button_to_character(gamescene, character, rect, text, tooltip, potential, active)
    if ut.text_button(text, rect, tooltip, potential, active) then
        gamescene.selected.character = character
        gamescene.inspector = "character"
    end
end

---@param gamescene GameScene
---@param province Province
---@param rect Rect
---@param tooltip string?
---@param potential boolean?
---@param active boolean?
function ib.text_button_to_province(gamescene, province, rect, text, tooltip, potential, active)
    if ut.text_button(text, rect, tooltip, potential, active) then
        gamescene.selected.province = province
        gamescene.selected.tile = DATA.province_get_center(province)
        gamescene.inspector = "tile"
    end
end


---@param gamescene GameScene
---@param building Building
---@param rect Rect
---@param tooltip string?
---@param potential boolean?
---@param active boolean?
function ib.text_button_to_building(gamescene, building, rect, text, tooltip, potential, active)
    if ut.text_button(text, rect, tooltip, potential, active) then
        gamescene.selected.building = building
        gamescene.inspector = "building"
    end
end


---@param gamescene GameScene
---@param warband Warband
---@param rect Rect
---@param tooltip string?
---@param potential boolean?
---@param active boolean?
function ib.text_button_to_warband(gamescene, warband, rect, text, tooltip, potential, active)
    if ut.text_button(text, rect, tooltip, potential, active) then
        gamescene.selected.warband = warband
        gamescene.inspector = "warband"
    end
end

return ib