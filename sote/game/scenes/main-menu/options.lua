local mm = {}

local ui = require "engine.ui"

function mm.rect() return ui.fullscreen():subrect(0, 20, 250, 300, "center", "center")
end

function mm.mask()
	if ui.trigger(mm.rect()) then
		return false
	else
		return true
	end
end

---Draws the main menu screen
---@return string screen_name The name of the screen to render
function mm.draw()
	local fs = ui.fullscreen()

	local menu_button_width = 230
	local menu_button_height = 30
	local base = mm.rect()
	ui.panel(base)

	local ll = base:subrect(0, 10, 0, 0, "center", "up")
	local layout = ui.layout_builder()
		:position(ll.x, ll.y)
		:vertical()
		:centered()
		:spacing(10)
		:build()

	-- VOLUME
	local new_volume = ui.named_slider(
		"Volume",
		layout:next(menu_button_width, menu_button_height * 2),
		love.audio.getVolume(), 0, 1, 0.1
	)
	love.audio.setVolume(new_volume)
	OPTIONS.volume = new_volume
	-- FULLSCREEN
	local original = OPTIONS.fullscreen
	OPTIONS.fullscreen = ui.named_checkbox(
		"Fullscreen",
		layout:next(menu_button_width, menu_button_height), OPTIONS.fullscreen,
		5
	)
	if original ~= OPTIONS.fullscreen then
		-- if the status changed, update the fullscreen state...
		love.window.setFullscreen(OPTIONS.fullscreen)
		require "game.ui-utils".reload_font()
	end

	-- ROTATION
	OPTIONS.rotation = ui.named_checkbox(
		"Rotate camera on zoom",
		layout:next(menu_button_width, menu_button_height), OPTIONS.rotation,
		5
	)

	-- RETURN
	if ui.text_button(
		"Return",
		layout:next(menu_button_width, menu_button_height)
	) then
		local opt = require "game.options"
		opt.save()
		return "main"
	end

	ui.left_text(VERSION_STRING, fs:subrect(5, 0, 400, 30, "left", "down"))

	return "options"
end



return mm