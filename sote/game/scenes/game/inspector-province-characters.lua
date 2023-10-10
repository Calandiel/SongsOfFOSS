local tabb = require "engine.table"
local ui = require "engine.ui"
local uit = require "game.ui-utils"

local portrait = require "game.scenes.game.widgets.portrait"
local name = require "game.scenes.game.widgets.character-name"

local window = {}

window.scroll = 0

---@return Rect
function window.rect() 
    return ui.fullscreen():subrect(0, 0, 600, 400, "center", "center")
end

function window.mask()
    if ui.trigger(window.rect()) then
		return false
	else
		return true
	end
end


---Draws characters list for a chosen province
---@param game table
---@param province Province
function window.draw(game, province)
    local panel = window.rect()
    ui.panel(panel)
    local base_unit = uit.BASE_HEIGHT

    ui.text('Select character', panel, "left", 'up')

    if ui.icon_button(ASSETS.icons["cancel.png"], panel:subrect(0, 0, base_unit, base_unit, "right", 'up')) then
        game.inspector = nil
    end

    panel.y = panel.y + base_unit
    panel.height = panel.height - base_unit

    ---comment
    ---@param index number
    ---@param rect Rect
    local function render_character(index, rect)
        ---@type Character
        local character = tabb.nth(province.characters, index)
        if character == nil then return end

        local portrait_rect = rect:subrect(0, 0, rect.height, rect.height, "left", 'center')
        portrait(portrait_rect, character)

        rect.x = rect.x + rect.height
        rect.width = rect.width - rect.height
        rect.width = rect.width / 2
        name(rect, character)

        rect.x = rect.x + rect.width
        ui.left_text(character.age .. " years old " .. character.race.name, rect)

        rect.x = rect.x + rect.width - rect.height
        rect.width = rect.height
        if ui.icon_button(ASSETS.icons['frog-prince.png'], rect, "Take control over this character") then
            WORLD.player_character = character
            WORLD.player_realm = province.realm
            WORLD.player_province = province
            game.refresh_map_mode()
            game.inspector = nil
        end
    end

    window.scroll = ui.scrollview(panel, render_character, base_unit * 2, tabb.size(province.characters), base_unit, window.scroll)
end

return window