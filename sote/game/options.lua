


local opt = {}

function opt.init()
	return {
		['volume'] = 0,
		['fullscreen'] = true,
		['rotation'] = false,
		['update_map'] = true,
		['treasury_ledger'] = 120,
		['debug_mode'] = false,
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