local mm = {}

local ui = require "engine.ui"
local screen = nil; -- declare "screen"
---
function mm.init()
	screen = "main"
end

---
---@param dt number
function mm.update(dt)

end

---
function mm.draw()
	ui.background(ASSETS.background)
	if screen == nil then
		screen = "main"
	end

	if screen == "main" then
		screen = require "game.scenes.main-menu.main".draw()
	elseif screen == "new-game" then
		screen = require "game.scenes.main-menu.new-game".draw()
	elseif screen == "load-game" then
		screen = require "game.scenes.main-menu.load-game".draw()
	elseif screen == "options" then
		screen = require "game.scenes.main-menu.options".draw()
	elseif screen == "generating" then
		local manager = require "game.scene-manager"
		manager.transition("world-loader")
	elseif screen == "empty" then
		-- Reset defines...
		---@diagnostic disable-next-line: undefined-global
		DEFINES = require "game.defines".init()
		DEFINES.empty = true
		local manager = require "game.scene-manager"
		manager.transition("world-loader")
	elseif screen == "default" then
		-- Reset defines...
		---@diagnostic disable-next-line: undefined-global
		DEFINES = require "game.defines".init()
		DEFINES.default = true
		local manager = require "game.scene-manager"
		manager.transition("world-loader")
	else
		love.graphics.setColor(1, 0, 0, 1)
		ui.centered_text("!!! UNKNOWN PANEL !!!", ui.fullscreen())
		love.graphics.setColor(1, 1, 1, 1)
	end
end


return mm