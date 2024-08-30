---@diagnostic disable: no-unknown

---@class (exact) BiogeographicRealm
---@field name string
---@field r number
---@field g number
---@field b number

local col = require "game.color"

local Realm = {}
Realm.__index = Realm
---@param o table
---@return BiogeographicRealm
function Realm:new(o)
	local r = {}
	r.name = "biogeographic-realm"
	r.r = 0
	r.g = 0
	r.b = 0

	for k, v in pairs(o) do
		r[k] = v
	end

	setmetatable(r, Realm)

	if RAWS_MANAGER.do_logging then
		print("------")
		print(type(WORLD))
	end
	local id = col.rgb_to_id(r.r, r.g, r.b)
	if RAWS_MANAGER.biogeographic_realms_by_name[r.name] ~= nil or RAWS_MANAGER.biogeographic_realms_by_color[id] ~= nil then
		local msg = "Failed to load a biogeographic realm (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end
	RAWS_MANAGER.biogeographic_realms_by_name[r.name] = r
	RAWS_MANAGER.biogeographic_realms_by_color[id] = r
	return r
end

return Realm
