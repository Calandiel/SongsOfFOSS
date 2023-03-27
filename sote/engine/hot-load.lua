-- Most of this code comes from the lume library for lua!
local hot_load = {}
local copy = require("engine.table").copy
local patternescape = require("engine.string").patternescape
local trim = require("engine.string").trim

--- Hotswaps ALL loaded modules that start with a string present in the passed table.
--- Potentially finnicky. Prefer the limited hotswap whenever possible.
--- The second table takes in a list of modules to reload. Use it to reload files that aren't placed in directories.
---@param hot_loadable_directories table
---@param post_load table
function hot_load.full_hotswap(hot_loadable_directories, post_load)
	print("== full hot load ==")
	hot_loadable_directories = hot_loadable_directories or {}
	post_load = post_load or {}
	-- Since package.loaded contains built-in packages we need to make sure we only hot load things defined by the game.
	-- We'll do it by checking the very beginning of the module name.
	-- If it starts with one of the following, hot load it.
	local starts_with = require("engine.string").starts_with
	for i, j in pairs(package.loaded) do
		-- Check if it's possible to hot load that file (aka does it exist in one of three predefined directories?)
		local hotloadable = false
		for k, v in pairs(hot_loadable_directories) do
			if starts_with(i, v) then
				hotloadable = true
				break
			end
		end
		if hotloadable then
			hot_load.hotswap(i)
		else
			--print("Skipped: " .. i)
		end
	end
	for i, j in pairs(post_load) do
		hot_load.hotswap(j)
	end
	print("== hot load success ==")
end

--- Hotswaps all modules defined in the passed table.
---@param to_hot_load table
function hot_load.limited_hotswap(to_hot_load)
	print("== limited hot load ==")
	-- Loop over all entries and hotswap them
	for i, j in pairs(to_hot_load) do
		hot_load.hotswap(j)
	end
	print("== hot load success ==")
end

--- Hotswaps only a single module. modname is a string following the same conventions as 'require'
---@param modname string
---@return any, string|nil
function hot_load.hotswap(modname)
	print("------ " .. modname)
	local oldglobal = copy(_G)
	local updated = {}
	local function update(old, new)
		if updated[old] then return end
		updated[old] = true
		local oldmt, newmt = getmetatable(old), getmetatable(new)
		if oldmt and newmt then update(oldmt, newmt) end
		for k, v in pairs(new) do
		if type(v) == "table" then update(old[k], v) else old[k] = v end
		end
	end
	local err = nil
	local function onerror(e)
		print("!!! Error when loading " .. modname .. ",\n" .. tostring(e) .. "\n")
		for k in pairs(_G) do _G[k] = oldglobal[k] end
		err = trim(e, nil)
	end
	local ok, oldmod = pcall(require, modname)
	oldmod = ok and oldmod or nil
	xpcall(function()
		package.loaded[modname] = nil
		local newmod = require(modname)
		if type(oldmod) == "table" then update(oldmod, newmod) end
		for k, v in pairs(oldglobal) do
			if v ~= _G[k] and type(v) == "table" then
				update(v, _G[k])
				_G[k] = v
			end
		end
	end, onerror)
	package.loaded[modname] = oldmod
	if err then return nil, err end
	return oldmod
end


return hot_load