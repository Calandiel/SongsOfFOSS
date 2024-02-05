local mm = {}

local ui = require "engine.ui"
local ut = require "game.ui-utils"

function mm.rect()
	return ui.fullscreen():subrect(0, 20, 300, 600, "center", "center")
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
	local menu_button_height = 28
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
	local new_volume = ut.named_slider(
		"Volume",
		layout:next(menu_button_width, menu_button_height * 1.5),
		love.audio.getVolume(), 0, 1, 0.05
	)
	love.audio.setVolume(new_volume)
	OPTIONS.volume = new_volume

	-- ZOOM SENS
	OPTIONS.zoom_sensitivity = ut.named_slider(
		"Zoom sensitivity",
		layout:next(menu_button_width, menu_button_height * 1.5),
		OPTIONS.zoom_sensitivity, 0.01, 5, 0.05
	)

	-- CAMERA SENS
	OPTIONS.camera_sensitivity = ut.named_slider(
		"Camera sensitivity",
		layout:next(menu_button_width, menu_button_height * 1.5),
		OPTIONS.camera_sensitivity, 0.01, 20, 0.05
	)

	-- FULLSCREEN
	local original = OPTIONS.fullscreen
	local fullscreen_text = "Windowed"
	if original == "exclusive" then fullscreen_text = "Exclusive"
	elseif original == "desktop" then fullscreen_text = "Desktop" end
	if ut.text_button(
		fullscreen_text,
		layout:next(menu_button_width, menu_button_height)
	) then
		if original == "normal" then OPTIONS.fullscreen = "exclusive"
		elseif original == "exclusive" then OPTIONS.fullscreen = "desktop"
		else OPTIONS.fullscreen = "normal" end
	end
	if original ~= OPTIONS.fullscreen then
		-- if the status changed, update the fullscreen state...
		if OPTIONS.fullscreen == "normal" then love.window.setFullscreen(false)
		else love.window.setFullscreen(true, OPTIONS.fullscreen) end
		require "game.ui-utils".reload_font()
	end

	-- ROTATION
	OPTIONS.rotation = ui.named_checkbox(
		"Rotate camera on zoom",
		layout:next(menu_button_width, menu_button_height), OPTIONS.rotation,
		5
	)

	-- Map update
	OPTIONS.update_map = ui.named_checkbox(
		"Update map every month",
		layout:next(menu_button_width, menu_button_height), OPTIONS.update_map,
		5
	)

	-- Debug Mode
	OPTIONS.debug_mode = ui.named_checkbox(
		"Debug mode",
		layout:next(menu_button_width, menu_button_height), OPTIONS.debug_mode,
		5
	)

	--- treasury ledger
	ui.centered_text("Saved treasury history", layout:next(menu_button_width, menu_button_height))
	local flag_120 = ui.named_checkbox("120 lines", layout:next(menu_button_width, menu_button_height), OPTIONS['treasury_ledger'] == 120, 5)
	if flag_120 then
		OPTIONS['treasury_ledger'] = 120
	end
	local flag_600 = ui.named_checkbox("600 lines", layout:next(menu_button_width, menu_button_height), OPTIONS['treasury_ledger'] == 600, 5)
	if flag_600 then
		OPTIONS['treasury_ledger'] = 600
	end


	-- RETURN
	if ut.text_button(
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