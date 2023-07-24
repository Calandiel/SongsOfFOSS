local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"
local realm = require "game.entities.realm"

local EconomicEffects = require "game.raws.effects.economic"

local window = {}

local reward = nil

local base_unit = ut.BASE_HEIGHT

---@return Rect
function window.rect() 
    return ui.fullscreen():subrect(0, 0, base_unit * 13, base_unit * 7, "center", "center")
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

---comment
---@param flag RewardFlag
local function save_flag(flag)
    local current_savings = WORLD.player_character.savings
    local reward_change = reward - flag.reward
    if reward_change > current_savings then
        reward_change = current_savings
    end
    if reward_change == 0 then
        return
    end
    flag.reward = flag.reward + reward_change
    EconomicEffects.add_pop_savings(WORLD.player_character, -reward_change, EconomicEffects.reasons.RewardFlag)
end

---comment
---@param flag RewardFlag
local function delete_flag(flag)
    local reward = flag.reward
    flag.owner.province.realm:remove_reward_flag(flag)
    EconomicEffects.add_pop_savings(WORLD.player_character, reward, EconomicEffects.reasons.RewardFlag)
end


---Draw flag edit window
---@param game table
---@param reward_flag RewardFlag
function window.draw(game, reward_flag)
    if reward == nil then
        reward = reward_flag.reward
    end
    local ui_panel = window.rect()
    -- draw a panel
    ui.panel(ui_panel)
    ui.text("Reward settings", ui_panel, "left", 'up')
    if ui.icon_button(ASSETS.icons["cancel.png"], ui_panel:subrect(0, 0, base_unit, base_unit, "right", 'up')) then
        game.inspector = nil
    end
    ui_panel.y = ui_panel.y + base_unit
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
                save_flag(reward_flag)
                game.inspector = nil
                reward = nil
            end
        end,
        function (rect)
            if ui.text_button('Delete', rect) then
                delete_flag(reward_flag)
                game.inspector = nil
                reward = nil
            end
        end,
        function (rect)
            if ui.text_button('Cancel', rect) then
                game.inspector = nil
                reward = nil
            end
        end
    }, ui_panel, ui_panel.width / 3, 0)
end

return window