local tabb = require "engine.table"
local ui = require "engine.ui"
local uit = require "game.ui-utils"

local window = {}

---@return Rect
function window.rect() 
    return ui.fullscreen():subrect(0, 0, 400, 600, "center", "center")
end

function window.mask()
    if ui.trigger(window.rect()) then
		return false
	else
		return true
	end
end

---Draw military window
---@param game table
---@param realm Realm
function window.draw(game, realm)
    local ui_panel = window.rect()
    -- draw a panel
    ui.panel(ui_panel)

    -- display warbands
    -- header
    ui_panel.height = ui_panel.height / 3 - uit.BASE_HEIGHT
    ui.text("Warbands", ui_panel, "left", 'up')

    if ui.icon_button(ASSETS.icons["cancel.png"], ui_panel:subrect(0, 0, uit.BASE_HEIGHT, uit.BASE_HEIGHT, "right", 'up')) then
        game.inspector = nil
    end

    -- substance
    ui_panel.y = ui_panel.y + uit.BASE_HEIGHT
    local warbands = realm:get_warbands()
    local sl = game.warbands_slider_level or 0
    game.warbands_slider_level = ui.scrollview(ui_panel, function(i, rect) 
        if i > 0 then
            ---@type Rect
            local r = rect
            local width_unit = r.width / 4
            local x = r.x
            
            r.width = width_unit * 2
            ---@type Warband
            local warband = warbands[i]
            ui.left_text(warband.name, r)
            
            r.width = width_unit
            r.x = x + width_unit * 2
            ui.left_text(warband.status, r)

            r.x = x + width_unit * 3
            ui.left_text("units: ", r)
            ui.right_text(' ' .. warband:size(), r)
        end
    end, uit.BASE_HEIGHT, tabb.size(warbands), uit.BASE_HEIGHT, sl)

    -- display raiding targets
    -- header
    ui_panel.y = ui_panel.y + ui_panel.height
    ui.text("Rewards", ui_panel, "left", 'up')
    -- ui.text("Prepared forces", ui_panel, "right", 'up')
    
    -- substance
    ui_panel.y = ui_panel.y + uit.BASE_HEIGHT
    local targets = realm.reward_flags
    local sl = game.raiding_targets_slider_level or 0
    game.raiding_targets_slider_level = ui.scrollview(ui_panel, function(i, rect)
        if i > 0 then
            ---@type Rect
            local r = rect
            ---@type RewardFlag
            local target = tabb.nth(targets, i)
            local warbands = realm.raiders_preparing[target]
            local size = 0
            for _, warband in pairs(warbands) do
                size = size  + warband:size()
            end
            if target.owner == WORLD.player_character then
                if ui.text_button('', rect) then
                    game.selected_reward_flag = target
                    game.inspector = 'reward-flag-edit'
                end
            end
            
            uit.columns({
                -- owner
                function (rect)
                    uit.data_entry('', target.owner.name, rect, 'Reward owner')
                end,
                --type 
                function (rect)
                    ui.right_text(target.flag_type, rect)
                end,
                -- target
                function (rect)
                    ui.right_text(target.target.name, rect)
                end,
                -- reward
                function (rect)
                    uit.money_entry("", target.reward, rect, "Remaining reward")
                end,
                function (rect)
                    uit.data_entry('', tostring(size), rect, 'Amount of awaiting warbands')
                end,
            }, rect, rect.width / 5, 0)
        end
    end,  uit.BASE_HEIGHT, tabb.size(targets), uit.BASE_HEIGHT, sl)

    ui_panel.y = ui_panel.y + ui_panel.height
    ui.text("Patrol targets", ui_panel, "left", 'up')
    ui.text("Prepared forces", ui_panel, "right", 'up')
    ui_panel.y = ui_panel.y + uit.BASE_HEIGHT
    local targets = realm.provinces
    local sl = game.raiding_targets_slider_level or 0
    game.raiding_targets_slider_level = ui.scrollview(ui_panel, function(i, rect)
        if i > 0 then
            ---@type Rect
            local r = rect
            local width_unit = r.width / 5
            local x = r.x
            r.width = width_unit

            ---@type Province
            local target = tabb.nth(targets, i)
            ui.left_text(target.name, r)
            r.x = x + 4 * width_unit
            local warbands = realm.raiders_preparing[target]

            local size = 0
            if warbands ~= nil then
                for _, warband in pairs(warbands) do
                    size = size  + warband:size()
                end
            end
            ui.right_text(tostring(size), r)
        end
    end,  uit.BASE_HEIGHT, tabb.size(targets), uit.BASE_HEIGHT, sl)
end

return window