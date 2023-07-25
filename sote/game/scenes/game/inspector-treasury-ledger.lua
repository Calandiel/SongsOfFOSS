local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"



local window = {}

local scroll = 0

---@type nil|'character'|'realm'
window.current_filter = nil

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

---Filters treasury changes
---@param data TreasuryEffectRecord[]
---@return TreasuryEffectRecord[]
local function filter(data)
    if window.current_filter == nil then
        return data
    end

    if window.current_filter == 'character' then
        local filtered_data = {}
        for i, v in ipairs(data) do
            if v.character_flag then
                table.insert(filtered_data, v)
            end
        end
        return filtered_data
    end

    if window.current_filter == 'realm' then
        local filtered_data = {}
        for i, v in ipairs(data) do
            if not v.character_flag then
                table.insert(filtered_data, v)
            end
        end
        return filtered_data
    end

    return data
end


function window.draw(game, realm)
    local ui_panel = window.rect()
    local base_unit = ut.BASE_HEIGHT
    ui.panel(ui_panel)

    -- display warbands
    -- header
    ui_panel.height = ui_panel.height - base_unit
    if ui.icon_button(ASSETS.icons["cancel.png"], ui_panel:subrect(0, 0, base_unit, base_unit, "right", 'up')) then
        game.inspector = nil
    end

    if ui.text_button('Character', ui_panel:subrect(0, 0, base_unit * 4, base_unit, "left", 'up'), "Display only character changes") then
        window.current_filter = 'character'
    end
    if ui.text_button('Realm', ui_panel:subrect(base_unit * 4, 0, base_unit * 4, base_unit, "left", 'up'), "Display only realm changes") then
        window.current_filter = 'realm'
    end
    
    ui_panel.y = ui_panel.y + base_unit
    
    local data_blob = {}
    for index = WORLD.old_treasury_effects.first, WORLD.old_treasury_effects.last do
        table.insert(data_blob, WORLD.old_treasury_effects.data[index])
    end

    local data = filter(data_blob)

    local function render_treasury_change(i, rect)
        ---@type TreasuryEffectRecord
        local effect = data[i]
        if effect ~= nil then
            if effect.reason == "new month" then
                ui.left_text(tostring(effect.day) .. " " .. ut.months[effect.month + 1] .. ' of year ' .. effect.year, rect)
            else
                ut.money_entry(effect.reason, effect.amount, rect)
            end
        end
    end

    local treasury_ledger_rect = ui_panel:copy():shrink(10)
    ui.panel(treasury_ledger_rect)
    scroll = ui.scrollview(
        treasury_ledger_rect, 
        render_treasury_change, 
        15,
        #data,
        base_unit,
        scroll)
end

return window