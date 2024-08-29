
local Resource = {}

---Creates a new resource
---@param o resource_id_data_blob_definition
---@return resource_id
function Resource:new(o)
	if RAWS_MANAGER.do_logging then
		print("Resource: " .. tostring(o.name))
	end

	local new_id = DATA.create_resource()
	DATA.setup_resource(new_id, o)

	if RAWS_MANAGER.resources_by_name[o.name] ~= nil then
		local msg = "Failed to load a resource (" .. tostring(o.name) .. ")"
		print(msg)
		error(msg)
	end
	RAWS_MANAGER.resources_by_name[o.name] = new_id

	return new_id
end

return Resource
