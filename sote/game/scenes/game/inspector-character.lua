local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

local pv = require "game.raws.values.political"

local TRAIT_ICONS = require "game.raws.traits.trait_to_icon"

local characters_list_widget = require "game.scenes.game.widgets.character-list"
local character_decisions_widget = require "game.scenes.game.widgets.decision-selection-character"
local character_name_widget = require "game.scenes.game.widgets.character-name"


local window = {}
local selected_decision = nil
local decision_target_primary = nil
local decision_target_secondary = nil

local traits_slider = 0

---@return Rect
function window.rect() 
    local unit = ut.BASE_HEIGHT
    local fs = ui.fullscreen()
    return fs:subrect(unit * 2, unit * 2, unit * 16, unit * 34, "left", 'up')
end

function window.mask()
    if ui.trigger(window.rect()) then
		return false
	else
		return true
	end
end

---Draw character window
---@param game GameScene
function window.draw(game)
    local character = game.selected.character

    if character == nil then
        return
    end

    local ui_panel = window.rect()
    -- draw a panel
    ui.panel(ui_panel)
    local unit = ut.BASE_HEIGHT

    --panel for a future portrait
    local portrait = ui_panel:subrect(0, 0, unit * 4, unit * 4, "left", 'up')
    local coa = ui_panel:subrect(unit * 3 - 2, unit * 3 - 2, unit, unit, "left", 'up')
    require "game.scenes.game.widgets.portrait" (portrait, character)
    

    -- name panel
    local name_panel = ui_panel:subrect(unit * 4, 0, unit * 12, unit * 4/3, "left", 'up'):shrink(3)

    local age_panel = ui_panel:subrect(unit * 4, unit * 4/3, unit * 12, unit * 4/3, "left", 'up'):shrink(3)

    local wealth_panel = ui_panel:subrect(unit * 4, unit * 8/3, unit * 6, unit * 4/3, "left", 'up'):shrink(3)
    local popularity_panel = ui_panel:subrect(unit * 10, unit * 8/3, unit * 6, unit * 4/3, "left", 'up'):shrink(3)

    local faith_panel = ui_panel:subrect(0, unit * 5, unit * 8, unit * 1, "left", 'up'):shrink(3)
    local culture_panel = ui_panel:subrect(unit * 8, unit * 5, unit * 8, unit * 1, "left", 'up'):shrink(3)

    local layout = ui.layout_builder():position(ui_panel.x, ui_panel.y + unit * 6):vertical():build()

    local description_block = layout:next(unit * 16, unit * 11)

    ui.panel(description_block)
    local half_width = unit * 8
    local description_block_height = unit * 11

    local description_panel =               description_block:subrect(0, 0,           half_width, description_block_height, "left", 'up'):shrink(3)
    local traits_panel =                    description_block:subrect(half_width, 0,  half_width, description_block_height, "left", 'up'):shrink(3)

    local decisions_label_panel =           layout:next(unit * 16, unit * 1)
    local decisions_panel =                 layout:next(unit * 16, unit * 7)
    local decisions_confirmation_panel =    layout:next(unit * 16, unit * 1)
    local characters_list =                 layout:next(unit * 16, unit * 10)

    character_name_widget(name_panel, character)

    local sex = 'male'
    if character.female then
        sex = 'female'
    end

    ui.left_text(sex .. ' ' .. character.race.name, age_panel)
    ui.right_text('age: ' .. character.age, age_panel)

    ut.money_entry_icon(character.savings, wealth_panel, "Personal savings")

    local popularity = pv.popularity(character, character.province.realm)
    ut.data_entry_icon('duality-mask.png', ut.to_fixed_point2(popularity), popularity_panel, "Popularity")


    ut.data_entry("", character.faith.name, faith_panel, "Faith")
    faith_panel.y = faith_panel.y - unit
    ui.left_text('Faith: ', faith_panel)

    ut.data_entry("", character.culture.name, culture_panel, "Culture")
    culture_panel.y = culture_panel.y - unit
    ui.left_text('Culture: ', culture_panel)

    ui.panel(traits_panel)
    
    -- character description
    local s = ''

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

    -- successor text
    if character.successor then
        s = s .. '\n ' .. character.successor.name .. ' is the designated successor of ' .. character.name .. '.'
    else
        s = s .. '\n ' .. character.name .. ' has not designated a successor yet.'
    end

    ui.panel(description_panel)
    description_panel:shrink(5)
    ui.left_text(s, description_panel)

    traits_slider = ui.scrollview(
        traits_panel, 
        function (index, rect)
            if index > 0 then
                local trait = tabb.nth(character.traits, index)
                ut.data_entry_icon(
                    TRAIT_ICONS[trait],
                    trait,
                    rect,
                    nil,
                    nil,
                    'left'
                )
            end
        end,
        unit * 1.5,
        tabb.size(character.traits),
        unit,
        traits_slider
    )

    ui.centered_text('Decisions:', decisions_label_panel)

    -- First, we need to check if the player is controlling a realm
    if WORLD.player_character then
        selected_decision, decision_target_primary, decision_target_secondary = require "game.scenes.game.widgets.decision-selection-character"(
            decisions_panel,
            'character',
            character,
            selected_decision
        )
    else
        -- No player realm: no decisions to draw
    end
    local res = require "game.scenes.game.widgets.decision-desc"(
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
        game.selected.character = response
    end

    ut.coa(character.realm, coa)
end

return window