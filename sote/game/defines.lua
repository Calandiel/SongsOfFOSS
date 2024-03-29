local def = {}

---@class (exact) Defines
---@field observer boolean
---@field world_gen boolean
---@field world_to_load string
---@field world_size number
---@field empty boolean
---@field default boolean

---Creates and returns defines as a table
---@return Defines
function def.init()
	return {
		observer = true,
		world_gen = true,
		world_to_load = "<error>",
		world_size = 410, --409,
		empty = false,
		default = false,
	}
end

return def
