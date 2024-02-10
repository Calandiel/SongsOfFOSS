
local opt = {}

---@alias Fullscreen "false" | "exclusive" | "desktop"
---@class Options
---@field ["version"] string
---@field ["volume"] number
---@field ["fullscreen"] Fullscreen
---@field ["fitscreen"] boolean
---@field ["rotation"] boolean
---@field ["update_map"] boolean
---@field ["treasury_ledger"] number
---@field ["debug_mode"] boolean
---@field ["zoom_sensitivity"] number
---@field ["camera_sensitivity"] number
---@field ["exploration"] number
---@field ["travel-start"] number
---@field ["travel-end"] number
---@field ["screen_resolution"] {width: number, height: number}

---@return Options
function opt.init()
	return {
		["version"] = "v0.3.1",
		["volume"] = 0,
		["fullscreen"] = "false",
		["fitscreen"] = true,
		["rotation"] = false,
		["update_map"] = false,
		["treasury_ledger"] = 120,
		["debug_mode"] = false,
		["zoom_sensitivity"] = 1,
		["camera_sensitivity"] = 1,
		["exploration"] = 0,
		["travel-start"] = 0,
		["travel-end"] = 0,
		["screen_resolution"] = {width = 1280, height = 720}
	}
end

function opt.save()
	local bs = require "engine.bitser"
	bs.dumpLoveFile("options.bin", OPTIONS)
end

---@return Options
function opt.load()
	local bs = require "engine.bitser"
	return bs.loadLoveFile("options.bin")
end

function opt.verify()
	local default = opt.init()

	if OPTIONS.version ~= default.version then
		OPTIONS = default
		return
	end
	
	for i, j in pairs(default) do
		if OPTIONS[i] == nil then
			OPTIONS[i] = j
		end
	end
end

---@param fullscreen Fullscreen
function opt.updateFullscreen(fullscreen)
	if OPTIONS == nil then return end
	---@class Options
	OPTIONS = OPTIONS
	local ui = require "engine.ui"
	OPTIONS.fullscreen = fullscreen
	if fullscreen == "false" then
		love.window.setFullscreen(false)
	else
		love.window.setFullscreen(true, fullscreen)
	end
	local dim_x, dim_y = love.graphics.getDimensions()
	if fullscreen ~= "false" and OPTIONS.fitscreen then
		if fullscreen == "desktop" then
			ui.set_reference_screen_dimensions(dim_x, dim_y)
		else
			ui.set_reference_screen_dimensions(OPTIONS.screen_resolution.width/dim_y,OPTIONS.screen_resolution.height/dim_x)
		end
	else
		ui.set_reference_screen_dimensions(OPTIONS.screen_resolution.width,OPTIONS.screen_resolution.height)
	end
	if GAME_STATE.scene[1] == "game" then
		if fullscreen == "desktop" or (fullscreen == "exclusive" and OPTIONS.fitscreen) then
			GAME_STATE.scene[2].game_canvas = love.graphics.newCanvas(dim_x,dim_y)
		else
			GAME_STATE.scene[2].game_canvas = love.graphics.newCanvas(OPTIONS.screen_resolution.width,OPTIONS.screen_resolution.height)
		end
	end
	require "game.ui-utils".reload_font()
end

return opt