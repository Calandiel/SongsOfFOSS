local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

local pv = require "game.raws.values.political"

local TRAIT_ICONS = require "game.raws.traits.trait_to_icon"

local trade_good = require "game.raws.raws-utils".trade_good

local characters_list_widget = require "game.scenes.game.widgets.character-list"
local custom_characters_list_widget = require "game.scenes.game.widgets.list-widget"
local character_decisions_widget = require "game.scenes.game.widgets.decision-selection-character"
local character_name_widget = require "game.scenes.game.widgets.character-name"


local window = {}
local selected_decision = nil
local decision_target_primary = nil
local decision_target_secondary = nil

local traits_slider = 0
local inventory_slider = 0
local character_list_tab = "Local"

---@return Rect
function window.rect()
    local unit = ut.BASE_HEIGHT
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
    local portrait = ui_panel:subrect(0, 0, unit * 4, unit * 4, "left", "up")
    local coa = ui_panel:subrect(unit * 3 - 2, unit * 3 - 2, unit, unit, "left", "up")
    require "game.scenes.game.widgets.portrait" (portrait, character)

    local inventory_panel = ui_panel:subrect(0, 0, 4 * unit, ui_panel.height, "right", "up")

    inventory_slider = ut.scrollview(
        inventory_panel,
        function (index, rect)
            if index > 0 then
                local good = tabb.nth(RAWS_MANAGER.trade_goods_by_name, index)
                local amount = character.inventory[good] or 0
                local good_entity = trade_good(good)

                local tooltip = "Amount of "
                    .. good_entity.name
                    .. " "
                    .. character.name
                    .. " owns. They think that its price is "
                    .. ut.to_fixed_point2(character.price_memory[good] or 0)
                ut.sqrt_number_entry_icon(
                    good_entity.icon,
                    amount or 0,
                    rect,
                    tooltip
                )
            end
        end,
        UI_STYLE.scrollable_list_large_item_height,
        tabb.size(RAWS_MANAGER.trade_goods_by_name),
        unit,
        inventory_slider
    )


    -- name panel
    local name_panel = ui_panel:subrect(unit * 4, 0, unit * 12, unit * 4/3, "left", "up"):shrink(3)

    local age_panel = ui_panel:subrect(unit * 4, unit * 4/3, unit * 12, unit * 4/3, "left", "up"):shrink(3)

    local wealth_panel = ui_panel:subrect(unit * 4, unit * 8/3, unit * 6, unit * 4/3, "left", "up"):shrink(3)
    local popularity_panel = ui_panel:subrect(unit * 10, unit * 8/3, unit * 6, unit * 4/3, "left", "up"):shrink(3)

    local location_panel = ui_panel:subrect(0, unit * 5, unit * 8, unit * 1, "left", "up"):shrink(3)
    local culture_panel = ui_panel:subrect(unit * 8, unit * 5, unit * 8, unit * 1, "left", "up"):shrink(3)

    local layout = ui.layout_builder():position(ui_panel.x, ui_panel.y + unit * 6):vertical():build()

    local description_block = layout:next(unit * 16, unit * 11)

    ui.panel(description_block)
    local half_width = unit * 8
    local description_block_height = unit * 11

    local description_panel =               description_block:subrect(0, 0,           half_width, description_block_height, "left", "up"):shrink(3)
    local traits_panel =                    description_block:subrect(half_width, 0,  half_width, description_block_height, "left", "up"):shrink(3)

    local decisions_label_panel =           layout:next(unit * 16, unit * 1)
    local decisions_panel =                 layout:next(unit * 16, unit * 7)
    local decisions_confirmation_panel =    layout:next(unit * 16, unit * 1)
    local character_tab =                 layout:next(unit * 16, unit * 1)
    local characters_list =                 layout:next(unit * 16, unit * 8)

    character_name_widget(name_panel, character)

    local sex = "male"
    if character.female then
        sex = "female"
    end

    ui.left_text(sex .. " " .. character.race.name, age_panel)
    ui.right_text("age: " .. character.age, age_panel)

    ut.money_entry_icon(character.savings, wealth_panel, "Personal savings")

    local popularity = 0
    if character.province then
        popularity = pv.popularity(character, character.province.realm)
    end
    ut.balance_entry_icon("duality-mask.png", popularity, popularity_panel, "Popularity")


    local province = character.province
    local player = WORLD.player_character

    local province_visible = true

    if province and (player == nil or player.realm.known_provinces[province]) then
        if ut.text_button(character.province.name, location_panel, "Current location of character") then
            game.inspector = "tile"
            game.selected.province = character.province
            game.selected.tile = character.province.center
            game.clicked_tile_id = character.province.center.tile_id
        end
    else
        ut.text_button("Unknown", location_panel, "Current location of character", false)
        province_visible = false
    end

    location_panel.y = location_panel.y - unit
    ui.left_text("Location: ", location_panel)

    ut.data_entry("", character.culture.name, culture_panel, character.culture.name)
    culture_panel.y = culture_panel.y - unit
    ut.data_entry("", character.faith.name, culture_panel, "Faith")

    ui.panel(traits_panel)

    -- character description
    local s = ""

    -- loyalty text
    if character.loyalty == nil then
        local ending = "himself"
        if character.female then
            ending = "herself"
        end
        s = s .. "\n " .. character.name .. " is loyal to " .. ending .. "."
    else
        s = s .. "\n " .. character.name .. " is loyal to " .. character.loyalty.name .. "."
    end

    -- successor text
    if character.successor then
        s = s .. "\n " .. character.successor.name .. " is the designated successor of " .. character.name .. "."
    else
        s = s .. "\n " .. character.name .. " has not designated a successor yet."
    end

    ui.panel(description_panel)
    description_panel:shrink(5)
    ui.text(s, description_panel, "left", "up")

    traits_slider = ut.scrollview(
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
                    "left"
                )
            end
        end,
        UI_STYLE.scrollable_list_large_item_height,
        tabb.size(character.traits),
        unit,
        traits_slider
    )

    ui.centered_text("Decisions:", decisions_label_panel)

    -- First, we need to check if the player is controlling a realm
    if WORLD.player_character then
        selected_decision, decision_target_primary, decision_target_secondary = require "game.scenes.game.widgets.decision-selection-character"(
            decisions_panel,
            "character",
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
    if res ~= "nothing" then
        selected_decision = nil
        decision_target_primary = nil
        decision_target_secondary = nil
    end
    ---@type table<number, Tab>
    local tabs = {}
    if province and province_visible then
        tabs[1] = {
            text = "Local",
            tooltip = "Characters in the same province.",
            closure = function ()
                local response = characters_list_widget(characters_list, character.province.characters, nil, true)()
                if response then
                    game.selected.character = response
                end
            end
        }
    end
    tabs[2] = {
        text = "Children",
        tooltip = "This character's children.",
        closure = function ()
            local response = characters_list_widget(characters_list, character.children, nil, true)()
            if response then
                game.selected.character = response
            end
        end
    }
    if character.leading_warband then
        local function pop_sex(pop)
            local f = "m"
            if pop.female then f = "f" end
            return f
        end
        local function render_name(rect, k, v)
            if ut.text_button(v.name, rect) then
                return v
            end
        end
        tabs[3] = {
            text = "Warriors",
            tooltip = "Warriors in the character's warband.",
            closure = function()
                local response = custom_characters_list_widget(characters_list, character.leading_warband.pops, {
                    {
                        header = ".",
                        render_closure = function(rect, k, v)
                            require "game.scenes.game.widgets.portrait" (rect, v)
                        end,
                        width = UI_STYLE.scrollable_list_small_item_height,
                        value = function(k, v)
                            ---@type POP
                            v = v
                            return v.race.name
                        end
                    },
                    {
                        header = "race",
                        render_closure = function (rect, k, v)
                            ui.right_text(v.race.name, rect)
                        end,
                        width = ut.BASE_HEIGHT * 4,
                        value = function(k, v)
                            return v.race.name
                        end
                    },
                    {
                        header = "culture",
                        render_closure = function (rect, k, v)
                            ui.right_text(v.culture.name, rect)
                        end,
                        width = ut.BASE_HEIGHT * 4,
                        value = function(k, v)
                            return v.culture.name
                        end
                    },
                    {
                        header = "faith",
                        render_closure = function (rect, k, v)
                            ui.right_text(v.faith.name, rect)
                        end,
                        width = ut.BASE_HEIGHT * 3,
                        value = function(k, v)
                            return v.faith.name
                        end
                    },
                    {
                        header = "age",
                        render_closure = function (rect, k, v)
                            ui.right_text(tostring(v.age), rect)
                        end,
                        width = ut.BASE_HEIGHT * 2,
                        value = function(k, v)
                            return v.age
                        end
                    },
                    {
                        header = "sex",
                        render_closure = function (rect, k, v)
                            ui.centered_text(pop_sex(v), rect)
                        end,
                        width = ut.BASE_HEIGHT * 1,
                        value = function(k, v)
                            return pop_sex(v)
                        end
                    }
                }, nil, true)()
            end
        }
    end
    local tab_layout = ui.layout_builder():position(character_tab.x, character_tab.y):horizontal():build()
    character_list_tab = ut.tabs(character_list_tab, tab_layout, tabs, 1, ut.BASE_HEIGHT * 4)

    ut.coa(character.realm, coa)
end

return window
