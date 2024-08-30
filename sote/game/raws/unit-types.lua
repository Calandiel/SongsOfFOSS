
local UnitType = {}

---Creates a new unit type
---@param o unit_type_id_data_blob_definition
---@return unit_type_id
function UnitType:new(o)
	if RAWS_MANAGER.do_logging then
		print("Unit Type: " .. tostring(o.name))
	end

	local new_id = DATA.create_unit_type()
	DATA.setup_unit_type(new_id, o)

	local required_tech = o.unlocked_by
	local fat = DATA.fatten_technology_unit(DATA.create_technology_unit())
	fat.technology = required_tech
	fat.unlocked = new_id

	if RAWS_MANAGER.unit_types_by_name[o.name] ~= nil then
		local msg = "Failed to load a unit type (" .. tostring(o.name) .. ")"
		print(msg)
		error(msg)
	end
	RAWS_MANAGER.unit_types_by_name[o.name] = new_id
	return new_id
end

return UnitType
