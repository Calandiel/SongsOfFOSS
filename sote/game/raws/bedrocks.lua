local col = require "game.color"

local Bedrock = {}
Bedrock.__index = Bedrock
---@param o bedrock_id_data_blob_definition
---@return bedrock_id
function Bedrock:new(o)
	local new_id = DATA.create_bedrock()
	DATA.setup_bedrock(new_id, o)
	local color_id = col.rgb_to_id(o.r, o.g, o.b)
	DATA.bedrock_set_color_id(new_id, color_id)

	if RAWS_MANAGER.bedrocks_by_name[o.name] ~= nil or RAWS_MANAGER.bedrocks_by_color_id[color_id] ~= nil then
		local msg = "Failed to load a bedrock (" .. tostring(o.name) .. ")"
		print(msg)
		error(msg)
	end
	RAWS_MANAGER.bedrocks_by_name[o.name] = new_id
	RAWS_MANAGER.bedrocks_by_color_id[color_id] = new_id

	return new_id
end

return Bedrock
