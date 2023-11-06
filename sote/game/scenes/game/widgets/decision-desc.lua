local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

local scroll = 0

---@alias DecisionWidgetResponse 'cancel'|'ok'|'nothing'


---Renders the decision widget
---@param rect Rect
---@param root any
---@param decision DecisionCharacter|DecisionRealm?
---@param target_primary any
---@param target_secondary any
---@return DecisionWidgetResponse
return function(rect, root, decision, target_primary, target_secondary)
    ---@type Rect
    local r = rect
    r.height = r.height - ut.BASE_HEIGHT
    -- Here, we need to check for the decision to render
    if decision then
        ---@type DecisionRealm|DecisionCharacter|nil
        local dec = decision
        if dec then
            local needs_secondary = dec.secondary_target ~= 'none'
            local can_check_viability = true
            if needs_secondary then
                if target_primary then
                    -- Secondary target search
                    if target_secondary then
                        can_check_viability = true
                    else
                        can_check_viability = false
                    end
                    -- Since the decision needs potential targets, let's just search for some!
                    local secondaries = dec.get_secondary_targets(root, target_primary)
                    if #secondaries > 0 then
                        scroll = ut.scrollview(
                            r, function(i, rect)
                                if i > 0 then
                                    local s = secondaries[i]
                                    local secondary_name = '---'
                                    if dec.secondary_target == 'tile' then
                                        secondary_name = tostring(s.tile_id)
                                    elseif dec.secondary_target == 'character' or dec.secondary_target == 'province' or
                                        dec.secondary_target == 'realm' then
                                        secondary_name = s.name
                                    elseif dec.secondary_target == 'building' then
                                        secondary_name = s.type.name
                                    end
                                    if s == target_secondary then
                                        ui.text_panel(secondary_name .. " (*)", rect)
                                    else
                                        if ut.text_button(secondary_name, rect) then
                                            target_secondary = s
                                        end
                                    end
                                end
                            end, ut.BASE_HEIGHT, #secondaries, ut.BASE_HEIGHT, scroll
                        )
                    end
                end
            end

            r.height = r.height + ut.BASE_HEIGHT
            -- If a decision is present, draw two button at the bottom
            local exit = r:subrect(0, 0, ut.BASE_HEIGHT * 3, ut.BASE_HEIGHT, "left", 'down')
            local confirm = r:subrect(0, 0, ut.BASE_HEIGHT * 3, ut.BASE_HEIGHT, "right", 'down')
            if ut.text_button("Cancel", exit) then
                -- Clear the decision data, it's not needed anymore
                return 'cancel'
            elseif can_check_viability then
                if dec.available(root, target_primary, target_secondary) then
                    if ut.text_button("Select", confirm) then
                        dec.effect(root, target_primary, target_secondary)
                        return 'ok'
                    end
                else
                    ut.text_button("Select", confirm, "Conditions not met!", false)
                end
            end
        end
    end

    return 'nothing'
end