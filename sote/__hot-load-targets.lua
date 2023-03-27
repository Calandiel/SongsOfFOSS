--[[

This table should contain a "list" of files that need to be hot-reloaded in a limited hot load.
Use this to make development easier!

]]
local modules_to_reload = {
	"main",
	"engine.hot-load",
	"__hot-load-targets",
}

return modules_to_reload