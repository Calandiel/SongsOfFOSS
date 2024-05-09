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
	if ws.coroutine == nil then
		ws.message = "Saving the world..."
        WORLD_PROGRESS.total = 0
        WORLD_PROGRESS.max = 6 * DEFINES.world_size * DEFINES.world_size
        WORLD_PROGRESS.is_loading = true
		ws.coroutine = coroutine.create(function ()
			require "engine.bitser".dumpLoveFile_async(DEFINES.world_to_load, WORLD)
			require "engine.bitser".clearBuffer()
		end)
	end

	local status, data = coroutine.resume(ws.coroutine)
	ui.text_panel(ws.message, ui.fullscreen():subrect(
		0, 0, 300, 60, "center", "down"
	))
    if type(data) == "number" then
        -- print(data)
        WORLD_PROGRESS.total = data
        require "game.scenes.game.widgets.loading-bar"()
    end

    -- print(status)

	if coroutine.status(ws.coroutine) == "dead" then
		-- Well, if the coroutine is dead it means that saving finished...
        WORLD_PROGRESS.is_loading = false
		print(debug.traceback(ws.coroutine))
		if loader_error ~= nil then
			error(loader_error)
			return
		end
		ws.coroutine = nil
		local manager = require "game.scene-manager"
		manager.transition("game")
	end
end

return ws