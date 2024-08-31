local province_utils = require "game.entities.province".Province

local bld = {}

bld.Building = {}

---@param province province_id province to build the building in
---@param building_type building_type_id
---@return building_id
function bld.Building.new(province, building_type)
	local new_id = DATA.create_building()
	DATA.building_set_type(new_id, building_type)

	local location = DATA.fatten_building_location(DATA.create_building_location())

	location.building = new_id
	location.location = province

	return new_id
end

---Removes a building from the province and other relevant data structures.
---@param building building_id
function bld.Building.remove_from_province(building)
	DATA.delete_building(building)
end

return bld
