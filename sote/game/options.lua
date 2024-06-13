local opt = {}

---@class Options
---@field ["version"] string
---@field ["volume"] number
---@field ["screen_resolution"] {width: number, height: number}
---@field ["fullscreen"] love.FullscreenType
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

---@return Options
function opt.init()
	return {
		["version"] = VERSION_STRING,
		["volume"] = 0,
		["screen_resolution"] = { width = 1280, height = 720 },
		["fullscreen"] = "normal",
		["fitscreen"] = true,
		["rotation"] = true,
		["update_map"] = true,
		["treasury_ledger"] = 120,
		["debug_mode"] = false,
		["zoom_sensitivity"] = 0.25,
		["camera_sensitivity"] = 0.25,
		["exploration"] = 0,
		["travel-start"] = 0,
		["travel-end"] = 0,
		["needs-inventory"] = false,
		["needs-savings"] = 1 / 12,
		["needs-hunt"] = 1 / 4,
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

---@param fullscreen love.FullscreenType
function opt.updateFullscreen(fullscreen)
	if OPTIONS == nil then return end
	---@class Options
	OPTIONS = OPTIONS
	local ui = require "engine.ui"
	OPTIONS.fullscreen = fullscreen
	if fullscreen == "normal" then
		love.window.setFullscreen(false)
	else
		love.window.setFullscreen(true, fullscreen)
	end
	local dim_x, dim_y = love.graphics.getDimensions()
	if fullscreen ~= "normal" and OPTIONS.fitscreen then
		if fullscreen == "desktop" then
			ui.set_reference_screen_dimensions(dim_x, dim_y)
		else
			ui.set_reference_screen_dimensions(OPTIONS.screen_resolution.width / dim_y,
				OPTIONS.screen_resolution.height / dim_x)
		end
	else
		ui.set_reference_screen_dimensions(OPTIONS.screen_resolution.width, OPTIONS.screen_resolution.height)
	end
	if GAME_STATE.scene[1] == "game" then
		if fullscreen == "desktop" or (fullscreen == "exclusive" and OPTIONS.fitscreen) then
			GAME_STATE.scene[2].game_canvas = love.graphics.newCanvas(dim_x, dim_y)
		else
			GAME_STATE.scene[2].game_canvas = love.graphics.newCanvas(OPTIONS.screen_resolution.width,
				OPTIONS.screen_resolution.height)
		end
	end
	require "game.ui-utils".reload_font()
end

return opt
