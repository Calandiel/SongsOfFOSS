---@class (exact) Resource
---@field __index Resource
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field required_biome table<number, Biome>
---@field required_bedrock table<number, Bedrock>
---@field base_frequency number number of tiles per which this resource is spawned
---@field coastal boolean
---@field land boolean
---@field water boolean
---@field minimum_trees number
---@field maximum_trees number
---@field minimum_elevation number
---@field maximum_elevation number
---@field ice_age boolean requires presence of ice age ice

---@class Resource
local Resource = {}
Resource.__index = Resource
---Creates a new resource
---@param o Resource
---@return Resource
function Resource:new(o)
	print("Resource: " .. tostring(o.name))
	---@type Resource
	local r = {}

	r.name = "<resource>"
	r.icon = 'uncertainty.png'
	r.description = "<resource description>"
	r.r = 0
	r.g = 0
	r.b = 0
	r.base_frequency = 1000
	r.coastal = false
	r.land = true
	r.water = false
	r.required_bedrock = {}
	r.required_biome = {}
	r.minimum_trees = 0
	r.maximum_trees = 1
	r.minimum_elevation = -math.huge
	r.maximum_elevation = math.huge
	r.ice_age = false

	for k, v in pairs(o) do
		r[k] = v
	end
	setmetatable(r, Resource)
	if RAWS_MANAGER.resources_by_name[r.name] ~= nil then
		local msg = "Failed to load a resource (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end
	RAWS_MANAGER.resources_by_name[r.name] = r
	return r
end

return Resource
