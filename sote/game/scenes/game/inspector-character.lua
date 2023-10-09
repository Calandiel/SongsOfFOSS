local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

local characters_list_widget = require "sote.game.scenes.game.widgets.character-list"
local character_decisions_widget = require "sote.game.scenes.game.widgets.decision-selection-character"

local window = {}
local selected_decision = nil
local decision_target_primary = nil
local decision_target_secondary = nil

---@return Rect
function window.rect() 
    local unit = ut.BASE_HEIGHT
    local fs = ui.fullscreen()
    return fs:subrect(0, unit * 2, unit * 14, unit * 30, "left", 'up')
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
--              14x 7
--              14x 7 actions
--              14x 3 action confirmation
--              14x 7 other characters




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
    require "sote.game.scenes.game.widgets.portrait" (portrait, character)
    

    -- name panel
    local name_panel = ui_panel:subrect(unit * 4, 0, unit * 10, unit * 4/3, "left", 'up'):shrink(3)

    local age_panel = ui_panel:subrect(unit * 4, unit * 4/3, unit * 10, unit * 4/3, "left", 'up'):shrink(3)

    local wealth_panel = ui_panel:subrect(unit * 4, unit * 8/3, unit * 5, unit * 4/3, "left", 'up'):shrink(3)
    local popularity_panel = ui_panel:subrect(unit * 9, unit * 8/3, unit * 5, unit * 4/3, "left", 'up'):shrink(3)

    local faith_panel = ui_panel:subrect(0, unit * 4, unit * 7, unit * 2, "left", 'up'):shrink(3)
    local culture_panel = ui_panel:subrect(unit * 7, unit * 4, unit * 7, unit * 2, "left", 'up'):shrink(3)

    local traits_panel =                    ui_panel:subrect(0, unit * 6,               unit * 14, unit * 7, "left", 'up')
    local decisions_panel =                 ui_panel:subrect(0, unit * (6 + 7),         unit * 14, unit * 7, "left", 'up')
    local decisions_confirmation_panel =    ui_panel:subrect(0, unit * (6 + 7 + 7),     unit * 14, unit * 3, "left", 'up')
    local characters_list =                 ui_panel:subrect(0, unit * (6 + 7 + 7 + 3), unit * 14, unit * 7, "left", 'up')

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
    -- traits text
    local s = ''
    for k, v in pairs(character.traits) do
        s = s .. ', ' .. v
    end
    -- loyalty text
    if character.loyalty == nil then
        local ending = 'himself'
        if character.female then
            ending = 'herself'
        end
        s = s .. '\n ' .. character.name .. ' is loyal to ' .. ending .. '.'
    else
        s = s .. '\n ' .. character.name .. ' is loyal to ' .. character.loyalty.name .. '.'
    end

    ui.left_text(s, traits_panel)

    -- First, we need to check if the player is controlling a realm
    if WORLD.player_character then
        selected_decision, decision_target_primary, decision_target_secondary = require "sote.game.scenes.game.widgets.decision-selection-character"(
            decisions_panel,
            'character',
            character,
            selected_decision
        )
    else
        -- No player realm: no decisions to draw
    end
    local res = require "sote.game.scenes.game.widgets.decision-desc"(
        decisions_confirmation_panel,
        WORLD.player_character,
        selected_decision,
        decision_target_primary,
        decision_target_secondary
    )
    if res ~= 'nothing' then
        selected_decision = nil
        decision_target_primary = nil
        decision_target_secondary = nil
    end

    local response = characters_list_widget(characters_list, unit, character.province)()
    if response then
        game.selected_character = response
    end

    ut.coa(character.province.realm, coa)
end

return window