local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

---Filters treasury changes
---@param data TreasuryEffectRecord[]
---@param filter nil|'character'|'realm'
---@return TreasuryEffectRecord[]
local function filter(data, filter)
    if filter == nil then
        return data
    end

    if filter == 'character' then
        local filtered_data = {}
        for i, v in ipairs(data) do
            if v.character_flag then
                table.insert(filtered_data, v)
            end
        end
        return filtered_data
    end

    if filter == 'realm' then
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

---Renders selected treasury ledger and returns current scroll
---@param rect Rect
---@param filter_tag nil|'character'|'realm'
---@param scroll number
---@param base_unit number
---@return number
return function (rect, filter_tag, scroll, base_unit)
    local data_blob = {}
    for index = WORLD.old_treasury_effects.first, WORLD.old_treasury_effects.last do
        table.insert(data_blob, WORLD.old_treasury_effects.data[index])
    end
    local data = filter(data_blob, filter_tag)
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
    ui.panel(rect)
    return ui.scrollview(
        rect,
        render_treasury_change,
        15,
        #data,
        base_unit,
        scroll)
end