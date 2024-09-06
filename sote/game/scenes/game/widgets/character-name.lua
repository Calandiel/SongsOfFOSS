local ui = require "engine.ui"
local ranks_localisation = require "game.raws.ranks.localisation"
local string = require "engine.string"

---comment
---@param rect Rect
---@param character_id Character
local function name(rect, character_id)
    -- rect = rect:shrink(5)
    local realm = REALM(character_id)

    local title = DATA.pop_get_name(character_id) .. "\n"
    if realm ~= INVALID_ID then

        local overseer = DATA.get_realm_overseer_from_overseer(character_id)
        if overseer ~= INVALID_ID then
            title = title .. " Overseer,"
        end

        local collector = DATA.get_tax_collector_from_collector(character_id)
        if collector ~= INVALID_ID then
            title = title .. " Tribute Collector,"
        end

        local guard = DATA.get_realm_guard_from_realm(realm)
        if (guard ~= INVALID_ID) then
            local warband = DATA.realm_guard_get_guard(guard)
            local recruiter_rel = DATA.get_warband_recruiter_from_warband(warband)
            local recruiter = DATA.warband_recruiter_get_recruiter(recruiter_rel)
            if character_id == recruiter then
                title = title .. " Protector,"
            end
        end
    end

    title = title .. " \n" .. string.title(ranks_localisation(character_id))
    ui.text(title .. " of " .. DATA.realm_get_name(realm), rect, "left", "up")
end

return name