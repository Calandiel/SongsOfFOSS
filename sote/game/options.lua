


local opt = {}


function opt.init()
	return {
		["volume"] = 0,
		["fullscreen"] = FULLSCREEN.FALSE,
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

function opt.load()
	local bs = require "engine.bitser"
	return bs.loadLoveFile("options.bin")
end

function opt.verify()
	local default = opt.init()

	for i, j in pairs(default) do
		if OPTIONS[i] == nil then
			OPTIONS[i] = j
		end
	end
end


return opt