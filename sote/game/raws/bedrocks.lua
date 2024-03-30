---@class (exact) Bedrock
---@field name string
---@field r number
---@field g number
---@field b number
---@field sand number
---@field silt number
---@field clay number
---@field organics number
---@field minerals number
---@field weathering number

local col = require "game.color"

local Bedrock = {}
Bedrock.__index = Bedrock
---@param o Bedrock
---@return Bedrock
function Bedrock:new(o)
	local r = {}
	r.name = "bedrock"
	r.r = 0
	r.g = 0
	r.b = 0
	r.sand = 0
	r.silt = 0
	r.clay = 0
	r.organics = 0
	r.minerals = 0
	r.weathering = 0
	r.igneous_extrusive = false
	r.acidity = 0.0
	r.igneous_intrusive = false
	r.sedimentary = false
	r.clastic = false
	r.grain_size = 0.0
	r.evaporative = false
	r.metamorphic_marble = false
	r.metamorphic_slate = false
	r.oceanic = false
	r.sedimentary_ocean_deep = false
	r.sedimentary_ocean_shallow = false
	for k, v in pairs(o) do
		r[k] = v
	end
	setmetatable(r, Bedrock)

	local id = col.rgb_to_id(r.r, r.g, r.b)
	if RAWS_MANAGER.bedrocks_by_name[r.name] ~= nil or RAWS_MANAGER.bedrocks_by_color[id] ~= nil then
		local msg = "Failed to load a bedrock (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end
	RAWS_MANAGER.bedrocks_by_name[r.name] = r
	RAWS_MANAGER.bedrocks_by_color[id] = r

	return r
end

return Bedrock
