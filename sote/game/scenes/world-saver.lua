local ws = {}

local loader_error = nil -- write this in coroutines to transmit the error out of coroutines scope...
---
function ws.init()

end

---
---@param dt number
function ws.update(dt)

end


function ws.draw()
	local ui = require "engine.ui"
	ui.background(ASSETS.background)
	ws.message = "Saving the world..."

	SAVE_GAME_STATE()

	-- Well, if the coroutine is dead it means that saving finished...
	WORLD_PROGRESS.is_loading = false
	local manager = require "game.scene-manager"
	manager.transition("game")
end

return ws