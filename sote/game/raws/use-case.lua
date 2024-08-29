---@class UseCase
local UseCase = {}

---Creates a new trade good
---@param o use_case_id_data_blob_definition
---@return use_case_id
function UseCase:new(o)
	if RAWS_MANAGER.do_logging then
		print("Trade Good Use Case: " .. tostring(o.name))
	end

	local r = DATA.create_use_case()
	DATA.setup_use_case(r, o)

	if RAWS_MANAGER.use_cases_by_name[o.name] ~= nil then
		local msg = "Failed to load a trade good use case (" .. tostring(o.name) .. ")"
		print(msg)
		error(msg)
	end

	RAWS_MANAGER.use_cases_by_name[o.name] = r
	return r
end

return UseCase
