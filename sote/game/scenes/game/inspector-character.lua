local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

local window = {}

---@return Rect
function window.rect() 
    local unit = ut.BASE_HEIGHT
    local fs = ui.fullscreen()
    return fs:subrect(0, unit * 2, unit * 14, unit * 20, "left", 'up')
end

function window.mask()
    if ui.trigger(window.rect()) then
		return false
	else
		return true
	end
end


--      ______
--     |      | 10x4/3
--     |4x4   | ______
--     |     |  5x4/3    5x4/3
--     |_____|  5x4/3    5x4/3
--      7x2            7x2
--
--              14x 14



---Draw character window
---@param game table
---@param character Character
function window.draw(game, character)
    local ui_panel = window.rect()
    -- draw a panel
    ui.panel(ui_panel)
    local unit = ut.BASE_HEIGHT

    --panel for a future portrait
    local portrait = ui_panel:subrect(0, 0, unit * 4, unit * 4, "left", 'up')
    local coa = ui_panel:subrect(unit * 3 - 2, unit * 3 - 2, unit, unit, "left", 'up')
    require "game.scenes.game.widget-portrait" (portrait, character)
    

    -- name panel
    local name_panel = ui_panel:subrect(unit * 4, 0, unit * 10, unit * 4/3, "left", 'up'):shrink(3)

    local age_panel = ui_panel:subrect(unit * 4, unit * 4/3, unit * 10, unit * 4/3, "left", 'up'):shrink(3)

    local wealth_panel = ui_panel:subrect(unit * 4, unit * 8/3, unit * 5, unit * 4/3, "left", 'up'):shrink(3)
    local popularity_panel = ui_panel:subrect(unit * 9, unit * 8/3, unit * 5, unit * 4/3, "left", 'up'):shrink(3)    

    local faith_panel = ui_panel:subrect(0, unit * 4, unit * 7, unit * 2, "left", 'up'):shrink(3)
    local culture_panel = ui_panel:subrect(unit * 7, unit * 4, unit * 7, unit * 2, "left", 'up'):shrink(3)

    local traits_panel = ui_panel:subrect(0, unit * 6, unit * 14, unit * 14, "left", 'up')

    ui.centered_text(character.name .. " of " .. character.province.realm.name, name_panel)
    local sex = 'male'
    if character.female then
        sex = 'female'
    end

    ui.left_text(sex .. ' ' .. character.race.name, age_panel)
    ui.right_text('age: ' .. character.age, age_panel)

    ui.panel(wealth_panel)
    ui.panel(popularity_panel)
    ut.money_entry_icon(character.savings, wealth_panel, "Personal savings")
    ut.data_entry_icon('duality-mask.png', ut.to_fixed_point2(character.popularity), popularity_panel, "Popularity")

    ui.panel(faith_panel)
    ut.data_entry("", character.faith.name, faith_panel, "Faith")
    ui.panel(culture_panel)
    ut.data_entry("", character.culture.name, culture_panel, "Culture")

    ui.panel(traits_panel)

    ut.coa(character.province.realm, coa)
end

return window