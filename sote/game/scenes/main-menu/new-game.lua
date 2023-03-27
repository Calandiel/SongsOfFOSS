local mm = {}

local ui = require "engine.ui"

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

	-- Reset defines...
	---@diagnostic disable-next-line: undefined-global
	DEFINES = require "game.defines".init()
	DEFINES.observer = ui.named_checkbox(
		"Observe",
		layout:next(menu_button_width, menu_button_height),
		DEFINES.observer,
		5
	)

	if ui.text_button(
		"Generate",
		layout:next(menu_button_width, menu_button_height)
	) then
		return "generating"
	end
	if ui.text_button(
		"Return",
		layout:next(menu_button_width, menu_button_height)
	) then
		return "main"
	end


	ui.left_text(VERSION_STRING, fs:subrect(5, 0, 400, 30, "left", "down"))

	return "new-game"
end



return mm