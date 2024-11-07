local ui = require "engine.ui"
local ut = require "game.ui-utils"

local pathfinding = require "game.ai.pathfinding"


---comment
---@param gam GameScene
---@param rect Rect rect for hover detection to draw path
---@param length number
---@param path Province[]
---@param tile_to_x_y fun(tile: tile_id): number, number, number
local function path(gam, rect, length, path, tile_to_x_y)
	if ui.hover_clicking_status(rect) then
		local previous = nil
		local prev_screen_x = 0
		local prev_screen_y = 0
		for index, current in ipairs(path) do
			local center = DATA.province_get_center(current)
			local current_x, current_y, _ = tile_to_x_y(center)
			local screen_x, screen_y = ui.ui_coord_to_screen_coord(current_x, current_y)

			if previous ~= nil then
				love.graphics.line(
					prev_screen_x,
					prev_screen_y,
					screen_x,
					screen_y
				)
			end

			previous = current
			prev_screen_x = screen_x
			prev_screen_y = screen_y
		end

		local days_rect = rect:copy()
		days_rect.y = days_rect.y - rect.height / 2
		days_rect.x = days_rect.x - rect.height
		days_rect.width = days_rect.width + rect.height * 2
		days_rect.height = rect.height / 2

		ut.log_number_entry("days: ", pathfinding.hours_to_travel_days(length), days_rect, nil, true)
	end
end

return path