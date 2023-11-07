local ut = require "game.ui-utils"

---comment
---@param tech Technology
---@param rect Rect
---@param gam GameScene
return function (tech, rect, gam)
    local tooltip = tech:get_tooltip()

    local icon_rect = rect:subrect(0, 0, rect.height, rect.height, "left", "up")
    if ut.icon_button(ASSETS.icons[tech.icon], icon_rect) then
        CACHED_TECH = tech
        print(tech.name)
        gam.update_map_mode("selected_technology")
    end

    local description_rect = rect:subrect(rect.height, 0, rect.width - rect.height, rect.height, "left", "up")
    ut.data_entry("", tech.name, description_rect, tooltip, nil, "left")
end