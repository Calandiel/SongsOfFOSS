local ut = require "game.ui-utils"
local tooltip = require "game.raws.technologies".get_tooltip

---comment
---@param tech Technology
---@param rect Rect
---@param gam GameScene
return function (tech, rect, gam)
    local tooltip = tooltip(tech)

    local icon = DATA.technology_get_icon(tech)
    local name = DATA.technology_get_name(tech)
    local description = DATA.technology_get_description(tech)

    local icon_rect = rect:subrect(0, 0, rect.height, rect.height, "left", "up")
    if ut.icon_button(ASSETS.icons[icon], icon_rect) then
        CACHED_TECH = tech
        print(name)
        gam.update_map_mode("selected_technology")
    end

    local description_rect = rect:subrect(rect.height, 0, rect.width - rect.height, rect.height, "left", "up")
    ut.data_entry("", name, description_rect, tooltip, nil, "left")
end