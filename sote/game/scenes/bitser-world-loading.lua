return function ()
    WORLD_PROGRESS.total = 0
	WORLD_PROGRESS.max = 6 * DEFINES.world_size * DEFINES.world_size
	WORLD_PROGRESS.is_loading = true
	local bs = require "engine.bitser"
	local loading_coroutine = coroutine.create(function() bs.loadLoveFile_async(DEFINES.world_to_load, WORLD_PROGRESS) end)
	local result = nil
    local success = true
    local data = nil
	while success do
		success, result, data = coroutine.resume(loading_coroutine)
        print('loading step')
        print(result)
        print(WORLD_PROGRESS.total)
        if data ~= nil then
            WORLD = data
        end
		require "game.scenes.game.widgets.loading-bar"()
        coroutine.yield()
	end
	---@type World|nil
	WORLD = WORLD
	-- WORLD = bs.loadLoveFile(DEFINES.world_to_load, WORLD_PROGRESS)
	WORLD_PROGRESS.is_loading = false
end