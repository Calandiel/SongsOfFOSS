local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"
local realm = require "game.entities.realm"

local EconomicEffects = require "game.raws.effects.economic"

local window = {}

local reward = 0.0
local flag_type = 'raid'

local base_unit = ut.BASE_HEIGHT

---@return Rect
function window.rect() 
    return ui.fullscreen():subrect(0, 0, base_unit * 12, base_unit * 13, "center", "center")
end

function window.mask()
    if ui.trigger(window.rect()) then
		return false
	else
		return true
	end
end

local function change_reward_button(x)
    local current_savings = WORLD.player_character.savings
    return function(rect)
        if ui.text_button(ut.to_fixed_point2(x), rect) then 
            reward = math.min(current_savings, math.max(0, reward + x))
        end
    end
end

local function create_flag(province)
    local current_savings = WORLD.player_character.savings
    if reward > current_savings then
        reward = current_savings
    end
    if reward == 0 then
        return
    end
    local reward_flag = realm.RewardFlag:new {
        target = province,
        reward = reward,
        flag_type = flag_type,
        owner = WORLD.player_character
    }
    WORLD.player_character.province.realm:add_reward_flag(reward_flag)
    EconomicEffects.add_pop_savings(WORLD.player_character, -reward, EconomicEffects.reasons.RewardFlag)
end

---Draw decisions window
---@param game table
function window.draw(game)
    local ui_panel = window.rect()
    -- draw a panel
    ui.panel(ui_panel)
    ui.text("Reward flag", ui_panel, "left", 'up')
    if ui.icon_button(ASSETS.icons["cancel.png"], ui_panel:subrect(0, 0, base_unit, base_unit, "right", 'up')) then
        game.inspector = nil
    end
    ui_panel.y = ui_panel.y + base_unit
    ui_panel.height = base_unit * 6

    ut.rows ({
        function (rect)
            ---@type Rect
            rect = rect
            ui.panel(rect)
            rect:shrink(10)
            ui.left_text('Explore', rect)            
            ui.checkbox(rect:subrect(0, 0, base_unit * 2, base_unit * 2, "right", 'center'), flag_type == 'explore', 4)
        end,
        function (rect)
            ui.panel(rect)
            rect:shrink(10)
            ui.left_text('Raid', rect)
            ui.checkbox(rect:subrect(0, 0, base_unit * 2, base_unit * 2, "right", 'center'), flag_type == 'raid', 4)
        end,
        function (rect)
            ui.panel(rect)
            rect:shrink(10)
            ui.left_text('Devastate', rect)
            ui.checkbox(rect:subrect(0, 0, base_unit * 2, base_unit * 2, "right", 'center'), flag_type == 'devastate', 4)
        end
    }, ui_panel, ui_panel.height / 3, 0)

    ui_panel.y = ui_panel.y + ui_panel.height
    ui_panel.height = base_unit * 4

    ut.rows({
        function(rect)
            ui.panel(rect)
            ut.columns({
                function(rect)
                    ui.panel(rect)
                    ui.left_text("Reward:", rect)
                end,
                function(rect)
                    ui.panel(rect)
                    ut.data_entry("", ut.to_fixed_point2(reward), rect, "Current reward")
                end
            }, rect, rect.width / 2, 0)
        end, 
        function(rect)
            ut.columns({
                change_reward_button(-1.0),
                change_reward_button(-0.5),
                change_reward_button(-0.1),
                change_reward_button(0.1),
                change_reward_button(0.5),
                change_reward_button(1.0),
            }, rect, rect.width / 6, 0)
        end
    }, ui_panel, ui_panel.height / 2, 0)


    ui_panel.y = ui_panel.y + ui_panel.height
    ui_panel.height = base_unit * 2
    ut.columns({
        function (rect)
            if ui.text_button('Save', rect) then
                create_flag(game.flagged_province)
            end
        end,
        function (rect)
            if ui.text_button('Cancel', rect) then
                game.inspector = nil
            end
        end
    }, ui_panel, ui_panel.width / 2, 0)
end

return window