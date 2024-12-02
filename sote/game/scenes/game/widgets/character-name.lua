local ui = require "engine.ui"
local ranks_localisation = require "game.raws.ranks.localisation"
local string = require "engine.string"

---comment
---@param rect Rect
---@param character_id Character
local function name(rect, character_id)
    if character_id == INVALID_ID then
        return "Invalid character"
    end

    -- rect = rect:shrink(5)
    local realm = REALM(character_id)

    local title = DATA.pop_get_name(character_id) .. "\n"
    if realm ~= INVALID_ID then

        local overseer_of = DATA.realm_overseer_get_realm(DATA.get_realm_overseer_from_overseer(character_id))
        if overseer_of ~= INVALID_ID then
            title = title .. " Overseer,"
        end

        local collector_of = DATA.tax_collector_get_realm(DATA.get_tax_collector_from_collector(character_id))
        if collector_of ~= INVALID_ID then
            title = title .. " Tribute Collector,"
        end

        local guard = DATA.realm_guard_get_guard(DATA.get_realm_guard_from_realm(realm))
        if (guard ~= INVALID_ID) then
            local recruiter_rel = DATA.get_warband_recruiter_from_warband(guard)
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