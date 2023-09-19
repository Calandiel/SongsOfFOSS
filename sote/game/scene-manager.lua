local scene_manager = {}

local tab = require "engine.table"
local asl = require "game.scenes.asset-loader"
local mm = require "game.scenes.main-menu"
local wl = require "game.scenes.world-loader"
local ws = require "game.scenes.world-saver"
local gam = require "game.scenes.game"

---@alias SceneName
---A viable scene name
---| 'asset-loader'
---| 'main-menu'
---| 'world-loader'
---| 'world-saver'
---| 'game'
scene_manager.scenes = {
	{ "asset-loader", asl },
	{ "main-menu", mm },
	{ "world-loader", wl }, -- also potentially a world generator
	{ "world-saver", ws },
	{ "game", gam } -- for actual gameplay
}

--- A table containing the game state for the UI and so on.
if GAME_STATE == nil then
	GAME_STATE = {}
end
--- Call this when the game loads.
--- It'll set up the game state
function scene_manager.init()
	-- Game state is special data that *can* be persistent for the purpose of hot loading but isn't assets.
	GAME_STATE = {}
	GAME_STATE.scene = scene_manager.scenes[1]
	GAME_STATE.scene[2].init()
end

---
---@param dt number
function scene_manager.update(dt)
	GAME_STATE.scene[2].update(dt)
end

---
function scene_manager.draw()
	GAME_STATE.scene[2].draw()
end

---Transitions to a new scene
---@param new_scene_name SceneName
function scene_manager.transition(new_scene_name)
	print("Requesting scene transition from " .. GAME_STATE.scene[1] .. " to " .. new_scene_name)
	local found = false
	for i, j in ipairs(scene_manager.scenes) do
		if j[1] == new_scene_name then
			-- Scene found!
			GAME_STATE = {}
			GAME_STATE.scene = tab.copy(j)
			GAME_STATE.scene[2].init()
			found = true
			break
		end
	end
	if found == false then
		error("Scene " .. tostring(new_scene_name) .. " not found!")
	end
end

return scene_manager
