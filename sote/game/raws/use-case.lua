---@class UseCase
local UseCase = {}

---Creates a new trade good
---@param o use_case_id_data_blob
---@return use_case_id
function UseCase:new(o)
	if RAWS_MANAGER.do_logging then
		print("Trade Good Use Case: " .. tostring(o.name))
	end

	local r = DATA.fatten_use_case(DATA.create_use_case())

	r.name = "<trade good use case>"
	r.icon = "uncertainty.png"
	r.description = "<trade good use case description>"
	r.r = 0
	r.g = 0
	r.b = 0

	for k, v in pairs(o) do
		r[k] = v
	end

	if RAWS_MANAGER.use_cases_by_name[r.name] ~= nil then
		local msg = "Failed to load a trade good use case (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end

	RAWS_MANAGER.use_cases_by_name[r.name] = r.id
	return r.id
end

return UseCase
