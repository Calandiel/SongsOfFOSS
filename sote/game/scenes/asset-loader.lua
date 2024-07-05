local asl = {}

asl.message = "Initializing assets loading..."

---
function asl.init()

end

---
---@param dt number
function asl.update(dt)

end

---
function asl.draw()
	local ui = require "engine.ui"
	ui.background(ASSETS.background)

	if asl.coroutine == nil then
		asl.coroutine = coroutine.create(asl.load_assets)
	end
	coroutine.resume(asl.coroutine)

	if coroutine.status(asl.coroutine) == "dead" then
		-- Well, if the coroutine is dead it means that loading finished...
		if ASSETS.all_done then
			local manager = require "game.scene-manager"
			manager.transition("main-menu")
		else
			print("Failed to load assets!")
			error("Failed to load assets!")
			love.event.quit()
		end
	end
end

function asl.load_assets()
	local yield_counter = 0
	coroutine.yield()

	asl.message = "Loading icons..."
	if not SILENT_ASSET_LOADING then print(asl.message) end
	---@type table<string, love.Image>
	ASSETS.icons = {}
	local fs = love.filesystem.getDirectoryItems("icons")
	for _, f in pairs(fs) do
		local icon = love.graphics.newImage(
			"icons/" .. f,
			{
				mipmaps = true,
				linear = false,
				dpiscale = 1
			}
		)
		icon:setFilter("linear", "linear", 2)
		ASSETS.icons[f] = icon
		-- Make sure to yield every now and then so that we don't hang the core!
		yield_counter = yield_counter + 1
		if yield_counter == 25 then
			yield_counter = 0
			coroutine.yield()
		end
	end
	coroutine.yield()

	asl.message = "Loading music..."
	if not SILENT_ASSET_LOADING then print(asl.message) end
	ASSETS.music = {}
	local ms = love.filesystem.getDirectoryItems("music")
	for _, m in pairs(ms) do
		table.insert(ASSETS.music, love.audio.newSource("music/" .. m, "stream"))
		ASSETS.music[#ASSETS.music]:setVolume(0.15)
		-- Make sure to yield every now and then so that we don't hang the core!
		yield_counter = yield_counter + 1
		if yield_counter == 25 then
			yield_counter = 0
			coroutine.yield()
		end
	end
	coroutine.yield()

	asl.message = "Loading sfx..."
	if not SILENT_ASSET_LOADING then print(asl.message) end
	---@type table<string, love.Source>
	ASSETS.sfx = {}
	local ms = love.filesystem.getDirectoryItems("sfx")
	for _, m in pairs(ms) do
		ASSETS.sfx[m] = love.audio.newSource("sfx/" .. m, "static")
		-- Make sure to yield every now and then so that we don't hang the core!
		yield_counter = yield_counter + 1
		if yield_counter == 25 then
			yield_counter = 0
			coroutine.yield()
		end
	end
	coroutine.yield()

	asl.message = "Loading emblems..."
	if not SILENT_ASSET_LOADING then print(asl.message) end
	ASSETS.emblems = {}
	local fs = love.filesystem.getDirectoryItems("emblems")
	for _, f in pairs(fs) do
		local emblem = love.graphics.newImage("emblems/" .. f)
		table.insert(ASSETS.emblems, emblem)
		-- Make sure to yield every now and then so that we don't hang the core!
		yield_counter = yield_counter + 1
		if yield_counter == 25 then
			yield_counter = 0
			coroutine.yield()
		end
	end
	coroutine.yield()

	asl.message = "Loading coa..."
	if not SILENT_ASSET_LOADING then print(asl.message) end
	ASSETS.coas = {}
	local fs = love.filesystem.getDirectoryItems("coa")
	for _, f in pairs(fs) do
		local c = love.graphics.newImage("coa/" .. f)
		table.insert(ASSETS.coas, c)
		-- Make sure to yield every now and then so that we don't hang the core!
		yield_counter = yield_counter + 1
		if yield_counter == 25 then
			yield_counter = 0
			coroutine.yield()
		end
	end
	coroutine.yield()

	asl.message = "Loading portraits..."
	if not SILENT_ASSET_LOADING then print(asl.message) end

	---@type table<string, love.Image>
	ASSETS.portraits = {}
	local fs = love.filesystem.getDirectoryItems("portraits")
	for _, folder in pairs(fs) do
		if not SILENT_ASSET_LOADING then print(folder) end
		ASSETS.portraits[folder] = {}
		local folder_content = love.filesystem.getDirectoryItems("portraits/" .. folder)
		for _, image_name in pairs(folder_content) do
			local c = love.graphics.newImage("portraits/" .. folder .. "/" .. image_name)
			ASSETS.portraits[folder][image_name] = c
			if not SILENT_ASSET_LOADING then print("portraits/" .. folder .. "/" .. image_name) end
			-- Make sure to yield every now and then so that we don't hang the core!
			yield_counter = yield_counter + 1
			if yield_counter == 25 then
				yield_counter = 0
				coroutine.yield()
			end
		end
	end
	coroutine.yield()

	ASSETS.all_done = true
end

return asl
