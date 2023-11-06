local tabb = require "engine.table"
local ui = require "engine.ui"
local uit = require "game.ui-utils"

local window = {}

local slider_warbands = 0
local slider_raiding_targets = 0


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
---@param game GameScene
function window.draw(game)
    local player_character = WORLD.player_character
    if player_character == nil then
        return
    end
    local realm = player_character.realm

    if realm == nil then
        return
    end

    local ui_panel = window.rect()
    -- draw a panel
    ui.panel(ui_panel)

    -- display warbands
    -- header
    ui_panel.height = ui_panel.height / 3 - uit.BASE_HEIGHT
    ui.text("Warbands", ui_panel, "left", 'up')

    if uit.icon_button(ASSETS.icons["cancel.png"], ui_panel:subrect(0, 0, uit.BASE_HEIGHT, uit.BASE_HEIGHT, "right", 'up')) then
        game.inspector = nil
    end

    -- substance
    ui_panel.y = ui_panel.y + uit.BASE_HEIGHT
    local warbands = realm:get_warbands()
    slider_warbands = uit.scrollview(ui_panel, function(i, rect) 
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
    end, uit.BASE_HEIGHT, tabb.size(warbands), uit.BASE_HEIGHT, slider_warbands)

    -- display raiding targets
    -- header
    ui_panel.y = ui_panel.y + ui_panel.height
    ui.text("Rewards", ui_panel, "left", 'up')
    -- ui.text("Prepared forces", ui_panel, "right", 'up')
    
    -- substance
    ui_panel.y = ui_panel.y + uit.BASE_HEIGHT
    local targets = realm.reward_flags
    slider_raiding_targets = uit.scrollview(ui_panel, function(i, rect)
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
                if uit.text_button('', rect) then
                    game.selected.reward_flag = target
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
    end,  uit.BASE_HEIGHT, tabb.size(targets), uit.BASE_HEIGHT, slider_raiding_targets)

    ui_panel.y = ui_panel.y + ui_panel.height
    ui.text("Patrol targets", ui_panel, "left", 'up')
    ui.text("Prepared forces", ui_panel, "right", 'up')
    ui_panel.y = ui_panel.y + uit.BASE_HEIGHT
    local targets = realm.reward_flags
    slider_raiding_targets = uit.scrollview(ui_panel, function(i, rect)
        if i > 0 then
            ---@type Rect
            local r = rect
            local width_unit = r.width / 5
            local x = r.x
            r.width = width_unit

            ---@type RewardFlag
            local target = tabb.nth(targets, i)
            ui.left_text(target.target.name, r)
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
    end, uit.BASE_HEIGHT, tabb.size(targets), uit.BASE_HEIGHT, slider_raiding_targets)
end

return window