local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

local scroll = 0

---Renders a list of decisions and returns selected decision
---@param rect Rect
---@param decision_type DecisionTarget
---@param primary_target any
---@param selected_decision any
---@return DecisionCharacter?, any, any
return function(rect, decision_type, primary_target, selected_decision)
    -- love.graphics.print("Decision selection", rect.x, rect.y)
    local total = 0
    local valid = 0

    -- Maps decisions to whether or not they can be clicked.
    ---@type table<number, table<DecisionRealm, boolean>>
    local decisions = {}
    for _, decision in pairs(RAWS_MANAGER.decisions_characters_by_name) do
        if decision.primary_target == decision_type then
            if decision.pretrigger(WORLD.player_character) and decision.clickable(WORLD.player_character, primary_target) then
                if decision.available(WORLD.player_character, primary_target) then
                    -- Decision is clickable
                    decisions[#decisions + 1] = { decision, true }
                else
                    decisions[#decisions + 1] = { decision, false }
                end
                valid = valid + 1
            end
            total = total + 1
        end
    end
    -- love.graphics.print("Total" .. tostring(total), rect.x, rect.y)
    -- love.graphics.print("Valid" .. tostring(valid), rect.x, rect.y + 20)

    -- Once the list of decisions is known, we can sort it by the decisions sorting order
    table.sort(decisions, function(a, b)
        return a[1].sorting < b[1].sorting
    end)

    local res_decision = selected_decision 
    local res_target_p = primary_target 
    local res_target_s = nil
    scroll = ui.scrollview(
        rect, function(i, rect)
            if i > 0 then
                local dec = decisions[i]
                ---@type DecisionCharacter
                local decis = dec[1]
                if dec[2] then
                    if decis == selected_decision then
                        ui.text_panel(decis.ui_name .. " (*)", rect)
                        ui.tooltip(decis.tooltip(WORLD.player_character, primary_target), rect)
                    else
                        if ui.text_button(decis.ui_name, rect, decis.tooltip(WORLD.player_character, primary_target)) then
                            -- We need to draw this specific decisions UI now!
                            print("Player selected the decision: " .. decis.name)
                            -- We'll be auto pausing the game when selected decision isn't nil so this is fine
                            res_decision, res_target_p, res_target_s = decis, primary_target, nil
                            print(res_decision)
                        end
                    end
                else
                    ui.text_panel(decis.ui_name, rect)
                    ui.tooltip(decis.tooltip(WORLD.player_character, primary_target), rect)
                end
            end
        end, ut.BASE_HEIGHT, #decisions, ut.BASE_HEIGHT, scroll
    )
    return res_decision, res_target_p, res_target_s
end