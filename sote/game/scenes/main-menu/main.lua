local mm = {}

local ui = require "engine.ui"
local ut = require "game.ui-utils"

---Draws the main menu screen
---@return string screen_name The name of the screen to render
function mm.draw()
	local fs = ui.fullscreen()

	local menu_button_width = 380
	local menu_button_height = 30
	local base = fs:subrect(0, 20, 400, 300, "center", "center")
	ui.panel(base)

	local ll = base:subrect(0, 10, 0, 0, "center", "up")
	local layout = ui.layout_builder()
		:position(ll.x, ll.y)
		:vertical()
		:centered()
		:spacing(10)
		:build()

	if ut.text_button(
		"New game",
		layout:next(menu_button_width, menu_button_height)
	) then
		return "default"
	end
	if ut.text_button(
		"Load game",
		layout:next(menu_button_width, menu_button_height)
	) then
		return "load-game"
	end
	-- default world replaces new game now
	-- if ui.text_button(
	-- 	"Default planet",
	-- 	layout:next(menu_button_width, menu_button_height)
	-- ) then
	-- 	return "default"
	-- end
	if ut.text_button(
		"Empty planet",
		layout:next(menu_button_width, menu_button_height)
	) then
		return "empty"
	end
	if IS_WINDOWS and ut.text_button(
		"New planet (WIP)",
		layout:next(menu_button_width, menu_button_height)
	) then
		return "new-planet"
	end
	if ut.text_button(
		"Options",
		layout:next(menu_button_width, menu_button_height)
	) then
		return "options"
	end
	if ut.text_button(
		"Quit",
		layout:next(menu_button_width, menu_button_height)
	) then
		love.event.quit()
	end


	ui.left_text(VERSION_STRING, fs:subrect(5, 0, 400, 30, "left", "down"))

	return "main"
end

return mm
