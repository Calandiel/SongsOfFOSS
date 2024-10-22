local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"
local ib = require "game.scenes.game.widgets.inspector-redirect-buttons"

local pv = require "game.raws.values.politics"

local trade_good = require "game.raws.raws-utils".trade_good

local characters_list_widget = require "game.scenes.game.widgets.character-list"
local custom_characters_list_widget = require "game.scenes.game.widgets.list-widget"
local character_decisions_widget = require "game.scenes.game.widgets.decision-selection-character"
local character_name_widget = require "game.scenes.game.widgets.character-name"

local string = require "engine.string"


local window = {}
local selected_decision = nil
local decision_target_primary = nil
local decision_target_secondary = nil

local traits_slider = 0
local inventory_slider = 0
local character_list_tab = "Local"
local warrior_list_state = nil

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
    local character_id = game.selected.character

    if character_id == INVALID_ID then
        return
    end
    local character = DATA.fatten_pop(character_id)
    local race = DATA.pop_get_race(character_id)

    local ui_panel = window.rect()
    -- draw a panel
    ui.panel(ui_panel)
    local unit = ut.BASE_HEIGHT

    --panel for a future portrait
    local portrait = ui_panel:subrect(0, 0, unit * 4, unit * 4, "left", "up")
    local coa = ui_panel:subrect(unit * 3 - 2, unit * 3 - 2, unit, unit, "left", "up")
    require "game.scenes.game.widgets.portrait" (portrait, character_id)

    if DEAD(character) then
        return
    end

    local inventory_panel = ui_panel:subrect(0, 0, 4 * unit, ui_panel.height, "right", "up")

    inventory_slider = ut.scrollview(
        inventory_panel,
        function (index, rect)
            if index > 0 then
                local _, good = tabb.nth(RAWS_MANAGER.trade_goods_by_name, index)
                assert(good ~= nil)
                local amount = DATA.pop_get_inventory(character_id, good)
                local name = DATA.trade_good_get_name(good)
                local icon = DATA.trade_good_get_icon(good)

                local tooltip = "Amount of "
                    .. name
                    .. " "
                    .. NAME(character)
                    .. " owns. They think that its price is "
                    .. ut.to_fixed_point2(DATA.pop_get_price_memory(character_id, good))
                ut.sqrt_number_entry_icon(
                    icon,
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
    local name_panel = ui_panel:subrect(unit * 4, 0, unit * 12, unit * 5/3, "left", "up"):shrink(3)

    local age_panel = ui_panel:subrect(unit * 4, unit * 7/3, unit * 12, unit * 4/3, "left", "up"):shrink(3)

    local wealth_panel = ui_panel:subrect(unit * 4, unit * 11/3, unit * 6, unit * 4/3, "left", "up"):shrink(3)
    local popularity_panel = ui_panel:subrect(unit * 10, unit * 11/3, unit * 6, unit * 4/3, "left", "up"):shrink(3)

    local location_panel = ui_panel:subrect(0, unit * 18/3, unit * 8, unit * 1, "left", "up"):shrink(3)
    local culture_panel = ui_panel:subrect(unit * 8, unit * 18/3, unit * 8, unit * 1, "left", "up"):shrink(3)

    local layout = ui.layout_builder():position(ui_panel.x, ui_panel.y + unit * 10):vertical():build()

    local description_block = layout:next(unit * 16, unit * 8)

    ui.panel(description_block)
    local half_width = unit * 8
    local description_block_height = description_block.height

    local description_panel =               description_block:subrect(0, 0,           half_width, description_block_height, "left", "up"):shrink(3)
    local traits_panel =                    description_block:subrect(half_width, 0,  half_width, description_block_height, "left", "up"):shrink(3)

    local decisions_label_panel =           layout:next(unit * 16, unit * 1)
    local decisions_panel =                 layout:next(unit * 16, unit * 6)
    local decisions_confirmation_panel =    layout:next(unit * 16, unit * 1)
    local character_tab =                 layout:next(unit * 16, unit * 1)
    local characters_list =                 layout:next(unit * 16, unit * 6)

    character_name_widget(name_panel, character_id)

    local sex = "male"
    if character.female then
        sex = "female"
    end

    ui.left_text(string.title(sex) .. " " .. string.title(DATA.race_get_name(race)), age_panel)
    ui.right_text("Age: " .. character.age, age_panel)

    ut.money_entry_icon(SAVINGS(character), wealth_panel, "Personal savings")

    local popularity = 0
    local province = PROVINCE(character_id)
    local realm = INVALID_ID
    if province ~= INVALID_ID then
        local part_of_realm = DATA.get_realm_provinces_from_province(province)
        if part_of_realm ~= INVALID_ID then
            realm = DATA.realm_provinces_get_realm(part_of_realm)
            popularity = pv.popularity(character_id, realm)
        end
    end
    ut.balance_entry_icon("duality-mask.png", popularity, popularity_panel, "Popularity")

    local player = WORLD.player_character
    local player_realm = WORLD:player_realm()
    local province_visible = true


    if province ~= INVALID_ID and (player == INVALID_ID or DATA.realm_get_known_provinces(player_realm)[province]) then
        if ut.text_button(DATA.province_get_name(province), location_panel, "Current location of character") then
            game.inspector = "tile"
            game.selected.province = province
            game.selected.tile = DATA.province_get_center(province)
            game.clicked_tile_id = DATA.province_get_center(province)
        end
    else
        ut.text_button("Unknown", location_panel, "Current location of character", false)
        province_visible = false
    end

    local warband_panel = location_panel:subrect(0, unit * 2, location_panel.width, location_panel.height, "left", "up")
    local warband = INVALID_ID
    local leader_of = DATA.get_warband_leader_from_leader(character_id)
    local commander_of = DATA.get_warband_commander_from_commander(character_id)
    local recruiter_of = DATA.get_warband_recruiter_from_recruiter(character_id)
    local unit_of = DATA.get_warband_unit_from_unit(character_id)

    if leader_of ~= INVALID_ID then
        warband = DATA.warband_leader_get_warband(leader_of)
        local name = DATA.warband_get_name(warband)
        ib.text_button_to_warband(game, warband, warband_panel, name, "This character is a leader of " .. name .. ".")
    elseif commander_of ~= INVALID_ID then
        warband = DATA.warband_commander_get_warband(commander_of)
        local name = DATA.warband_get_name(warband)
        ib.text_button_to_warband(game, warband, warband_panel, name, "This character is a commander of " .. name .. ".")
    elseif recruiter_of ~= INVALID_ID then
        warband = DATA.warband_recruiter_get_warband(recruiter_of)
        local name = DATA.warband_get_name(warband)
        ib.text_button_to_warband(game, warband, warband_panel, name, "This character is a recruiter of " .. name .. ".")
    elseif unit_of ~= INVALID_ID then
        warband = DATA.warband_unit_get_warband(unit_of)
        local name = DATA.warband_get_name(warband)
        ib.text_button_to_warband(game, warband, warband_panel, name, "This character is a unit of " .. name .. ".")
    else
        ut.text_button("None", warband_panel, "This character is not part of a warband", false)
    end

    location_panel.y = location_panel.y - unit
    ui.left_text("Location: ", location_panel)

    warband_panel.y = warband_panel.y - unit
    ui.left_text("Warband: ", warband_panel)


    ut.data_entry("", character.culture.name, culture_panel, "This character follows the customs of " .. character.culture.name .. "." .. require "game.economy.diet-breadth-model".culture_target_tooltip(character.culture))

    local faith_panel = culture_panel:subrect(0, unit * 2, culture_panel.width, culture_panel.height, "left", "up")
    ut.data_entry("", character.faith.name, faith_panel, "This character is a practitioner of " .. character.faith.name .. ".")

    culture_panel.y = culture_panel.y - unit
    ui.left_text("Culture: ", culture_panel)

    faith_panel.y = faith_panel.y - unit
    ui.left_text("Faith: ", faith_panel)

    ui.panel(traits_panel)

    -- character description
    local s = ""

    local loyalty = DATA.get_loyalty_from_bottom(character_id)

    -- loyalty text
    if loyalty == INVALID_ID then
        local ending = "himself"
        if character.female then
            ending = "herself"
        end
        s = s .. "\n " .. NAME(character) .. " is loyal to " .. ending .. "."
    else
        local loyal_to = DATA.loyalty_get_top(loyalty)
        s = s .. "\n " .. NAME(character) .. " is loyal to " .. DATA.pop_get_name(loyal_to) .. "."
    end

    -- successor text
    local succession = DATA.get_succession_from_successor_of(character_id)
    if succession ~= INVALID_ID then
        local successor = DATA.succession_get_successor(succession)
        s = s .. "\n " .. DATA.pop_get_name(successor) .. " is the designated successor of " .. NAME(character) .. "."
    else
        s = s .. "\n " .. NAME(character) .. " has not designated a successor yet."
    end

    ui.panel(description_panel)
    description_panel:shrink(5)
    ui.text(s, description_panel, "left", "up")

    ---@type TRAIT[]
    local traits = {}
    local trait_count = 0

    for i = 0, MAX_TRAIT_INDEX do
        local trait = DATA.pop_get_traits(character_id, i)
        if trait == TRAIT.INVALID then
            break
        end
        table.insert(traits, trait)
        ---@type number
        trait_count = trait_count + 1
    end

    traits_slider = ut.scrollview(
        traits_panel,
        function (index, rect)
            if index > 0 then
                local trait = traits[index]
                ut.data_entry_icon(
                    DATA.trait_get_icon(trait),
                    DATA.trait_get_name(trait),
                    rect,
                    nil,
                    nil,
                    "left"
                )
            end
        end,
        UI_STYLE.scrollable_list_large_item_height,
        trait_count,
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
                local locations = DATA.get_character_location_from_location(province)
                local characters = tabb.map_array(locations, DATA.character_location_get_character)
                local response = characters_list_widget(characters_list, characters, nil, true)()
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
            local parenthood = DATA.get_parent_child_relation_from_parent(character_id)
            local children = tabb.map_array(parenthood, DATA.parent_child_relation_get_child)
            local response = characters_list_widget(characters_list, children, nil, true)()
            if response then
                game.selected.character = response
            end
        end
    }
    local tab_layout = ui.layout_builder():position(character_tab.x, character_tab.y):horizontal():build()
    character_list_tab = ut.tabs(character_list_tab, tab_layout, tabs, 1, ut.BASE_HEIGHT * 4)

    ut.coa(character.realm, coa)
end

return window
