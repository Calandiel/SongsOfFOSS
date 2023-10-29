local ut = require "game.ui-utils"


---@param gam table
---@param realm Realm
---@param unit number
---@param rect Rect
---@param mode 'immediate'|'callback'|nil
local function realm_name(gam, realm, unit, rect, mode)
    if mode == nil then
        mode = 'immediate'
    end

    local COA_rect = rect:subrect(0, 0, unit, unit, "left", 'up')

    local function press()
        gam.inspector = "realm"
        gam.selected.realm = realm
        ---@type Tile
        local captile = realm.capitol.center
        gam.click_tile(captile.tile_id)
    end

    if ut.coa(realm, COA_rect) then
        print("Player COA Clicked")
        print(mode)

        if mode == 'immediate' then
            press()
            return true
        else
            return press
        end
    end

    local name_rect = rect:subrect(unit, 0, rect.width - unit, unit, "left", 'up')
    ut.data_entry("", realm.name, name_rect)

    return false
end


return realm_name