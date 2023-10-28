local ut = require "game.ui-utils"


---@param gam table
---@param realm Realm
---@param unit number
---@param rect Rect
local function realm_name(gam, realm, unit, rect)

    local COA_rect = rect:subrect(0, 0, unit, unit, "left", 'up')
    if ut.coa(realm, COA_rect) then
        print("Player COA Clicked")
        gam.inspector = "realm"
        gam.selected.realm = realm
        ---@type Tile
        local captile = realm.capitol.center
        gam.click_tile(captile.tile_id)

        return true
    end

    local name_rect = rect:subrect(unit, 0, rect.width - unit, unit, "left", 'up')
    ut.data_entry("", realm.name, name_rect)

    return false
end


return realm_name