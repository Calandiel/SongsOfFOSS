local ui = require "engine.ui";

return function()
	if WORLD_PROGRESS ~= nil then
		if WORLD_PROGRESS.is_loading then
			local loading_rect = ui.fullscreen():subrect(0, 0, 300, 50, "center", "center")
            ui.panel(loading_rect)
            local progress = WORLD_PROGRESS.total / WORLD_PROGRESS.max * 300
            local progress_bar = loading_rect:subrect(0, 0, progress, 50, "left", "up")

            local temporary_r = ui.style.panel_inside.r
            ui.style.panel_inside.r = 1.0
            ui.panel(progress_bar)
            ui.style.panel_inside.r = temporary_r
			-- ui.slider(loading_rect, , 0, 1, false, 50)
		end
	end
end