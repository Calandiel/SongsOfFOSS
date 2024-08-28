local col = require "game.color"

local bedrock_index = 1

local Bedrock = {}
Bedrock.__index = Bedrock
---@param o bedrock_id_data_blob
---@return bedrock_id
function Bedrock:new(o)
	local r = DATA.fatten_bedrock(bedrock_index)
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

	-- print(r.g, r.g, r.b)
	r.color_id = col.rgb_to_id(r.r, r.g, r.b)
	print(r.name, r.color_id)
	-- print(r.color_id)

	if RAWS_MANAGER.bedrocks_by_name[r.name] ~= nil or RAWS_MANAGER.bedrocks_by_color_id[r.color_id] ~= nil then
		local msg = "Failed to load a bedrock (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end
	RAWS_MANAGER.bedrocks_by_name[r.name] = r.id
	RAWS_MANAGER.bedrocks_by_color_id[r.color_id] = r.id

	bedrock_index = bedrock_index + 1

	return r.id
end

return Bedrock
