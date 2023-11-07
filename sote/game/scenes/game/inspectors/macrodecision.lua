local inspector = {}

local ui = require "engine.ui";
local ut = require "game.ui-utils"

local scroll = 0

---@return Rect
local function get_main_panel()
	local fs = ui.fullscreen()
	local panel = fs:subrect(ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 15 , fs.height - ut.BASE_HEIGHT * 2, "left", "up")
	return panel
end

---Returns whether or not clicks on the planet can be registered.
---@return boolean
function inspector.mask()
	if ui.trigger(get_main_panel()) then
		return false
	else
		return true
	end
end

---comment
---@param gam GameScene
function inspector.draw(gam)
    local rect = get_main_panel()

    ui.panel(rect)

    local top_rect = rect:subrect(0, 0, rect.width - UI_STYLE.slider_width, UI_STYLE.scrollable_list_item_height, "left", "up")

    ui.centered_text("Provincial decisions", top_rect)

    local decisions_rect = rect:subrect(
        0,
        UI_STYLE.scrollable_list_item_height,
        rect.width,
        rect.height - UI_STYLE.scrollable_list_item_height,
        "left",
        "up"
    )

    if WORLD.player_character == nil then
        return
    end

    -- love.graphics.print("Decision selection", rect.x, rect.y)
    local total = 0
    local valid = 0

    -- Maps decisions to whether or not they can be clicked.
    ---@type table<number, {[1]: DecisionCharacter, [2]: boolean}>
    local decisions = {}
    for _, decision in pairs(RAWS_MANAGER.decisions_characters_by_name) do
        if decision.primary_target == "province" then
            if decision.pretrigger(WORLD.player_character) then
                decisions[#decisions + 1] = { decision, true }
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


    scroll = ut.scrollview(
        decisions_rect,
        function(i, rect)
            if i > 0 then
                local dec = decisions[i]
                ---@type DecisionCharacter
                local decis = dec[1]
                local available = dec[2]
                local active = decis == gam.selected.macrodecision
                if ut.text_button(decis.ui_name, rect, nil, available, active) then
                    print("Player selected the macrodecision: " .. decis.name)
                    if active then
                        gam.selected.macrodecision = nil
                    else
                        gam.selected.macrodecision = decis
                    end
                end
            end
        end,
        UI_STYLE.scrollable_list_item_height,
        #decisions,
        UI_STYLE.slider_width,
        scroll
    )
end


return inspector